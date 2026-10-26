#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# Directories
###############################################################################

METADATA_DIR="resources/metadata"

OUTDIR="results/01_master_table"

mkdir -p "${OUTDIR}"

###############################################################################
# Merge patient metadata
###############################################################################

echo
echo "Merging patient metadata..."
echo

genometabletools concat \
    "${METADATA_DIR}/RSV-A_patient_metadata.tsv" \
    "${METADATA_DIR}/RSV-B_patient_metadata.tsv" \
    --output "${OUTDIR}/patient_metadata.tsv"

###############################################################################
# Merge sequencing metadata
###############################################################################

echo
echo "Merging sequencing metadata..."
echo

genometabletools concat \
    "${METADATA_DIR}/RSV-A_sequencing_metadata.tsv" \
    "${METADATA_DIR}/RSV-B_sequencing_metadata.tsv" \
    --output "${OUTDIR}/sequencing_metadata.tsv"

###############################################################################
# Merge date/location metadata
###############################################################################

echo
echo "Merging date/location metadata..."
echo

genometabletools concat \
    "${METADATA_DIR}/RSV-A_date_location_metadata.tsv" \
    "${METADATA_DIR}/RSV-B_date_location_metadata.tsv" \
    --output "${OUTDIR}/date_location_metadata.tsv"

###############################################################################
# Build master table
###############################################################################

echo
echo "Generating master table..."
echo

genometabletools integrate \
    "${OUTDIR}/sequencing_metadata.tsv" \
    "${OUTDIR}/patient_metadata.tsv" \
    "${OUTDIR}/date_location_metadata.tsv" \
    "${METADATA_DIR}/laboratory_metadata.tsv" \
    --keys "Accession ID" \
    --preserve_duplicates_columns comments \
    --output "${OUTDIR}/master_table.tsv"

echo
echo "Metadata integration completed."
echo
echo "Output:"
echo "    ${OUTDIR}/master_table.tsv"
echo
echo "Next step:"
echo "    bash workflow/02_epidemiological_qc/run.sh"
echo