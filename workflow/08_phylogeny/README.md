# 08. Phylogenetic analysis

## Objective

Reconstruct and visualize phylogenetic trees for RSV-A and RSV-B.

This step performs phylogenetic inference from the SNP alignments generated during Step 05 and combines the resulting trees with the metadata prepared during Step 07 to generate annotated phylogenetic visualizations.

Two phylogenetic inference methods are available:

- **FastTree** — fast phylogenetic reconstruction for routine and exploratory analyses.
- **IQ-TREE** — more computationally intensive phylogenetic inference for analyses requiring a more comprehensive phylogenetic reconstruction.

Step 08 is **optional**. GenomeReport can be generated directly after Step 07 without performing phylogenetic reconstruction.

## Input

Step 08 requires three arguments and accepts one optional argument:

```bash
bash workflow/08_phylogeny/run.sh ANALYSIS_DIR MODE METHOD [PLOT_PROFILE]
```

### `ANALYSIS_DIR`

Directory containing the analysis results.

Examples:

```text
results/national_surveillance
results/custom/valencia
results/custom/2022_2024
```

### `MODE`

Defines the analysis mode:

```text
national
custom
```

The mode must correspond to the mode used during Step 07.

### `METHOD`

Defines the phylogenetic inference method:

```text
fasttree
iqtree
```

### `PLOT_PROFILE`

Optional argument defining the annotation profile used for phylogenetic visualization:

```text
standard
detailed
```

If no profile is explicitly provided, the following defaults are used:

```text
national → standard
custom   → detailed
```

The default can be overridden by explicitly providing `PLOT_PROFILE`.

The `standard` profile is intended for broad datasets where geographic and temporal patterns provide the most informative overview.

The `detailed` profile is intended for more focused datasets where fine-scale genomic clustering and institution-level information remain interpretable.

The plot profile is independent of the analysis mode. Therefore, a custom analysis can use the `standard` profile when appropriate.

## Phylogenetic methods

Two alternative phylogenetic inference methods are available.

### FastTree

FastTree provides rapid phylogenetic inference and is intended primarily for routine surveillance, exploratory analyses, and large datasets.

For each RSV subtype, FastTree is run directly on the SNP-only alignment generated during Step 05:

```text
alignment.snps.fasta
```

using:

```bash
fasttree \
    -gtr \
    -nt
```

The analysis therefore uses nucleotide sequence data under a GTR model.

FastTree is recommended when rapid phylogenetic reconstruction is preferred over the more computationally intensive IQ-TREE analysis.

Typical runtime is on the order of minutes, depending on dataset size and available computational resources.

### IQ-TREE

IQ-TREE provides the more comprehensive phylogenetic inference workflow implemented in the pipeline.

For each RSV subtype, IQ-TREE uses the SNP-only alignment:

```text
alignment.snps.fasta
```

while constant-site information is calculated from the corresponding complete whole-genome alignment:

```text
alignment.fasta
```

using:

```bash
snp-sites -C alignment.fasta
```

The resulting constant-site information is supplied to IQ-TREE using `-fconst`.

IQ-TREE is run using:

```text
GTR+F+I+R10
```

with branch support estimated using:

```text
1000 ultrafast bootstrap replicates
1000 SH-aLRT replicates
```

The implemented command is equivalent to:

```bash
iqtree2 \
    -s alignment.snps.fasta \
    -m GTR+F+I+R10 \
    -B 1000 \
    -alrt 1000 \
    -nt AUTO \
    -fconst <constant-site counts>
```

IQ-TREE is recommended when a more comprehensive phylogenetic reconstruction and branch-support estimation are required.

Runtime can be substantially longer than FastTree and may extend to hours depending on dataset size and computational resources.

## Processing

The workflow is performed independently for RSV-A and RSV-B.

### 1. Phylogenetic inference

The selected `METHOD` determines which inference workflow is executed.

#### FastTree workflow

```text
alignment.snps.fasta
        │
        ▼
     FastTree
GTR nucleotide model
        │
        ▼
*.fasttree.tree.nwk
```

FastTree uses the SNP-only alignment directly.

#### IQ-TREE workflow

