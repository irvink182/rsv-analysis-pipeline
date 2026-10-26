# 04. Sequence quality control

## Objective

Perform sequence-level quality control using Nextclade and generate high-quality RSV-A and RSV-B genome datasets for downstream genomic analyses.

Nextclade is used to evaluate genome quality and gene coverage. Sequences failing one or more predefined QC criteria are identified and excluded from the final analysis FASTA files.

This step operates independently on the RSV-A and RSV-B datasets generated during Step 03.

## Input

Step 04 requires an analysis directory:

```bash
bash workflow/04_sequence_qc/run.sh ANALYSIS_DIR
```

Input files are read from:

```text
ANALYSIS_DIR/
└── 03_dataset_selection/
    ├── RSV-A/
    │   ├── analysis_table.tsv
    │   └── analysis.fasta
    │
    └── RSV-B/
        ├── analysis_table.tsv
        └── analysis.fasta
```

The sequence QC is performed on:

```text
RSV-A/analysis.fasta
RSV-B/analysis.fasta
```

The corresponding `analysis_table.tsv` files remain the metadata source for the selected analysis datasets.

## Nextclade datasets

Local Nextclade datasets are stored under:

```text
resources/nextclade/
```

Subtype-specific datasets are used:

```text
resources/nextclade/
├── rsv_a/
└── rsv_b/
```

RSV-A sequences are analysed using `rsv_a`, while RSV-B sequences are analysed using `rsv_b`.

## Processing

For each RSV subtype, the workflow consists of three stages.

### 1. Nextclade analysis

Nextclade is run on the selected FASTA file:

```text
analysis.fasta
      │
      ▼
   Nextclade
      │
      ▼
nextclade/
└── nextclade.tsv
```

Nextclade generates sequence-level QC metrics and other genomic information.

### 2. QC evaluation

The Nextclade table is evaluated using:

```text
scripts/sequence_qc/nextclade_qc.py
```

The script applies the predefined sequence QC criteria and identifies sequences failing one or more filters.

```text
nextclade.tsv
      │
      ▼
nextclade_qc.py
      │
      ▼
summary/
├── problematic_sequences.tsv
├── cds_coverage.tsv
└── cds_coverage_summary.tsv
```

### 3. Sequence exclusion

Sequences listed in `problematic_sequences.tsv` are removed from the original analysis FASTA using:

```text
scripts/sequence_qc/select_fasta.py
```

```text
analysis.fasta
       +
problematic_sequences.tsv
       │
       ▼
 select_fasta.py
    --exclude
       │
       ▼
analysis.qc.fasta
```

The resulting `analysis.qc.fasta` contains only sequences that pass all sequence QC criteria.

## Applied quality filters

The following QC criteria are applied independently to RSV-A and RSV-B:

| QC criterion | Threshold |
|---|---:|
| Nextclade overall QC | Exclude `bad` |
| Genome coverage | ≥ 90% |
| F gene coverage | ≥ 90% |
| G gene coverage | ≥ 90% |
| Stop codons | 0 |
| Missing bases | ≤ 500 |

A sequence failing one or more criteria is included in:

```text
summary/problematic_sequences.tsv
```

together with the corresponding reason or reasons for exclusion.

The QC thresholds are defined in:

```text
workflow/04_sequence_qc/run.sh
```


## Workflow

```text
03_dataset_selection/
       │
       ├──────────── RSV-A ────────────┐
       │                               │
       │                         analysis.fasta
       │                               │
       │                               ▼
       │                           Nextclade
       │                               │
       │                               ▼
       │                         nextclade.tsv
       │                               │
       │                               ▼
       │                        nextclade_qc.py
       │                               │
       │                               ▼
       │                  problematic_sequences.tsv
       │                               │
       │                               ▼
       │                         select_fasta.py
       │                           --exclude
       │                               │
       │                               ▼
       │                       analysis.qc.fasta
       │
       └──────────── RSV-B ─────────── same workflow
```

## Output

Outputs are written under:

```text
ANALYSIS_DIR/04_sequence_qc/
```

with separate directories for RSV-A and RSV-B:

```text
ANALYSIS_DIR/
└── 04_sequence_qc/
    ├── RSV-A/
    │   ├── analysis.qc.fasta
    │   ├── nextclade/
    │   │   └── ...
    │   └── summary/
    │       ├── problematic_sequences.tsv
    │       ├── cds_coverage.tsv
    │       └── cds_coverage_summary.tsv
    │
    └── RSV-B/
        ├── analysis.qc.fasta
        ├── nextclade/
        │   └── ...
        └── summary/
            ├── problematic_sequences.tsv
            ├── cds_coverage.tsv
            └── cds_coverage_summary.tsv
```

The main outputs used by downstream genomic analyses are:

```text
ANALYSIS_DIR/04_sequence_qc/RSV-A/analysis.qc.fasta
ANALYSIS_DIR/04_sequence_qc/RSV-B/analysis.qc.fasta
```

## Software

This step uses:

- Nextclade
- `scripts/sequence_qc/nextclade_qc.py`
- `scripts/sequence_qc/select_fasta.py`

Nextclade calculates sequence QC and genomic metrics.

`nextclade_qc.py` evaluates the Nextclade output against the pipeline QC thresholds.

`select_fasta.py` removes sequences failing QC from the analysis FASTA.

## Run

For national surveillance:

```bash
bash workflow/04_sequence_qc/run.sh \
    results/national_surveillance
```

For a custom analysis:

```bash
bash workflow/04_sequence_qc/run.sh \
    results/custom/valencia
```

After successful completion, continue with Step 05:

```bash
bash workflow/05_reference_alignment/run.sh ANALYSIS_DIR
```

For example:

```bash
bash workflow/05_reference_alignment/run.sh \
    results/custom/valencia
```

## Notes

This step performs **sequence quality control only**.

Reference genomes are not added during sequence QC. They are introduced during Step 05 — Reference-guided alignment.

The QC thresholds are applied identically to national surveillance and custom datasets.

Because Step 04 operates within `ANALYSIS_DIR`, each custom analysis retains its own Nextclade results, QC summaries, excluded sequences, and final quality-controlled FASTA files.