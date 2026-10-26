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
# Directories
###############################################################################

INPUT_DIR="${ANALYSIS_DIR}/04_sequence_qc"
OUTDIR="${ANALYSIS_DIR}/05_reference_alignment"

REFERENCE_DIR="resources/references"
NEXTCLADE_DIR="resources/nextclade"

mkdir -p "${OUTDIR}/RSV-A"
mkdir -p "${OUTDIR}/RSV-B"

###############################################################################
# RSV-A
###############################################################################

echo
echo "============================================================"
echo "RSV-A reference-guided alignment"
echo "============================================================"
echo

cat \
    "${REFERENCE_DIR}/RSV-A_reference.fasta" \
    "${INPUT_DIR}/RSV-A/analysis.qc.fasta" \
> "${OUTDIR}/RSV-A/alignment_input.fasta"

nextclade run \
    --input-dataset "${NEXTCLADE_DIR}/rsv_a" \
    --output-fasta "${OUTDIR}/RSV-A/alignment.fasta" \
    --output-tsv "${OUTDIR}/RSV-A/nextclade.tsv" \
    "${OUTDIR}/RSV-A/alignment_input.fasta"

python scripts/sequence_qc/check_fasta.py \
    --fasta "${OUTDIR}/RSV-A/alignment.fasta" \
    --reference "${REFERENCE_DIR}/RSV-A_reference.fasta" \
    --output "${OUTDIR}/RSV-A/fasta_summary.tsv"

snp-sites \
    "${OUTDIR}/RSV-A/alignment.fasta" \
> "${OUTDIR}/RSV-A/alignment.snps.fasta"

snp-sites \
    -C \
    "${OUTDIR}/RSV-A/alignment.fasta" \
> "${OUTDIR}/RSV-A/constant_sites.txt"

###############################################################################
# RSV-B
###############################################################################

echo
echo "============================================================"
echo "RSV-B reference-guided alignment"
echo "============================================================"
echo

cat \
    "${REFERENCE_DIR}/RSV-B_reference.fasta" \
    "${INPUT_DIR}/RSV-B/analysis.qc.fasta" \
> "${OUTDIR}/RSV-B/alignment_input.fasta"

nextclade run \
    --input-dataset "${NEXTCLADE_DIR}/rsv_b" \
    --output-fasta "${OUTDIR}/RSV-B/alignment.fasta" \
    --output-tsv "${OUTDIR}/RSV-B/nextclade.tsv" \
    "${OUTDIR}/RSV-B/alignment_input.fasta"

python scripts/sequence_qc/check_fasta.py \
    --fasta "${OUTDIR}/RSV-B/alignment.fasta" \
    --reference "${REFERENCE_DIR}/RSV-B_reference.fasta" \
    --output "${OUTDIR}/RSV-B/fasta_summary.tsv"

snp-sites \
    "${OUTDIR}/RSV-B/alignment.fasta" \
> "${OUTDIR}/RSV-B/alignment.snps.fasta"

snp-sites \
    -C \
    "${OUTDIR}/RSV-B/alignment.fasta" \
> "${OUTDIR}/RSV-B/constant_sites.txt"

###############################################################################
# Summary
###############################################################################

echo
echo "============================================================"
echo "Reference-guided alignment completed."
echo "============================================================"
echo
echo "Output:"
echo "    ${OUTDIR}"
echo
echo "Next step:"
echo "    bash workflow/06_clustering/run.sh ${ANALYSIS_DIR}"
echo