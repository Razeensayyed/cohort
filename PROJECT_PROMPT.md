# Pothole Detection System — YOLOv12 + Streamlit (Research-Grade Project Prompt)

> **Audience:** PhD supervisor and a panel of research scholars.
> **Standard required:** research-grade. Reproducible, rigorously evaluated, honestly reported, and demo-ready.
> **Constraint:** only free and open resources (free datasets, free tools, free compute such as Kaggle). Nothing paid.

---

## 0. How to use this document

This file is the single source of truth for the build. It is written as a prompt to a senior computer-vision engineer (or an AI coding agent). Build the project **phase by phase** (Section 14), stop at each phase's acceptance criteria, and do not skip ahead. Where a decision is marked **[CONFIRM]**, ask the project owner before proceeding.

---

## 1. Role and goal

**Role:** You are a senior computer-vision research engineer.

**Goal:** Build a complete pothole detection system that:

1. Trains **YOLOv12 (Ultralytics)** on the owner's Kaggle pothole data, **plus additional free, openly licensed datasets** (Section 4).
2. Evaluates it with a rigorous, reproducible protocol: baselines, ablations, robustness tests, cross-dataset generalisation, confidence intervals and error analysis (Section 6).
3. Exposes everything through a polished **Streamlit** application with detection, analysis, batch, video and webcam, severity, GPS map, history and PDF reports (Section 8).
4. Ships with documentation and artefacts good enough to present to scholars and to support a paper or thesis chapter (Section 12).

**What "outstanding" means here:** not only a working demo, but (a) a defensible methodology, (b) numbers with uncertainty, (c) honest limitations, (d) explainability, (e) reproducibility, and (f) a professional interface.

---

## 2. Scope

### In scope
- Single-class pothole detection (`pothole`), extensible to more road-damage classes.
- Images, batches/ZIPs, video files and webcam.
- Severity grading, GPS mapping from EXIF, history, PDF report.
- Training notebooks (Kaggle), an evaluation suite and a research-analysis page.

### Out of scope (state this in the README)
- Real-time vehicle-mounted deployment, mobile apps and cloud hosting.
- Metric (centimetre) depth/volume measurement without calibrated hardware.
- Paid datasets, paid APIs and paid compute.

---

## 3. Technology stack (all free / open source)

| Layer | Choice |
|---|---|
| Language | Python 3.10+ |
| Detector | `ultralytics>=8.3.78` (provides YOLOv12 `yolo12n/s/m/l/x`) |
| Deep learning | PyTorch |
| Vision | OpenCV, Pillow, `albumentations` (optional extra augmentation) |
| Small-object inference | `sahi` (optional, Section 7.4) |
| Explainability | `grad-cam` (`pytorch-grad-cam`) using EigenCAM, which suits YOLO |
| GUI | Streamlit |
| Charts | Plotly |
| Maps | Folium + `streamlit-folium` |
| Data | pandas, numpy, SQLite (stdlib) |
| Metadata | `exifread` or `piexif` (GPS) |
| PDF | `fpdf2` or `reportlab` |
| Stats | `scipy`, `numpy` (bootstrap confidence intervals) |
| Hashing / dedup | `imagehash` |
| Tests/quality | `pytest`, `ruff`, `black` |
| Training compute | Kaggle free GPU (P100/T4), Google Colab as fallback |
| Experiment log | CSV/JSON logs by default; TensorBoard (free) optional |

Pin all versions in `requirements.txt`. Record the exact `ultralytics`, `torch` and CUDA versions in every results file for reproducibility.

---

## 4. Data strategy

### 4.1 Owner's data (primary)
- Use the owner's Kaggle pothole dataset as the primary source.
- **[CONFIRM]** its format (YOLO / COCO / VOC / CSV), class names and licence. If it is not YOLO format, implement `src/convert_dataset.py`.

### 4.2 Additional free datasets (to enlarge and diversify)
Integrate **free, openly licensed** sources. **Verify and record each dataset's licence, citation and download date in `DATA_CARD.md` before use. Do not use any dataset whose licence forbids academic use or redistribution of derived models.** Candidate sources:

