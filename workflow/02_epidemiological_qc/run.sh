#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# Directories
###############################################################################

INPUT="results/01_master_table/master_table.tsv"

OUTDIR="results/02_epidemiological_qc"

mkdir -p "${OUTDIR}"

###############################################################################
# Epidemiological quality control
###############################################################################

echo
echo "============================================================"
echo "Step 2: Epidemiological quality control"
echo "============================================================"
echo

genometabletools filter \
    "${INPUT}" \
    --where "Host=Human" \
    --where "Collection date notna" \
    --where "Location notna" \
    --where "autonomous_community notcontains Unknown" \
    --where "Lineage notna" \
    --where "Genotype notna" \
    --where "Sequence Length>=13700" \
    --where "Additional host information notcontains same patient" \
    --output "${OUTDIR}/qc_epi_table.tsv"

echo
echo "✓ Epidemiological QC completed."
echo
echo "Output:"
echo "    ${OUTDIR}/qc_epi_table.tsv"
echo
echo "Next step:"
echo "    bash workflow/03_dataset_selection/run.sh"
echo