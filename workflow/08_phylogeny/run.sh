#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# Arguments
###############################################################################

if [[ $# -lt 3 ]]; then
    echo "ERROR: Missing arguments."
    echo
    echo "Usage:"
    echo "    bash $0 ANALYSIS_DIR MODE METHOD [PLOT_PROFILE]"
    echo
    echo "MODE:"
    echo "    national"
    echo "    custom"
    echo
    echo "METHOD:"
    echo "    fasttree    Fast phylogenetic inference"
    echo "    iqtree      IQ-TREE phylogenetic inference (slower)"
    echo 
    echo "PLOT_PROFILE:"
    echo "    standard    Standard phylogenetic annotation: Community and Collection year variables"
    echo "    detailed    Detailed phylogenetic annotation: 5-SNP clustering, Institution, Collection year and month"
    echo "                for small datasets (for example, one Community datset)."
    exit 1
fi

ANALYSIS_DIR="$1"
MODE="$2"
METHOD="$3"
PLOT_PROFILE="${4:-}"

###############################################################################
# Validate MODE argument
###############################################################################

if [[ "${MODE}" != "national" && "${MODE}" != "custom" ]]; then
    echo "ERROR: Invalid mode: ${MODE}"
    echo "Expected: national or custom"
    exit 1
fi

if [[ "${METHOD}" != "fasttree" && "${METHOD}" != "iqtree" ]]; then
    echo "ERROR: Invalid phylogenetic method: ${METHOD}"
    echo "Expected: fasttree or iqtree"
    exit 1
fi

###############################################################################
# Plot profile
###############################################################################

if [[ -z "${PLOT_PROFILE}" ]]; then

    if [[ "${MODE}" == "national" ]]; then
        PLOT_PROFILE="standard"
    else
        PLOT_PROFILE="detailed"
    fi

fi

if [[ "${PLOT_PROFILE}" != "standard" && \
      "${PLOT_PROFILE}" != "detailed" ]]; then

    echo "ERROR: Invalid plot profile: ${PLOT_PROFILE}"
    echo "Expected: standard or detailed"
    exit 1
fi

###############################################################################
# Step 08 - Phylogenetic analysis
###############################################################################

echo
echo "============================================================"
echo "Step 08: Phylogenetic analysis"
echo "============================================================"
echo
echo "Analysis directory:"
echo "    ${ANALYSIS_DIR}"
echo
echo "Mode:"
echo "    ${MODE}"
echo
echo "Method:"
echo "    ${METHOD}"
echo

###############################################################################
# Tree inference
###############################################################################

case "${METHOD}" in

    fasttree)

        echo "Running FastTree..."
        echo

        bash workflow/08_phylogeny/run_fasttree.sh \
            "${ANALYSIS_DIR}"
        ;;

    iqtree)

        echo "Running IQ-TREE..."
        echo "NOTE: IQ-TREE may take substantially longer than FastTree."
        echo

        bash workflow/08_phylogeny/run_iqtree.sh \
            "${ANALYSIS_DIR}"
        ;;

esac

###############################################################################
# Annotated phylogeny
###############################################################################

echo
echo "============================================================"
echo "Generating annotated phylogenies"
echo "============================================================"
echo

bash workflow/08_phylogeny/plot_tree.sh \
    "${ANALYSIS_DIR}" \
    "${MODE}" \
    "${METHOD}" \
    "${PLOT_PROFILE}"

###############################################################################
# Summary
###############################################################################

echo
echo "============================================================"
echo "Phylogenetic analysis completed successfully."
echo "============================================================"
echo
echo "Method:"
echo "    ${METHOD}"
echo
echo "Plot profile:"
echo "    ${PLOT_PROFILE}"
echo
echo "Results:"
echo "    ${ANALYSIS_DIR}/08_phylogeny"
echo
echo "Annotated phylogenies:"
echo "    ${ANALYSIS_DIR}/08_phylogeny/RSV-A/figures"
echo "    ${ANALYSIS_DIR}/08_phylogeny/RSV-B/figures"
echo
echo "To update GenomeReport with the annotated circular phylogenies, run:"
echo
echo "    bash workflow/09_genome_report/run.sh \\"
echo "        ${ANALYSIS_DIR} \\"
echo "        ${ANALYSIS_DIR}/08_phylogeny/RSV-A/figures/RSV-A_${METHOD}_circular.png \\"
echo "        ${ANALYSIS_DIR}/08_phylogeny/RSV-B/figures/RSV-B_${METHOD}_circular.png"
echo