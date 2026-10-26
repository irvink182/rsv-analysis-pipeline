# Sequences

This directory contains the RSV genome sequences used as input by the RSV Analysis Pipeline.

## Required files

The pipeline expects separate FASTA files for RSV-A and RSV-B:

```text
RSV-A.fasta
RSV-B.fasta
```

The corresponding paths are:

```text
resources/sequences/RSV-A.fasta
resources/sequences/RSV-B.fasta
```

These files are used during dataset selection and subsequent genomic analyses.

## GISAID data

Genome sequences obtained from GISAID are not distributed with this repository.

Users must obtain the required sequences directly from GISAID and place them in this directory in accordance with the applicable GISAID access, use, and acknowledgement requirements.

The sequences should correspond to the records represented in the metadata files stored under:

```text
resources/metadata/
```

For the national surveillance dataset used in this pipeline, the corresponding GISAID accession identifiers are documented under `docs/`.

See `docs/input_files.md` for the complete input requirements and file organization.