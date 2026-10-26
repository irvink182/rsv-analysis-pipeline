#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# Arguments
###############################################################################

if [[ $# -lt 1 ]]; then
    echo "ERROR: Missing analysis directory."
    echo
    echo "Usage:"
    echo "    bash workflow/03_dataset_selection/run.sh ANALYSIS_DIR [--where \"EXPRESSION\"] ..."
    echo
    echo "Examples:"
    echo
    echo "    National surveillance:"
    echo "        bash workflow/03_dataset_selection/run.sh results/national_surveillance"
    echo
    echo "    Custom analysis:"
    echo "        bash workflow/03_dataset_selection/run.sh results/custom/valencia \\"
    echo "            --where \"autonomous_community=Comunitat Valenciana\""
    echo
    echo "    Custom analysis with multiple filters:"
    echo "        bash workflow/03_dataset_selection/run.sh results/custom/valencia_2025 \\"
    echo "            --where \"autonomous_community=Comunitat Valenciana\" \\"
    echo "            --where \"Collection date after 2025-01-01\" \\"
    echo "            --where \"Collection date before 2026-01-01\""
    exit 1
fi

ANALYSIS_DIR="$1"
shift

CUSTOM_FILTERS=()
SELECTIONS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --where)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --where requires an expression."
                exit 1
            fi

            CUSTOM_FILTERS+=(--where "$2")
            SELECTIONS+=("$2")

            shift 2
            ;;

        -h|--help)
            echo "Usage:"
            echo "    bash workflow/03_dataset_selection/run.sh ANALYSIS_DIR [--where \"EXPRESSION\"] ..."
            exit 0
            ;;

        *)
            echo "ERROR: Unknown argument: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
done

###############################################################################
# Directories
###############################################################################

TABLE="results/02_epidemiological_qc/qc_epi_table.tsv"

RSVA_FASTA="resources/sequences/RSV-A.fasta"
RSVB_FASTA="resources/sequences/RSV-B.fasta"

OUTDIR="${ANALYSIS_DIR}/03_dataset_selection"

mkdir -p "${OUTDIR}/RSV-A"
mkdir -p "${OUTDIR}/RSV-B"

###############################################################################
# Record dataset selection
###############################################################################

SELECTION_FILE="${OUTDIR}/selection.txt"

if [[ ${#SELECTIONS[@]} -eq 0 ]]; then

    {
        echo "Dataset selection: national surveillance"
        echo "Additional filters: none"
    } > "${SELECTION_FILE}"

    echo
    echo "============================================================"
    echo "Dataset selection: national surveillance"
    echo "============================================================"
    echo
    echo "Using all sequences passing epidemiological QC."
    echo

else

    {
        echo "Dataset selection: custom"
        echo
        echo "Filters:"
        for filter in "${SELECTIONS[@]}"; do
            echo "- ${filter}"
        done
    } > "${SELECTION_FILE}"

    echo
    echo "============================================================"
    echo "Dataset selection: custom"
    echo "============================================================"
    echo
    echo "Filters:"

    for filter in "${SELECTIONS[@]}"; do
        echo "    ${filter}"
    done

    echo

fi

###############################################################################
# RSV-A
###############################################################################

echo
echo "============================================================"
echo "Selecting RSV-A dataset"
echo "============================================================"
echo

genometabletools filter \
    "${TABLE}" \
    --where "Subtype=A" \
    "${CUSTOM_FILTERS[@]}" \
    --output "${OUTDIR}/RSV-A/analysis_table.tsv"

python scripts/sequence_qc/select_fasta.py \
    --table "${OUTDIR}/RSV-A/analysis_table.tsv" \
    --column "Accession ID" \
    --fasta "${RSVA_FASTA}" \
    --output "${OUTDIR}/RSV-A/analysis.fasta"

###############################################################################
# RSV-B
###############################################################################

echo
echo "============================================================"
echo "Selecting RSV-B dataset"
echo "============================================================"
echo

genometabletools filter \
    "${TABLE}" \
    --where "Subtype=B" \
    "${CUSTOM_FILTERS[@]}" \
    --output "${OUTDIR}/RSV-B/analysis_table.tsv"

python scripts/sequence_qc/select_fasta.py \
    --table "${OUTDIR}/RSV-B/analysis_table.tsv" \
    --column "Accession ID" \
    --fasta "${RSVB_FASTA}" \
    --output "${OUTDIR}/RSV-B/analysis.fasta"

###############################################################################
# Summary
###############################################################################

echo
echo "============================================================"
echo "Dataset selection completed."
echo "============================================================"
echo
echo "Analysis directory:"
echo "    ${ANALYSIS_DIR}"
echo
echo "Output:"
echo "    ${OUTDIR}/RSV-A/analysis_table.tsv"
echo "    ${OUTDIR}/RSV-A/analysis.fasta"
echo "    ${OUTDIR}/RSV-B/analysis_table.tsv"
echo "    ${OUTDIR}/RSV-B/analysis.fasta"
echo
echo "Selection criteria:"
echo "    ${SELECTION_FILE}"
echo
echo "Next step:"
echo "    bash workflow/04_sequence_qc/run.sh ${ANALYSIS_DIR}"
echo