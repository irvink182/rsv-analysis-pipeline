#!/usr/bin/env python3

from argparse import ArgumentParser
from pathlib import Path

import pandas as pd


###############################################################################
# Constants
###############################################################################

COLLECTION_DATE = "Collection date"

TEMPORAL_COLUMNS = [
    "gisaid_collection_year",
    "gisaid_collection_month",
    "gisaid_epiweek",
    "epidemiological_season",
    "season_epiweek",
    "season_epiweek_custom",
    "season_week",
]


###############################################################################
# Arguments
###############################################################################

def parse_args():

    parser = ArgumentParser(
        description=(
            "Add epidemiological temporal variables "
            "derived from collection dates."
        )
    )

    parser.add_argument(
        "--input",
        required=True,
        help="Input metadata table (TSV).",
    )

    parser.add_argument(
        "--output",
        required=True,
        help="Output metadata table (TSV).",
    )

    parser.add_argument(
        "--date-column",
        default=COLLECTION_DATE,
        help=(
            "Column containing collection dates "
            f"(default: '{COLLECTION_DATE}')."
        ),
    )

    return parser.parse_args()


###############################################################################
# Epidemiological temporal metadata
###############################################################################

def add_epidemiological_time(
    metadata,
    date_column=COLLECTION_DATE,
):
    """
    Add epidemiological temporal variables derived
    from collection dates.

    Epidemiological season follows the SiVIRA convention:

        ISO week 40 of year Y
            to
        ISO week 39 of year Y+1

    Added variables:

        gisaid_collection_year
        gisaid_collection_month
        gisaid_epiweek
        epidemiological_season
        season_epiweek
        season_epiweek_custom
        season_week

    Examples:

        2024-W40 -> 2024-25 -> W40_S24-25 -> W40_S25 -> season week 1
        2025-W03 -> 2024-25 -> W03_S24-25 -> W03_S25 -> season week 16

    ISO years containing week 53 are handled explicitly.
    """

    metadata = metadata.copy()

    if date_column not in metadata.columns:
        raise ValueError(
            f"Date column '{date_column}' "
            "was not found in metadata."
        )

    # -------------------------------------------------------------------------
    # Collection date
    # -------------------------------------------------------------------------

    collection_date_raw = (
        metadata[date_column]
        .astype("string")
        .str.strip()
    )

    collection_date = pd.to_datetime(
        collection_date_raw,
        format="mixed",
        errors="coerce",
    )

    # -------------------------------------------------------------------------
    # Calendar year
    # -------------------------------------------------------------------------

    metadata[
        "gisaid_collection_year"
    ] = pd.to_numeric(
        collection_date_raw.str.extract(
            r"^(\d{4})",
            expand=False,
        ),
        errors="coerce",
        ).astype("Int64")

    # -------------------------------------------------------------------------
    # Calendar month
    # -------------------------------------------------------------------------

    metadata[
        "gisaid_collection_month"
    ] = pd.to_numeric(
        collection_date_raw.str.extract(
            r"^\d{4}-(\d{2})",
            expand=False,
        ),
        errors="coerce",
    ).astype("Int64")

    # -------------------------------------------------------------------------
    # Complete collection dates
    #
    # Epidemiological week and season require day-level precision.
    # Partial dates (YYYY or YYYY-MM) are therefore excluded from
    # epidemiological calendar calculations.
    # -------------------------------------------------------------------------

    complete_date = collection_date_raw.str.match(
        r"^\d{4}-\d{2}-\d{2}$",
        na=False,
    )

    collection_date_complete = collection_date.where(
        complete_date
    )

    # -------------------------------------------------------------------------
    # ISO epidemiological calendar
    # -------------------------------------------------------------------------

    iso_calendar = (
        collection_date_complete
        .dt
        .isocalendar()
    )

    iso_year = (
        iso_calendar["year"]
        .astype("Int64")
    )

    epiweek = (
        iso_calendar["week"]
        .astype("Int64")
    )

    metadata[
        "gisaid_epiweek"
    ] = epiweek

    # -------------------------------------------------------------------------
    # Epidemiological season
    #
    # W40-W39
    # -------------------------------------------------------------------------

    season_start_year = (
        iso_year.where(
            epiweek >= 40,
            iso_year - 1,
        )
        .astype("Int64")
    )

    season_end_year = (
        season_start_year + 1
    ).astype("Int64")

    metadata[
        "epidemiological_season"
    ] = (
        season_start_year
        .astype("string")
        +
        "-"
        +
        (
            season_end_year % 100
        )
        .astype("string")
        .str.zfill(2)
    )

    # -------------------------------------------------------------------------
    # Week within epidemiological season
    # -------------------------------------------------------------------------

    weeks_in_start_year = pd.to_datetime(
        season_start_year
        .astype("string")
        + "-12-28",
        errors="coerce",
    ).dt.isocalendar()["week"]

    season_week = (
        epiweek - 39
    )

    next_calendar_year = (
        iso_year > season_start_year
    )

    season_week = season_week.where(
        ~next_calendar_year,
        (weeks_in_start_year - 39) + epiweek,
    )

    metadata[
        "season_week"
    ] = season_week.astype("Int64")

    # -------------------------------------------------------------------------
    # Full season / epiweek label
    #
    # Example:
    # W03_S24-25
    # -------------------------------------------------------------------------

    metadata[
        "season_epiweek"
    ] = (
        "W"
        +
        epiweek
        .astype("string")
        .str.zfill(2)
        +
        "_S"
        +
        (
            season_start_year % 100
        )
        .astype("string")
        .str.zfill(2)
        +
        "-"
        +
        (
            season_end_year % 100
        )
        .astype("string")
        .str.zfill(2)
    )

    # -------------------------------------------------------------------------
    # Compact season / epiweek label
    #
    # Epidemiological year corresponds to the year in which
    # the season ends.
    #
    # Example:
    # W03_S25
    # -------------------------------------------------------------------------

    metadata[
        "season_epiweek_custom"
    ] = (
        "W"
        +
        epiweek
        .astype("string")
        .str.zfill(2)
        +
        "_S"
        +
        (
            season_end_year % 100
        )
        .astype("string")
        .str.zfill(2)
    )

    return metadata


###############################################################################
# Main
###############################################################################

def main():

    args = parse_args()

    input_file = Path(args.input)
    output_file = Path(args.output)

    metadata = pd.read_csv(
        input_file,
        sep="\t",
        dtype=str,
    )

    metadata = add_epidemiological_time(
        metadata=metadata,
        date_column=args.date_column,
    )

    output_file.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    metadata.to_csv(
        output_file,
        sep="\t",
        index=False,
    )

    print()
    print("=" * 70)
    print("Epidemiological temporal metadata")
    print("=" * 70)
    print()
    print(f"Input records:       {len(metadata):,}")
    print(f"Date column:         {args.date_column}")
    print(
        f"Valid dates:         "
        f"{metadata['gisaid_epiweek'].notna().sum():,}"
    )
    print(
        f"Missing/invalid:     "
        f"{metadata['gisaid_epiweek'].isna().sum():,}"
    )
    print()
    print("Added variables:")
    for column in TEMPORAL_COLUMNS:
        print(f"    {column}")
    print()
    print(f"Output: {output_file}")
    print()


if __name__ == "__main__":
    main()