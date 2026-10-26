#!/usr/bin/env python3

"""
Summarize the quality metrics produced by Nextclade.

The script provides descriptive statistics to help users define
sequence-quality filtering thresholds before downstream analyses.

It does not modify or filter the dataset.
"""

###############################################################################
# Imports
###############################################################################

import argparse
from pathlib import Path
from collections import Counter

import numpy as np
import pandas as pd

###############################################################################
# Column names
###############################################################################

SEQNAME = "seqName"
CLADE = "clade"
QC_STATUS = "qc.overallStatus"
QC_SCORE = "qc.overallScore"
ALIGNMENT_SCORE = "alignmentScore"
COVERAGE = "coverage"
CDS_COVERAGE = "cdsCoverage"
MISSING = "totalMissing"
NS = "totalNonACGTNs"
FRAMESHIFTS = "totalFrameShifts"
STOP_CODONS = "qc.stopCodons.totalStopCodons"
DELETIONS = "totalDeletions"
INSERTIONS = "totalInsertions"
WARNINGS = "warnings"
ERRORS = "errors"

###############################################################################
# Suggested filtering thresholds
###############################################################################

ALIGNMENT_THRESHOLDS = (
    44000,
    44500,
    44600,
    44700,
)

COVERAGE_THRESHOLDS = (
    90,
    95,
    99,
)

MISSING_THRESHOLDS = (
    10,
    50,
    100,
    250,
    500,
)

NS_THRESHOLDS = (
    10,
    50,
    100,
    250,
    500,
)

CDS_COVERAGE_THRESHOLD = 95

###############################################################################
# CLI
###############################################################################

def parse_args():

    #Input and Output arguments
    parser = argparse.ArgumentParser(
        description="Summarize Nextclade QC metrics."
    )

    parser.add_argument(
        "--input",
        required=True,
        help="Nextclade TSV table.",
    )

    parser.add_argument(
    	"--outdir",
    	default="results",
    	help=(
    		"Output directory "
    		"(default: results)"
    	),
    )

    # QC filters
    qc_group = parser.add_argument_group(
    	"QC filters",
    )

    qc_group.add_argument(
    	"--exclude-bad",
    	action="store_true",
    	help="Flag sequences with qc.overallStatus == 'bad'.",
    )
    qc_group.add_argument(
    	"--exclude-mediocre",
    	action="store_true",
    	help="Flag sequences with qc.overallStatus == 'mediocre'.",
    )

    qc_group.add_argument(
    	"--min-genome-coverage",
    	type=float,
    	default=None,
    	help="Minimum genome coverage (%%).",
    )

    qc_group.add_argument(
    	"--min-f-coverage",
    	type=float,
    	default=None,
    	help="Minimum F gene coverage (%%).",
    )

    qc_group.add_argument(
    	"--min-g-coverage",
    	type=float,
    	default=None,
    	help="Minimum G gene coverage (%%).",
    )

    qc_group.add_argument(
    	"--min-l-coverage",
    	type=float,
    	default=None,
    	help="Minimum L gene coverage (%%).",
    )

    qc_group.add_argument(
    	"--max-missing-bases",
    	type=int,
    	default=None,
    	help="Maximum number of missing bases.",
    )

    qc_group.add_argument(
    	"--max-stop-codons",
    	type=int,
    	default=None,
    	help="Maximum number of stop codons.",
    )

    return parser.parse_args()


###############################################################################
# Read table
###############################################################################

def read_nextclade_table(path):
    """
    Read Nextclade TSV table.
    """

    df = pd.read_csv(
        path,
        sep="\t",
    )

    return df

###############################################################################
# Extract accession IDs
###############################################################################

def extract_accession_ids(df):
    """
    Extract GISAID accession IDs
    from seqName.
    """

    df = df.copy()

    df["Accession ID"] = (
        df[SEQNAME]
        .str.split("|")
        .str[1]
    )

    return df

###############################################################################
# Problematic sequences
###############################################################################

