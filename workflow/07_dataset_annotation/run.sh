#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# Arguments
###############################################################################

if [[ $# -lt 2 ]]; then
    echo "ERROR: Missing arguments."
    echo "Usage: bash $0 ANALYSIS_DIR MODE"
    echo
    echo "MODE:"
    echo "    national    Use curated national annotation templates"
    echo "    custom      Use annotation config generated from the custom dataset"
    exit 1
fi

ANALYSIS_DIR="$1"
MODE="$2"

if [[ "${MODE}" != "national" && "${MODE}" != "custom" ]]; then
    echo "ERROR: Invalid mode: ${MODE}"
    echo "Expected: national or custom"
    exit 1
fi

###############################################################################
# Directories
###############################################################################

MASTER="results/01_master_table/master_table.tsv"

CLUSTER_DIR="${ANALYSIS_DIR}/06_clustering"
OUTDIR="${ANALYSIS_DIR}/07_dataset_annotation"

mkdir -p "${OUTDIR}/RSV-A"
mkdir -p "${OUTDIR}/RSV-B"

###############################################################################
# RSV-A
###############################################################################

echo
echo "============================================================"
echo "RSV-A dataset annotation"
echo "============================================================"
echo

python scripts/clustering/cluster_metadata.py \
    --master_table "${MASTER}" \
    --cluster_annotations \
        "${CLUSTER_DIR}/RSV-A/tables/cluster_annotations.tsv" \
    --prefix RSV-A \
    --outdir "${OUTDIR}/RSV-A"

phyloannot \
    --metadata "${OUTDIR}/RSV-A/RSV-A_phylogeny_metadata.tsv" \
    --init-config \
    --outdir "${OUTDIR}/RSV-A/phyloannot"

if [[ "${MODE}" == "national" ]]; then

    CONFIG_A="${OUTDIR}/RSV-A/phyloannot/annotation_config.tsv"

else

    CONFIG_A="${OUTDIR}/RSV-A/phyloannot/annotation_config.tsv"

fi

echo "Annotation config:"
echo "    ${CONFIG_A}"
echo

phyloannot \
    --metadata "${OUTDIR}/RSV-A/RSV-A_phylogeny_metadata.tsv" \
    --config "${CONFIG_A}" \
    --itol \
    --ggtree \
    --microreact \
    --location autonomous_community \
    --location-file resources/locations/spanish_communities.tsv \
    --outdir "${OUTDIR}/RSV-A/phyloannot"

###############################################################################
# RSV-B
###############################################################################

echo
echo "============================================================"
echo "RSV-B dataset annotation"
echo "============================================================"
echo

python scripts/clustering/cluster_metadata.py \
    --master_table "${MASTER}" \
    --cluster_annotations \
        "${CLUSTER_DIR}/RSV-B/tables/cluster_annotations.tsv" \
    --prefix RSV-B \
    --outdir "${OUTDIR}/RSV-B"

phyloannot \
    --metadata "${OUTDIR}/RSV-B/RSV-B_phylogeny_metadata.tsv" \
    --init-config \
    --outdir "${OUTDIR}/RSV-B/phyloannot"

if [[ "${MODE}" == "national" ]]; then

    CONFIG_B="${OUTDIR}/RSV-B/phyloannot/annotation_config.tsv"

else

    CONFIG_B="${OUTDIR}/RSV-B/phyloannot/annotation_config.tsv"

fi

echo "Annotation config:"
echo "    ${CONFIG_B}"
echo

phyloannot \
    --metadata "${OUTDIR}/RSV-B/RSV-B_phylogeny_metadata.tsv" \
    --config "${CONFIG_B}" \
    --itol \
    --ggtree \
    --microreact \
    --location autonomous_community \
    --location-file resources/locations/spanish_communities.tsv \
    --outdir "${OUTDIR}/RSV-B/phyloannot"

###############################################################################
# Summary
###############################################################################

echo
echo "Next steps:"
echo "    Optional phylogeny:"
echo "        bash workflow/08_phylogeny/run.sh ${ANALYSIS_DIR} ${MODE} fasttree"
echo "        bash workflow/08_phylogeny/run.sh ${ANALYSIS_DIR} ${MODE} iqtree"
echo
echo "    Generate report:"
echo "        bash workflow/09_genome_report/run.sh ${ANALYSIS_DIR}"
echo