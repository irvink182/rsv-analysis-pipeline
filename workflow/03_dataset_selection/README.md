# 03. Dataset selection

## Objective

Generate analysis-specific RSV-A and RSV-B datasets from the epidemiologically curated metadata table and extract the corresponding genome sequences from the original FASTA files.

This step defines the genomic dataset that will be analysed in all subsequent steps.

Two selection modes are supported:

- **National surveillance** — includes all records passing epidemiological QC.
- **Custom analysis** — applies one or more user-defined filters to the epidemiologically curated dataset.

RSV-A and RSV-B are subsequently processed as independent datasets.

## Input

### Epidemiologically curated metadata

```text
results/02_epidemiological_qc/qc_epi_table.tsv
```

This table is generated during Step 02 and represents the common epidemiologically curated source dataset for all analyses.

### Genome sequences

```text
resources/sequences/
├── RSV-A.fasta
└── RSV-B.fasta
```

These FASTA files contain the original RSV-A and RSV-B genome sequences.

Sequences are matched to the selected metadata records using `Accession ID`.

## Analysis directory

Step 03 requires an analysis directory as its first argument:

```bash
bash workflow/03_dataset_selection/run.sh ANALYSIS_DIR
```

For national surveillance:

```text
results/national_surveillance
```

For custom analyses:

```text
results/custom/<analysis_name>
```

All Step 03 outputs are written under:

```text
ANALYSIS_DIR/03_dataset_selection/
```

## Dataset selection

### National surveillance

When no additional filters are provided, all records passing Step 02 are included.

```bash
bash workflow/03_dataset_selection/run.sh \
    results/national_surveillance
```

The dataset is then separated according to RSV subtype:

```text
qc_epi_table.tsv
       │
       ├── Subtype=A ──► RSV-A
       │
       └── Subtype=B ──► RSV-B
```

### Custom analysis

Custom datasets can be generated using one or more `--where` expressions.

For example, to select sequences from Comunitat Valenciana:

```bash
bash workflow/03_dataset_selection/run.sh \
    results/custom/valencia \
    --where "autonomous_community=Comunitat Valenciana"
```

Multiple filters can be combined.

For example:

```bash
bash workflow/03_dataset_selection/run.sh \
    results/custom/valencia_2025 \
    --where "autonomous_community=Comunitat Valenciana" \
    --where "Collection date between 2025-01-01,2026-01-01"
```

All supplied filters are applied in addition to the RSV subtype selection.

Custom analyses can also be launched through:

```bash
bash run_pipeline_custom.sh ANALYSIS_NAME \
    --where "EXPRESSION"
```

For example:

```bash
bash run_pipeline_custom.sh valencia \
    --where "autonomous_community=Comunitat Valenciana"
```

## Processing

For each RSV subtype, Step 03 performs two operations.

First, the epidemiologically curated metadata table is filtered using GenomeTableTools:

```text
                         qc_epi_table.tsv
                                │
                   ┌────────────┴────────────┐
                   │                         │
              Subtype=A                 Subtype=B
                   │                         │
          + custom filters           + custom filters
                   │                         │
                   ▼                         ▼
        RSV-A/analysis_table.tsv   RSV-B/analysis_table.tsv
```

The corresponding sequences are then extracted from the original FASTA files:

```text
analysis_table.tsv
       │
       │ Accession ID
       ▼
 select_fasta.py
       │
       ▼
 analysis.fasta
```

This ensures that the metadata table and FASTA file for each subtype contain the same selected analysis dataset.

## Selection record

The selection criteria used for each analysis are recorded in:

```text
ANALYSIS_DIR/03_dataset_selection/selection.txt
```

For national surveillance, the file records:

```text
Dataset selection: national surveillance
Additional filters: none
```

For custom analyses, it records the complete set of user-defined filters.

For example:

```text
Dataset selection: custom

Filters:
- autonomous_community=Comunitat Valenciana
- Collection date between 2025-01-01,2026-01-01
```

This provides a simple record of the criteria used to construct each analysis dataset.

## Output

The output structure is:

```text
ANALYSIS_DIR/
└── 03_dataset_selection/
    ├── selection.txt
    │
    ├── RSV-A/
    │   ├── analysis_table.tsv
    │   └── analysis.fasta
    │
    └── RSV-B/
        ├── analysis_table.tsv
        └── analysis.fasta
```

### `analysis_table.tsv`

Contains the metadata records selected for the corresponding RSV subtype and analysis.

### `analysis.fasta`

Contains the genome sequences corresponding to the records in `analysis_table.tsv`.

### `selection.txt`

Records whether the dataset corresponds to national surveillance or a custom analysis and stores any custom filters used.

## Software

This step uses:

- GenomeTableTools
- `scripts/sequence_qc/select_fasta.py`

`genometabletools filter` performs metadata selection.

`select_fasta.py` extracts the corresponding sequences from the original RSV-A and RSV-B FASTA files using `Accession ID`.

## Run

### National surveillance

```bash
bash workflow/03_dataset_selection/run.sh \
    results/national_surveillance
```

### Custom analysis

```bash
bash workflow/03_dataset_selection/run.sh \
    results/custom/valencia \
    --where "autonomous_community=Comunitat Valenciana"
```

After successful completion, continue with Step 04:

```bash
bash workflow/04_sequence_qc/run.sh ANALYSIS_DIR
```

For example:

```bash
bash workflow/04_sequence_qc/run.sh \
    results/custom/valencia
```

## Notes

National and custom analyses always start from the same epidemiologically curated source table:

```text
results/02_epidemiological_qc/qc_epi_table.tsv
```

Custom filters therefore define the analysis dataset **after epidemiological QC**.

RSV-A and RSV-B are always separated during this step and remain independent throughout the downstream subtype-specific genomic analyses.

Because dataset selection occurs before genomic clustering, clustering is recalculated independently for every national or custom analysis rather than being inherited from another dataset.