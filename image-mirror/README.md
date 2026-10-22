# image-mirror

Keeps a copy of every container image the cluster uses in your own registry (Forgejo's
package registry), and keeps the versions current with reviewed PRs:

```
Renovate (apps/renovate, nightly)   Mirror workflow (Forgejo Actions)          k3s nodes
 newer image upstream?   ──PR──▶     copies every image under apps/      ──▶   pull docker.io / ghcr.io / lscr.io
 opens one PR per update             to git.example.com/mirror/<registry>/…     images from the mirror first,
 (you review and merge)              (on PRs, pushes to main, nightly)          upstream if a copy is missing
```

- **Manifests keep upstream image names** (`lscr.io/linuxserver/plex:…`). The nodes'
  containerd redirects the pull (`/etc/rancher/k3s/registries.yaml`, written by role
  `registry_mirror` of [ansible-k3s-homelab](https://github.com/mipapi1/ansible-k3s-homelab)).
  If Forgejo is down or a copy is missing, the pull falls back to the upstream registry, so
  the mirror can't stop pods from starting.
- **Whole multi-platform images are copied** (`crane copy`), so their digests stay the
  same and `@sha256` pins in the manifests match the copies.
- **Copies are made before a PR is merged**: the workflow runs on Renovate's PRs, so the
  new version is already in the mirror when Argo CD rolls it out.
- **Runs on a runner without Docker** ([`apps/forgejo-runner`](../apps/forgejo-runner)):
  shell steps only, `crane` downloaded and checked against its SHA-256.

## Files

Copy them into your cluster repo:

| File | Goes to |
|---|---|
| `.forgejo/workflows/mirror-images.yaml` | same path; set `IMAGE_DIRS` (folders with manifests) and the registry host |
| `.forgejo/scripts/mirror-images.sh` | same path; `DEST_REGISTRY` and `DEST_ORG` set the target |
| `renovate.json` | repo root; `managerFilePatterns` = which manifests Renovate updates |

## Setup in Forgejo

1. A bot user (`ci-bot`, not an admin) and an organization `mirror` (private) that the bot
   owns. Packages pushed to `git.example.com/mirror/...` belong to that organization.
2. Protect `main` of the cluster repo so only you can push and merge (Argo CD deploys
   `main`); give the bot write access for its own branches and PRs.
3. Three tokens for the bot, each with only what it needs:
   - `write:package, read:repository`: Actions secret `MIRROR_TOKEN` of the cluster repo
   - `read:package`: the nodes' pull token (`registry_mirror_password`)
   - repository and issue write, user/organization/package read: Renovate
4. `renovate.json`'s linuxserver.io rule: their tags are
   `<version>[-<build>]-ls<revision>`; the regex compares the version, then the revision,
   and ignores the build id (otherwise Renovate sees every build as a new version).