```text
alignment.fasta
      │
      ▼
 SNP-sites -C
      │
      ▼
constant-site counts
      │
      │
      ├─────────────────────────┐
      │                         │
      │                 alignment.snps.fasta
      │                         │
      └────────────┬────────────┘
                   ▼
                 IQ-TREE
           GTR+F+I+R10
           UFBoot = 1000
           SH-aLRT = 1000
                   │
                   ▼
                *.treefile
```

Providing constant-site information allows IQ-TREE to account for the invariant positions that are absent from the SNP-only alignment.

### 2. Annotated phylogenetic visualization

After phylogenetic inference, the main Step 08 workflow automatically executes:

```text
workflow/08_phylogeny/plot_tree.sh
```

using:

```text
ANALYSIS_DIR
MODE
METHOD
PLOT_PROFILE
```

The inferred tree is combined with the phylogenetic metadata generated during Step 07 to produce annotated phylogenetic figures.

The corresponding reference genome is used to root the RSV-A and RSV-B phylogenies.

The annotations included in the visualization are determined by `PLOT_PROFILE`, independently of whether the analysis was generated using `national` or `custom` mode.

## Output

Results are written under:

```text
ANALYSIS_DIR/08_phylogeny/
```

### FastTree

FastTree results are written to:

```text
ANALYSIS_DIR/08_phylogeny/
├── RSV-A/
│   └── fasttree/
│       └── RSV-A.fasttree.tree.nwk
│
└── RSV-B/
    └── fasttree/
        └── RSV-B.fasttree.tree.nwk
```

### IQ-TREE

IQ-TREE results are written to:

```text
ANALYSIS_DIR/08_phylogeny/
├── RSV-A/
│   └── iqtree/
│       └── RSV-A.*
│
└── RSV-B/
    └── iqtree/
        └── RSV-B.*
```

The primary tree files used for downstream visualization are:

```text
RSV-A/iqtree/RSV-A.treefile
RSV-B/iqtree/RSV-B.treefile
```

### Annotated phylogenies

Regardless of the inference method, annotated figures are written under:

```text
ANALYSIS_DIR/08_phylogeny/RSV-A/figures/
ANALYSIS_DIR/08_phylogeny/RSV-B/figures/
```

Both rectangular and circular visualizations are generated.

## Phylogenetic annotations

All phylogenetic visualizations use `Lineage` as the main tree-tip color variable.

Additional annotation tracks are determined by the selected `PLOT_PROFILE`.

### Standard profile

The `standard` profile provides a general geographic and temporal overview and is suitable for national surveillance and other broad datasets.

The visualization includes:

- lineage;
- autonomous community;
- collection year.

Additional annotation tracks:

```text
autonomous_community
gisaid_collection_year
```

`gisaid_collection_year` is represented as a continuous variable.

### Detailed profile

The `detailed` profile provides additional fine-scale genomic and epidemiological information and is intended for focused datasets where these annotations remain interpretable.

The visualization includes:

- lineage;
- **5-SNP genomic cluster**;
- institution;
- collection year;
- collection month.

Additional annotation tracks:

```text
Cluster_5
institution
gisaid_collection_year
gisaid_collection_month
```

`Cluster_5` and `institution` are represented as discrete variables.

Collection year and collection month are represented as continuous variables.

The `Cluster_5` assignment generated during Step 06 is the genomic clustering level used by the detailed phylogenetic profile.

The 10- and 20-SNP clustering levels remain available in the metadata but are not displayed by this profile.

## Workflow

```text
                 alignment.snps.fasta
                         │
              ┌──────────┴──────────┐
              │                     │
              ▼                     ▼
           FastTree              IQ-TREE
              │                     │
              └──────────┬──────────┘
                         ▼
                 phylogenetic tree
                         │
                         │
              phylogenetic metadata
                         │
                         ▼
                    plot_tree.sh
                         │
                  PLOT_PROFILE
                         │
              ┌──────────┴──────────┐
              │                     │
           standard              detailed
              │                     │
              └──────────┬──────────┘
                         ▼
                  ┌──────┴──────┐
                  ▼             ▼
            rectangular      circular
             phylogeny       phylogeny
```

The complete workflow is performed independently for RSV-A and RSV-B.

## Output

Results are written under:

```text
ANALYSIS_DIR/08_phylogeny/
```

with separate directories for RSV-A and RSV-B.

The exact tree files depend on the selected phylogenetic method.

