# THIS OVERWRITES THE FILE
  maybe_resize_image <- function(local_path,
                                 resize_if_greater = ifelse(is_local(), 100000, 400000),
                                 px_to_resize_to = ifelse(is_local(), "200x", "700x")) {
  img <- magick::image_read(local_path)
  info <- magick::image_info(img)
  if (info$filesize > resize_if_greater) {
    print(glue("resizing {local_path}"))
    resized <- magick::image_resize(img, px_to_resize_to)
    magick::image_write(resized, local_path)
  }
}

zero_if_negative <- function(x) {
  ifelse(x < 0, 0, x)
}

head_aware_crop_circle <- function(original_img_path, cr, cropped_path) {
  cr <- zero_if_negative(cr)
  x1 <- cr[1]
  y1 <- cr[2]

  x2 <- cr[3]
  y2 <- cr[4]

  raw_img <- magick::image_read(original_img_path)
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

  head_cropped <- magick::image_crop(
    raw_img,
    geometry = glue("{wd}x{ht}+{x_off}+{y_off}")
  )

  cropcircles::crop_circle(
    head_cropped,
    to = cropped_path
  )
}

crop_headshots <- function(detector, raw_paths, cropped_paths) {

  one_try <- function(raw_path, cropped_path) {
    tryCatch({
      # attempt to detect head coordinates
      cr <- py$one_detection(detector, raw_path)
      x <- head_aware_crop_circle(raw_path, cr = unlist(cr), cropped_path)
      NULL
    },
    error = function(e) {
      raw_path
    })
  }

  failures <- pbapply::pbmapply(
    one_try,
    raw_path = raw_paths,
    cropped_path = cropped_paths,
    USE.NAMES = FALSE
  )
  failures <- unlist(failures)
  if (length(failures) == 0) {
    NULL
  } else {
    as.numeric(gsub("\\..*", "", basename(failures)))
  }

}

crop_alternate_imgs <- function(detector, alternatives, path_df) {

  success <- c()
  failure_ids <- unique(alternatives$id)
  TEMP_RAW <- "0.jpg"
  on.exit(try(file.remove(TEMP_RAW)))

  for (i in failure_ids) {
    this_pup <- alternatives %>% filter(id == i)

    for (one_pic in this_pup$full) {
      try({
        one_img <- httr2::req_perform_sequential(
          list(httr2::request(one_pic)),
          on_error = "stop",
          paths = TEMP_RAW
        )
        maybe_resize_image(TEMP_RAW)
        local_failure <- crop_headshots(detector, TEMP_RAW, TEMP_RAW)
        if (length(local_failure) == 0) {
          file.copy(
            TEMP_RAW,
            path_df[path_df$id == i, "cropped_path"][[1]],
            overwrite = TRUE
          )
          success <- c(success, i)
          break
        }
      })
    }
  }

  failure_ids[!(failure_ids %in% success)]
}
