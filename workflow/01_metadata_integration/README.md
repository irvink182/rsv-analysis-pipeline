# 01. Metadata integration

## Objective

Integrate the RSV-A and RSV-B GISAID metadata tables and the curated laboratory metadata into a single master table.

The resulting `master_table.tsv` is the common metadata source used by all downstream analyses in the RSV Analysis Pipeline.

## Input

The input metadata files are expected under:

```text
resources/metadata/
```

### GISAID metadata

For each RSV subtype, three metadata tables are used:

```text
RSV-A_patient_metadata.tsv
RSV-B_patient_metadata.tsv

RSV-A_sequencing_metadata.tsv
RSV-B_sequencing_metadata.tsv

RSV-A_date_location_metadata.tsv
RSV-B_date_location_metadata.tsv
```

These tables contain complementary metadata associated with the GISAID sequence records.

### Curated laboratory metadata

```text
laboratory_metadata.tsv
```

This table contains manually curated information about the originating and submitting laboratories.

The file is maintained as a curated resource and is not generated automatically by the workflow.

## Processing

The step is divided into two stages.

First, the corresponding RSV-A and RSV-B GISAID metadata tables are concatenated:

```text
RSV-A patient metadata ──────┐
                             ├── patient_metadata.tsv
RSV-B patient metadata ──────┘


RSV-A sequencing metadata ───┐
                             ├── sequencing_metadata.tsv
RSV-B sequencing metadata ───┘


RSV-A date/location metadata ─┐
                              ├── date_location_metadata.tsv
RSV-B date/location metadata ─┘
```

The three resulting tables are then integrated with the curated laboratory metadata:

```text
sequencing_metadata.tsv ────┐
patient_metadata.tsv ───────┤
date_location_metadata.tsv ─┼── master_table.tsv
laboratory_metadata.tsv ────┘
```

Metadata integration is performed using `Accession ID` as the common key.

The `comments` column is preserved when duplicate columns are encountered during integration.

## Output

All outputs are generated under:

```text
results/01_master_table/
```

| File | Description |
|---|---|
| `patient_metadata.tsv` | Combined RSV-A and RSV-B patient metadata |
| `sequencing_metadata.tsv` | Combined RSV-A and RSV-B sequencing metadata |
| `date_location_metadata.tsv` | Combined RSV-A and RSV-B date and location metadata |
| `master_table.tsv` | Integrated master metadata table used by downstream analyses |

The main output of this step is:

```text
results/01_master_table/master_table.tsv
```

## Software

This step uses:

- GenomeTableTools

`genometabletools concat` is used to combine the RSV-A and RSV-B source tables, while `genometabletools integrate` is used to construct the final master table.

## Run

Execute Step 01 with:

```bash
bash workflow/01_metadata_integration/run.sh
```

After successful completion, the next step is:

```bash
bash workflow/02_epidemiological_qc/run.sh
```

## Downstream use

The `master_table.tsv` has two direct uses in the pipeline.

It serves as the input for Step 02:

```text
master_table.tsv
       │
       ▼
02 Epidemiological QC
```

It can also be inspected directly using the raw master-table report:

```bash
bash run_pipeline_master_table_raw.sh
```

which generates a GenomeReport under:

```text
results/99_raw_report/
```

This raw report provides an overview of the complete integrated metadata before epidemiological filtering or downstream genomic analysis.

## Notes

`laboratory_metadata.tsv` is a manually curated resource and should be reviewed and updated when new laboratories or metadata patterns are introduced.

The master table represents the complete integrated metadata dataset before epidemiological quality control and dataset selection.