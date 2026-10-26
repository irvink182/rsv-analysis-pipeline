# Laboratory Registry

This directory contains the curated laboratory registry used to generate the laboratory metadata required by the RSV Analysis Pipeline.

The registry provides a reusable mapping between laboratory identifiers present in GISAID virus names and standardized information about originating and submitting laboratories.

The registry is **cumulative**. When a new dataset is downloaded, the existing curated registry should be used as the baseline and only new or unresolved records should be reviewed and incorporated.

The registry should **not be rebuilt from scratch** for each dataset update.

---

## Directory structure

```text
resources/registry/
├── laboratories.tsv
├── submitters.tsv
├── lab_aliases.tsv
├── generated/
│   ├── laboratories_candidates.tsv
│   ├── laboratories_conflicts.tsv
│   └── lab_aliases_candidates.tsv
├── parser_validation.tsv
└── lab_codes_summary.tsv
```

The main curated files are:

```text
laboratories.tsv
submitters.tsv
lab_aliases.tsv
```

These files are maintained between dataset updates and constitute the reusable laboratory registry.

Files under `generated/`, together with `parser_validation.tsv` and `lab_codes_summary.tsv`, are generated during registry validation and are used for quality control and manual review.

---

## Overview

Updating laboratory metadata for a new dataset follows this workflow:

```text
New RSV sequencing metadata
        │
        ▼
Combine RSV-A and RSV-B metadata
        │
        ▼
sequencing_metadata.tsv
        │
        ▼
registry build
        │
        ▼
Compare against existing curated registry
        │
        ├── New laboratory
        │       └── update laboratories.tsv
        │
        ├── New submitter
        │       └── update submitters.tsv
        │
        ├── Identifier exception
        │       └── update lab_aliases.tsv when appropriate
        │
        └── Unresolved sample
                └── manual review
        │
        ▼
registry parse
        │
        ▼
resources/metadata/laboratory_metadata.tsv
        │
        ▼
Manual completion of unresolved samples
        │
        ▼
Step 01 — Metadata integration
```

---

## 1. Prepare the sequencing metadata

The registry is built from the sequencing metadata containing both RSV-A and RSV-B records.

Combine the subtype-specific sequencing metadata:

```bash
genometabletools concat \
    resources/metadata/RSV-A_sequencing_metadata.tsv \
    resources/metadata/RSV-B_sequencing_metadata.tsv \
    --output sequencing_metadata.tsv
```

The resulting `sequencing_metadata.tsv` is used as input for the registry update.

This preparation is performed independently of Step 01 because `laboratory_metadata.tsv` itself is an input required by Step 01.

---

## 2. Compare the new dataset against the existing registry

Run:

```bash
genometabletools registry build \
    sequencing_metadata.tsv \
    --registry resources/registry
```

The command uses the existing curated registry as the baseline and evaluates the laboratory identifiers present in the new dataset.

It generates several files for review:

```text
resources/registry/generated/
├── laboratories_candidates.tsv
├── laboratories_conflicts.tsv
└── lab_aliases_candidates.tsv

resources/registry/parser_validation.tsv
resources/registry/lab_codes_summary.tsv
```

These files are quality-control outputs and should not be considered part of the curated registry.

---

## 3. Review new laboratories

Inspect:

```text
resources/registry/generated/laboratories_candidates.tsv
```

This file contains laboratory codes detected in the new dataset that are not currently represented in `laboratories.tsv`.

Not every candidate necessarily represents a new laboratory.

For each candidate, determine whether it represents:

- a genuinely new originating laboratory;
- an alternative representation of an existing laboratory;
- a parsing artefact;
- or an identifier that cannot be reliably resolved automatically.

Confirmed new laboratories should be added to:

```text
resources/registry/laboratories.tsv
```

Existing curated laboratory records should normally be preserved. Differences observed in a new dataset should be reviewed rather than automatically replacing previously curated information.

---

## 4. Review new submitters

New submitting laboratories identified in the dataset should be incorporated into:

```text
resources/registry/submitters.tsv
```

As with `laboratories.tsv`, this table is cumulative.

Existing curated records should normally be retained unless there is clear evidence that the registry itself needs correction.

---

## 5. Review unresolved identifiers

Inspect:

```text
resources/registry/generated/lab_aliases_candidates.tsv
```

