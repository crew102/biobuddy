library(renv)

snapshot(prompt = FALSE)
lfile <- lockfile_read()
# Needs to be 1.3-4 on mac (local) but 1.6-5 on linux (for Docker) for some
# reason. So the offiical version is the version that works with Docker images
# and I just have a local version that works for me on my mac.
lfile$Packages$Matrix$Version <- "1.6-5"
lockfile_write(lfile)
