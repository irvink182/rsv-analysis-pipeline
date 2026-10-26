# Metadata

This directory contains the metadata files required by the RSV Analysis Pipeline.

## Required files

The pipeline expects separate metadata files for RSV-A and RSV-B:

| File | Description |
|------|-------------|
| `RSV-A_patient_metadata.tsv` | RSV-A patient metadata |
| `RSV-B_patient_metadata.tsv` | RSV-B patient metadata |
| `RSV-A_sequencing_metadata.tsv` | RSV-A sequencing metadata |
| `RSV-B_sequencing_metadata.tsv` | RSV-B sequencing metadata |
| `RSV-A_date_location_metadata.tsv` | RSV-A parsed collection date and location metadata |
| `RSV-B_date_location_metadata.tsv` | RSV-B parsed collection date and location metadata |
| `laboratory_metadata.tsv` | Curated laboratory metadata used for laboratory harmonization |

During metadata integration, the RSV-A and RSV-B metadata files are combined by metadata type and subsequently integrated using `Accession ID` as the common identifier.

The resulting master table is generated under:

```text
results/01_master_table/master_table.tsv
```

## GISAID data

Metadata obtained from GISAID are not distributed with this repository.

Users must obtain the corresponding data directly from GISAID and prepare the required input files locally under this directory in accordance with the applicable GISAID access, use, and acknowledgement requirements.

The metadata records should correspond to the genomic sequences stored under:

```text
resources/sequences/
```

The GISAID dataset used for the national surveillance analysis and its corresponding accession identifiers are documented under `docs/`.

See `docs/input_files.md` for the complete input requirements and file organization.