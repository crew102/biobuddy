## R: Image Processing

Helpers to resize, crop, and generate circular headshots using a Python detector.

### Resizing

- **`maybe_resize_image(local_path, resize_if_greater = ...)`**: Overwrites `local_path` with a resized version if the file is larger than threshold.

Example:

```r
maybe_resize_image("/tmp/0.jpg")
```

### Cropping

- **`head_aware_crop_circle(original_img_path, cr, cropped_path)`**: Crops a square region expanded from detector coords and writes a circular PNG to `cropped_path`.
- **`crop_headshots(detector, raw_paths, cropped_paths)`**: Batch crop; returns `NULL` on success or a numeric vector of IDs that failed.
- **`crop_alternate_imgs(detector, alternatives, path_df)`**: Attempts alternate images per failed ID; returns IDs still failing.

Examples:

```r
# Assume py$detector was created in .onLoad
failures <- crop_headshots(
  detector,
  raw_paths = c("/tmp/100.jpg", "/tmp/101.jpg"),
  cropped_paths = c("/tmp/100-c.png", "/tmp/101-c.png")
)

if (!is.null(failures)) {
  # Try alternates using a data.frame with columns: id, full
  remaining <- crop_alternate_imgs(detector, alternatives_df, path_df)
}
```