| Source | Notes |
|---|---|
| **RDD2022** (Road Damage Detection, figshare / CRDDC2022) | Large, multi-country; pothole class is `D40`. Check the licence on the figshare page. |
| **Roboflow Universe** public pothole datasets | Free to download in YOLO format. Choose only those with permissive licences (e.g. CC BY 4.0) and record the exact licence of each. |
| **Other Kaggle pothole datasets** (e.g. the "Annotated Potholes" style datasets) | Check the per-dataset licence on its Kaggle page. |
| **Mendeley Data / Zenodo** pothole sets | Often CC BY; verify. |

The exact datasets are chosen at implementation time, because licences and availability can change. The agent must **not assume** a licence. If a licence is unclear, exclude the dataset and note it.

### 4.3 Curation pipeline (`src/data_prep/`)
1. **Unify format** to YOLO; map all relevant classes to `pothole` (for RDD2022 keep only `D40`).
2. **Validate labels:** drop empty/corrupt images, boxes outside the image, zero-area boxes, and extreme aspect-ratio outliers. Log every removal.
3. **Deduplicate** with perceptual hashing (`imagehash`) **within and across datasets**.
4. **Leakage-safe splitting.** Frames from the same video or near-identical scenes must stay in one split. Split by source/sequence, not randomly by image.
5. **Hard negatives:** include road images with no potholes (manholes, patches, shadows, cracks, wet roads) so the model learns to reject lookalikes. Target about 5–10% negatives.
6. **Report dataset statistics:** counts per source and split, box-size distribution, image-resolution distribution, objects per image, and a sample grid. Save charts under `docs/figures/`.
7. Produce `data/data.yaml` and `DATA_CARD.md` (provenance, licences, splits, known biases).

### 4.4 Split protocol
- **Main split:** 70/20/10 (train/val/test) from the merged data, leakage-safe.
- **Cross-dataset hold-out (important for research):** keep **one entire dataset (or source) completely unseen** during training and use it only as an external test set. This measures real generalisation and is the strongest credibility point for scholars.
- The test set is used **once**, at the end, after all choices are frozen.

---

## 5. Training protocol (Kaggle notebook `notebooks/train_kaggle.ipynb`)

- Install pinned versions, print the GPU and library versions, and set **fixed seeds** (`seed=0`, `deterministic=True`).
- Starting config: `yolo12s.pt`, `imgsz=640`, `epochs=100`, `batch=16`, `patience=20`, AdamW or default auto optimiser, cosine LR, mosaic/HSV/flip augmentations.
- Save to `runs/` and export `best.pt`, `last.pt`, `results.csv`, `args.yaml`, curves and confusion matrix.
- Provide a CLI equivalent, `src/train.py --config configs/*.yaml`, so every run is reproducible from a config file.
- Handle Kaggle limits (about 12 h session, 30 h/week GPU): checkpoint with `save_period`, support `resume=True`, and note this in the README.
- Export deployable formats from `best.pt`: **ONNX** (and optionally OpenVINO for CPU) and record the latency of each.

---

## 6. Experimental design (this is what makes it research-grade)

### 6.1 Baselines (same data, same splits, same budget)
Compare YOLOv12 against free, Ultralytics-supported models so the choice of YOLOv12 is justified by evidence:

| Model | Purpose |
|---|---|
| YOLOv8s | Widely used reference baseline |
| YOLO11s | Recent predecessor |
| **YOLOv12s** | Proposed model |
| YOLOv12n / m | Size–accuracy trade-off |
| RT-DETR-l (Ultralytics) | Transformer-based comparison (optional if compute allows) |

Report for each: Precision, Recall, F1, mAP50, mAP50-95, AP-small/medium/large, params, GFLOPs, and latency (ms) on GPU and CPU.

### 6.2 Ablations (on YOLOv12s)
- Pretrained vs from-scratch weights.
- With vs without extra datasets (value of data enlargement).
- With vs without hard negatives.
- Input size 512 vs 640 vs 960.
- Augmentation on vs off, or mosaic on vs off.
- Standard inference vs **SAHI sliced inference** (small potholes).
- Test-time augmentation (TTA) on vs off.

### 6.3 Robustness study
Evaluate the frozen model on **synthetically degraded test images**: low light, motion blur, Gaussian noise, JPEG compression, rain/fog, glare/overexposure, and shadows. Plot mAP50 vs degradation severity. Where a free dataset provides it, also report per-condition results (day/night, wet/dry).

