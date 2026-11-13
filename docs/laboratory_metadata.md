# Laboratory metadata

## Overview

The RSV Analysis Pipeline uses a curated laboratory metadata table to harmonize information about the laboratories associated with GISAID records.

The required file is:

```text
resources/metadata/laboratory_metadata.tsv
```

This file must be prepared and curated **before running the pipeline**. It is treated as an input resource and is not modified by the pipeline.

Laboratory metadata can be updated using the `registry update` workflow implemented in GenomeTableTools.

## Required data

Updating the laboratory metadata requires:

1. The current GISAID sequencing metadata for RSV-A and RSV-B.
2. A previously curated `laboratory_metadata.tsv` used as the historical reference.

The sequencing metadata files used by the RSV Analysis Pipeline are:

```text
resources/metadata/RSV-A_sequencing_metadata.tsv
resources/metadata/RSV-B_sequencing_metadata.tsv
```

The historical laboratory metadata table should correspond to the previously curated version of the registry.

## 1. Combine sequencing metadata

First, combine the RSV-A and RSV-B sequencing metadata:

```bash
genometabletools concat \
    resources/metadata/RSV-A_sequencing_metadata.tsv \
    resources/metadata/RSV-B_sequencing_metadata.tsv \
    --output sequencing_metadata.tsv
```

The resulting `sequencing_metadata.tsv` contains the current set of GISAID records used to update the laboratory metadata.

## 2. Update the laboratory metadata

Run the GenomeTableTools registry update using the current sequencing metadata and the previously curated laboratory metadata:

```bash
genometabletools registry update \
    --input sequencing_metadata.tsv \
    --reference laboratory_metadata_previous.tsv \
    --output laboratory_metadata.tsv \
    --new-records-output registry_new_records.tsv \
    --review-output registry_review.tsv
```

GenomeTableTools compares the current accessions against the historical reference.

Existing accessions preserve their curated laboratory metadata, while new accessions are resolved using historical laboratory relationships and conservative parsing of the GISAID virus name.

Laboratory metadata are assigned only when they can be resolved unambiguously. Ambiguous or unresolved fields are left for manual review.

## 3. Review new records

The registry update generates three main files:

| File | Description |
|------|-------------|
| `laboratory_metadata.tsv` | Complete laboratory metadata table for the current dataset |
| `registry_new_records.tsv` | Records introduced since the historical reference |
| `registry_review.tsv` | New records containing laboratory metadata fields that require manual review |

The `registry_new_records.tsv` file can be used to inspect all newly incorporated records.

The `registry_review.tsv` file contains the subset requiring manual curation. The `review_fields` column identifies which metadata fields could not be resolved automatically.

## 4. Curate unresolved records

Records reported in `registry_review.tsv` should be reviewed before the laboratory metadata table is used by the RSV Analysis Pipeline.

Any required corrections or additional information should be incorporated into:

```text
laboratory_metadata.tsv
```

The resulting table represents the curated laboratory registry for the current dataset.

The registry workflow prioritizes precision over automatic coverage. Ambiguous laboratory assignments should therefore be curated manually rather than inferred without sufficient evidence.

## 5. Prepare the pipeline input

Once the updated table has been reviewed and curated, copy or move it to:

```text
resources/metadata/laboratory_metadata.tsv
```

This is the file consumed by Step 01 of the RSV Analysis Pipeline during metadata integration.

The pipeline assumes that this file has already been curated and does not perform registry updating or manual laboratory metadata resolution during execution.

## Validation

When a curated laboratory metadata table for the current dataset is available, the optional `--validation` argument can be used to evaluate the automatic assignments:

```bash
genometabletools registry update \
    --input sequencing_metadata.tsv \
    --reference laboratory_metadata_previous.tsv \
    --validation laboratory_metadata_validation.tsv \
    --output laboratory_metadata.tsv \
    --new-records-output registry_new_records.tsv \
    --review-output registry_review.tsv
```

Validation is optional and is primarily useful when evaluating registry behavior against an independently curated dataset.

## Recommended update cycle

The recommended laboratory metadata maintenance workflow is:

```text
Current GISAID sequencing metadata
              +
Previous curated laboratory_metadata.tsv
              │
              ▼
     GenomeTableTools registry update
              │
        ┌─────┴─────┐
        ▼           ▼
   new records   manual review
        │           │
        └─────┬─────┘
              ▼
       manual curation
              │
              ▼
 Current curated laboratory_metadata.tsv
              │
        ┌─────┴─────┐
        ▼           ▼
 RSV Analysis    Reference for
   Pipeline      next update
```

Each curated version therefore becomes the historical reference for the next laboratory metadata update.

## GenomeTableTools

Laboratory registry updating requires GenomeTableTools v1.3.0 or later.

For additional details about the registry workflow and command-line options, see the GenomeTableTools documentation.