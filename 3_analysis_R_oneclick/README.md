# 3 — One-click reproducible pipeline (R, Colab)

`PI_MRONJ_oneclick.ipynb` is a reorganised version of the analysis in
[`../2_analysis_R_raw/`](../2_analysis_R_raw/) with **identical analysis logic and identical
results** — only structure and reproducibility changed. It runs top-to-bottom on Google Colab's
R runtime (*Runtime ▸ Run all*). A full run takes ≈1.5 h (mostly the B=1000 bootstrap).

## Required uploads (to `/content/`)

1. `PI_MRONJ_v4.xlsx` — de-identified feature table from
   [`../0_data_deidentified/`](../0_data_deidentified/) (Coding sheet; dates relativised).
2. `ICC_radiomics_evaluation.xlsx` — radiomic reliability table consumed by Multi-GEE
   (sheet `ICC_stable_features`); provided in
   [`../4_results_precomputed/reliability/`](../4_results_precomputed/reliability/).

## Run order

1. **Setup & config** — packages, paths, single `SEED` / `OFFSETS` block.
2. **Data foundation** — loaders + feature-table builders (offset-independent).
3. **0-month model selection (CELL 1–7, run once → frozen).** Data prep → Uni-GEE → Multi-GEE →
   Uni-Cox → mRMR pruning → Multi-Cox → defense (+ correlation plot). Run **only at 0M**;
   re-running at another offset would change `df_imp` and the selected models, so they are
   **not** looped.
4. **Offset sensitivity validation (CELL 8–10).** A loop over `OFFSETS = c(0,3,6,9)` runs only
   bootstrap / LOGO-CV / calibration on the offset-filtered data, reusing the frozen 0-month
   pool.
4b. **Feature-level interaction analysis (manuscript Table 3).** Offset-independent; uses all
   245 raw timepoints (not looped over `OFFSETS`). Fits
   `feature_z ~ group * ns(lead_yr, 2) + (1|Patient_ID) + (1|Implant_UID)` for the 10 v5
   candidate radiomic features (8 static + 2 dynamic base names) to test whether case/control
   trajectories diverge, and applies Benjamini–Hochberg (BH-FDR) and Bonferroni correction
   across the 10 interaction tests. Exports the formatted `Table3_Interaction_FDR.xlsx`.
5. **Figure generation.** Figures 3 / 4 / S2, drawn from the freshly produced `{offset}M_*`
   spreadsheets (so it runs in the same pass).
6. **Session info** — `sessionInfo()` + key package versions (see `sessionInfo.txt`).

Table 1 generation is **not** in this notebook: it depended on patient-level demographics that
were removed for stronger de-identification, and the descriptive table is already provided in
`../4_results_precomputed/tables/`.

ICC *regeneration* is in the separate `Reliability_regeneration_ICC.ipynb` (it needs
observer-remeasurement files that are not distributed). The pipeline consumes the prepared
`ICC_radiomics_evaluation.xlsx` instead.

## Cell numbering

Cell banners (`CELL 1` … `CELL 10`) and the output **filenames** (`Cell2_…` … `Cell10_…`) now
use the same sequential numbers, matching the files in `../4_results_precomputed/`.

## What changed vs the raw notebook (structure only)

- Cells reordered; ICC split into a separate notebook; Table 1 removed; figures at the end.
- Cells 8/9/10 wrapped into functions parameterised by `months`; `df_imp` rebuilt per offset;
  model pool always read from the frozen 0M selection.
- Random seed centralised (`SEED <- 42L`, value unchanged); no new seeds; `RNGkind()` left at
  default → results unchanged.
- Calibration / DCA **plotting** removed; underlying data still exported for re-plotting.
- Dates de-identified: `Study_Date` / `T0_Surgery` are relative day-offsets, read with
  `as.numeric()` and differenced by subtraction (no `as.Date`/`difftime`).
- Reviewer-defense **diagnostic** prints removed from the data-prep cell (not needed to run).

## Environment & reproducibility

`sessionInfo.txt` records the exact R + package versions. ggplot2 4.0.x needs
`ggplot2::margin()` namespace-qualified (already applied). After running, the freshly produced
`{offset}M_*` spreadsheets should match `../4_results_precomputed/` (bootstrap noise aside).