def find_problematic_sequences(
    df,
    cds_df,
    exclude_bad=False,
    exclude_mediocre=False,
    min_genome_coverage=None,
    min_f_coverage=None,
    min_g_coverage=None,
    min_l_coverage=None,
    max_stop_codons=None,
    max_missing_bases=None,
):
    """
    Identify sequences that do not satisfy
    the requested QC criteria.
    """

    problematic = []

    # Genome coverage (0-1 -> %)
    genome_coverage = (
        pd.to_numeric(
            df[COVERAGE],
            errors="coerce",
        )
        * 100
    )

    for idx in df.index:

        reasons = []

        # QC status
        status = df.at[
            idx,
            QC_STATUS,
        ]

        if (
            exclude_bad
            and status == "bad"
        ):
            reasons.append(
                "qc.overallStatus == bad"
            )

        if (
            exclude_mediocre
            and status == "mediocre"
        ):
            reasons.append(
                "qc.overallStatus == mediocre"
            )

        # Genome coverage
        if (
            min_genome_coverage is not None
            and genome_coverage.loc[idx] < min_genome_coverage
        ):
            reasons.append(
                f"Genome coverage <{min_genome_coverage:g}%"
            )

        # Gene coverage
        gene_thresholds = {
            "F": min_f_coverage,
            "G": min_g_coverage,
            "L": min_l_coverage,
        }

        for gene, threshold in gene_thresholds.items():

            if threshold is None:
                continue

            value = pd.to_numeric(
                cds_df.at[idx, gene],
                errors="coerce",
            )

            threshold_fraction = threshold / 100
            if value < threshold_fraction:
                reasons.append(
                    f"{gene} coverage <{threshold:g}%"
                )

        # Missing bases
        missing = pd.to_numeric(
        	df[MISSING],
        	errors="coerce",
        )
        if (
        	max_missing_bases is not None
        	and missing.loc[idx] > max_missing_bases
        ):
        	reasons.append(
        		f"missing bases >{max_missing_bases}"
        	)

        # Stop codons
        stop_codons = pd.to_numeric(
        	df[STOP_CODONS],
        	errors="coerce",
        )
        if (
        	max_stop_codons is not None
        	and stop_codons.loc[idx] > max_stop_codons
        ):
       		reasons.append(
       			f"stop codons >{max_stop_codons}"
        )

        # Save
        if reasons:
            problematic.append(
                {
                    "seqName": df.at[
                        idx,
                        "seqName",
                    ],
                    "reason": "; ".join(
                        reasons,
                    ),
                }
            )

    return pd.DataFrame(
        problematic,
    )

###############################################################################
# Print helpers
###############################################################################

def print_header(title):
    """
    Print report header.
    """

    print()
    print("=" * 70)
    print(title)
    print("=" * 70)


def print_section(title):
    """
    Print section title.
    """

    print()
    print("-" * 70)
    print(title)
    print("-" * 70)


def print_field(label, value):
    """
    Print one formatted field.
    """

    print(f"{label:.<25} {value}")

def print_subfield(
    label,
    value,
):
    """
    Print one indented field.
    """

    print(
        f"    {label:.<20} {value}"
    )

def format_percentage(
    n,
    total,
):
    """
    Format counts and percentages.
    """

    return (
        f"{n:,} "
        f"({100 * n / total:.1f}%)"
    )

def parse_cds_coverage(text):
    """
    Parse the Nextclade cdsCoverage field.
    """

    if pd.isna(text):
        return {}

    coverage = {}

    for item in str(text).split(","):
        gene, value = item.split(":")
        coverage[gene] = float(value)

    return coverage

###############################################################################
# Functions
###############################################################################

# Dataset summary
def dataset_summary(
    df,
    dataset,
):
    """
    Print dataset summary.
    """

    print_section(
        "Dataset summary",
    )

    print_field(
        "Dataset",
        dataset,
    )

    print_field(
        "Sequences",
        f"{len(df):,}",
    )

    print_field(
        "Clades",
        df[CLADE].nunique(),
    )

# QC status
def qc_status_summary(df):
    """
    Print QC status summary.
    """

    print_section(
        "Overall QC status",
    )

    counts = (
        df[QC_STATUS]
        .fillna("Unknown")
        .value_counts()
    )

    total = len(df)

    for status in (
        "good",
        "mediocre",
        "bad",
    ):

        n = counts.get(
            status,
            0,
        )

        print_field(
            status.capitalize(),
            format_percentage(
                n,
                total,
            ),
        )

# Numeric summary
def numeric_summary(
    df,
    column,
    title,
    scale=1,
    decimals=0,
):
    """
    Print descriptive statistics
    for a numeric column.
    """

    values = (
        pd.to_numeric(
            df[column],
            errors="coerce",
        )
        .dropna()
    )

    values = values * scale

    print()
    print(title)

    fmt = f",.{decimals}f"

    print_subfield(
        "Minimum",
        format(values.min(), fmt),
    )

    print_subfield(
        "Q1",
        format(values.quantile(0.25), fmt),
    )

    print_subfield(
        "Median",
        format(values.median(), fmt),
    )

    print_subfield(
        "Q3",
        format(values.quantile(0.75), fmt),
    )

    print_subfield(
        "Maximum",
        format(values.max(), fmt),
    )

def summarize_cds(
    values,
):
    """
    Summarize one CDS coverage vector.
    """

    values = (
        pd.to_numeric(
            values,
            errors="coerce",
        )
        .dropna()
        * 100
    )

    n = len(values)

    complete = (
        values == 100
    ).sum()

    threshold = (
        values >= CDS_COVERAGE_THRESHOLD
    ).sum()

    return {
        "Complete (%)":
            100 * complete / n,
        f">={CDS_COVERAGE_THRESHOLD}% (%)":
            100 * threshold / n,
        "Minimum (%)":
            values.min(),
    }

