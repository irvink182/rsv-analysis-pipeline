#!/usr/bin/env python3

"""
normalize_nextclade_table.py

Normalize the Nextclade output table by extracting metadata
from the 'seqName' column and adding helper columns for
downstream analyses.
"""

###############################################################################
# Imports
###############################################################################

import argparse

import pandas as pd


###############################################################################
# Command-line arguments
###############################################################################

def parse_args():
    """
    Parse command-line arguments.
    """

    parser = argparse.ArgumentParser(
        description=(
            "Normalize a Nextclade TSV by splitting the "
            "'seqName' column into metadata fields."
        )
    )

    parser.add_argument(
        "--input",
        required=True,
        help="Input Nextclade TSV."
    )

    parser.add_argument(
        "--output",
        required=True,
        help="Output normalized TSV."
    )

    return parser.parse_args()


###############################################################################
# Read table
###############################################################################

def read_table(path):
    """
    Read Nextclade table.
    """

    return pd.read_csv(
        path,
        sep="\t",
        dtype=str,
    )


###############################################################################
# Normalize table
###############################################################################

def normalize_table(df):
    """
    Normalize the Nextclade table.

    Adds the following columns:

        - Virus name
        - Accession ID
        - Collection date
        - nextclade_lineage
    """

    required = [
        "seqName",
        "clade",
    ]

    missing = [
        column
        for column in required
        if column not in df.columns
    ]

    if missing:

        raise ValueError(
            "Missing required columns: "
            + ", ".join(missing)
        )

    ###########################################################################
    # Split seqName
    ###########################################################################

    fields = (
        df["seqName"]
        .str.split(
            "|",
            expand=True,
        )
    )

    if fields.shape[1] != 3:

        raise ValueError(
            "Expected 'seqName' format:\n"
            "'Virus name|Accession ID|Collection date'."
        )

    df = df.copy()

    df.insert(
        0,
        "Virus name",
        fields[0],
    )

    df.insert(
        1,
        "Accession ID",
        fields[1],
    )

    df.insert(
        2,
        "Collection date",
        fields[2],
    )

    ###########################################################################
    # Duplicate lineage column
    ###########################################################################

    insert_position = (
        df.columns
        .get_loc("clade")
        + 1
    )

    df.insert(
        insert_position,
        "nextclade_lineage",
        df["clade"],
    )

    return df


###############################################################################
# Write table
###############################################################################

def write_table(
    df,
    output,
):
    """
    Write normalized table.
    """

    df.to_csv(
        output,
        sep="\t",
        index=False,
    )


###############################################################################
# Summary
###############################################################################

def print_summary(df):
    """
    Print normalization summary.
    """

    print()

    print("=" * 70)
    print("Nextclade normalization summary")
    print("=" * 70)

    print(
        f"{'Sequences':35}"
        f"{len(df):>10,}"
    )

    print(
        f"{'Columns':35}"
        f"{len(df.columns):>10,}"
    )

    print()

    print("Added columns")

    for column in (
        "Virus name",
        "Accession ID",
        "Collection date",
        "nextclade_lineage",
    ):

        print(f"  • {column}")

    print()


###############################################################################
# Main
###############################################################################

def main():

    args = parse_args()

    table = read_table(
        args.input,
    )

    table = normalize_table(
        table,
    )

    write_table(
        table,
        args.output,
    )

    print_summary(
        table,
    )


if __name__ == "__main__":

    main()