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

mkdir -p "${OUTDIR}/RSV-A/fasttree"
mkdir -p "${OUTDIR}/RSV-B/fasttree"

###############################################################################
# RSV-A
###############################################################################

echo
echo "============================================================"
echo "Inferring RSV-A FastTree tree"
echo "============================================================"
echo

fasttree \
    -gtr \
    -nt \
    < "${INPUTDIR}/RSV-A/alignment.snps.fasta" \
    > "${OUTDIR}/RSV-A/fasttree/RSV-A.fasttree.tree.nwk"

echo
echo "RSV-A FastTree tree file generated."
echo

###############################################################################
# RSV-B
###############################################################################

echo
echo "============================================================"
echo "Inferring RSV-B FastTree tree"
echo "============================================================"
echo

fasttree \
    -gtr \
    -nt \
    < "${INPUTDIR}/RSV-B/alignment.snps.fasta" \
    > "${OUTDIR}/RSV-B/fasttree/RSV-B.fasttree.tree.nwk"

echo
echo "RSV-B FastTree tree file generated."
echo

###############################################################################
# Summary
###############################################################################

echo
echo "============================================================"
echo "FastTree trees finished"
echo "============================================================"
echo
echo "Output:"
echo "    ${OUTDIR}"
echo