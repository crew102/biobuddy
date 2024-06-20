library(renv)

snapshot()
lfile <- lockfile_read()
lfile$Packages$Matrix$Version <- "1.6-5"
lockfile_write(lfile)
