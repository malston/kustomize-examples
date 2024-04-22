#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

DEMO_HOME=$__DIR

function kustomizeBd {
  XDG_CONFIG_HOME=$DEMO_HOME \
  kustomize build \
    --enable-alpha-plugins \
    "$DEMO_HOME/$1"
}

kustomizeBd "$@"
