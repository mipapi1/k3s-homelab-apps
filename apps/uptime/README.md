# uptime

Monitoring and alerts. https://uptime.example.com, behind
Authelia (group `admins` or `app-uptime`).

- **Uptime Kuma** checks every service once a minute and alerts by push (ntfy.sh topic)
  and email (SMTP settings in `kuma-config.yaml`) when one stays down, again every hour
  while it's still down (in case the first alert couldn't be sent, e.g. the internet was
  down too), and when it's back. Kuma's own login is turned off (Settings → Security), Authelia does it.
- **Monitors and alert channels are in git**: `kuma-config/monitors.json`. After every Argo
  CD sync of this app, the `kuma-config` job (`kuma-config.yaml`) applies it: missing
  monitors are created, existing ones (same name) are overwritten with what's in git.
  Monitors added by hand in the UI are left alone, and removing one from the file doesn't
  delete it in Kuma (delete it in the UI too). History lives in Kuma's database on its
  volume (nightly Longhorn backups).
- **Quiet during backups**: the same job keeps a maintenance window "Nightly backups"
  (`configure.js`): every day 03:00-04:00 (the job's `TZ`), all monitors, no alerts. Alertmanager
  mutes the same hour. Anything still down at 04:00 alerts then.
- **Heartbeat** (`heartbeat.yaml`): every 2 minutes a job reports to healthchecks.io
  whether Kuma is up. healthchecks.io is outside the homelab, so if the cluster or the
  home internet goes down, the reports stop and it alerts by itself.

## Vault

| Path | Keys |
|---|---|
| `secret/k8s/uptime/healthchecks` | `ping-url` (healthchecks.io check, period 2 min) |
| `secret/k8s/uptime/ntfy` | `topic` (long random ntfy.sh topic; anyone who knows it can read the alerts) |
| `secret/k8s/uptime/smtp` | `password` (for `SMTP_USERNAME`), `to` (where alert emails go) |

Kuma checks apps behind Authelia directly, so their NetworkPolicies must allow Kuma
(namespace `uptime`, pod label `app: uptime-kuma`) on their web ports, next to
the rule for Traefik.