### 6.4 Generalisation
- In-distribution test mAP vs **cross-dataset (unseen source)** mAP. Report the gap.

### 6.5 Statistical rigour
- Train each headline model with **≥3 seeds** where compute allows. Report mean ± std.
- Compute **95% bootstrap confidence intervals** (1,000 resamples over test images) for Precision, Recall, F1, mAP50 and accuracy. Present results as `value [low, high]`.
- If two models are compared, use a paired bootstrap on per-image outcomes and state the p-value or CI of the difference. Do not claim "better" when the intervals overlap.

### 6.6 Error analysis
- Categorise errors: false positives (manholes, patches, shadows, cracks, stains), false negatives (small, occluded, water-filled, night), and localisation errors (IoU between 0.3 and 0.5).
- Save a gallery of the top false positives and top false negatives per category and discuss the causes.
- Plot detection performance versus pothole size.

### 6.7 Confidence calibration and threshold selection
- Plot reliability diagrams and compute the **expected calibration error (ECE)** for the detector's confidence.
- Choose the operating confidence threshold from the **validation** F1-vs-confidence curve (not the test set). Justify it in the report.

### 6.8 Explainability
- Generate **EigenCAM** heatmaps for true positives, false positives and false negatives. Provide them in the Analysis page and in the PDF report.

### 6.9 Metric definitions (must appear in the app and report)
| Metric | Definition |
|---|---|
| Precision | TP / (TP + FP) |
| Recall | TP / (TP + FN) |
| F1 | 2·P·R / (P + R) |
| mAP@0.5 | Mean average precision at IoU 0.5 |
| mAP@0.5:0.95 | Mean AP averaged over IoU 0.5 to 0.95 (step 0.05) |
| **Detection accuracy** | **TP / (TP + FP + FN)** at the chosen IoU (default 0.5) and confidence threshold |

**Footnote required wherever accuracy is shown:** *"Classification accuracy needs true negatives, which do not exist in object detection (the number of background boxes is unbounded). Detection accuracy here is defined as TP / (TP + FP + FN) and is reported alongside Precision, Recall, F1 and mAP, which are the standard detection metrics."*

All metrics are computed on the **test split** with the matching rule (IoU threshold, one-to-one assignment) documented in `docs/METHODOLOGY.md`.

---

## 7. Inference module (`src/inference.py`)

### 7.1 API
`detect(image, conf, iou, imgsz, tta=False, sahi=False) -> list[Detection]`. Each `Detection` holds: id, bbox (xyxy), confidence, area ratio (box area ÷ image area), cropped thumbnail, severity, and optional GPS.

### 7.2 Severity grading
Default heuristic by **relative box area**:
- **Low:** < 2% of image area
- **Medium:** 2–6%
- **High:** > 6%

Thresholds are configurable in the sidebar. **State clearly that this is a heuristic proxy**, because apparent size depends on camera distance and angle.

**Optional research extension (free):** use a monocular depth model (e.g. Depth Anything V2 Small, Apache-2.0) to estimate **relative** depth inside each box and combine it with area into a severity score. Label output as *relative*, not metric. Include only if time allows, and always disclose the limitation.

### 7.3 Visualisation
Boxes colour-coded by severity, with labels `Pothole #id · conf`.

### 7.4 Optional: SAHI
Sliced inference for small or distant potholes, switchable in the sidebar, with the speed cost shown.

### 7.5 Video
`src/video.py`: frame loop with the Ultralytics tracker (ByteTrack) so each physical pothole is **counted once**, not once per frame. Output FPS, running unique count, and an annotated video file.

---

## 8. Streamlit application (`app/`)

### 8.1 Global design
- Wide layout, custom CSS (`app/assets/style.css`), light and dark theme, consistent colour palette, severity colours (Low = amber, Medium = orange, High = red).
- Header with project title and a model badge ("YOLOv12s · mAP50 xx.x").
- Sidebar: model weights selector, confidence slider (default from validation F1 peak), IoU slider (0.45), image size, TTA and SAHI toggles, severity thresholds.
- `st.cache_resource` for model loading; clear error messages for a missing `best.pt`, unsupported files, no detections and no GPS.
- CPU fallback if no GPU is present.

### 8.2 Pages

