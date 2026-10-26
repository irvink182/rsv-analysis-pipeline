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

OUTDIR="${ANALYSIS_DIR}/08_phylogeny"
INPUTDIR="${ANALYSIS_DIR}/05_reference_alignment"

mkdir -p "${OUTDIR}/RSV-A/iqtree"
mkdir -p "${OUTDIR}/RSV-B/iqtree"

###############################################################################
# RSV-A
###############################################################################

echo
echo "============================================================"
echo "Inferring RSV-A IQTREE tree"
echo "============================================================"
echo

fconstsvarA=$(snp-sites -C "${INPUTDIR}/RSV-A/alignment.fasta")

iqtree2 \
    -s "${INPUTDIR}/RSV-A/alignment.snps.fasta" \
    -m GTR+F+I+R10 \
    -B 1000 \
    -alrt 1000 \
    -nt AUTO \
    -fconst "${fconstsvarA}" \
    --prefix "${OUTDIR}/RSV-A/iqtree/RSV-A" \
    -redo

echo
echo "RSV-A IQTREE tree file generated."
echo

###############################################################################
# RSV-B
###############################################################################

echo
echo "============================================================"
echo "Inferring RSV-B IQTREE tree"
echo "============================================================"
echo

fconstsvarB=$(snp-sites -C "${INPUTDIR}/RSV-B/alignment.fasta")

iqtree2 \
    -s "${INPUTDIR}/RSV-B/alignment.snps.fasta" \
    -m GTR+F+I+R10 \
    -B 1000 \
    -alrt 1000 \
    -nt AUTO \
    -fconst "${fconstsvarB}" \
    --prefix "${OUTDIR}/RSV-B/iqtree/RSV-B" \
    -redo

echo
echo "RSV-B IQTREE tree file generated."
echo

###############################################################################
# Summary
###############################################################################

echo
echo "============================================================"
echo "IQTREE trees finished"
echo "============================================================"
echo
echo "Output:"
echo "    ${OUTDIR}"
echo