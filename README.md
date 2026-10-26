# RSV Analysis Pipeline

The **RSV Analysis Pipeline** is a reproducible workflow for the integration, quality control, genomic analysis, and reporting of Respiratory Syncytial Virus (RSV) surveillance data.

The pipeline integrates genomic sequences and epidemiological metadata, performs epidemiological and sequence quality control, generates reference-guided alignments, identifies genomic clusters, prepares annotated datasets for phylogenetic analysis, and generates interactive surveillance reports using GenomeReport.

The workflow supports both **national genomic surveillance** and **custom analyses** of user-defined subsets of the surveillance dataset.

## Overview

The pipeline is organized into nine analysis steps:

```text
01  Metadata integration
02  Epidemiological QC
03  Dataset selection
04  Sequence QC
05  Reference-guided alignment
06  Genomic clustering
07  Dataset annotation
08  Phylogeny
09  GenomeReport
```

Steps 01 and 02 generate the common curated dataset used by downstream analyses.

From this dataset, two main analysis modes are supported:

```text
                         ┌──────────────────────┐
                         │  01 Master table     │
                         └──────────┬───────────┘
                                    │
                     ┌──────────────┴──────────────┐
                     │                             │
                     ▼                             ▼
              Raw GenomeReport              02 Epidemiological QC
                                                    │
                                      ┌─────────────┴─────────────┐
                                      │                           │
                                      ▼                           ▼
                            National surveillance          Custom analysis
                                      │                           │
                                      └────── Steps 03–07 ───────┘
                                                  │
                                     ┌────────────┴────────────┐
                                     │                         │
                                     ▼                         ▼
                              08 Phylogeny               09 GenomeReport
                                (optional)
```

Phylogenetic reconstruction is optional and is not executed automatically by the main pipelines. This allows GenomeReport to be generated without waiting for potentially time-consuming phylogenetic analyses.

## Features

- Integration and harmonization of RSV genomic and epidemiological metadata.
- Epidemiological quality control.
- Flexible dataset selection.
- RSV-A and RSV-B sequence quality control.
- Reference-guided multiple sequence alignment.
- Pairwise SNP distance calculation.
- SNP-based genomic clustering.
- Generation of metadata for downstream phylogenetic analyses.
- Phylogenetic reconstruction using FastTree or IQ-TREE.
- Phylogenetic visualization and metadata annotation.
- Interactive genomic surveillance reports using GenomeReport.
- National surveillance and user-defined custom analyses.
- Raw master-table reporting for metadata inspection and quality control.

## Installation

Clone the repository:

```bash
git clone https://github.com/irvink182/rsv-analysis-pipeline.git
cd rsv-analysis-pipeline
```

Create the Conda environment:

```bash
conda env create -f environment.yml
```

Activate the environment:

```bash
conda activate rsv-analysis-pipeline
```

The environment includes the main bioinformatics and visualization dependencies required by the workflow, including:

- Nextclade
- SNP-sites
- SNP-dists
- FastTree
- IQ-TREE
- R / ggtree / ggtreeExtra
- GenomeTableTools
- GenomeReport
- phyloannot

For detailed installation instructions, including Nextclade dataset setup, see `docs/installation.md`.

## Input data

The pipeline requires RSV genomic sequences and associated metadata obtained from GISAID.

GISAID-derived sequence and metadata files are **not distributed with this repository**. Users must obtain the required records directly from GISAID and place them under the corresponding `resources/` directories before running the pipeline.

The dataset used for the national surveillance analysis and its corresponding GISAID accession identifiers are documented under `docs/`.

See `docs/input_files.md` for the complete input requirements and expected directory structure.

### Laboratory metadata

The `laboratory_metadata.tsv` file is generated from the sequencing metadata using a curated laboratory registry maintained under:

```text
resources/registry/
```

The registry is cumulative and is updated when new datasets are incorporated. Most laboratory assignments are generated automatically, while a small number of unresolved records may require manual curation.

