# 0 — De-identified dataset (not in this repository)

The de-identified analysis dataset (`PI_MRONJ_v4.xlsx`) is **not committed to this public
repository**. It is distributed as **journal supplementary material** and is available from the
authors **on reasonable request**. The raw dataset (real dates) and panoramic images are not
shared publicly.

This folder documents the dataset so the analysis is fully understandable without it.

## Data dictionary — sheet `Coding`

245 timepoints × implant. Columns: `Patient_ID` (coded `PT01`–`PT07`), `Implant_ID`
(tooth position, e.g. `46i`), `Study_Date` / `T0_Surgery` (see below), `Days_Since_Surgery`,
`PI-MRONJ` (event), clinical codes (jaw, region, prosthesis, insertion depth/angle, …) and
125 IBSI radiomic features (`FO_*`, `GLCM_*`, `GLRLM_*`, `GLSZM_*`, `NGTDM_*`, `Wav_*`).

## De-identification applied to the supplementary file

- Patient IDs coded; implant IDs are tooth positions.
- **No real dates.** `Study_Date` / `T0_Surgery` are **relative day-offsets** (integer days from
  each patient's first record). All within-patient / within-implant intervals — visit spacing,
  time-to-T0, follow-up duration — are preserved exactly, so the pipeline reproduces
  identically, while absolute dates and cross-patient timing are unrecoverable.
- The patient-level `Characteristic` sheet (exact age, anti-resorptive drug + duration,
  comorbidities) was removed as quasi-identifiers in an N = 7 cohort; the aggregate Table 1 is in
  `../4_results_precomputed/tables/`.
- Sheets carrying real dates / duplicates (`Coding_legacy`, `Sheet1`) removed.
- Radiomic values preserved to full double precision.

## To run the pipeline

Place the supplementary `PI_MRONJ_v4.xlsx` at `/content/` in Colab (see
[`../3_analysis_R_oneclick/`](../3_analysis_R_oneclick/)). The columns `Study_Date` /
`T0_Surgery` hold relative day indices (integers), read with `as.numeric()`.
