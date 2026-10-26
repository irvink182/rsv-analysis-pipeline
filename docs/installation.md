# Installation

This document describes how to install the software required to run the RSV Analysis Pipeline.

## Requirements

- Linux
- Conda (Miniconda or Anaconda)
- Git

## 1. Clone the repository

Clone the repository and enter the project directory:

```bash
git clone https://github.com/irvink182/rsv-analysis-pipeline.git

cd rsv-analysis-pipeline
```

## 2. Create the Conda environment

Create the environment from the provided `environment.yml` file:

```bash
conda env create -f environment.yml
```

Activate the environment:

```bash
conda activate rsv-analysis-pipeline
```

The environment installs the command-line tools required by the pipeline, including:

- Nextclade
- IQ-TREE
- FastTree
- SNP-sites
- SNP-dists
- SeqKit

It also installs the Python packages used by the pipeline, including:

- GenomeTableTools
- GenomeReport
- phyloannot

The exact software versions and package dependencies used by the pipeline are defined in `environment.yml`.

## 3. Download Nextclade datasets

The RSV-A and RSV-B Nextclade datasets required for sequence QC, reference-guided alignment, and lineage assignment can be downloaded using:

```bash
bash scripts/setup/setup_nextclade.sh
```

The datasets are stored in:

```text
resources/nextclade/
```

## 4. Verify the installation

Verify that the main command-line tools are available:

```bash
nextclade --help

iqtree2 -h

FastTree

snp-sites -h

snp-dists -h

seqkit --help

genometabletools --help

genomereport --version

phyloannot --help
```

If these commands execute successfully, the environment is ready to run the pipeline.