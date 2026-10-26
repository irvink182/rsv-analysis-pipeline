# 06. Genomic clustering

## Objective

Identify genomic clusters from pairwise SNP distances calculated from the SNP-only alignments of RSV-A and RSV-B.

This step calculates pairwise SNP distance matrices and identifies genomic clusters independently for each RSV subtype using three SNP-distance thresholds:

- **5 SNPs**
- **10 SNPs**
- **20 SNPs**

Clustering is based exclusively on genomic distances. Epidemiological metadata are not incorporated during this step.

## Genomic cluster analysis

The pairwise SNP distance matrix is analysed using:

```text
scripts/clustering/cluster_analysis.py
```

Genomic clusters are independently defined at three pairwise SNP-distance thresholds:

| Threshold | Cluster annotation |
|---:|---|
| 5 SNPs | `Cluster_5` |
| 10 SNPs | `Cluster_10` |
| 20 SNPs | `Cluster_20` |

For each threshold, sequences connected by pairwise SNP distances within the corresponding cutoff are grouped into genomic clusters.

The analysis generates cluster assignments, summaries, statistics, and graphical representations of the genomic distance and cluster distributions.

The **5-SNP clustering level (`Cluster_5`)** is subsequently used for cluster annotation in the phylogenetic visualization.

## Input

Step 06 requires an analysis directory:

```bash
bash workflow/06_clustering/run.sh ANALYSIS_DIR
```

The input SNP alignments are generated during Step 05:

```text
ANALYSIS_DIR/
└── 05_reference_alignment/
    ├── RSV-A/
    │   └── alignment.snps.fasta
    │
    └── RSV-B/
        └── alignment.snps.fasta
```

RSV-A and RSV-B are analysed independently.

## Processing

For each RSV subtype, Step 06 consists of two stages.

### 1. Pairwise SNP distances

`snp-dists` calculates the pairwise SNP distance matrix from the SNP-only alignment:

```text
alignment.snps.fasta
        │
        ▼
     snp-dists
        │
        ▼
   distances.tsv
```

The distance calculation is performed independently for RSV-A and RSV-B.

### 2. Genomic cluster analysis

The resulting pairwise SNP distance matrix is analysed using:

```text
scripts/clustering/cluster_analysis.py
```

```text
distances.tsv
      │
      ▼
cluster_analysis.py
      │
      ├── cluster annotations
      ├── cluster summaries
      ├── cluster statistics
      └── cluster figures
```

The script identifies genomic clusters at the SNP-distance thresholds implemented by the clustering analysis.

## Workflow

```text
alignment.snps.fasta
        │
        ▼
     snp-dists
        │
        ▼
   distances.tsv
        │
        ▼
cluster_analysis.py
        │
        ├── tables/
        │
        └── figures/
```

The complete workflow is performed independently for RSV-A and RSV-B.

## Output

Outputs are written under:

```text
ANALYSIS_DIR/06_clustering/
```

with the following general structure:

```text
ANALYSIS_DIR/
└── 06_clustering/
    ├── RSV-A/
    │   ├── distances.tsv
    │   ├── tables/
    │   └── figures/
    │
    └── RSV-B/
        ├── distances.tsv
        ├── tables/
        └── figures/
```

The clustering tables include:

```text
cluster_annotations.tsv
cluster_summary.tsv
cluster_statistics.tsv
```

### `distances.tsv`

Pairwise SNP distance matrix generated with `snp-dists`.

### `cluster_annotations.tsv`

Contains the cluster assignments generated from the pairwise SNP distances.

### `cluster_summary.tsv`

Summarizes the genomic clusters identified at the analysed SNP-distance thresholds.

### `cluster_statistics.tsv`

Contains summary statistics describing the genomic clustering results.

### `figures/`

Contains graphical summaries of the pairwise SNP distances and genomic cluster distributions.

## Software

This step uses:

- SNP-dists
- `scripts/clustering/cluster_analysis.py`

SNP-dists calculates pairwise genomic distances from the SNP-only alignment.

`cluster_analysis.py` identifies genomic clusters and generates the corresponding tables, statistics, and figures.

## Run

For national surveillance:

```bash
bash workflow/06_clustering/run.sh \
    results/national_surveillance
```

For a custom analysis:

```bash
bash workflow/06_clustering/run.sh \
    results/custom/valencia
```

After successful completion, continue with Step 07:

```bash id="wsh3u2"
bash workflow/07_dataset_annotation/run.sh ANALYSIS_DIR MODE
```

where `MODE` is:

```text
national
```

or:

```text 
custom
```

For example:

```bash
bash workflow/07_dataset_annotation/run.sh \
    results/national_surveillance \
    national
```

or:

```bash
bash workflow/07_dataset_annotation/run.sh \
    results/custom/valencia \
    custom
```

## Notes

Genomic clusters are inferred exclusively from pairwise SNP distances using thresholds of **5, 10, and 20 SNPs**.

No epidemiological metadata are used to define clusters during this step. Epidemiological and genomic metadata are integrated during Step 07.

Cluster assignments should therefore be interpreted as **genomic relatedness**, rather than direct evidence of epidemiological linkage or transmission.

Clustering is recalculated independently for every analysis dataset. Consequently, a custom analysis does not inherit cluster assignments from the national surveillance analysis.

Although clustering is evaluated at 5-, 10-, and 20-SNP thresholds, the **5-SNP cluster assignment (`Cluster_5`)** is the clustering level used for annotation of the phylogenetic trees.