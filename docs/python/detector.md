## Python: Detector (`inst/python/detector.py`)

Minimal wrapper around a dlib-style face detector to return bounding box coordinates.

- **`one_detection(detector, img_path)`** → `(x1, y1, x2, y2)` for the first detection.

Example (R via reticulate):

```r
reticulate::source_python("inst/python/detector.py")
coords <- py$one_detection(detector, "/tmp/0.jpg")
```

