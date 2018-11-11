#!/usr/bin/env bash -e
#
# Reference: https://github.com/koalaman/shellcheck/wiki/Directive

cd "$(dirname "$0")/.."

set -x
find . -name "*.sh" \
    -not -regex ".*/ci/semver_bash/.*" \
    -not -regex ".*/.cargo/.*" \
    -not -regex ".*/node_modules/.*" \
    -not -regex ".*/target/.*" \
    -print0 \
  | xargs -0 \
      ci/docker-run.sh koalaman/shellcheck --color=always --external-sources --shell=bash

exit 0
