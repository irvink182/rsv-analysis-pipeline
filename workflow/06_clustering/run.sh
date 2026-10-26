#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# Arguments
###############################################################################

if [[ $# -lt 1 ]]; then
    echo "ERROR: Missing analysis directory."
    echo "Usage: bash $0 ANALYSIS_DIR"
    exit 1
fi

ANALYSIS_DIR="$1"

###############################################################################
# Parameters
###############################################################################

THREADS=16

INPUT_DIR="${ANALYSIS_DIR}/05_reference_alignment"
OUTDIR="${ANALYSIS_DIR}/06_clustering"

mkdir -p "${OUTDIR}/RSV-A"
mkdir -p "${OUTDIR}/RSV-B"

###############################################################################
# RSV-A
###############################################################################

echo
echo "============================================================"
echo "RSV-A clustering"
echo "============================================================"
echo

snp-dists \
    -j ${THREADS} \
    -m \
    -t \
    "${INPUT_DIR}/RSV-A/alignment.snps.fasta" \
> "${OUTDIR}/RSV-A/distances.tsv"

python scripts/clustering/cluster_analysis.py \
    --distances "${OUTDIR}/RSV-A/distances.tsv" \
    --outdir "${OUTDIR}/RSV-A"

###############################################################################
# RSV-B
###############################################################################

echo
echo "============================================================"
echo "RSV-B clustering"
echo "============================================================"
echo

snp-dists \
    -j ${THREADS} \
    -m \
    -t \
    "${INPUT_DIR}/RSV-B/alignment.snps.fasta" \
> "${OUTDIR}/RSV-B/distances.tsv"

python scripts/clustering/cluster_analysis.py \
    --distances "${OUTDIR}/RSV-B/distances.tsv" \
    --outdir "${OUTDIR}/RSV-B"

###############################################################################
# Summary
###############################################################################

echo
echo "============================================================"
echo "Cluster analysis completed."
echo "============================================================"
echo
echo "Output:"
echo "    ${OUTDIR}"
echo
echo "Next step:"
echo "    bash workflow/07_dataset_annotation/run.sh ${ANALYSIS_DIR}"
echo