**1. Detect (main)**, laid out like the owner's reference screenshot:
```
┌───────────────┬─────────────────────────────────┬────────────────────┐
│ SIDEBAR       │ Original | Annotated (toggle)   │ Detected Potholes  │
│ upload, model │ zoomable image                  │ (scrollable cards) │
│ sliders       │ ┌ Analysis Statistics ────────┐ │ #1 [thumb] 0.91 H  │
│ [▶ Run]       │ │ Model, Status, Inference ms │ │ #2 [thumb] 0.84 M  │
│               │ │ Detections, Conf threshold  │ │ #3 [thumb] 0.72 L  │
│               │ │ Severity counts             │ │ [CSV][Image][PDF]  │
│               │ └─────────────────────────────┘ │                    │
└───────────────┴─────────────────────────────────┴────────────────────┘
```
- The **right column** shows one card per detected pothole: cropped thumbnail, ID, confidence %, severity badge, box size. It is sortable by confidence or size, and selecting a card highlights its box on the image. It also shows a total count and download buttons.
- **Explain (Grad-CAM) toggle:** show the EigenCAM overlay for the current image.

**2. Batch**
Multi-upload or ZIP, progress bar, results table (file, count, mean confidence, worst severity), summary charts, and download of an annotated-images ZIP plus a CSV. Results are saved to history.

**3. Video / Webcam**
Upload or webcam (note: webcam works locally only). Live annotated stream, FPS, running unique count, saved annotated video for download.

**4. Analysis (research dashboard)**
- Metric cards for Precision, Recall, F1, mAP50, mAP50-95 and Accuracy, with **95% CI** and the accuracy footnote.
- Interactive Plotly charts: training curves (loss, mAP per epoch), PR curve, F1-vs-confidence, confusion matrix, size-vs-performance, calibration plot.
- **Model comparison table** (YOLOv8 / YOLO11 / YOLOv12 / etc.) with params, GFLOPs, latency and CIs.
- **Ablation table** and **robustness chart** (mAP vs degradation).
- **Error-analysis gallery** (top FPs and FNs) and EigenCAM examples.
- All of this reads from `outputs/results/*.json|csv`, never hard-coded numbers.

**5. Map**
Reads EXIF GPS from uploaded photos and plots potholes on a Folium map (marker colour = severity, popup = thumbnail, confidence, time). Manual lat/lon entry when EXIF is absent, and a heatmap layer toggle. Export to GeoJSON and CSV.

**6. History**
SQLite table (timestamp, source, count, severity breakdown, GPS, thumbnail). Filter, search, re-open, delete, export CSV.

**7. About / Methodology**
Project description, dataset provenance (from `DATA_CARD.md`), training setup, metric definitions, limitations and ethics notes.

### 8.3 PDF report (`src/report.py`)
Cover (title, date, model version), annotated image, detections table with severity, summary counts, GPS location (and map snapshot if available), model metrics with CIs and the accuracy footnote, and a short methodology and limitations paragraph.

---

## 9. Repository layout

```
cohort/
├── README.md
├── PROJECT_PROMPT.md          # this file
├── DATA_CARD.md               # datasets: source, licence, counts, bias notes
├── requirements.txt
├── .gitignore
├── configs/                   # one YAML per experiment (reproducibility)
├── data/                      # data.yaml (images gitignored)
├── notebooks/
│   ├── train_kaggle.ipynb
│   └── evaluate_research.ipynb
├── src/
│   ├── data_prep/             # convert, validate, dedup, split, stats
│   ├── train.py
│   ├── evaluate.py            # metrics + bootstrap CIs
│   ├── experiments/           # baselines, ablations, robustness, calibration
│   ├── explain.py             # EigenCAM
│   ├── inference.py
│   ├── video.py
│   ├── metrics.py
│   ├── gps.py
│   ├── history.py
│   └── report.py
├── app/
│   ├── main.py
│   ├── pages/
│   ├── components/
│   └── assets/style.css
├── models/                    # best.pt, exports (gitignored)
├── outputs/                   # results json/csv, annotated media, PDFs (gitignored)
├── docs/
│   ├── METHODOLOGY.md
│   ├── RESULTS.md
│   ├── LIMITATIONS.md
│   └── figures/
└── tests/
```

---

## 10. Reproducibility requirements

