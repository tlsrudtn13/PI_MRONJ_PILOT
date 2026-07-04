# PI-MRONJ — Longitudinal Panoramic Radiomics (Pilot)

Analysis code for a **proof-of-concept pilot study** on early prediction of peri-implant
medication-related osteonecrosis of the jaw (PI-MRONJ) from longitudinal panoramic
radiographs, combining clinical predictors with static (single-timepoint) and dynamic
(trajectory) radiomic features.

> This is a **hypothesis-generating pilot**. The repository reports observed signals and
> their internal validation; it makes **no claim of superiority** for any feature, model,
> or modality. Findings warrant confirmation in larger cohorts and against CBCT.

This repository contains the **analysis pipeline and pre-computed result tables only**.
The patient dataset is de-identified and is **not** included (see [Data availability](#data-availability)).

---

## Repository layout

The repository is split into five self-contained parts:

```
PI_MRONJ_PILOT/
├── 0_data_deidentified/      # Data dictionary only — the de-identified dataset itself is
│                             #   NOT committed (journal supplementary material / on request)
├── 1_extraction_matlab/      # Image cropping + bone masking + IBSI radiomics (MATLAB GUI tools)
├── 2_analysis_R_raw/         # Original working notebook (R) — as used during the study
├── 3_analysis_R_oneclick/    # Cleaned, seed-fixed, one-click reproducible pipeline (R, Colab)
└── 4_results_precomputed/    # Result spreadsheets, to inspect outputs without re-running anything
```

| Folder | What it is | When to use it |
|---|---|---|
| `0_data_deidentified/` | Data dictionary and de-identification notes for the analysis dataset. The de-identified `PI_MRONJ_v4.xlsx` itself is **not committed here** — it is distributed as journal supplementary material and is available from the authors on reasonable request. The raw dataset (real dates) and panoramic images are never shared publicly. | To understand the dataset structure without needing the file itself. |
| `1_extraction_matlab/` | Interactive MATLAB tools that crop the ROI and produce IBSI radiomic features per implant/timepoint. | To reproduce feature extraction from your own DICOM panoramas. |
| `2_analysis_R_raw/` | The original analysis notebook exactly as it was used (mixed-language comments, single-offset manual workflow). Kept for provenance. | To see the unmodified working code behind the published results. |
| `3_analysis_R_oneclick/` | A reorganized version of the same analysis: fixed random seed, pinned/recorded package versions, runs reliability → 0-month model selection → 3/6/9-month sensitivity validation → tables/figures in one pass on Google Colab. | To re-run the full analysis reproducibly. |
| `4_results_precomputed/` | Every result spreadsheet the analysis produces, organised by sensitivity offset. | To read the results directly, without installing R or running any code. |

`2_` and `3_` contain the **same analysis logic**; `3_` only reorganises structure and fixes
reproducibility. Results are identical.

---

## Analysis overview

1. **Feature extraction (MATLAB).** ROI cropping and peri-implant bone masking, followed by
   IBSI-compliant radiomic feature extraction (first-order, GLCM, GLRLM, GLSZM, NGTDM, and
   wavelet sub-bands).
2. **Reliability (ICC).** Inter-/intra-observer intraclass correlation for clinical and
   radiomic features.
3. **Screening (GEE).** Generalised estimating equations on the timepoint-level data
   (implant-clustered) to screen single-timepoint and temporal features, with an ICC
   reproducibility filter applied when building the multivariable screening pools.
4. **Survival screening + redundancy pruning (Cox + mRMR).** Univariable/multivariable Cox
   (patient-clustered) on the implant-level data, followed by mRMR redundancy pruning
   (relevance = |Cox z|, redundancy = |Spearman ρ|) to a compact candidate set.
5. **Internal validation.** Patient-clustered bootstrap (primary) and leave-one-group-out
   cross-validation (sensitivity), for logistic regression (primary) and XGBoost
   (pre-specified exploratory comparator).
6. **Calibration.** Brier score, Hosmer–Lemeshow, and calibration data export for decision-curve
   and calibration plotting.

### Sensitivity offsets (important)

Model **selection** (screening → Cox → pruning → model pool) is performed **once at the
0-month offset** and then **frozen**. The 3-, 6-, and 9-month offsets are **sensitivity
analyses** that exclude peri-diagnostic panoramas and **re-run only the validation steps**
(bootstrap, LOGO-CV, calibration) on the offset-filtered data, reusing the 0-month model pool.

This is why `4_results_precomputed/0M/` contains the full pipeline outputs, while `3M/`, `6M/`,
and `9M/` contain only the validation outputs.

---

## Requirements

- **R** ≥ 4.2 (developed on Google Colab's R runtime).
- **MATLAB** R2021a+ with Image Processing Toolbox (for `1_extraction_matlab/`).
- Package list and exact versions are recorded inside `3_analysis_R_oneclick/`.

---

## Data availability

This repository contains **code and pre-computed results only**. The de-identified analysis
dataset (`PI_MRONJ_v4.xlsx`; real dates removed, dates stored as relative day-offsets, patient
demographics dropped) is provided as **journal supplementary material** and is available from
the authors **on reasonable request**. The raw dataset (real surgery/study dates) and the
panoramic radiographs are not shared publicly. See
[`0_data_deidentified/`](0_data_deidentified/) for the data dictionary and de-identification
details.

---

## Citation

If you use this code, please cite the associated pilot study (reference to be added on
publication) and the archived release (Zenodo DOI to be added).
