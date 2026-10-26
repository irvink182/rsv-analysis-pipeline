#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# Configuration
###############################################################################

ANALYSIS_DIR="results/national_surveillance"

###############################################################################
# Header
###############################################################################

echo
echo "============================================================"
echo "RSV national surveillance pipeline"
echo "============================================================"
echo
echo "Analysis directory:"
echo "    ${ANALYSIS_DIR}"
echo

###############################################################################
# Step 01 - Master table
###############################################################################

echo
echo "============================================================"
echo "Step 01: Master table"
echo "============================================================"
echo

bash workflow/01_metadata_integration/run.sh

###############################################################################
# Step 02 - Epidemiological QC
###############################################################################

echo
echo "============================================================"
echo "Step 02: Epidemiological quality control"
echo "============================================================"
echo

bash workflow/02_epidemiological_qc/run.sh

###############################################################################
# Step 03 - Dataset selection
###############################################################################

echo
echo "============================================================"
echo "Step 03: Dataset selection"
echo "============================================================"
echo

bash workflow/03_dataset_selection/run.sh \
    "${ANALYSIS_DIR}"

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
    national

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
echo "National surveillance pipeline completed successfully."
echo "============================================================"
echo
echo "Results:"
echo "    ${ANALYSIS_DIR}"
echo
echo "GenomeReport:"
echo "    ${ANALYSIS_DIR}/09_genome_report"

echo
echo "Optional phylogenetic analysis:"
echo
echo "    FastTree (faster):"
echo "    bash workflow/08_phylogeny/run.sh ${ANALYSIS_DIR} national fasttree"
echo
echo "    IQ-TREE (slower):"
echo "    bash workflow/08_phylogeny/run.sh ${ANALYSIS_DIR} national iqtree"

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