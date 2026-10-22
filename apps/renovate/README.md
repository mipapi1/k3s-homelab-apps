# renovate

Every night at 06:00 Renovate compares the images in your cluster repo with their
registries and opens a PR in Forgejo for each newer version, as a bot user (`ci-bot`).
Rules are in `renovate.json` at the root of that repo (example:
[`image-mirror/renovate.json`](../../image-mirror/renovate.json)). Nothing merges on its
own: review and merge the PR, and Argo CD rolls it out.

Opening a PR also triggers the mirror workflow
([`image-mirror/`](../../image-mirror)), which copies the new image into your own
registry before it's merged.

Set `RENOVATE_ENDPOINT`, `RENOVATE_REPOSITORIES` and `RENOVATE_GIT_AUTHOR` in
`renovate.yaml`. The bot's token (scopes: repository and issue write, user, organization
and package read) is in Vault `secret/k8s/forgejo/ci-bot`, key `renovate-token`.

Run it now instead of waiting:

    kubectl -n renovate create job --from=cronjob/renovate renovate-manual
