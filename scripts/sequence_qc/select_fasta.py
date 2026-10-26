#!/usr/bin/env python3

"""
Select FASTA records using identifiers from a metadata table
or a plain-text list.
"""

###############################################################################
# Imports
###############################################################################

import argparse
import pandas as pd
from Bio import SeqIO

###############################################################################
# Command-line arguments
###############################################################################

def parse_args():
    """
    Parse command-line arguments.
    """

    parser = argparse.ArgumentParser(
        description=(
            "Select FASTA records using identifiers from a "
            "metadata table or a plain-text list."
        ),
        epilog="""
Examples:

  # Select sequences from a metadata table
  python select_fasta.py \\
      --table gisaid_RSV-A_phylogeny.tsv \\
      --column "Accession ID" \\
      --fasta gisaid_RSV-A.fasta \\
      --output gisaid_RSV-A_phylogeny.fasta

  # Select sequences from a list of accession IDs
  python select_fasta.py \\
      --list accession_ids.txt \\
      --fasta gisaid_RSV-A.fasta \\
      --output selected.fasta
""",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    ###########################################################################
    # Selection
    ###########################################################################

    input_group = parser.add_argument_group(
        "Selection"
    )

    source = input_group.add_mutually_exclusive_group(
        required=True,
    )

    source.add_argument(
        "--table",
        help="Input metadata table (TSV).",
    )

    source.add_argument(
        "--list",
        dest="id_list",
        help="Plain-text file containing one identifier per line.",
    )

    input_group.add_argument(
        "--column",
        default="Accession ID",
        help="Column containing the identifiers.",
    )

    input_group.add_argument(
        "--exclude",
        action="store_true",
        help=(
            "Exclude matching sequences instead of "
            "selecting them."
        ),
    )

    ###########################################################################
    # Input FASTA
    ###########################################################################

    fasta_group = parser.add_argument_group(
        "Input FASTA"
    )

    fasta_group.add_argument(
        "--fasta",
        required=True,
        help="Input FASTA file.",
    )

    fasta_group.add_argument(
        "--separator",
        default="|",
        help="Header separator.",
    )

    fasta_group.add_argument(
        "--id-field",
        type=int,
        default=2,
        help=(
            "Header field containing the identifier "
            "(1-based index)."
        ),
    )

    ###########################################################################
    # Output
    ###########################################################################

    output_group = parser.add_argument_group(
        "Output"
    )

    output_group.add_argument(
        "--output",
        required=True,
        help="Output FASTA file.",
    )

    output_group.add_argument(
        "--missing",
        help=(
            "Write identifiers not found in the FASTA "
            "to a text file."
        ),
    )

    return parser.parse_args()


###############################################################################
# Read identifiers
###############################################################################

def read_ids(
    args,
):
    """
    Read identifiers from a metadata table
    or a plain-text list.
    """

    # Metadata table
    if args.table:

        table = pd.read_csv(
            args.table,
            sep="\t",
            dtype=str,
        )

        if args.column not in table.columns:
            raise ValueError(
                f"Column '{args.column}' not found."
            )

        ids = (
            table[args.column]
            .dropna()
            .astype(str)
            .str.strip()
        )

    # Plain-text list
    else:

        with open(
            args.id_list,
        ) as handle:

            ids = [
                line.strip()
                for line in handle
                if line.strip()
            ]

    ids = set(ids)

    if len(ids) == 0:
        raise ValueError(
            "No identifiers found."
        )

    return ids

###############################################################################
# Select FASTA records
###############################################################################

def select_records(
    fasta,
    ids,
    separator="|",
    id_field=2,
    exclude=False,
):
    """
    Select FASTA records.
    """

    records = []

    found_ids = set()

    total_records = 0

    id_field -= 1

    for record in SeqIO.parse(
        fasta,
        "fasta",
    ):

        total_records += 1

        header = record.description.strip()

        # Try matching the complete FASTA header first
        if header in ids:
            identifier = header

        # Otherwise, extract the requested header field
        else:
            fields = header.split(
                separator,
            )

            if len(fields) <= id_field:
                continue

            identifier = fields[
                id_field
            ].strip()

        selected = (
            identifier in ids
        )

        if exclude:
            selected = not selected

        if selected:
            records.append(
                record,
            )

        if identifier in ids:
            found_ids.add(
                identifier,
            )

    missing_ids = ids - found_ids

    return (
        records,
        found_ids,
        missing_ids,
        total_records,
    )

###############################################################################
# Write FASTA
###############################################################################

def write_fasta(
    records,
    output,
):
    """
    Write selected FASTA records.
    """

    SeqIO.write(
        records,
        output,
        "fasta",
    )

###############################################################################
# Print summary
###############################################################################

def print_summary(
    total_records,
    ids,
    records,
    missing_ids,
    output,
    exclude=False,
):
    """
    Print FASTA selection summary.
    """

    print()

    print("=" * 70)
    print("FASTA selection summary")
    print("=" * 70)

    print(
        f"{'Input FASTA records':35}"
        f"{total_records:>10,}"
    )

    print(
        f"{'Identifiers requested':35}"
        f"{len(ids):>10,}"
    )

    label = (
        "Sequences retained"
        if exclude
        else "Sequences selected"
    )

    print(
        f"{label:35}"
        f"{len(records):>10,}"
    )

    print(
        f"{'Sequences selected':35}"
        f"{len(records):>10,}"
    )

    print(
        f"{'Missing identifiers':35}"
        f"{len(missing_ids):>10,}"
    )

    print(
        f"{'Output FASTA':35}"
        f"{output}"
    )

    print()


###############################################################################
# Main
###############################################################################

def main():

    args = parse_args()

    ids = read_ids(
        args,
    )

    (
        records,
        found_ids,
        missing_ids,
        total_records,
    ) = select_records(
        fasta=args.fasta,
        ids=ids,
        separator=args.separator,
        id_field=args.id_field,
        exclude=args.exclude,
    )

    write_fasta(
        records,
        args.output,
    )

    if args.missing:

        with open(
            args.missing,
            "w",
        ) as handle:

            for identifier in sorted(
                missing_ids,
            ):

                handle.write(
                    identifier + "\n",
                )

    print_summary(
    	total_records,
        ids,
        records,
        missing_ids,
        args.output,
    )

if __name__ == "__main__":

    main()