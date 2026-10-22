# forgejo-runner

Runs Forgejo Actions jobs for `git.example.com` (runner `k3s-runner`, label `host`), as a
plain Deployment: no Docker daemon, no privileged pod, no persistent state.

Jobs run as plain processes inside the runner pod (the runner's "host" backend): no Docker
daemon and no privileged pod. So workflows use `runs-on: host` and shell `run:` steps only;
JavaScript actions such as `actions/checkout` need Node and aren't available. The image is
Alpine with bash, git and wget; workflows download any other tool they need, pinned by
checksum.

The shared secret is in Vault `secret/k8s/forgejo/runner`. It was registered once in Forgejo
(global runner, label `host`):

    vault kv get -field=secret secret/k8s/forgejo/runner | tr -d '\n' | kubectl -n forgejo \
      exec -i deploy/forgejo -c forgejo -- sh -c 'forgejo forgejo-cli actions register \
      --name k3s-runner --labels host --secret "$(cat)"'

(Not `--secret-stdin`: that flag wants an argument, and without one it fails while still
exiting 0.)

Example workflow: the image mirror (`image-mirror/` in this repo).
