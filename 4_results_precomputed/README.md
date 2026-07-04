# 4 — Pre-computed results

Every result spreadsheet produced by the pipeline, so the outputs can be inspected (and figures
re-plotted) **without running any code**. All files are de-identified (coded patient IDs,
tooth-position implant labels, prediction probabilities; no names, no dates).

## Layout

```
4_results_precomputed/
├── 0M/            # 0-month: FULL pipeline (model selection + validation)
├── 3M/  6M/  9M/  # sensitivity offsets: validation only (model pool frozen at 0M)
├── figures/       # Figure 3, 4, S1, and S2 (PDF format)
├── reliability/   # inter-/intra-observer ICC (radiomic + clinical)
└── tables/        # Table 1 and Table 3 (.xlsx)
```

## File → stage map

Files are prefixed by offset (e.g. `0M_`). Cell numbers match the notebook's `CELL N` banners.

| File | Stage (notebook cell) |
|---|---|
| `Cell2_UniGEE.xlsx` | Univariable GEE screening |
| `Cell3_MultiGEE.xlsx` | Multivariable GEE screening pools (ICC ≥ 0.75 gate) |
| `Cell4_UniCox.xlsx` | Univariable Cox |
| `Cell5_Pruning.xlsx` | mRMR redundancy pruning → final candidates |
| `Cell6_MultiCox.xlsx` | Multivariable Cox |
| `Cell7_Defense.xlsx` | VIF / PH / EPV / ESS checks (+ correlation plot) |
| `Within_Family_Collinearity.xlsx` | Within-family Spearman correlation matrix (feeds mRMR pruning; 0M only) |
| `Cell8_2Algo_Boot_Categorized.xlsx` | Bootstrap internal validation (LR + XGBoost) |
| `Cell9_LOGO_CV_Categorized.xlsx` | Leave-one-group-out CV |
| `Cell10_ClinicalDefense_Categorized.xlsx` | Calibration (Brier, slope, HL) + Probabilities |

`reliability/` holds `ICC_radiomics_evaluation.xlsx` and `Final_clinical_ICC_Results.xlsx`.
`tables/` holds `Table1_Clinical_Features_Stats.xlsx` and `Table3_Interaction_FDR.xlsx`
(feature-level group × lead-time interaction analysis, with BH-FDR and Bonferroni correction).

## Model-category abbreviations

Models are grouped by composition (sheet names / column prefixes): **CM** clinical only,
**SRM** single radiomic feature, **RM** radiomic-only (multi-feature), **CRM** clinical +
radiomic. Logistic regression (`_LR`) is primary; XGBoost (`_XGB`) is a pre-specified
exploratory comparator. No single model is designated as best.

## Re-plotting figures

`ROC_Plot_Data` / `CV_ROC_Plot_Data` (Cell 8 / 9) and the calibration metrics + `Probabilities`
sheet (Cell 10) hold everything needed to redraw ROC, calibration, and decision curves.
