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
    echo "    fasttree"
    echo "    iqtree"
    echo
    echo "PLOT_PROFILE:"
    echo "    standard"
    echo "    detailed"
    exit 1
fi

ANALYSIS_DIR="$1"
MODE="$2"
METHOD="$3"
PLOT_PROFILE="${4:-}"


###############################################################################
# Validate MODE arguments
###############################################################################

if [[ "${MODE}" != "national" && "${MODE}" != "custom" ]]; then
    echo "ERROR: Invalid mode: ${MODE}"
    echo "Expected: national or custom"
    exit 1
fi

if [[ "${METHOD}" != "fasttree" && "${METHOD}" != "iqtree" ]]; then
    echo "ERROR: Invalid phylogeny method: ${METHOD}"
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
# Directories
###############################################################################

OUTDIR="${ANALYSIS_DIR}/08_phylogeny"
METADIR="${ANALYSIS_DIR}/07_dataset_annotation"

FIGDIR_A="${OUTDIR}/RSV-A/figures"
FIGDIR_B="${OUTDIR}/RSV-B/figures"

mkdir -p "${FIGDIR_A}"
mkdir -p "${FIGDIR_B}"


###############################################################################
# Plotting script
###############################################################################

PLOT_SCRIPT="scripts/phylogeny/plot_phylogeny.R"

if [[ ! -f "${PLOT_SCRIPT}" ]]; then
    echo "ERROR: Phylogeny plotting script not found:"
    echo "    ${PLOT_SCRIPT}"
    exit 1
fi


###############################################################################
# Metadata
###############################################################################

METADATA_A="${METADIR}/RSV-A/phyloannot/ggtree/metadata.tsv"
METADATA_B="${METADIR}/RSV-B/phyloannot/ggtree/metadata.tsv"

if [[ ! -f "${METADATA_A}" ]]; then
    echo "ERROR: RSV-A metadata not found:"
    echo "    ${METADATA_A}"
    exit 1
fi

if [[ ! -f "${METADATA_B}" ]]; then
    echo "ERROR: RSV-B metadata not found:"
    echo "    ${METADATA_B}"
    exit 1
fi


###############################################################################
# Reference taxa
###############################################################################

ROOT_A="hRSV/A/England/397/2017"
ROOT_B="hRSV/B/Australia/VIC-RCH056/2019"


###############################################################################
# Select tree files
###############################################################################

case "${METHOD}" in

    fasttree)

        TREE_A="${OUTDIR}/RSV-A/fasttree/RSV-A.fasttree.tree.nwk"
        TREE_B="${OUTDIR}/RSV-B/fasttree/RSV-B.fasttree.tree.nwk"
        ;;

    iqtree)

        TREE_A="${OUTDIR}/RSV-A/iqtree/RSV-A.treefile"
        TREE_B="${OUTDIR}/RSV-B/iqtree/RSV-B.treefile"
        ;;

esac


if [[ ! -f "${TREE_A}" ]]; then
    echo "ERROR: RSV-A tree not found:"
    echo "    ${TREE_A}"
    exit 1
fi

if [[ ! -f "${TREE_B}" ]]; then
    echo "ERROR: RSV-B tree not found:"
    echo "    ${TREE_B}"
    exit 1
fi

###############################################################################
# Annotation arguments
###############################################################################

case "${PLOT_PROFILE}" in

    standard)

        ANNOTATIONS=(
            --annotation "autonomous_community:discrete:Community"
            --annotation "gisaid_collection_year:continuous:Collection year"
        )
        ;;

    detailed)

        ANNOTATIONS=(
            --annotation "Cluster_5:discrete:5-SNP cluster"
            --annotation "institution:discrete:Institution"
            --annotation "gisaid_collection_year:continuous:Collection year"
            --annotation "gisaid_collection_month:continuous:Collection month"
        )
        ;;

esac


###############################################################################
# Function: plot phylogeny
###############################################################################

plot_phylogeny() {

    local subtype="$1"
    local tree="$2"
    local metadata="$3"
    local root="$4"
    local figdir="$5"

    echo
    echo "============================================================"
    echo "Plotting ${subtype} phylogeny"
    echo "Method:         ${METHOD}"
    echo "Mode:           ${MODE}"
    echo "Plot profile:   ${PLOT_PROFILE}"
    echo "============================================================"
    echo


    ###########################################################################
    # Rectangular
    ###########################################################################

    echo "Generating rectangular tree..."

    Rscript "${PLOT_SCRIPT}" \
        --tree "${tree}" \
        --metadata "${metadata}" \
        --taxon-column Taxon \
        --root "${root}" \
        --color Lineage \
        "${ANNOTATIONS[@]}" \
        --layout rectangular \
        --output "${figdir}/${subtype}_${METHOD}_rectangular"


    ###########################################################################
    # Circular
    ###########################################################################

    echo
    echo "Generating circular tree..."

    Rscript "${PLOT_SCRIPT}" \
        --tree "${tree}" \
        --metadata "${metadata}" \
        --taxon-column Taxon \
        --root "${root}" \
        --color Lineage \
        "${ANNOTATIONS[@]}" \
        --layout circular \
        --output "${figdir}/${subtype}_${METHOD}_circular" \
        --width 8 \
        --height 10

    echo
    echo "${subtype} figures generated."
}


###############################################################################
# RSV-A
###############################################################################

plot_phylogeny \
    "RSV-A" \
    "${TREE_A}" \
    "${METADATA_A}" \
    "${ROOT_A}" \
    "${FIGDIR_A}"


###############################################################################
# RSV-B
###############################################################################

plot_phylogeny \
    "RSV-B" \
    "${TREE_B}" \
    "${METADATA_B}" \
    "${ROOT_B}" \
    "${FIGDIR_B}"


###############################################################################
# Summary
###############################################################################

echo
echo "============================================================"
echo "Phylogeny plotting finished"
echo "============================================================"
echo
echo "Analysis:"
echo "    ${ANALYSIS_DIR}"
echo
echo "Mode:"
echo "    ${MODE}"
echo
echo "Method:"
echo "    ${METHOD}"
echo
echo "Plot profile:"
echo "    ${PLOT_PROFILE}"
echo
echo "Figures:"
echo "    ${FIGDIR_A}"
echo "    ${FIGDIR_B}"
echo