These records correspond to identifiers for which a laboratory code could not be reliably assigned automatically.

When an identifier represents a reproducible naming exception that is expected to occur again, it can be incorporated into:

```text
resources/registry/lab_aliases.tsv
```

However, aliases should not be created simply to force every individual sample to resolve automatically.

Dataset-specific identifiers that cannot be reliably interpreted from the `Virus name` should instead be reviewed manually.

---

## 6. Known `HUNSC_ITER` parsing behaviour

Identifiers following the `HUNSC_ITER_*` naming scheme may appear in `laboratories_candidates.tsv` as multiple individual laboratory codes.

For example:

```text
HUNSC_ITER_150358959
HUNSC_ITER_150359169
HUNSC_ITER_402076432
```

These identifiers correspond to the already curated laboratory:

```text
HUNSC_ITER
```

They should therefore **not be incorporated into `laboratories.tsv` as new laboratories**.

Similar `HUNSC_ITER` identifiers with unusual suffixes may also appear among unresolved alias candidates.

These are known parsing artefacts and do not represent independent laboratories.

---

## 7. Generate laboratory metadata

Once the reusable registry has been updated with the new laboratories, submitters, and relevant aliases, generate the sample-level laboratory metadata:

```bash
genometabletools registry parse \
    sequencing_metadata.tsv \
    --registry resources/registry \
    --output resources/metadata/laboratory_metadata.tsv
```

The resulting file contains the standardized laboratory information assigned to each sample in the current dataset.

Unlike the registry files, `laboratory_metadata.tsv` is **dataset-specific** and must be regenerated when the dataset is updated.

---

## 8. Manually curate unresolved samples

Some samples cannot be reliably assigned to an originating laboratory from their `Virus name`.

Typical examples include identifiers without a recognizable laboratory code or identifiers whose apparent code does not uniquely identify the originating laboratory.

These cases require manual review.

The corresponding originating laboratory, submitting laboratory, submitter, and other relevant information should be checked against the source metadata when available.

The resolved information should then be completed directly in:

```text
resources/metadata/laboratory_metadata.tsv
```

These dataset-specific manual corrections do not necessarily need to be incorporated into `lab_aliases.tsv`, particularly when the identifier is unique and is unlikely to provide a reusable parsing rule.

The objective is therefore not to resolve every possible identifier automatically, but to automate reproducible cases while keeping the number of records requiring manual curation small.

---

## 9. Validate the final metadata

Before running the main pipeline, verify that:

- all samples expected in the analysis are represented in `laboratory_metadata.tsv`;
- newly identified laboratories have been reviewed;
- new submitters have been reviewed;
- known parsing artefacts such as `HUNSC_ITER_*` have not been introduced as independent laboratories;
- unresolved identifiers have been manually reviewed where necessary;
- laboratory and autonomous-community assignments are consistent with the curated information.

The final file used by the pipeline is:

```text
resources/metadata/laboratory_metadata.tsv
```

---

## 10. Use in the RSV Analysis Pipeline

Once `laboratory_metadata.tsv` has been generated and manually curated where necessary, the normal pipeline can be started.

Step 01 integrates it with the remaining metadata:

```text
resources/metadata/
├── RSV-A_patient_metadata.tsv
├── RSV-B_patient_metadata.tsv
├── RSV-A_sequencing_metadata.tsv
├── RSV-B_sequencing_metadata.tsv
├── RSV-A_date_location_metadata.tsv
├── RSV-B_date_location_metadata.tsv
└── laboratory_metadata.tsv
```

The resulting integrated metadata table is:

```text
results/01_master_table/master_table.tsv
```

---

## Registry update principle

The registry should evolve incrementally:

```text
Curated registry
      │
      ▼
New dataset
      │
      ▼
Detect new or unresolved records
      │
      ▼
Review only those records
      │
      ▼
Update curated registry
      │
      ▼
Generate dataset-specific laboratory_metadata.tsv
```

**Never rebuild the curated registry from scratch when updating the dataset.**

The existing `laboratories.tsv`, `submitters.tsv`, and `lab_aliases.tsv` files are the baseline for each new update. Only genuinely new or reusable information should be incorporated into these files; individual unresolved samples can be manually curated in the dataset-specific `laboratory_metadata.tsv`.