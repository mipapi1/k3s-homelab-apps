#!/bin/bash
# Copies every container image referenced in the given directories into this Forgejo's
# registry, under the `mirror` org:
#   lscr.io/linuxserver/plex:1.2.3  ->  git.example.com/mirror/lscr.io/linuxserver/plex:1.2.3
#   alpine:3.22                      ->  git.example.com/mirror/docker.io/library/alpine:3.22
# The whole multi-platform index is copied unchanged, so its digest stays the same and
# manifests pinned with @sha256 match the copy. Images already copied are skipped.
# The k3s nodes pull from these copies first (ansible role registry_mirror).
#
# Usage: mirror-images.sh DIR...   (needs crane, logged in to the registry)
set -euo pipefail
DEST_REGISTRY=${DEST_REGISTRY:-git.example.com}
DEST_ORG=${DEST_ORG:-mirror}
CRANE=${CRANE:-crane}

images=$(find "$@" -name '*.yaml' -exec grep -hE '^[[:space:]]*-?[[:space:]]*image:[[:space:]]*[^[:space:]]+' {} + \
  | sed -E 's/^[[:space:]]*-?[[:space:]]*image:[[:space:]]*//; s/["'"'"']//g; s/[[:space:]].*$//' | sort -u)

copied=0; current=0; failed=0
for src in $images; do
  ref=${src%@*}
  digest=""; [[ $src == *@* ]] && digest=${src#*@}
  name=${ref%:*}; tag=${ref##*:}
  [[ $ref == *:* && $tag != */* ]] || { name=$ref; tag=latest; }
  first=${name%%/*}
  if [[ $name == */* && ( $first == *.* || $first == *:* ) ]]; then
    registry=$first; path=${name#*/}
  else
    registry=docker.io; path=$name; [[ $path == */* ]] || path=library/$path
  fi
  [[ $registry == "$DEST_REGISTRY" ]] && continue

  pull=$registry/$path:$tag; [[ -n $digest ]] && pull=$registry/$path@$digest
  dest=$DEST_REGISTRY/$DEST_ORG/$registry/$path:$tag
  want=$($CRANE digest "$pull") || { echo "FAILED (upstream) $src"; failed=$((failed+1)); continue; }
  have=$($CRANE digest "$dest" 2>/dev/null || true)
  if [[ $want == "$have" ]]; then
    echo "current  $dest"; current=$((current+1)); continue
  fi
  if $CRANE copy "$pull" "$dest"; then
    echo "copied   $dest ($want)"; copied=$((copied+1))
  else
    echo "FAILED   $src"; failed=$((failed+1))
  fi
done
echo "done: copied=$copied current=$current failed=$failed"
[ "$failed" -eq 0 ]
