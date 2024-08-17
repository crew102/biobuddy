library(renv)
library(devtools)

document()

necessary_packages <- dependencies()$Package
snapshot(packages = necessary_packages, prompt = FALSE)
clean()
