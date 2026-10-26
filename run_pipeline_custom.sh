#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# Arguments
###############################################################################

if [[ $# -lt 1 ]]; then
    echo "ERROR: Missing analysis name."
    echo
    echo "Usage:"
    echo "    bash run_pipeline_custom.sh ANALYSIS_NAME --where \"EXPRESSION\" [--where \"EXPRESSION\"] ..."
    echo
    echo "Example:"
    echo "    bash run_pipeline_custom.sh valencia \\"
    echo "        --where \"autonomous_community=Comunitat Valenciana\""
    exit 1
fi

ANALYSIS_NAME="$1"
shift

ANALYSIS_DIR="results/custom/${ANALYSIS_NAME}"

###############################################################################
# Validate shared input
###############################################################################

if [[ ! -f "results/02_epidemiological_qc/qc_epi_table.tsv" ]]; then
    echo "ERROR: Epidemiological QC table not found."
    echo
    echo "Expected:"
    echo "    results/02_epidemiological_qc/qc_epi_table.tsv"
    echo
    echo "Run the national pipeline first, or execute steps 01 and 02."
    exit 1
fi

###############################################################################
# Header
###############################################################################

echo
echo "============================================================"
echo "RSV custom analysis"
echo "============================================================"
echo
echo "Analysis name:"
echo "    ${ANALYSIS_NAME}"
echo
echo "Analysis directory:"
echo "    ${ANALYSIS_DIR}"
echo

###############################################################################
# Step 03 - Dataset selection
###############################################################################

echo
echo "============================================================"
echo "Step 03: Dataset selection"
echo "============================================================"
echo

bash workflow/03_dataset_selection/run.sh \
    "${ANALYSIS_DIR}" \
    "$@"

###############################################################################
# Step 04 - Sequence QC
###############################################################################

echo
echo "============================================================"
echo "Step 04: Sequence quality control"
echo "============================================================"
echo

bash workflow/04_sequence_qc/run.sh \
    "${ANALYSIS_DIR}"

###############################################################################
# Step 05 - Reference alignment
###############################################################################

echo
echo "============================================================"
echo "Step 05: Reference-guided alignment"
echo "============================================================"
echo

bash workflow/05_reference_alignment/run.sh \
    "${ANALYSIS_DIR}"

###############################################################################
# Step 06 - Clustering
###############################################################################

echo
echo "============================================================"
echo "Step 06: Genomic clustering"
echo "============================================================"
echo

bash workflow/06_clustering/run.sh \
    "${ANALYSIS_DIR}"

###############################################################################
# Step 07 - Dataset annotation
###############################################################################

echo
echo "============================================================"
echo "Step 07: Dataset annotation"
echo "============================================================"
echo

bash workflow/07_dataset_annotation/run.sh \
    "${ANALYSIS_DIR}" \
    custom

###############################################################################
# Step 09 - GenomeReport
###############################################################################

echo
echo "============================================================"
echo "Step 09: GenomeReport"
echo "============================================================"
echo

bash workflow/09_genome_report/run.sh \
    "${ANALYSIS_DIR}"

###############################################################################
# Summary
###############################################################################

echo
echo "============================================================"
echo "Custom analysis completed successfully."
echo "============================================================"
echo
echo "Analysis:"
echo "    ${ANALYSIS_NAME}"
echo
echo "Results:"
echo "    ${ANALYSIS_DIR}"
echo
echo "GenomeReport:"
echo "    ${ANALYSIS_DIR}/09_genome_report"
echo
echo "Optional phylogenetic analysis:"
echo
echo "    Detailed profile (Cluster_5, institution, year, month):"
echo
echo "    FastTree:"
echo "    bash workflow/08_phylogeny/run.sh ${ANALYSIS_DIR} custom fasttree detailed"
echo
echo "    IQ-TREE:"
echo "    bash workflow/08_phylogeny/run.sh ${ANALYSIS_DIR} custom iqtree detailed"
echo
echo "    Standard profile (community, year):"
echo
echo "    FastTree:"
echo "    bash workflow/08_phylogeny/run.sh ${ANALYSIS_DIR} custom fasttree standard"
echo
echo "    IQ-TREE:"
echo "    bash workflow/08_phylogeny/run.sh ${ANALYSIS_DIR} custom iqtree standard"

echo
echo "After generating the phylogenies, update GenomeReport with:"
echo
echo "    FastTree:"
echo "    bash workflow/09_genome_report/run.sh \\"
echo "        ${ANALYSIS_DIR} \\"
echo "        ${ANALYSIS_DIR}/08_phylogeny/RSV-A/figures/RSV-A_fasttree_circular.png \\"
echo "        ${ANALYSIS_DIR}/08_phylogeny/RSV-B/figures/RSV-B_fasttree_circular.png"

echo
echo "    IQ-TREE:"
echo "    bash workflow/09_genome_report/run.sh \\"
echo "        ${ANALYSIS_DIR} \\"
echo "        ${ANALYSIS_DIR}/08_phylogeny/RSV-A/figures/RSV-A_iqtree_circular.png \\"
echo "        ${ANALYSIS_DIR}/08_phylogeny/RSV-B/figures/RSV-B_iqtree_circular.png"

echo