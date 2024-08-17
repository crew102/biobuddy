#' @export
BUCKET <- NULL

.onLoad <- function(libname, pkgname) {
  source_python(here::here("inst/python/s3.py"))
  source_python(here::here("inst/python/secrets.py"))
  source_python(here::here("inst/python/detector.py"))
  BUCKET <<- py$get_catchall_bucket_name()
}
