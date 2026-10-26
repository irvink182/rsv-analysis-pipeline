#!/usr/bin/env bash

set -e

###############################################################################
# Download Nextclade datasets
###############################################################################

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/../.. && pwd )"

DATASET_DIR="${ROOT_DIR}/resources/nextclade"

mkdir -p "${DATASET_DIR}"

echo
echo "Downloading RSV-A dataset..."
echo

nextclade dataset get \
    --name rsv_a \
    --output-dir "${DATASET_DIR}/rsv_a"

echo
echo "Downloading RSV-B dataset..."
echo

nextclade dataset get \
    --name rsv_b \
    --output-dir "${DATASET_DIR}/rsv_b"

echo
echo "Nextclade datasets successfully installed."