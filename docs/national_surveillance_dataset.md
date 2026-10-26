# National RSV surveillance dataset

This document describes the dataset used for the national RSV surveillance analysis implemented in this pipeline.

## Dataset

- **Source:** GISAID EpiRSV
- **Geographical scope:** Spain
- **Data cutoff:** 14 October 2026
- **Pathogen:** Respiratory syncytial virus (RSV)
- **Subtypes:** RSV-A and RSV-B

The genomic sequences and associated metadata obtained from GISAID are not distributed with this repository.

Users must obtain the corresponding records directly from GISAID under the applicable GISAID access, use, and acknowledgement requirements.

## Accession identifiers

The GISAID accession identifiers corresponding to the records included in this dataset are provided in:

```text
docs/national_surveillance_accessions.txt
```

The accession identifiers allow the records used for the analysis to be identified without redistributing their genomic sequences or associated metadata.

## Local input files

For local execution of the national surveillance workflow, the corresponding sequences are expected at:

```text
resources/sequences/RSV-A.fasta
resources/sequences/RSV-B.fasta
```

The associated metadata files are expected under:

```text
resources/metadata/
```

These GISAID-derived input files are maintained locally and are not distributed with the repository.

See `docs/input_files.md` for the complete input file requirements.