The complete procedure for updating the laboratory registry and generating `resources/metadata/laboratory_metadata.tsv` is described in [`resources/registry/README.md`].

## Pipeline execution

Three main launcher scripts are provided.

### 1. National surveillance

The complete national surveillance workflow is executed with:

```bash
bash run_pipeline.sh
```

Results are written to:

```text
results/national_surveillance/
```

The national pipeline performs:

```text
01 Metadata integration
        ↓
02 Epidemiological QC
        ↓
03 Dataset selection
        ↓
04 Sequence QC
        ↓
05 Reference-guided alignment
        ↓
06 Genomic clustering
        ↓
07 Dataset annotation
        ↓
09 GenomeReport
```

Step 08 (phylogenetic analysis) is optional and is not executed automatically.

### 2. Custom analysis

Custom analyses can be generated from the epidemiologically curated dataset using:

```bash
bash run_pipeline_custom.sh ANALYSIS_NAME \
    --where "COLUMN=VALUE"
```

For example, to analyse sequences from Comunitat Valenciana:

```bash
bash run_pipeline_custom.sh valencia \
    --where "autonomous_community=Comunitat Valenciana"
```
For example, to analyse sequences between 2022 and 2024:

```bash
bash run_pipeline_custom.sh 2022_2024 \
    --where "Collection date between 2022-01-01,2024-12-12"
```

Results are written to:

```text
results/custom/ANALYSIS_NAME/
```

For the examples above:

```text
results/custom/valencia/
```
```text
results/custom/2022_2024/
```

Multiple selection conditions can be supplied when required.

The custom workflow starts at Step 03 and therefore requires:

```text
results/02_epidemiological_qc/qc_epi_table.tsv
```

to exist.

This file can be generated by running the national pipeline or by executing Steps 01 and 02 independently.

Genomic clustering is recalculated for each custom dataset rather than inherited from the national analysis.

### 3. Raw master-table report

A GenomeReport can also be generated directly from the complete master table produced during metadata integration:

```bash
bash run_pipeline_master_table_raw.sh
```

Input:

```text
results/01_master_table/master_table.tsv
```

Output:

```text
results/99_raw_report/
```

This report is generated before epidemiological filtering and downstream genomic analyses and is intended for inspection and quality control of the complete integrated metadata table.

## Workflow

### Step 01 — Metadata integration

Integrates the input metadata sources and generates the common master table used by the pipeline.

Main output:

```text
results/01_master_table/master_table.tsv
```

### Step 02 — Epidemiological QC

Performs epidemiological quality control on the integrated metadata.

Main output:

```text
results/02_epidemiological_qc/qc_epi_table.tsv
```

Steps 01 and 02 are shared between national and custom analyses.

### Step 03 — Dataset selection

Selects the sequences included in a specific analysis.

For the national surveillance workflow, the predefined national surveillance dataset is selected.

For custom analyses, user-defined filters can be supplied using `--where`.

### Step 04 — Sequence QC

Performs sequence-level quality control and separates the dataset into RSV-A and RSV-B analyses.

### Step 05 — Reference-guided alignment

Generates reference-guided multiple sequence alignments for RSV-A and RSV-B and prepares the alignments required for SNP-based analyses.

### Step 06 — Genomic clustering

Calculates pairwise genomic distances and identifies genomic clusters using SNP-distance thresholds.

Clustering is performed independently for each analysis dataset.

### Step 07 — Dataset annotation

Combines genomic clustering results with epidemiological metadata and generates annotation files for downstream phylogenetic visualization and reporting.

Annotation configurations are generated automatically from the metadata using `phyloannot`.

### Step 08 — Phylogeny

Phylogenetic reconstruction is optional and is not executed automatically by the main pipeline launchers.

Two phylogenetic reconstruction methods are supported:

```text
fasttree
iqtree
```

Phylogenetic reconstruction is optional.

FastTree can be used for rapid phylogenetic reconstruction:

```bash
bash workflow/08_phylogeny/run.sh \
    ANALYSIS_DIR \
    MODE \
    fasttree
```

IQ-TREE can be used for a more computationally intensive analysis:

```bash
bash workflow/08_phylogeny/run.sh \
    ANALYSIS_DIR \
    MODE \
    iqtree
```

`MODE` defines the analysis context and must be either:

```text
national
custom
```

Two phylogenetic visualization profiles are available:

```text
standard
detailed
```

The default profiles are:

```text
national --> standard
custom --> detailed
```

For example, national surveillance using IQ-TREE:

```bash
bash workflow/08_phylogeny/run.sh \
    results/national_surveillance \
    national \
    iqtree
```

A custom analysis using the default detailed profile.
In this case, a dataset based on Comunitat Valenciana:

```bash
bash workflow/08_phylogeny/run.sh \
    results/custom/valencia \
    custom \
    fasttree
```

A broader custom analysis using the standard profile.
In this case, a dataset based on sequences from 2022-2024

```bash
bash workflow/08_phylogeny/run.sh \
    results/custom/2022_2024 \
    custom \
    iqtree \
    standard
```


Phylogenetic figures are generated for RSV-A and RSV-B.
See `workflow/08_phylogeny/run.sh`

### Step 09 — GenomeReport

GenomeReport generates the final interactive report for each national or custom analysis.

It is automatically executed by:

```text
run_pipeline.sh
run_pipeline_custom.sh
```

without phylogenetic figures.

After Step 08 has been completed, GenomeReport can be regenerated with the phylogenetic figures.

For example, using FastTree:

```bash
bash workflow/09_genome_report/run.sh \
    results/custom/valencia \
    results/custom/valencia/08_phylogeny/RSV-A/figures/RSV-A_fasttree_circular.png \
    results/custom/valencia/08_phylogeny/RSV-B/figures/RSV-B_fasttree_circular.png
```

The same procedure can be used with IQ-TREE-generated figures.

## Output structure

The main output structure is:

```text
results/
├── 01_master_table/
│   └── master_table.tsv
│
├── 02_epidemiological_qc/
│   └── qc_epi_table.tsv
│
├── national_surveillance/
│   ├── 03_dataset_selection/
│   ├── 04_sequence_qc/
│   ├── 05_reference_alignment/
│   ├── 06_clustering/
│   ├── 07_dataset_annotation/
│   ├── 08_phylogeny/
│   └── 09_genome_report/
│
├── custom/
│   └── <analysis_name>/
│       ├── 03_dataset_selection/
│       ├── 04_sequence_qc/
│       ├── 05_reference_alignment/
│       ├── 06_clustering/
│       ├── 07_dataset_annotation/
│       ├── 08_phylogeny/
│       └── 09_genome_report/
│
└── 99_raw_report/
```

The `08_phylogeny` directory is generated only when the optional phylogenetic analysis is executed.

## Main software

The pipeline integrates several external bioinformatics tools and dedicated metadata/reporting packages.

### GenomeTableTools

GenomeTableTools is used for tabular metadata processing, integration, annotation, and manipulation throughout the workflow.

### GenomeReport

GenomeReport generates interactive HTML reports summarizing epidemiological and genomic characteristics of the analysed dataset.

### phyloannot

phyloannot prepares metadata annotation files for phylogenetic visualization and downstream platforms.

### Nextclade

Nextclade is used for RSV sequence classification and lineage assignment.

### FastTree and IQ-TREE

FastTree and IQ-TREE provide alternative approaches for phylogenetic reconstruction.

FastTree is intended as a faster exploratory option, whereas IQ-TREE provides a more computationally intensive phylogenetic analysis.

## Reproducibility

The software environment is defined in:

```text
environment.yml
```

Analyses are organized into independent workflow steps under:

```text
workflow/
```

Each analysis mode writes its outputs to a dedicated directory, allowing national surveillance and multiple custom analyses to coexist without overwriting one another.