Annotated phylogenetic figures are written under:

```text
ANALYSIS_DIR/08_phylogeny/RSV-A/figures/
ANALYSIS_DIR/08_phylogeny/RSV-B/figures/
```

For each subtype, both rectangular and circular phylogenetic visualizations are generated.

The circular figures follow the naming convention:

```text
RSV-A_<method>_circular.png
RSV-B_<method>_circular.png
```

where `<method>` is:

```text
fasttree
```

or:

```text
iqtree
```

These circular phylogenies can subsequently be incorporated into GenomeReport.

## Run

### National surveillance with FastTree

The `standard` profile is selected automatically for national surveillance:

```bash
bash workflow/08_phylogeny/run.sh \
    results/national_surveillance \
    national \
    fasttree
```

### National surveillance with IQ-TREE

```bash
bash workflow/08_phylogeny/run.sh \
    results/national_surveillance \
    national \
    iqtree
```

### Focused custom analysis with FastTree

Custom analyses use the `detailed` profile by default:

```bash
bash workflow/08_phylogeny/run.sh \
    results/custom/valencia \
    custom \
    fasttree
```

### Focused custom analysis with IQ-TREE

```bash
bash workflow/08_phylogeny/run.sh \
    results/custom/valencia \
    custom \
    iqtree
```

### Custom analysis using the standard profile

For broader custom datasets, the default `detailed` profile can be overridden explicitly:

```bash
bash workflow/08_phylogeny/run.sh \
    results/custom/2022_2024 \
    custom \
    iqtree \
    standard
```

This allows custom analyses to use the same geographic and temporal annotation strategy as national surveillance without changing the analysis mode.

### Explicit detailed profile

The plot profile can also be specified explicitly:

```bash
bash workflow/08_phylogeny/run.sh \
    results/custom/valencia \
    custom \
    iqtree \
    detailed
```

## Add phylogenies to GenomeReport

After Step 08, GenomeReport can be regenerated with the annotated circular phylogenies.

For FastTree:

```bash
bash workflow/09_genome_report/run.sh \
    ANALYSIS_DIR \
    ANALYSIS_DIR/08_phylogeny/RSV-A/figures/RSV-A_fasttree_circular.png \
    ANALYSIS_DIR/08_phylogeny/RSV-B/figures/RSV-B_fasttree_circular.png
```

For IQ-TREE:

```bash
bash workflow/09_genome_report/run.sh \
    ANALYSIS_DIR \
    ANALYSIS_DIR/08_phylogeny/RSV-A/figures/RSV-A_iqtree_circular.png \
    ANALYSIS_DIR/08_phylogeny/RSV-B/figures/RSV-B_iqtree_circular.png
```

The exact command required for the selected method is also displayed automatically when Step 08 finishes.

## Software

This step uses:

- FastTree
- IQ-TREE 2
- SNP-sites
- R
- ggtree
- `scripts/phylogeny/plot_phylogeny.R`

FastTree provides rapid phylogenetic inference from the SNP-only alignment.

IQ-TREE 2 performs phylogenetic inference using the SNP-only alignment together with constant-site information derived from the complete reference-guided alignment.

SNP-sites is used to recover constant-site counts required by the IQ-TREE workflow.

The R/ggtree visualization workflow combines the inferred phylogenies with the metadata generated during Step 07.

## Notes

Step 08 is optional and is not required to generate the standard GenomeReport.

FastTree and IQ-TREE represent alternative phylogenetic inference workflows. Only the method selected with `METHOD` is executed.

Phylogenetic inference is performed independently for RSV-A and RSV-B.

The reference sequences included during Step 05 are retained in the phylogenetic analysis and are used to root the corresponding RSV-A and RSV-B trees.

Phylogenetic annotations are derived from the metadata prepared during Step 07.

`MODE` and `PLOT_PROFILE` control different aspects of the workflow:

```text
MODE
    national | custom
    → analysis context

PLOT_PROFILE
    standard | detailed
    → phylogenetic annotation strategy
```

By default, national analyses use the `standard` profile and custom analyses use the `detailed` profile. The plot profile can be explicitly overridden when required.

The `detailed` profile displays the **5-SNP genomic cluster (`Cluster_5`)**. Other genomic clustering thresholds remain available in the metadata but are not displayed as tree annotations by this profile.