# Input files

The RSV Analysis Pipeline requires RSV genomic sequences and associated metadata obtained from GISAID.

GISAID-derived sequence and metadata files are **not distributed with this repository**. Users must obtain the required data directly from GISAID under the applicable GISAID access and acknowledgement requirements.

The pipeline expects these input files to be placed under the `resources/` directory before execution.

## Genome sequences

RSV genome sequences are stored in:

```text
resources/sequences/
```

The pipeline expects separate FASTA files for RSV-A and RSV-B:

```text
resources/sequences/RSV-A.fasta
resources/sequences/RSV-B.fasta
```

For the national surveillance workflow, these files contain the RSV sequences selected for analysis from GISAID.

## Metadata

Metadata files are stored in:

```text
resources/metadata/
```

The pipeline expects:

| File | Description |
|------|-------------|
| `RSV-A_patient_metadata.tsv` | RSV-A patient metadata used for metadata integration |
| `RSV-B_patient_metadata.tsv` | RSV-B patient metadata used for metadata integration |
| `RSV-A_sequencing_metadata.tsv` | RSV-A sequencing metadata used for metadata integration |
| `RSV-B_sequencing_metadata.tsv` | RSV-B sequencing metadata used for metadata integration |
| `RSV-A_date_location_metadata.tsv` | RSV-A parsed collection date and location metadata |
| `RSV-B_date_location_metadata.tsv` | RSV-B parsed collection date and location metadata |
| `laboratory_metadata.tsv` | Curated laboratory metadata used for laboratory harmonization |

The sequence and metadata records must correspond to the same GISAID dataset.

## GISAID data

Sequence and associated metadata obtained from GISAID are not included in this repository.

Users are responsible for obtaining the required records directly from GISAID and for complying with the applicable GISAID terms of use and acknowledgement requirements.

For reproducible analyses, the GISAID accession identifiers corresponding to the analyzed records should be retained.

The GISAID dataset used for the national surveillance analysis implemented in this repository is documented in:

- `docs/national_surveillance_dataset.md`
- `docs/national_surveillance_accessions.txt`

Where applicable, a GISAID EPI_SET identifier and associated DOI can also be used to identify a dataset.

## Reference genomes

Reference genomes used by the pipeline are stored in:

```text
resources/references/
```

Separate reference sequences are used for RSV-A and RSV-B during reference-guided alignment and downstream phylogenetic analysis.

## Nextclade datasets

Nextclade datasets are stored in:

```text
resources/nextclade/
```

They can be installed using:

```bash
bash scripts/setup/setup_nextclade.sh
```

See `docs/installation.md` for installation instructions.

## Input organization

After obtaining and preparing the required input data, the expected organization is:

```text
resources/
├── metadata/
│   ├── README.md
│   ├── RSV-A_patient_metadata.tsv
│   ├── RSV-B_patient_metadata.tsv
│   ├── RSV-A_sequencing_metadata.tsv
│   ├── RSV-B_sequencing_metadata.tsv
│   ├── RSV-A_date_location_metadata.tsv
│   ├── RSV-B_date_location_metadata.tsv
│   └── laboratory_metadata.tsv
├── sequences/
│   ├── README.md
│   ├── RSV-A.fasta
│   └── RSV-B.fasta
├── references/
└── nextclade/
```

The processing of these files and the outputs generated at each stage are documented in the corresponding README files under `workflow/`.