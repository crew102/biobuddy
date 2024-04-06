clean_raw_bios <- function(bios) {
  bios <- gsub("Meet [A-z]*", "", bios)
  bios <- gsub(" {2,}", " ", bios)
  bios <- gsub("\n", " ", bios)
  bios <- gsub(" {2,}", " ", bios)
  bios <- gsub("^ ", "", bios)
  bios <- gsub("^ +!|^! ", "", bios)
  bios <- gsub("^[0-9]* ", "", bios)
  bios <- gsub(" ,", ",", bios)
  ifelse(nchar(bios) < 300, NA, bios)
}

write_local_cropped_img <- function(id, url, directory) {
  if (!dir.exists(directory)) {
    dir.create(directory, recursive = TRUE)
  }
  cropped_fi <- file.path(directory, glue("{id}.png"))
  GET(url, write_disk(cropped_fi, overwrite = TRUE))
  raw_img <- magick::image_read(cropped_fi)
  cropcircles::crop_circle(raw_img, to = cropped_fi)
}
