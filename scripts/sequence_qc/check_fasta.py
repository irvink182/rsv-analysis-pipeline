#!/usr/bin/env python3

"""
Check FASTA sequence quality.
"""

###############################################################################
# Imports
###############################################################################

import argparse

import pandas as pd

from Bio import SeqIO
from Bio.SeqUtils import gc_fraction

###############################################################################
# Command-line arguments
###############################################################################

def parse_args():
    """
    Parse command-line arguments.
    """

    parser = argparse.ArgumentParser(
        description=(
            "Generate quality statistics for a FASTA file."
        ),
        epilog="""
Examples:

  python check_fasta.py \\
      --fasta gisaid_RSV-A_phylogeny.fasta

  python check_fasta.py \\
      --fasta gisaid_RSV-A_phylogeny.fasta \\
      --reference RSV-A_reference.fasta

  python check_fasta.py \\
      --fasta sequences.fasta \\
      --reference reference.fasta \\
      --output fasta_statistics.tsv
""",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    ###########################################################################
    # Input
    ###########################################################################

    input_group = parser.add_argument_group(
        "Input"
    )

    input_group.add_argument(
        "--fasta",
        required=True,
        help="Input FASTA file.",
    )

    input_group.add_argument(
        "--reference",
        help=(
            "Reference FASTA used to calculate "
            "genome coverage."
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
        help=(
            "Write per-sequence statistics "
            "to a TSV file."
        ),
    )

    return parser.parse_args()

###############################################################################
# Read reference
###############################################################################

def read_reference(
    reference,
):
    """
    Read a reference FASTA file.
    """

    if reference is None:
        return None

    records = list(
        SeqIO.parse(
            reference,
            "fasta",
        )
    )

    if len(records) == 0:
        raise ValueError(
            "Reference FASTA is empty."
        )

    if len(records) > 1:
        raise ValueError(
            "Reference FASTA must contain "
            "exactly one sequence."
        )

    return records[0]

###############################################################################
# Analyze FASTA
###############################################################################

def analyze_fasta(
    fasta,
    reference=None,
):
    """
    Analyze FASTA sequence quality.
    """

    rows = []

    reference_length = None

    if reference is not None:

        reference_length = len(
            reference.seq,
        )

    for record in SeqIO.parse(
        fasta,
        "fasta",
    ):

        sequence = str(
            record.seq,
        ).upper()

        length = len(
            sequence,
        )

        n_count = sequence.count(
            "N",
        )

        informative_length = (
            length -
            n_count
        )

        ambiguous = sum(
        	base not in {"A", "C", "G", "T"}
        	for base in sequence
        ) 

        n_percentage = (
            100 * n_count / length
            if length > 0
            else 0
        )

        valid_bases = sequence.replace(
        	"N",
        	"",
        )

        gc = (
            gc_fraction(sequence)
            * 100
            if valid_bases
            else 0
        )

        leading_ns = len(sequence) - len(sequence.lstrip("N"))

        trailing_ns = len(sequence) - len(sequence.rstrip("N"))

        row = {

            "Sequence": record.id,

            "Length": length,

            "informative length": informative_length,

            "Ns": n_count,

            "%Ns": round(
                n_percentage,
                2,
            ),

            "Ambiguous bases": ambiguous,

            "GC (%)": round(
                gc,
                2,
            ),

            "Leading Ns": leading_ns,

            "Trailing Ns": trailing_ns,
        }

        if reference_length is not None:

            row["Coverage (%)"] = round(
                100 * length / reference_length,
                2,
            )

        rows.append(
            row,
        )

    if not rows:
    	raise ValueError(
    		"No sequences found in FASTA file.")

    return pd.DataFrame(
        rows,
    )

###############################################################################
# Write table
###############################################################################

def write_table(
    table,
    output,
):
    """
    Write FASTA statistics to a TSV file.
    """

    if output is None:
        return

    table.to_csv(
        output,
        sep="\t",
        index=False,
    )

###############################################################################
# Print summary
###############################################################################

def print_summary(
    table,
    fasta,
    reference=None,
):
    """
    Print FASTA quality summary.
    """

    print()
    print("=" * 70)
    print("FASTA quality summary")
    print("=" * 70)
    print(
        f"{'Input FASTA':35}"
        f"{fasta}"
    )
    if reference is not None:
        print(
            f"{'Reference':35}"
            f"{reference.id}"
        )
        print(
            f"{'Reference length (bp)':35}"
            f"{len(reference.seq):>10,}"
        )
    print()
    print(
        f"{'Sequences':35}"
        f"{len(table):>10,}"
    )
    print()

    # Sequence length
    print("Sequence length (bp)")
    print(
        f"{'  Minimum':35}"
        f"{table['Length'].min():>10,}"
    )
    print(
        f"{'  Median':35}"
        f"{table['Length'].median():>10.0f}"
    )
    print(
        f"{'  Maximum':35}"
        f"{table['Length'].max():>10,}"
    )
    
    # Coverage
    if "Coverage (%)" in table.columns:
    	print()
    	print("Genome coverage (%)")
    	print(
    		f"{'  Minimum':35}"
    		f"{table['Coverage (%)'].min():>10.2f}"
    	)
    	print(
    		f"{'  Median':35}"
    		f"{table['Coverage (%)'].median():>10.2f}"
    	)
    	print(
    		f"{'  Maximum':35}"
    		f"{table['Coverage (%)'].max():>10.2f}"
    	)
    	print()
    	print(
    		f"{'  Coverage ≥99%':35}"
    		f"{(table['Coverage (%)'] >= 99).sum():>10,}"
    	)
    	print(
    		f"{'  Coverage ≥95%':35}"
    		f"{(table['Coverage (%)'] >= 95).sum():>10,}"
    	)
    	print(
    		f"{'  Coverage ≥90%':35}"
    		f"{(table['Coverage (%)'] >= 90).sum():>10,}"
    	)

    # Ns
    print()
    print("Ambiguous bases (N)")
    print(
        f"{'  Minimum':35}"
        f"{table['Ns'].min():>10,}"
    )
    print(
        f"{'  Median':35}"
        f"{table['Ns'].median():>10.0f}"
    )
    print(
        f"{'  Maximum':35}"
        f"{table['Ns'].max():>10,}"
    )
    print(
        f"{'  Sequences with Ns':35}"
        f"{(table['Ns'] > 0).sum():>10,}"
    )
    # GC
    print()
    print("GC content (%)")
    print(
        f"{'  Minimum':35}"
        f"{table['GC (%)'].min():>10.2f}"
    )
    print(
        f"{'  Median':35}"
        f"{table['GC (%)'].median():>10.2f}"
    )
    print(
        f"{'  Maximum':35}"
        f"{table['GC (%)'].max():>10.2f}"
    )
    
    # Leading / Trailing Ns
    print()
    print(
        f"{'Sequences with leading Ns':35}"
        f"{(table['Leading Ns'] > 0).sum():>10,}"
    )
    print(
        f"{'Sequences with trailing Ns':35}"
        f"{(table['Trailing Ns'] > 0).sum():>10,}"
    )
    print()

###############################################################################
# Main
###############################################################################

def main():

    args = parse_args()

    reference = read_reference(
        args.reference,
    )

    table = analyze_fasta(
        fasta=args.fasta,
        reference=reference,
    )

    write_table(
        table,
        args.output,
    )

    print_summary(
        table=table,
        fasta=args.fasta,
        reference=reference,
    )

if __name__ == "__main__":

    main()