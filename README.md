# Platform Engineering Workshop — Helm Charts

Helm charts that deploy a complete Platform Engineering workshop environment on OpenShift 4.x. Designed for use with the [platform-engineering-workshop](https://github.com/rhpds/platform-engineering-workshop) Ansible-based deployer, which bootstraps the cluster and deploys a single Argo CD `Application` CR pointing to the `app-of-apps/` chart. From there, Argo CD manages everything.

> [!NOTE]
> This is a **workshop/demo environment**. Some design choices (storing passwords in Vault at deploy time, broad RBAC grants, shared credentials) reflect that priority. Don't use this as a production reference architecture.

## What gets deployed

The workshop stands up the following on a single OpenShift cluster:

| Component | Chart | Purpose |
|---|---|---|
| **HashiCorp Vault** | `vault/` | Secrets backend — stores tokens, passwords, and credentials |
| **External Secrets Operator** | `external-secrets/` | Syncs Vault secrets into Kubernetes `Secret` resources via `ExternalSecret` CRs |
| **OpenShift Pipelines** | `openshift-pipelines/` | Tekton-based CI/CD |
| **NooBaa** | `noobaa/` | S3-compatible object storage (backing store for Quay) |
| **GitLab** | `gitlab/` | Source code management — users, groups, and repos are created via init Jobs |
| **Keycloak** | `keycloak/` | SSO/OIDC provider for Developer Hub, Trusted Artifact Signer, and OpenShift login |
| **OpenShift OAuth** | `openshift-oauth/` | Adds Keycloak as an OpenID identity provider on the cluster OAuth CR |
| **Quay** | `quay/` | Container image registry |
| **RHDH GitOps** | `gitops/` | Dedicated Argo CD instance for Developer Hub-managed applications |
| **Red Hat Developer Hub** | `redhat-developer-hub/` | Internal developer portal (Backstage) |
| **Trusted Artifact Signer** | `rhtas/` | Sigstore-based container image signing (Fulcio, Rekor, etc.) |

## App-of-apps pattern

The `app-of-apps/` chart is the root. It renders one Argo CD `Application` CR per component, each pointing back into this same repository at the appropriate chart path. Argo CD then syncs each child Application independently.

Sync waves control ordering:

- **Wave 0** — Foundational: Vault, External Secrets, OpenShift Pipelines, NooBaa
- **Wave 1** — Services: GitLab, Keycloak, Quay, RHDH GitOps
- **Wave 2** — Consumers: Red Hat Developer Hub, Trusted Artifact Signer

Every child Application uses a foreground deletion finalizer, so deleting the root app-of-apps Application cascade-deletes everything.

## Secret management

Vault is the single source of truth for secrets. The flow works like this:

1. **Ansible** provides known secrets (common password, Keycloak client secrets, ArgoCD password, etc.) as Helm values when creating the app-of-apps Application
2. **Vault's setup Job** (`vault/templates/cm-vault-setup.yaml`) initialises the KV v2 engine, configures Kubernetes auth, and **pre-populates** these known secrets at `kv/secrets/<service>/...` paths
3. **Service init Jobs** (GitLab, Quay) generate additional secrets at runtime (GitLab root PAT, webhook secret, Quay registry credentials) and write them to Vault
4. **ExternalSecret CRs** in the RHDH prereqs chart pull secrets from Vault into Kubernetes Secrets that Developer Hub consumes

> [!IMPORTANT]
> The Vault setup Job pre-populates secrets using values passed through Helm. In a production setup you'd use a proper secret injection workflow. Here, the tradeoff is acceptable because the passwords are generated once by Ansible and the cluster is ephemeral.

### Vault paths

| Path | Written by | Consumed by |
|---|---|---|
| `kv/secrets/gitlab/root-password` | Vault setup Job | — |
| `kv/secrets/gitlab/token` | GitLab init Job | RHDH (ExternalSecret) |
| `kv/secrets/gitlab/webhook-secret` | GitLab init Job | — |
| `kv/secrets/keycloak/client-secret` | Vault setup Job | RHDH (ExternalSecret) |
| `kv/secrets/keycloak/openshift-client-secret` | Vault setup Job | OpenShift OAuth (ExternalSecret) |
| `kv/secrets/keycloak/plugin-client-secret` | Vault setup Job | — |
| `kv/secrets/quay/auth` | Quay config Job | — |
| `kv/secrets/quay/username` | Quay config Job | — |
| `kv/secrets/quay/password` | Quay config Job | — |
| `kv/secrets/rhdh/argocd-password` | Vault setup Job | RHDH (ExternalSecret) |
| `kv/secrets/rhdh/postgresql-password` | Vault setup Job | RHDH (ExternalSecret) |
| `kv/secrets/rhdh/kubernetes-sa-token` | RHDH SA token Job | RHDH (ExternalSecret) |
| `kv/secrets/gitlab/devspaces-oauth` | GitLab init Job | DevSpaces (ExternalSecret) |
| `kv/secrets/common/password` | Vault setup Job | — |

## Developer authentication

Workshop users (dev1, dev2, pe1, pe2) authenticate via Keycloak. The `openshift-oauth/` chart adds a **"developers"** OpenID Connect identity provider to the cluster OAuth CR alongside the default htpasswd provider. Users see both options on the OpenShift login page.

DevSpaces reuses this flow — the DevSpaces operator hardcodes `provider="openshift"` in its gateway proxy config, so it always authenticates through OpenShift OAuth, which in turn redirects to Keycloak.

## Embedded Ansible playbooks

Several charts use a pattern where a `ConfigMap` contains an Ansible playbook, and a `Job` runs it using an Ansible execution environment image. This handles multi-step imperative setup that can't be expressed declaratively:

- **`vault/templates/cm-vault-setup.yaml`** — Initialises Vault: retrieves the root token, creates policies, enables Kubernetes auth, enables the KV engine, and pre-populates secrets
- **`gitlab/templates/cm-gitlab-init.yaml`** — Waits for GitLab to be ready, creates a root PAT, configures application settings, creates users/groups/repos, imports repositories, and writes the PAT + webhook secret to Vault
- **`quay/quay-registry/templates/cm-config.yaml`** — Waits for the Quay registry to be ready, creates the admin user, extends the API token expiration, and writes registry credentials to Vault
- **`redhat-developer-hub/redhat-developer-hub-prereqs/templates/cm-sa-token-writer.yaml`** — Creates a `kubernetes.io/service-account-token` Secret, waits for the token to be populated, and writes it to Vault so RHDH can use it for cluster access
- **`redhat-developer-hub/redhat-developer-hub-config-template/templates/rhdh-config-template.yaml`** — Clones the Developer Hub config repo from GitLab, templates it with cluster-specific values, and pushes the result back

These Jobs use the `quay.io/agnosticd/ee-multicloud` execution environment image (or `ose-cli` for simpler scripts) and follow Helm/Argo CD sync-wave ordering to ensure dependencies are ready.

## Vault auto-unseal

Vault uses Shamir key shares stored on the pod's PVC. A `CronJob` (`vault/templates/cronjob-auto-unseal.yaml`) runs every minute to check Vault's seal status and automatically unseal it if needed. This handles:

- **Initial deployment** — initialises Vault, stores unseal keys, and unseals
- **Pod/cluster restarts** — detects the sealed state and unseals using the persisted keys

## Verifying RHTAS

To verify the Trusted Artifact Signer installation:

1. Login to the OpenShift cluster

2. Download `cosign` from the OCP console "Command Line Tools" and install it in your PATH

3. `oc project trusted-artifact-signer`

4. Setup your environment:

```
export TUF_URL=$(oc get tuf -o jsonpath='{.items[0].status.url}' -n trusted-artifact-signer)
export OIDC_ISSUER_URL=https://$(oc get route keycloak -n keycloak | tail -n 1 | awk '{print $2}')/realms/backstage
export COSIGN_FULCIO_URL=$(oc get fulcio -o jsonpath='{.items[0].status.url}' -n trusted-artifact-signer)
export COSIGN_REKOR_URL=$(oc get rekor -o jsonpath='{.items[0].status.url}' -n trusted-artifact-signer)
export COSIGN_MIRROR=$TUF_URL
export COSIGN_ROOT=$TUF_URL/root.json
export COSIGN_OIDC_CLIENT_ID="trusted-artifact-signer"
export COSIGN_OIDC_ISSUER=$OIDC_ISSUER_URL
export COSIGN_CERTIFICATE_OIDC_ISSUER=$OIDC_ISSUER_URL
export COSIGN_YES="true"
export SIGSTORE_FULCIO_URL=$COSIGN_FULCIO_URL
export SIGSTORE_OIDC_ISSUER=$COSIGN_OIDC_ISSUER
export SIGSTORE_REKOR_URL=$COSIGN_REKOR_URL
export REKOR_REKOR_SERVER=$COSIGN_REKOR_URL
```

5. `cosign initialize`

6. Sign an arbitrary container image:

```
echo "FROM scratch" > ./tmp.Dockerfile
podman build . -f ./tmp.Dockerfile -t ttl.sh/rhtas/test-image:1h
podman push ttl.sh/rhtas/test-image:1h
cosign sign -y ttl.sh/rhtas/test-image:1h
```

When asked to authenticate, use one of the registered workshop users, e.g. `dev1@rhdemo.com`.

7. Verify the signature:

```
cosign verify --certificate-identity=dev1@rhdemo.com ttl.sh/rhtas/test-image:1h | jq
```

8. Show signature/security info related to the OCI artifact:

```
cosign tree ttl.sh/rhtas/test-image:1h
```