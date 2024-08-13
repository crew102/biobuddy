#' @import reticulate

maybe_resize_image <- function(local_path, resize_if_greater = 500000,
                               px_to_resize_to = "800x") {
  img <- magick::image_read(local_path)
  info <- magick::image_info(img)
  if (info$filesize > resize_if_greater) {
    print(glue('resizing {local_path}'))
    resized <- magick::image_resize(img, px_to_resize_to)
    magick::image_write(resized, local_path)
  }
}

# Backup function if face detection fails
naive_crop_circle <- function(local_path) {
  raw_img <- magick::image_read(local_path)
  cropcircles::crop_circle(raw_img, to = local_path)
}

zero_if_negative <- function(x) {
  ifelse(x < 0, 0, x)
}

head_aware_crop_circle <- function(local_path, cr) {
  cr <- zero_if_negative(cr)
  x1 <- cr[1]
  y1 <- cr[2]

  x2 <- cr[3]
  y2 <- cr[4]

  raw_img <- magick::image_read(local_path)
  inf2 <- magick::image_info(raw_img)

  tow_mins <- c(
    min(c(x1, inf2$width - x2)),
    min(c(y1, inf2$height - y2))
  )

  to_add <- min(tow_mins)

  # new coords:
  x1_new <- x1 - to_add
  x2_new <- x2 + to_add
  y1_new <- y1 - to_add
  y2_new <- y2 + to_add

  wd <- x2_new - x1_new
  ht <- y2_new - y1_new
  x_off <- x1_new #+ wd/ 2
  y_off <- y1_new #+ ht/ 2

  some_img <- magick::image_crop(
    raw_img,
    geometry = glue("{wd}x{ht}+{x_off}+{y_off}")
  )

  cropcircles::crop_circle(
    some_img,
    to = local_path
  )
}
