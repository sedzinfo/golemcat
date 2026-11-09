##########################################################################################
# The example questionnaires of the app, one per IRT model (inst/extdata/examples/).
# Each one is a model fitted with mirt and written with questionnaire_from_mirt(), the
# same way a user makes their own csv; every scale is checked against mirt::probtrace.
#   IPIP-50 Big Five (rwf::df_ocean, 19,718 people): rsm, Rasch (PCM), graded, grsm (MGRM)
#   SAT12 science test (mirt::SAT12, 600 students):  3PL (scored with the key), nominal
# Run from the package folder:  Rscript data-raw/examples.R   (takes a few minutes)
##########################################################################################
pkgload::load_all(quiet = TRUE)
library(mirt)
out_dir <- file.path("inst", "extdata", "examples")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

check <- function(rows, fit) {
  bank <- read_questionnaire(rows)
  diff <- validate_questionnaire_against_mirt(bank, fit)
  message(sprintf("  %-18s %-8s max diff with mirt %.1e", rows$scale[1], rows$itemtype[1], diff))
  stopifnot(diff < 1e-8)
  rows
}

# IPIP-50 ---------------------------------------------------------------------------------
ipip <- utils::read.csv(file.path("inst", "extdata", "ipip50_items.csv"), check.names = FALSE, stringsAsFactors = FALSE)
statement <- ipip[[7]] # the statement without "I" (the second stem column)
lower_first <- function(x) paste0(tolower(substr(x, 1, 1)), substring(x, 2))
ipip$text <- paste("I", lower_first(statement))
likert <- read_likert(file.path("inst", "extdata", "ipip50_likert.csv"))$label
ocean <- c("Openness", "Conscientiousness", "Extraversion", "Agreeableness", "Neuroticism")
stem <- "How accurately does this statement describe you?"

responses <- rwf::df_ocean
ids <- unique(ipip$itemo)
x <- responses[, ids]
x[x == 0] <- NA # 0 = not answered
x <- x[rowSums(!is.na(x)) > 0, ]

ipip_fits <- function(itemtype) {
  lapply(ocean, function(trait) {
    it <- ipip[ipip$scale == trait, ]
    it <- it[order(as.integer(sub("^[A-Z]", "", it$itemo))), ]
    d <- x[, it$itemo]
    d[, it$reverse] <- 6 - d[, it$reverse] # reverse-keyed items scored the other way
    fit <- mirt(d, 1, itemtype = itemtype, verbose = FALSE, SE = FALSE, technical = list(NCYCLES = 20000))
    rows <- questionnaire_from_mirt(fit, trait,
      question = it$text, options = likert, reverse = it$reverse, stem = stem
    )
    check(rows, fit)
  })
}
for (m in list(c("rsm", "ipip50_rsm.csv"), c("Rasch", "ipip50_pcm.csv"), c("graded", "ipip50_grm.csv"), c("grsm", "ipip50_mgrm.csv"))) {
  message(m[1])
  write_questionnaire(ipip_fits(m[1]), file.path(out_dir, m[2]))
}

# SAT12 -----------------------------------------------------------------------------------
data(SAT12, package = "mirt")
sat <- SAT12
sat[sat == 8] <- NA # 8 = not answered
# the key of the mirt documentation, with item 32 corrected to option 3 as the
# documentation suggests (the nominal model shows that option 3 is the right one)
key <- c(1, 4, 5, 2, 3, 1, 2, 1, 3, 1, 2, 4, 2, 1, 5, 3, 4, 4, 1, 4, 3, 3, 4, 1, 3, 5, 1, 3, 1, 5, 4, 3)
sat_question <- sprintf("SAT12 science question %d", seq_len(ncol(sat)))
sat_options <- paste("Option", LETTERS[1:5])
sat_stem <- "The texts of the SAT12 questions are not public: choose one of the five options."

message("3PL")
fit <- mirt(key2binary(sat, key), 1, itemtype = "3PL", verbose = FALSE, SE = FALSE, technical = list(NCYCLES = 20000))
rows <- questionnaire_from_mirt(fit, "Science (SAT12)", question = sat_question, options = sat_options, key = key, stem = sat_stem)
write_questionnaire(check(rows, fit), file.path(out_dir, "sat12_3pl.csv"))

message("nominal")
fit <- mirt(sat, 1, itemtype = "nominal", verbose = FALSE, SE = FALSE, technical = list(NCYCLES = 20000))
rows <- questionnaire_from_mirt(fit, "Science (SAT12)", question = sat_question, options = sat_options, key = key, stem = sat_stem)
write_questionnaire(check(rows, fit), file.path(out_dir, "sat12_nrm.csv"))
