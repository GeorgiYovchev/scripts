#!/bin/bash
set -euo pipefail

TARGET_REGISTRY="oddstechexternal.cr.de-fra.ionos.com"

# Full list of external images to mirror
IMAGES=(
  "quay.io/skopeo/stable:latest"
  "quay.io/strimzi/kafka:0.45.0-kafka-3.9.0"
  "quay.io/strimzi/operator:0.45.0"
  "registry.gitlab.com/gitlab-org/gitlab-runner:alpine-v17.11.3"
  "registry.infra.cluster.ionos.com/mk8s-public/images/registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.14.0-clean.1"
  "registry.infra.cluster.ionos.com/registry.k8s.io/kube-proxy:v1.32.6"
  "registry.k8s.io/ingress-nginx/controller:v1.11.6@sha256:4f04fad99f00e604ab488cf0945b4eaa2a93f603f97d2a45fc610ff0f3cad0f9"
  "registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.16.0"
  "weblate/weblate:5.11.3.0@sha256:b72921998206f1eb57b4b198f21a76612cc02c6fe3f08965e34ba2a9906f55cb"
)

for IMAGE in "${IMAGES[@]}"; do
  echo "=== Processing $IMAGE ==="

  # Strip only the first registry part (before first '/')
  REPO=$(echo "$IMAGE" | sed -E 's|^[^/]+/||')

  TARGET="$TARGET_REGISTRY/$REPO"

  echo "Pulling $IMAGE..."
  docker pull "$IMAGE"

  echo "Tagging as $TARGET..."
  docker tag "$IMAGE" "$TARGET"

  echo "Pushing $TARGET..."
  docker push "$TARGET"

  echo "✅ Done with $IMAGE"
done
