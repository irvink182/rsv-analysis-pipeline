#!/usr/bin/env python3

"""
Characterize the genetic structure of a viral population from pairwise SNP distances..
"""

###############################################################################
# Imports
###############################################################################

import argparse

import pandas as pd

import networkx as nx
import matplotlib.pyplot as plt
from pathlib import Path
from dataclasses import dataclass
from matplotlib.ticker import ScalarFormatter

###############################################################################
# Sequence metadata
###############################################################################

@dataclass
class SequenceMetadata:

    header: str

    virus_name: str

    accession_id: str

    collection_date: str | None

    reference: bool

    @property
    def subtype(self):

        if "/A/" in self.virus_name:
            return "A"

        elif "/B/" in self.virus_name:
            return "B"

        return None

###############################################################################
# Plot settings
###############################################################################

FIGURE_WIDTH = 8
FIGURE_HEIGHT = 5
FIGURE_DPI = 300
FONT_SIZE = 11
TITLE_SIZE = 13
LABEL_SIZE = 12
TICK_SIZE = 10
LINE_WIDTH = 2.5
MARKER_SIZE = 7
GRID_ALPHA = 0.3
EXPORT_FORMATS = [
    "png",
    "svg",
]
PNG_RESOLUTION = 300

###############################################################################
# Distance plot settings
###############################################################################

DISTANCE_BIN = 5
DISTANCE_ZOOM = 40

CLUSTER_THRESHOLDS = [0, 5, 10, 15, 20]

###############################################################################
# Colors
###############################################################################

COLOR_BLUE = "#2C5AA0"
COLOR_ORANGE = "#DD8452"
COLOR_GREEN = "#55A868"
COLOR_RED = "#C44E52"
COLOR_GREY = "#808080"
COLOR_PURPLE = "#8172B2"

###############################################################################
# Configure plot style
###############################################################################

def setup_plot():
    """
    Configure matplotlib defaults.
    """

    plt.rcParams.update({
        "font.size": FONT_SIZE,
        "axes.titlesize": TITLE_SIZE,
        "axes.labelsize": LABEL_SIZE,
        "xtick.labelsize": TICK_SIZE,
        "ytick.labelsize": TICK_SIZE,
        "axes.linewidth": 0.8,
        "svg.fonttype": "none",
    })

###############################################################################
# Save figure
###############################################################################

def save_figure(
    figure,
    output,
):
    """
    Save figure in all configured formats.
    """

    for fmt in EXPORT_FORMATS:
        kwargs = {
            "bbox_inches": "tight",
        }

        if fmt == "png":
            kwargs["dpi"] = PNG_RESOLUTION

        figure.savefig(
            output.with_suffix(f".{fmt}"),
            **kwargs,
        )

###############################################################################
# Command-line arguments
###############################################################################

