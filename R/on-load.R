BUCKET <- NULL

.onLoad <- function(libname, pkgname) {
  reticulate::source_python(here::here("inst/python/s3.py"))
  BUCKET <<- reticulate::py$get_catchall_bucket_name()
}
