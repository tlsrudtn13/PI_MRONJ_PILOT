# 1 — Radiomics extraction (MATLAB)

Interactive MATLAB tools used to turn raw panoramic DICOMs into per-implant, per-timepoint
IBSI radiomic features. These are **GUI / click-driven** tools (ROI selection, lasso masking),
so they are operated manually and are **not** part of the one-click R pipeline.

## Files

| File | Role |
|---|---|
| `a_Crop_Tool_v1_8.m` | Loads a DICOM panorama, lets the operator click the implant centre, and crops a fixed `112 × 224` patch (PATCH_W × PATCH_H). |
| `b_Masking_and_Extraction_tool_v5.m` | Loads cropped patches, provides lasso/eraser bone-masking, and extracts IBSI-compliant radiomic features (NBINS = 32) per masked ROI. |

## Usage (outline)

1. Run `a_Crop_Tool_v1_8.m`, select a DICOM, click the implant location → a cropped patch is saved.
2. Run `b_Masking_and_Extraction_tool_v5.m`, load the cropped patches, draw the peri-implant
   bone mask, and run extraction → a feature table is written.

## Notes

- Requires MATLAB with the Image Processing Toolbox.
- These scripts are provided as-is for provenance and reproducibility of the extraction step;
  comments are mixed Korean/English.
- The wavelet convention used downstream is `[LL, LH, HL, HH] = dwt2(img, 'haar')`
  (MATLAB `dwt2` = `[cA, cH, cV, cD]`), i.e. **LH = horizontal detail, HL = vertical detail**.
