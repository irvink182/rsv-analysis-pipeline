#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# Directories
###############################################################################

MASTER_TABLE="results/01_master_table/master_table.tsv"
OUTDIR="results/99_raw_report"

###############################################################################
# Validate input
###############################################################################

if [[ ! -f "${MASTER_TABLE}" ]]; then
    echo "ERROR: Master table not found:"
    echo "    ${MASTER_TABLE}"
    echo
    echo "Run Step 01 first:"
    echo "    bash workflow/01_metadata_integration/run.sh"
    exit 1
fi

###############################################################################
# Output directory
###############################################################################

mkdir -p "${OUTDIR}"

###############################################################################
# GenomeReport
###############################################################################

echo
echo "============================================================"
echo "Generating raw GenomeReport"
echo "============================================================"
echo
echo "Input:"
echo "    ${MASTER_TABLE}"
echo
echo "Output:"
echo "    ${OUTDIR}"
echo

genomereport \
    "${MASTER_TABLE}" \
    --output "${OUTDIR}"

###############################################################################
# Summary
###############################################################################

echo
echo "============================================================"
echo "Raw GenomeReport completed."
echo "============================================================"
echo
echo "Input:"
echo "    ${MASTER_TABLE}"
echo
echo "Output:"
echo "    ${OUTDIR}"
echo
echo "Pipeline completed successfully."
echo