- Fixed seeds, pinned `requirements.txt`, one YAML config per experiment, and logged library/GPU versions.
- Every results file stores: config hash, dataset version/split hash, seed, library versions, date.
- `make`-style commands (or a documented script list) to reproduce: data prep → train → evaluate → experiments → app.
- Never report a number that is not produced by a script in the repo.

---

## 11. Quality requirements

- Type hints, docstrings, `ruff`/`black` clean.
- Unit tests for: severity function, accuracy/F1 formulas, metrics parsing, bootstrap CI function, EXIF GPS parsing, tracker-based unique counting, dataset de-dup and split leakage checks.
- The app never crashes on bad input: it shows a clear message.
- No secrets or large binaries committed (use `.gitignore`).
- The README includes setup, the Kaggle training steps, the run guide, screenshots and troubleshooting.

---

## 12. Deliverables for the scholar presentation

1. Working Streamlit app (all pages in Section 8).
2. Trained weights and exports (`best.pt`, ONNX).
3. `DATA_CARD.md`, `docs/METHODOLOGY.md`, `docs/RESULTS.md`, `docs/LIMITATIONS.md`.
4. A results package: baseline table, ablation table, robustness plot, cross-dataset gap, CI-annotated metrics, error-analysis gallery and EigenCAM figures.
5. A sample PDF report generated by the app.
6. A short demo script (what to click, in what order, in about 8 minutes) and a list of likely scholar questions with prepared answers.
7. A **limitations and future work** section covering, among others: relative (not metric) severity, geographic and camera bias in the datasets, heuristics in severity, and no real-time vehicle deployment.

---

## 13. Honesty and ethics rules

- Report results exactly as produced. If YOLOv12 does not beat a baseline, say so and discuss why.
- Never tune on the test set. Never report cherry-picked images as typical results.
- Cite every dataset and the Ultralytics/YOLOv12 sources, and respect licences.
- State that GPS data and road images may be sensitive: process locally and avoid storing identifying imagery (for example faces or number plates) beyond what the user chooses to keep.
- Label heuristics as heuristics.

---

## 14. Build phases and acceptance criteria

| # | Phase | Acceptance criteria |
|---|---|---|
| 1 | Skeleton | Layout, `requirements.txt`, `.gitignore`, lint/test config, README stub. `import ultralytics; YOLO('yolo12n.pt')` loads. |
| 2 | Data | Datasets chosen and licence-checked, curation pipeline runs, `data.yaml` and `DATA_CARD.md` produced, split-leakage test passes, stats figures saved. |
| 3 | Training | Kaggle notebook and `train.py` produce `best.pt` and curves for YOLOv12s, with seeds logged. |
| 4 | Evaluation suite | Metrics and bootstrap CIs on the test split and on the cross-dataset hold-out, with tests. |
| 5 | Experiments | Baselines, ablations, robustness, calibration, error analysis and EigenCAM complete, saved to `outputs/results/`. |
| 6 | Inference module | `detect()` with severity, TTA and SAHI options, plus the tracker-based video counter, with unit tests. |
| 7 | App: Detect | Matches the layout in 8.2, with the detections column, stats panel and downloads. |
| 8 | App: Analysis | Reads results files and shows all charts/tables with CIs and the accuracy footnote. |
| 9 | App: Batch, Video, Map, History | All work end to end with error handling. |
| 10 | PDF report | A generated report contains every item listed in 8.3. |
| 11 | Polish and docs | README, METHODOLOGY, RESULTS, LIMITATIONS, demo script, scholar Q&A. |

**Compute note:** phases 3 and 5 need a GPU and run on Kaggle (free). Phases 1, 2, 4 (on saved predictions) and 6–11 run on CPU. The agent prepares notebooks and scripts for Kaggle and the owner runs them and returns the artefacts (`best.pt`, `results.csv`, metrics JSON). The agent then integrates them.

---

## 15. Open items to confirm with the project owner

- **[CONFIRM]** Format, class names, size and licence of the owner's Kaggle dataset.
- **[CONFIRM]** Whether the supervisor expects a **paper-style write-up**; if so, add an `docs/PAPER_DRAFT.md` skeleton (abstract, related work, method, experiments, results, discussion).
- **[CONFIRM]** Whether the RT-DETR comparison and the depth-based severity extension are wanted, given the free-compute budget.
- **[CONFIRM]** Whether the demo runs on the owner's laptop (webcam works) or on a shared machine.