def parse_args():
    """
    Parse command-line arguments.
    """

    parser = argparse.ArgumentParser(
        description=(
            "Characterize the genetic structure of a viral "
            "population from pairwise SNP distances."
        ),
        epilog="""
Examples:

  python cluster_analysis.py \\
      --distances RSV-A.snpdist.tsv

  python cluster_analysis.py \\
      --distances RSV-A.snpdist.tsv \\
      --reference "hRSV/A/England/397/2017"

  python cluster_analysis.py \\
      --distances RSV-A.snpdist.tsv \\
      --thresholds 0 5 10 15 20 \\
      --outdir workflow/06_clusters/RSV-A
""",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    # Input
    input_group = parser.add_argument_group(
        "Input",
    )

    input_group.add_argument(
        "--distances",
        required=True,
        help=(
            "Pairwise SNP distance table generated "
            "with snp-dists (-m -t)."
        ),
    )

    # Clustering
    cluster_group = parser.add_argument_group(
        "Clustering",
    )

    cluster_group.add_argument(
        "--thresholds",
        type=int,
        nargs="+",
        default=CLUSTER_THRESHOLDS,
        help=(
            "SNP distance thresholds "
            "(default: 0 5 10 15 20)."
        ),
    )

    # Output
    output_group = parser.add_argument_group(
        "Output",
    )

    output_group.add_argument(
        "--outdir",
        default="cluster_analysis",
        help=(
            "Output directory "
            "(default: cluster_analysis)."
        ),
    )

    return parser.parse_args()

###############################################################################
# Parse sequence names
###############################################################################

def parse_sequence_name(
    header,
):
    """
    Parse a FASTA header.

    Supported formats:

        Virus name|Accession ID|Collection date
    or
        Virus name

    (reference sequence)
    """

    fields = header.split("|")

    # GISAID sequence
    if len(fields) == 3:

        return SequenceMetadata(
            header=header,
            virus_name=fields[0],
            accession_id=fields[1],
            collection_date=fields[2],
            reference=False,
        )

    # Reference sequence
    elif len(fields) == 1:

        return SequenceMetadata(
            header=header,
            virus_name=fields[0],
            accession_id=fields[0],
            collection_date=None,
            reference=True,
        )

    # Unknown format
    raise ValueError(
        f"Invalid FASTA header:\n{header}"
    )

###############################################################################
# Read pairwise SNP distances
###############################################################################

def read_distance_matrix(
    distances,
    remove_reference=True,
):
    """
    Read pairwise SNP distances generated by
    snp-dists (-m -t).
    """

    # Read table
    df = pd.read_csv(
        distances,
        sep="\t",
    )

    expected_columns = [
        "sequence_1",
        "sequence_2",
        "distance",
    ]

    if list(df.columns) != expected_columns:

        raise ValueError(
            "Input file must contain the columns:\n"
            "sequence_1, sequence_2, distance."
        )

    # Parse sequence headers
    seq1 = df["sequence_1"].map(
        parse_sequence_name,
    )

    seq2 = df["sequence_2"].map(
        parse_sequence_name,
    )

    # Add metadata
    df["taxon_1"] = seq1.map(
    	lambda x: x.header,
    )

    df["taxon_2"] = seq2.map(
    	lambda x: x.header,
    )

    df["accession_1"] = seq1.map(
        lambda x: x.accession_id,
    )

    df["accession_2"] = seq2.map(
        lambda x: x.accession_id,
    )

    df["virus_1"] = seq1.map(
        lambda x: x.virus_name,
    )

    df["virus_2"] = seq2.map(
        lambda x: x.virus_name,
    )

    df["header_1"] = seq1.map(
    	lambda x: x.header,
    )

    df["header_2"] = seq2.map(
    	lambda x: x.header,
    )

    df["reference_1"] = seq1.map(
        lambda x: x.reference,
    )

    df["reference_2"] = seq2.map(
        lambda x: x.reference,
    )

    # Remove reference sequences
    if remove_reference:

        df = df.loc[
            ~df["reference_1"]
            &
            ~df["reference_2"]
        ].copy()

    # Remove self comparisons
    df = df.loc[
        df["accession_1"]
        !=
        df["accession_2"]
    ].copy()

    # Remove duplicated pairs
    df["pair"] = df.apply(
        lambda row: tuple(
            sorted(
                (
                    row["accession_1"],
                    row["accession_2"],
                )
            )
        ),
        axis=1,
    )

    df = (
        df
        .drop_duplicates(
            subset="pair",
        )
        .drop(
            columns=[
                "pair",
                "reference_1",
                "reference_2",
            ],
        )

        .reset_index(
            drop=True,
        )

    )

    # Check completeness
    sequences = sorted(
        set(
            df["accession_1"]
        )
        |
        set(
            df["accession_2"]
        )
    )

    expected_pairs = (
        len(sequences)
        *
        (len(sequences) - 1)
        //
        2
    )

    if len(df) != expected_pairs:
        raise ValueError(
            "Pairwise distance matrix appears "
            "to be incomplete."
        )

    return df

###############################################################################
# Summarize pairwise distances
###############################################################################

def summarize_distances(
    distances,
):
    """
    Summarize pairwise SNP distances.
    """

    summary = {
        "pairs": len(distances),
        "unique_sequences": len(
            set(distances["accession_1"])
            |
            set(distances["accession_2"])
        ),
        "minimum": distances["distance"].min(),
        "median": distances["distance"].median(),
        "maximum": distances["distance"].max(),
        "identical_pairs": (
            distances["distance"] == 0
        ).sum(),
    }

    distribution = (
        distances["distance"]
        .value_counts()
        .sort_index()
        .rename_axis(
            "distance"
        )
        .reset_index(
            name="count"
        )
    )

    return (
        summary,
        distribution,
    )

###############################################################################
# Find genetic clusters
###############################################################################

def find_clusters(
    distances,
    thresholds,
):
    """
    Identify genetic clusters for one or more
    SNP distance thresholds.
    """

    # Accession → Taxon lookup
    accession_to_taxon = (
        pd.concat(
            [
                distances[
                    ["accession_1", "taxon_1"]
                ].rename(
                    columns={
                        "accession_1": "Accession ID",
                        "taxon_1": "Taxon",
                    }
                ),
                distances[
                    ["accession_2", "taxon_2"]
                ].rename(
                    columns={
                        "accession_2": "Accession ID",
                        "taxon_2": "Taxon",
                    }
                ),
            ]
        )
        .drop_duplicates()
        .set_index("Accession ID")["Taxon"]
        .to_dict()
    )

    assignments = []

    summaries = []

    # All sequences
    sequences = sorted(
        set(distances["accession_1"])
        |
        set(distances["accession_2"])
    )

    # Iterate thresholds
    for threshold in thresholds:
        graph = nx.Graph()
        graph.add_nodes_from(
            sequences,
        )

        # Add edges
        edges = distances.loc[
            distances["distance"] <= threshold
        ]

        graph.add_edges_from(
            zip(
                edges["accession_1"],
                edges["accession_2"],
            )
        )

        # Connected components
        components = list(
            nx.connected_components(
                graph,
            )
        )

        # Sort components by representative accession
        components = sorted(
            components,
            key=lambda x: sorted(x)[0],
        )

        cluster_sizes = []

        # Process clusters
        for i, component in enumerate(
            components,
            start=1,
        ):
            representative = sorted(component)[0]

            representative_taxon = accession_to_taxon[
                representative
            ]

            size = len(component)

            cluster_sizes.append(size)

            if size == 1:
                cluster_id = "Singleton"
            else:
                cluster_id = (
                    f"SNP{threshold}_"
                    f"C{i:06d}"
                )

            for accession in sorted(component):
                assignments.append(
                    {
                        "Taxon": accession_to_taxon[
                            accession
                        ],
                        "Accession ID": accession,
                        "Cluster threshold": threshold,
                        "Cluster ID": cluster_id,
                        "Representative Taxon": representative_taxon,
                        "Representative ID": representative,
                        "Representative": (
                            accession == representative
                        ),
                        "Cluster size": size,
                    }
                )

        # Summary
        transmission_sizes = [
            s
            for s in cluster_sizes
            if s > 1
        ]

        clustered_samples = sum(
            transmission_sizes
        )

        summaries.append(
            {
                "Cluster threshold": threshold,
                "Sequences": len(
                    sequences,
                ),
                "Clusters": len(
                    transmission_sizes,
                ),
                "Clustered samples": clustered_samples,
                "Singletons": sum(
                    s == 1
                    for s in cluster_sizes
                ),
                "Largest cluster": (
                    max(
                        transmission_sizes,
                    )
                    if transmission_sizes
                    else 0
                ),
                "Mean cluster size": (
                    round(
                        pd.Series(
                            transmission_sizes,
                        ).mean(),
                        2,
                    )
                    if transmission_sizes
                    else 0
                ),
                "Median cluster size": (
                    round(
                        pd.Series(
                            transmission_sizes,
                        ).median(),
                        2,
                    )
                    if transmission_sizes
                    else 0
                ),
            }
        )

    # Convert to DataFrames
    genetic_clusters = pd.DataFrame(
        assignments,
    )

    cluster_summary = pd.DataFrame(
        summaries,
    )

    # Sort output table
    genetic_clusters = (
        genetic_clusters
        .sort_values(
            by=[
                "Cluster threshold",
                "Cluster size",
                "Representative ID",
                "Accession ID",
            ],
            ascending=[
                True,
                False,
                True,
                True,
            ],
        )
        .reset_index(
            drop=True,
        )
    )

    # Reorder columns
    genetic_clusters = genetic_clusters[
        [
            "Taxon",
            "Accession ID",
            "Cluster threshold",
            "Cluster ID",
            "Representative Taxon",
            "Representative ID",
            "Representative",
            "Cluster size",
        ]
    ]

    return (
        genetic_clusters,
        cluster_summary,
    )

###############################################################################
# Cluster size distribution
###############################################################################

def summarize_cluster_sizes(
    genetic_clusters,
):
    """
    Summarize the distribution of cluster sizes.
    """

    # One row per cluster
    clusters = (
        genetic_clusters
        .drop_duplicates(
            subset=[
                "Cluster threshold",
                "Cluster ID",
            ]
        )
    )

    # Count clusters of each size
    distribution = (
        clusters
        .groupby(
            [
                "Cluster threshold",
                "Cluster size",
            ],
            as_index=False,
        )
        .size()
        .rename(
            columns={
                "size": "Clusters",
            }
        )
    )

    return distribution

###############################################################################
# Cluster size CCDF
###############################################################################

def summarize_cluster_size_ccdf(
    cluster_size_distribution,
):
    """
    Compute the complementary cumulative distribution
    of cluster sizes.
    """

    ccdf = []

    for threshold in CLUSTER_THRESHOLDS:
        data = (
            cluster_size_distribution
            .loc[
                cluster_size_distribution[
                    "Cluster threshold"
                ] == threshold
            ]
            .sort_values(
                "Cluster size",
            )
            .copy()
        )
        # Reverse cumulative sum
        data["Clusters ≥ size"] = (
            data["Clusters"]
            .iloc[::-1]
            .cumsum()
            .iloc[::-1]
        )
        ccdf.append(data)

    ccdf = pd.concat(
        ccdf,
        ignore_index=True,
    )

    return ccdf

###############################################################################
# Cluster annotations
###############################################################################

def build_cluster_annotations(
    genetic_clusters,
):
    """
    Convert long-format cluster assignments into
    a wide annotation table.
    """

    annotations = (
        genetic_clusters
        .pivot(
            index=["Taxon", "Accession ID"],
            columns="Cluster threshold",
            values="Cluster ID",
        )
        .rename(
            columns={
                t: f"Cluster_{t}"
                for t in CLUSTER_THRESHOLDS
            }
        )
        .reset_index()
    )

    annotations.columns.name = None

    # Reorder columns
    annotations = annotations[
    	[
    		"Taxon",
    		"Accession ID",
    	]
    	+
    	[
    		f"Cluster_{threshold}"
    		for threshold in CLUSTER_THRESHOLDS
    	]
    ]

    return annotations

###############################################################################
# Write output tables
###############################################################################

def write_tables(
    distribution,
    genetic_clusters,
    cluster_summary,
    cluster_annotations,
    cluster_size_distribution,
    cluster_size_ccdf,
    outdir,
):
    """
    Write output tables.
    """

    # Create output directories
    outdir = Path(outdir)

    tables_dir = outdir / "tables"

    figures_dir = outdir / "figures"

    tables_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    figures_dir.mkdir(
        exist_ok=True,
    )

    # Pairwise distance distribution
    distribution.to_csv(
        tables_dir / "distance_distribution.tsv",
        sep="\t",
        index=False,
    )

    # Genetic clusters
    genetic_clusters.to_csv(
        tables_dir / "genetic_clusters.tsv",
        sep="\t",
        index=False,
    )

    # Identical sequences (0 SNPs)
    identical = (
        genetic_clusters

        .loc[
            genetic_clusters["Cluster threshold"] == 0
        ]
        .copy()
    )

    identical.to_csv(
        tables_dir / "identical_sequences.tsv",
        sep="\t",
        index=False,
    )

    # Cluster representatives
    representatives = (
        genetic_clusters
        .loc[
            genetic_clusters["Representative"],
            [
            	"Cluster threshold",
            	"Cluster ID",
            	"Representative ID",
            	"Cluster size",
            ],
        ]
        .copy()
    )

    representatives.to_csv(
        tables_dir / "cluster_representatives.tsv",
        sep="\t",
        index=False,
    )

    # Cluster summary
    cluster_summary.to_csv(
        tables_dir / "cluster_summary.tsv",
        sep="\t",
        index=False,
    )

    # Cluster size distribution
    cluster_size_distribution.to_csv(
    	tables_dir / "cluster_size_distribution.tsv",
    	sep="\t",
    	index=False,
    )

    # Cluster size CCDF
    cluster_size_ccdf.to_csv(
    	tables_dir / "cluster_size_ccdf.tsv",
    	sep="\t",
    	index=False,
    )

    # Cluster annotations
    cluster_annotations.to_csv(
    	tables_dir / "cluster_annotations.tsv",
    	sep="\t",
    	index=False,
    )

    return (
        tables_dir,
        figures_dir,
    )

###############################################################################
# Pairwise SNP distance distribution
###############################################################################

def plot_pairwise_distance_distribution(
    distribution,
    figures_dir,
    xmax=None,
    suffix="",
):
    """
    Plot the distribution of pairwise SNP distances.
    """

    # Prepare data
    plot_data = distribution.copy()

    if xmax is not None:
        plot_data = plot_data.loc[
            plot_data["distance"] <= xmax
        ].copy()
        x = plot_data["distance"]
        y = plot_data["count"]
    else:
    	plot_data["bin"] = (
    		plot_data["distance"]
    		//
    		DISTANCE_BIN
    		) * DISTANCE_BIN
    	plot_data = (
    		plot_data
    		.groupby(
    			"bin",
    			as_index=False,
    		)["count"]
    		.sum()
    	)
    	x = plot_data["bin"]
    	y = plot_data["count"]

    # Create figure
    fig, ax = plt.subplots(
        figsize=(
            FIGURE_WIDTH,
            FIGURE_HEIGHT,
        ),
    )

    # Plot
    ax.step(
    	x,
    	y,
        where="post",
        color=COLOR_BLUE,
        linewidth=LINE_WIDTH,
    )

    # Labels
    ax.set_xlabel(
        "Pairwise SNP distance",
    )

    ax.set_ylabel(
        "Number of pairwise comparisons",
    )

    ax.set_title(
        "Pairwise SNP distance distribution",
    )

    # Axes
    if xmax is not None:
    	ax.set_yscale(
    		"linear",
    	)
    else:
    	ax.set_yscale(
    		"log",
    	)

    ax.set_xlim(
        left=0,
    )

    if xmax is not None:
        ax.set_xlim(
            0,
            xmax,
        )

    #Cluster threshold vertical lines
    if xmax is not None:
    	for threshold in CLUSTER_THRESHOLDS:
    		if threshold <= xmax:
    			ax.axvline(
    				threshold,
    				color=COLOR_GREY,
    				linestyle="--",
    				linewidth=0.8,
    				alpha=0.7,
    				zorder=5,
    			)

    #Annotation above threshold lines
    for threshold in CLUSTER_THRESHOLDS:
    	ax.text(
    		threshold,
    		ax.get_ylim()[1],
    		str(threshold),
    		rotation=90,
    		fontsize=8,
    		ha="center",
    		va="bottom",
    		)

    #Style
    ax.grid(
        axis="y",
        alpha=GRID_ALPHA,
        linewidth=0.5,
    )

    ax.spines["top"].set_visible(
        False,
    )

    ax.spines["right"].set_visible(
        False,
    )

    # Save figure
    fig.tight_layout()

    save_figure(
        figure=fig,
        output=(
            figures_dir
            /
            f"pairwise_distance_distribution{suffix}"
        ),
    )

    plt.close(
        fig,
    )

###############################################################################
# Cluster summary
###############################################################################

def plot_cluster_summary(
    cluster_summary,
    figures_dir,
):
    """
    Plot summary statistics of genetic clusters.
    """

    # Figure
    fig, axes = plt.subplots(
        2,
        2,
        figsize=(
            FIGURE_WIDTH * 1.6,
            FIGURE_HEIGHT * 1.6,
        ),
        sharex=True,
    )

    axes = axes.flatten()

    # Common x-axis
    x = cluster_summary["Cluster threshold"]

    # Panel 1 - Number of clusters
    axes[0].plot(
        x,
        cluster_summary["Clusters"],
        color=COLOR_BLUE,
        linewidth=LINE_WIDTH,
        marker="o",
        markersize=MARKER_SIZE,
    )

    axes[0].set_ylabel(
        "Clusters",
    )

    axes[0].set_title(
        "Number of clusters",
    )

    # Panel 2 - Clustered samples
    axes[1].plot(
        x,
        cluster_summary["Clustered samples"],
        color=COLOR_RED,
        linewidth=LINE_WIDTH,
        marker="o",
        markersize=MARKER_SIZE,
    )

    axes[1].set_ylabel(
        "Samples",
    )

    axes[1].set_title(
        "Clustered samples",
    )

    # Panel 3 - Largest cluster
    axes[2].plot(
        x,
        cluster_summary["Largest cluster"],
        color=COLOR_GREEN,
        linewidth=LINE_WIDTH,
        marker="o",
        markersize=MARKER_SIZE,
    )

    axes[2].set_ylabel(
        "Sequences",
    )

    axes[2].set_xlabel(
        "Cluster threshold (SNPs)",
    )

    axes[2].set_title(
        "Largest cluster",
    )

    # Panel 4 - Singletons
    axes[3].plot(
        x,
        cluster_summary["Singletons"],
        color=COLOR_ORANGE,
        linewidth=LINE_WIDTH,
        marker="o",
        markersize=MARKER_SIZE,
    )

    axes[3].set_ylabel(
        "Samples",
    )

    axes[3].set_xlabel(
        "Cluster threshold (SNPs)",
    )

    axes[3].set_title(
        "Singletons",
    )

    # Style
    for ax in axes:
        ax.grid(
            axis="y",
            alpha=GRID_ALPHA,
            linewidth=0.5,
        )

        ax.spines["top"].set_visible(
            False,
        )

        ax.spines["right"].set_visible(
            False,
        )

        ax.set_xticks(
            CLUSTER_THRESHOLDS,
        )

        ax.set_ylim(
        	bottom=0,
        )

    # Save figure
    fig.tight_layout()

    save_figure(
        figure=fig,
        output=(
            figures_dir
            /
            "cluster_summary"
        ),
    )

    plt.close(
        fig,
    )

###############################################################################
# Cluster size distribution
###############################################################################

def plot_cluster_size_distribution(
    cluster_size_distribution,
    figures_dir,
):
    """
    Plot the distribution of cluster sizes.
    """

    fig, ax = plt.subplots(
        figsize=(
            FIGURE_WIDTH,
            FIGURE_HEIGHT,
        ),
    )

    # Plot one line per threshold
    colors = {
        0: COLOR_BLUE,
        5: COLOR_ORANGE,
        10: COLOR_GREEN,
        15: COLOR_RED,
        20: COLOR_PURPLE,
    }

    for threshold in CLUSTER_THRESHOLDS:
        data = cluster_size_distribution.loc[
            cluster_size_distribution["Cluster threshold"]
            == threshold
        ]

        ax.plot(
            data["Cluster size"],
            data["Clusters"],
            label=f"{threshold} SNPs",
            color=colors[threshold],
            linewidth=LINE_WIDTH,
            markersize=MARKER_SIZE,
        )

    # Axes
    ax.set_xscale("log")

    ax.set_yscale("log")

    ax.set_xticks(
    	[1, 2, 5, 10, 20, 50, 100]
    )

    ax.xaxis.set_major_formatter(
    	ScalarFormatter()
    )

    max_size = cluster_size_distribution["Cluster size"].max()

    ax.set_xlim(
    	1,
    	max_size * 1.1,
    )

    ax.set_xlabel(
        "Cluster size (# sequences)",
    )

    ax.set_ylabel(
        "Number of clusters",
    )

    ax.set_title(
        "Cluster size distribution",
    )

    ax.legend(
    	title="Threshold",
        frameon=False,
        loc="center left",
        bbox_to_anchor=(0.98, 0.5),
    )

    ax.grid(
        which="major",
        alpha=GRID_ALPHA,
        linewidth=0.5,
    )

    ax.spines["top"].set_visible(False)

    ax.spines["right"].set_visible(False)

    # Save
    fig.tight_layout()

    save_figure(
        fig,
        figures_dir / "cluster_size_distribution",
    )

    plt.close(fig)

###############################################################################
# Cluster size CCDF
###############################################################################

def plot_cluster_size_ccdf(
    cluster_size_ccdf,
    figures_dir,
):
    """
    Plot the complementary cumulative distribution
    of cluster sizes.
    """

    fig, ax = plt.subplots(
        figsize=(
            FIGURE_WIDTH,
            FIGURE_HEIGHT,
        ),
    )

    # Plot one line per threshold
    colors = {
        0: COLOR_BLUE,
        5: COLOR_ORANGE,
        10: COLOR_GREEN,
        15: COLOR_RED,
        20: COLOR_PURPLE,
    }

    for threshold in CLUSTER_THRESHOLDS:
        data = cluster_size_ccdf.loc[
            cluster_size_ccdf["Cluster threshold"]
            == threshold
        ]
        ax.plot(
            data["Cluster size"],
            data["Clusters ≥ size"],
            linewidth=LINE_WIDTH,
            color=colors[threshold],
            label=f"{threshold} SNPs",
        )

    # Axes
    ax.set_xscale("log")

    ax.set_yscale("log")

    ax.set_xlabel(
        "Cluster size (# sequences)",
    )

    ax.set_ylabel(
        "Number of clusters",
    )

    ax.set_title(
        "Cluster size distribution",
    )

    ax.set_xticks(
        [1, 2, 5, 10, 20, 50, 100]
    )

    ax.xaxis.set_major_formatter(
        ScalarFormatter()
    )

    ax.legend(
        title="Threshold",
        frameon=False,
        loc="center left",
        bbox_to_anchor=(1.0, 0.5),
    )

    ax.grid(
        which="major",
        alpha=GRID_ALPHA,
        linewidth=0.5,
    )

    ax.spines["top"].set_visible(False)

    ax.spines["right"].set_visible(False)

    fig.tight_layout()

    save_figure(
        figure=fig,
        output=(
            figures_dir
            /
            "cluster_distribution"
        ),
    )

    plt.close(fig)

###############################################################################
# Generate plots
###############################################################################

def plot_results(
    distribution,
    cluster_summary,
    genetic_clusters,
    cluster_size_distribution,
    cluster_size_ccdf,
    figures_dir,
):
    """
    Generate all analysis figures.
    """

    plot_pairwise_distance_distribution(
        distribution=distribution,
        figures_dir=figures_dir,
    )

    plot_pairwise_distance_distribution(
        distribution=distribution,
        figures_dir=figures_dir,
        xmax=DISTANCE_ZOOM,
        suffix="_zoom",
    )

    plot_cluster_summary(
        cluster_summary=cluster_summary,
        figures_dir=figures_dir,
    )

    #plot_cluster_size_distribution(
    #    cluster_size_distribution=cluster_size_distribution,
    #    figures_dir=figures_dir,
    #)

    plot_cluster_size_ccdf(
    	cluster_size_ccdf=cluster_size_ccdf,
    	figures_dir=figures_dir,
    )

###############################################################################
# Print summary
###############################################################################

def print_summary(
    summary,
    cluster_summary,
    outdir,
):
    """
    Print analysis summary.
    """

    print()

    print("=" * 70)

    print(
        "Genetic cluster analysis summary"
    )

    print("=" * 70)

    print()

    # Pairwise distances
    print(
        f"{'Sequences':35}"
        f"{summary['unique_sequences']:>10,}"
    )

    print(
        f"{'Pairwise comparisons':35}"
        f"{summary['pairs']:>10,}"
    )

    print()

    print("Pairwise SNP distances")

    print(
        f"{'  Minimum':35}"
        f"{summary['minimum']:>10}"
    )

    print(
        f"{'  Median':35}"
        f"{summary['median']:>10.1f}"
    )

    print(
        f"{'  Maximum':35}"
        f"{summary['maximum']:>10}"
    )

    print(
        f"{'  Identical pairs (0 SNPs)':35}"
        f"{summary['identical_pairs']:>10,}"
    )

    print()

    # Cluster summary
    print("Genetic clusters")

    for _, row in cluster_summary.iterrows():

        print()

        print(
            f"  Threshold ≤ {int(row['Cluster threshold'])} SNPs"
        )

        print(
            f"{'    Clusters':35}"
            f"{int(row['Clusters']):>10,}"
        )

        print(
            f"{'    Clustered samples':35}"
            f"{int(row['Clustered samples']):>10,}"
        )

        print(
            f"{'    Largest cluster':35}"
            f"{int(row['Largest cluster']):>10,}"
        )

        print(
            f"{'    Mean cluster size':35}"
            f"{row['Mean cluster size']:>10.2f}"
        )

        print(
            f"{'    Median cluster size':35}"
            f"{row['Median cluster size']:>10.1f}"
        )

        print(
            f"{'    Singletons':35}"
            f"{int(row['Singletons']):>10,}"
        )

    print()

    # Output
    print(
        f"{'Output directory':35}"
        f"{outdir}"
    )

    print()

    print("=" * 70)

###############################################################################
# Main
###############################################################################

def main():

    args = parse_args()

    # Read pairwise distances
    distances = read_distance_matrix(
        distances=args.distances,
    )

    # Summarize distances
    summary, distribution = summarize_distances(
        distances,
    )

    # Identify genetic clusters
    genetic_clusters, cluster_summary = find_clusters(
        distances=distances,
        thresholds=args.thresholds,
    )

    # Cluster size distribution
    cluster_size_distribution = summarize_cluster_sizes(
    	genetic_clusters=genetic_clusters,
    )

    # Cluster size CCDF
    cluster_size_ccdf = summarize_cluster_size_ccdf(
    	cluster_size_distribution=cluster_size_distribution,
    )

    # Cluster annotations
    cluster_annotations = build_cluster_annotations(
    	genetic_clusters=genetic_clusters,
    )

    # Write output tables
    tables_dir, figures_dir = write_tables(
        distribution=distribution,
        genetic_clusters=genetic_clusters,
        cluster_annotations=cluster_annotations,
        cluster_summary=cluster_summary,
        cluster_size_distribution=cluster_size_distribution,
        cluster_size_ccdf=cluster_size_ccdf,
        outdir=args.outdir,
    )

    # Generate figures
    plot_results(
    	distribution=distribution,
    	cluster_summary=cluster_summary,
    	genetic_clusters=genetic_clusters,
    	cluster_size_distribution=cluster_size_distribution,
    	cluster_size_ccdf=cluster_size_ccdf,
    	figures_dir=figures_dir,
    )

    # Print summary
    print_summary(
        summary=summary,
        cluster_summary=cluster_summary,
        outdir=args.outdir,
    )


if __name__ == "__main__":

    main()