##########################################################################################
# DIRECTORIES
##########################################################################################
# R CMD check golemcat
# R CMD Rd2pdf golemcat
# R CMD build golemcat --resave-data
library(devtools)
library(roxygen2)
rm(list = ls())
graphics.off()
cat("\014")
##########################################################################################
# FUNCTIONS PACKAGE
##########################################################################################
directory <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(directory)
if ("golemcat" %in% loadedNamespaces()) unloadNamespace("golemcat") # an old version still loaded would make the reinstalled one look corrupt
if ("golemcat" %in% rownames(installed.packages())) remove.packages("golemcat")
document()
test()
install()
library(golemcat)

pkgdown::build_site(getwd())
system("R CMD Rd2pdf . --force --no-preview --output=golemcat.pdf")
if (.Platform$OS.type == "windows") shell.exec("golemcat.pdf") else system("evince golemcat.pdf")
system("R CMD build . --resave-data")

golemcat::run_app()
