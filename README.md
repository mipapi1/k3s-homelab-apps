# k3s-homelab-apps

Apps from a three-node k3s homelab, as plain Kustomize folders that Argo CD deploys. These
are the ones worth reusing: GPU transcoding, an image mirror kept current by reviewed PRs,
and monitoring set up from code.

They're copied from the cluster's own (private) repo, with addresses, names and
domains replaced by `example.com` and `192.168.x.x`. The comments say why things are set
the way they are.

## Apps

| Folder | What it is |
|---|---|
| [`apps/plex`](apps/plex) | Plex with hardware transcoding on a passed-through Intel iGPU; library from a NAS over NFS |
| [`apps/intel-gpu`](apps/intel-gpu) | Intel GPU device plugin: offers `/dev/dri` to pods as `gpu.intel.com/i915` |
| [`apps/renovate`](apps/renovate) | Renovate as a nightly CronJob against Forgejo: one PR per image update |
| [`apps/forgejo-runner`](apps/forgejo-runner) | Forgejo Actions runner without Docker (shell steps only) |
| [`image-mirror/`](image-mirror) | Workflow and script that copy every image under `apps/` into your registry, before a PR is merged |
| [`apps/uptime`](apps/uptime) | Uptime Kuma, its monitors and notifications configured from git, plus a heartbeat |
| [`apps/homepage`](apps/homepage) | Homepage dashboard with Kubernetes and Proxmox widgets |

Each folder has a README with its settings and the Vault entries it reads.

## How it's deployed

One folder = one app = one namespace. An Argo CD ApplicationSet (installed by role
`argocd` of [ansible-k3s-homelab](https://github.com/mipapi1/ansible-k3s-homelab)) turns
every folder under `apps/` into an Application, named after the folder, deployed into a
namespace of the same name, with automated sync, prune and self-heal:

```yaml
generators:
  - git:
      repoURL: https://git.example.com/you/cluster.git
      directories: [{path: apps/*}]
template:
  metadata: {name: '{{.path.basename}}'}
  spec:
    source: {path: '{{.path.path}}'}
    destination: {namespace: '{{.path.basename}}'}
```

Adding an app is adding a folder; deleting the folder removes the app. Nothing here
needs Argo CD, though: `kubectl apply -k apps/<name>` works on any Kubernetes.

## What the apps expect

The platform from [ansible-k3s-homelab](https://github.com/mipapi1/ansible-k3s-homelab):

- **External Secrets** with a `ClusterSecretStore` named `vault`. Secrets come from Vault
  (`secret/k8s/<app>/...`), never from git.
- **Longhorn** as the default StorageClass; bulk data over NFS.
- **Traefik** ingress, and **Authelia** in namespace `authelia`. UIs that need a login
  bring their own `forwardAuth` Middleware pointing at it; NetworkPolicies let only
  Traefik reach those pods, so the login can't be bypassed.
- TLS ends at a proxy in front of the cluster, so ingresses are plain HTTP.
- VMs, including the iGPU passthrough, from
  [terraform-proxmox-vm](https://github.com/mipapi1/terraform-proxmox-vm).

## Conventions

- **Images pinned by tag, most also by digest** (`tag@sha256:...`). Renovate updates
  both; the mirror copies whole multi-platform images, so the digests still match.
- **Upstream image names in manifests.** The nodes pull from the mirror first and fall
  back to upstream (see [`image-mirror/`](image-mirror)).
- **Volumes that hold data aren't pruned** (`argocd.argoproj.io/sync-options: Prune=false`),
  so deleting an app folder can't delete its database.

## Testing

CI builds every app with `kubectl kustomize` and validates the result with
[kubeconform](https://github.com/yannh/kubeconform) (strict, CRDs from the
[CRDs catalog](https://github.com/datreeio/CRDs-catalog)), parses the JavaScript, runs
shellcheck, and scans the history for secrets.

## License

MIT
