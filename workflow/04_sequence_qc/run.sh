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

NEXTCLADE_DB="resources/nextclade"

INPUT_DIR="${ANALYSIS_DIR}/03_dataset_selection"
OUTDIR="${ANALYSIS_DIR}/04_sequence_qc"

mkdir -p "${OUTDIR}/RSV-A"
mkdir -p "${OUTDIR}/RSV-B"

###############################################################################
# RSV-A
###############################################################################

echo
echo "============================================================"
echo "Running Nextclade (RSV-A)"
echo "============================================================"
echo

nextclade run \
    --input-dataset "${NEXTCLADE_DB}/rsv_a" \
    --output-all "${OUTDIR}/RSV-A/nextclade" \
    "${INPUT_DIR}/RSV-A/analysis.fasta"

python scripts/sequence_qc/nextclade_qc.py \
    --input "${OUTDIR}/RSV-A/nextclade/nextclade.tsv" \
    --outdir "${OUTDIR}/RSV-A/summary" \
    --exclude-bad \
    --min-genome-coverage 90 \
    --min-f-coverage 90 \
    --min-g-coverage 90 \
    --max-stop-codons 0 \
    --max-missing-bases 500

python scripts/sequence_qc/select_fasta.py \
    --table "${OUTDIR}/RSV-A/summary/problematic_sequences.tsv" \
    --exclude \
    --column "seqName" \
    --fasta "${INPUT_DIR}/RSV-A/analysis.fasta" \
    --output "${OUTDIR}/RSV-A/analysis.qc.fasta"

###############################################################################
# RSV-B
###############################################################################

echo
echo "============================================================"
echo "Running Nextclade (RSV-B)"
echo "============================================================"
echo

nextclade run \
    --input-dataset "${NEXTCLADE_DB}/rsv_b" \
    --output-all "${OUTDIR}/RSV-B/nextclade" \
    "${INPUT_DIR}/RSV-B/analysis.fasta"

python scripts/sequence_qc/nextclade_qc.py \
    --input "${OUTDIR}/RSV-B/nextclade/nextclade.tsv" \
    --outdir "${OUTDIR}/RSV-B/summary" \
    --exclude-bad \
    --min-genome-coverage 90 \
    --min-f-coverage 90 \
    --min-g-coverage 90 \
    --max-stop-codons 0 \
    --max-missing-bases 500

python scripts/sequence_qc/select_fasta.py \
    --table "${OUTDIR}/RSV-B/summary/problematic_sequences.tsv" \
    --exclude \
    --column "seqName" \
    --fasta "${INPUT_DIR}/RSV-B/analysis.fasta" \
    --output "${OUTDIR}/RSV-B/analysis.qc.fasta"

###############################################################################
# Summary
###############################################################################

echo
echo "============================================================"
echo "Sequence quality control completed."
echo "============================================================"
echo
echo "Output:"
echo "    ${OUTDIR}/RSV-A/analysis.qc.fasta"
echo "    ${OUTDIR}/RSV-B/analysis.qc.fasta"
echo
echo "Next step:"
echo "    bash workflow/05_reference_alignment/run.sh ${ANALYSIS_DIR}"
echo