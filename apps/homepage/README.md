# homepage

Homelab dashboard at https://home.example.com ([Homepage](https://gethomepage.dev)),
behind Authelia (group `admins`, 2FA). Works on the phone over WireGuard; "Add to Home
Screen" makes it an app.

- `config/` — the dashboard itself (services, top-bar widgets, settings). Edit, push,
  Argo CD rolls it out (the configmap name changes with its content, so the pod restarts).
- Kubernetes numbers (nodes, pods per service) come from the cluster with a read-only
  service account (`rbac.yaml`); Longhorn from its in-cluster API.
- Proxmox: read-only API token of user `homepage@pve` (role `PVEAuditor` on `/`), in
  Vault at `secret/k8s/homepage/proxmox` (`token-id`, `token-secret`). The pve-exporter of
  ansible-k3s-homelab's monitoring role can share it (`monitoring_vault_proxmox_key`).

Widget credentials are always read-only tokens/keys from Vault, as `HOMEPAGE_VAR_*`
(`external-secret.yaml`), referenced in `config/*.yaml` as `{{HOMEPAGE_VAR_...}}`.
