# 2 — Original analysis notebook (R, raw)

`PI_MRONJ_analysis_raw.ipynb` is the **original working notebook** behind the published
results, kept unmodified for provenance.

It reflects the manual workflow that was actually used:

- one R notebook with all stages (data prep → GEE → Cox → mRMR pruning → bootstrap/LOGO-CV →
  calibration → tables/figures);
- comments are mixed Korean/English;
- a single offset variable `SENS_CUTOFF_MONTHS` controls the sensitivity offset. The 0-month
  run was executed top to bottom; the 3-/6-/9-month sensitivity runs were produced by changing
  `SENS_CUTOFF_MONTHS` and re-running **only** the validation cells (Bootstrap, LOGO-CV,
  Clinical Defense), reusing the 0-month model pool.

For a cleaned, seed-fixed, **one-click** version of the same analysis (identical logic), see
[`../3_analysis_R_oneclick/`](../3_analysis_R_oneclick/).

> This file is for reference. Do not edit it; reproducibility work happens in folder `3_`.
