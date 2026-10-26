#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# Arguments
###############################################################################

if [[ $# -lt 1 ]]; then
    echo "ERROR: Missing analysis directory."
    echo
    echo "Usage:"
    echo "    bash $0 ANALYSIS_DIR [PHYLOGENY ...]"
    echo
    echo "Examples:"
    echo "    bash $0 results/custom/valencia"
    echo "    bash $0 results/custom/valencia phylogeny.png"
    echo "    bash $0 results/custom/valencia RSV-A.png RSV-B.png"
    exit 1
fi

ANALYSIS_DIR="$1"
shift

# Any remaining arguments are optional phylogeny figures
PHYLOGENY_FILES=("$@")

###############################################################################
# Validate phylogeny files
###############################################################################

if (( ${#PHYLOGENY_FILES[@]} > 0 )); then

    for phylogeny in "${PHYLOGENY_FILES[@]}"; do

        if [[ ! -f "${phylogeny}" ]]; then
            echo "ERROR: Phylogeny figure not found:"
            echo "    ${phylogeny}"
            exit 1
        fi

    done

fi

###############################################################################
# Directories
###############################################################################

REF_TABLE_DIR="${ANALYSIS_DIR}/07_dataset_annotation"
NEXTCLADE_TABLE_DIR="${ANALYSIS_DIR}/05_reference_alignment"

OUTDIR="${ANALYSIS_DIR}/09_genome_report"

mkdir -p "${OUTDIR}"

###############################################################################
# Add Nextclade lineage data
###############################################################################

echo
echo "============================================================"
echo "Adding Nextclade lineage classification"
echo "============================================================"
echo

# RSV-A
python scripts/sequence_qc/normalize_nextclade_table.py \
    --input "${NEXTCLADE_TABLE_DIR}/RSV-A/nextclade.tsv" \
    --output "${NEXTCLADE_TABLE_DIR}/RSV-A/nextclade_normalized.tsv"

genometabletools annotate \
    "${REF_TABLE_DIR}/RSV-A/RSV-A_master_table_clustered.tsv" \
    "${NEXTCLADE_TABLE_DIR}/RSV-A/nextclade_normalized.tsv" \
    --key "Accession ID" \
    --columns nextclade_lineage \
    --rename-columns nextclade_lineage Lineage \
    --overwrite \
    --output "${OUTDIR}/RSV-A_master_table"

# RSV-B
python scripts/sequence_qc/normalize_nextclade_table.py \
    --input "${NEXTCLADE_TABLE_DIR}/RSV-B/nextclade.tsv" \
    --output "${NEXTCLADE_TABLE_DIR}/RSV-B/nextclade_normalized.tsv"

genometabletools annotate \
    "${REF_TABLE_DIR}/RSV-B/RSV-B_master_table_clustered.tsv" \
    "${NEXTCLADE_TABLE_DIR}/RSV-B/nextclade_normalized.tsv" \
    --key "Accession ID" \
    --columns nextclade_lineage \
    --rename-columns nextclade_lineage Lineage \
    --overwrite \
    --output "${OUTDIR}/RSV-B_master_table"

###############################################################################
# Merge RSV-A and RSV-B metadata
###############################################################################

echo
echo "============================================================"
echo "Updating lineage annotations and merging metadata"
echo "============================================================"
echo

genometabletools concat \
    "${OUTDIR}/RSV-A_master_table.tsv" \
    "${OUTDIR}/RSV-B_master_table.tsv" \
    --output "${OUTDIR}/master_table_final.tsv"

# Remove intermediate report files
rm -f "${OUTDIR}/RSV-A_master_table_report.txt"
rm -f "${OUTDIR}/RSV-B_master_table_report.txt"

###############################################################################
# GenomeReport
###############################################################################

echo
echo "============================================================"
echo "Generating GenomeReport"
echo "============================================================"
echo

if (( ${#PHYLOGENY_FILES[@]} > 0 )); then

    echo "Phylogenetic figures:"
    for phylogeny in "${PHYLOGENY_FILES[@]}"; do
        echo "    ${phylogeny}"
    done
    echo

    genomereport \
        "${OUTDIR}/master_table_final.tsv" \
        --output "${OUTDIR}" \
        --phylogeny "${PHYLOGENY_FILES[@]}"

else

    echo "No phylogenetic figures provided."
    echo "GenomeReport will be generated without phylogenies."
    echo

    genomereport \
        "${OUTDIR}/master_table_final.tsv" \
        --output "${OUTDIR}"

fi

###############################################################################
# Summary
###############################################################################

echo
echo "============================================================"
echo "GenomeReport completed."
echo "============================================================"
echo
echo "Output:"
echo "    ${OUTDIR}"

if (( ${#PHYLOGENY_FILES[@]} > 0 )); then
    echo
    echo "Phylogenies included:"
    for phylogeny in "${PHYLOGENY_FILES[@]}"; do
        echo "    ${phylogeny}"
    done
fi

echo
echo "Pipeline completed successfully."
echo