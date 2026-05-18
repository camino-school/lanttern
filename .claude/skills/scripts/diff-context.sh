#!/usr/bin/env bash
set -euo pipefail
BASE_REF="$1"
HEAD_REF="$2"
git diff "${BASE_REF}...${HEAD_REF}"
git diff "${BASE_REF}...${HEAD_REF}" --name-only
git diff "${BASE_REF}...${HEAD_REF}" --stat -- 'lib/**'
git log "${BASE_REF}..${HEAD_REF}" --oneline