# Sequence quality metrics
def sequence_quality_summary(df):
    """
    Print descriptive statistics
    for the main QC metrics.
    """

    print_section(
        "Sequence quality metrics",
    )

    numeric_summary(
        df,
        ALIGNMENT_SCORE,
        "Alignment score",
    )

    numeric_summary(
        df,
        COVERAGE,
        "Coverage (%)",
        scale=100,
        decimals=1,
    )

    numeric_summary(
        df,
        MISSING,
        "Missing bases",
    )

    numeric_summary(
        df,
        NS,
        "Non-ACGT Ns",
    )

    numeric_summary(
        df,
        FRAMESHIFTS,
        "Frameshifts",
    )

    numeric_summary(
        df,
        STOP_CODONS,
        "Stop codons",
    )

    numeric_summary(
        df,
        DELETIONS,
        "Deletions",
    )

    numeric_summary(
        df,
        INSERTIONS,
        "Insertions",
    )

# CDS coverage
def extract_cds_coverage(df):
    """
    Expand cdsCoverage into one column per CDS.
    """

    coverage = (
        df["cdsCoverage"]
        .apply(parse_cds_coverage)
    )

    return pd.DataFrame(
        coverage.tolist(),
        index=df.index,
    )

def cds_coverage_table(
    cds_df,
):
    """
    Build CDS coverage summary table.
    """

    rows = []

    for gene in sorted(cds_df.columns):
        summary = summarize_cds(
            cds_df[gene],
        )
        summary["Gene"] = gene
        rows.append(
            summary,
        )

    return (
        pd.DataFrame(rows)
        .set_index("Gene")
    )

# CDS coverage summary
def cds_coverage_summary(
    cds_df,
):
    """
    Print CDS coverage summary.
    """

    print_section(
        "CDS coverage",
    )

    table = cds_coverage_table(
        cds_df,
    )

    print(
        table.round(1)
    )

# Warnig summary
def qc_filters_summary(
    problematic,
    total_sequences,
):
    """
    Print summary of the applied QC filters.
    """

    print_section(
        "QC filters",
    )

    if problematic.empty:
        print(
            "No problematic sequences detected."
        )
        return

    print_field(
        "Problematic sequences",
        format_percentage(
            len(problematic),
            total_sequences,
        ),
    )

    print()
    print(
        "Applied filters"
    )
    print()

    counter = Counter()

    for reasons in problematic[
        "reason"
    ]:
        for reason in reasons.split(
            "; "
        ):

            counter[
                reason
            ] += 1

    for reason, count in sorted(
        counter.items(),
        key=lambda x: x[0],
    ):
        print_field(
            reason,
            format_percentage(
                count,
                total_sequences,
            ),
        )

    print()
    print(
        "Recommendation:"
    )
    print()
    print(
        "    Exclude the flagged sequences and "
        "rerun Nextclade."
    )

###############################################################################
# Export tables
###############################################################################

def export_tables(
    tables,
    output,
):
    """
    Export summary tables.
    """

    output.mkdir(
        parents=True,
        exist_ok=True,
    )

    for name, table in tables.items():

        table.to_csv(
            output / f"{name}.tsv",
            sep="\t",
            index=False,
        )

###############################################################################
# Main
###############################################################################

def main():

    args = parse_args()

    df = read_nextclade_table(
        args.input,
    )

    df = extract_accession_ids(
        df,
    )

    cds_df = extract_cds_coverage(
    	df,
    )

    print_header(
        "Nextclade QC summary",
    )

    dataset_summary(
        df,
        Path(args.input).stem,
    )

    qc_status_summary(
        df,
    )

    sequence_quality_summary(
        df,
    )

    cds_coverage_summary(
    	cds_df,
    )

    problematic = find_problematic_sequences(
    	df=df,
    	cds_df=cds_df,
    	exclude_bad=args.exclude_bad,
    	exclude_mediocre=args.exclude_mediocre,
    	min_genome_coverage=args.min_genome_coverage,
    	min_f_coverage=args.min_f_coverage,
    	min_g_coverage=args.min_g_coverage,
    	min_l_coverage=args.min_l_coverage,
    	max_missing_bases=args.max_missing_bases,
    	max_stop_codons=args.max_stop_codons,
    )

    qc_filters_summary(
    	problematic,
    	len(df),
    )

    tables = {
    	"problematic_sequences":
    		problematic,

    	"cds_coverage":
    		cds_coverage_table(
    			cds_df,
    		),
    }

    export_tables(
    	tables,
    	Path(args.outdir),
    )

    print()
    print(
    	f"Tables exported to: {args.outdir}"
    )

if __name__ == "__main__":

    main()