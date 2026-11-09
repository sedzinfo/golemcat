ex <- example_questionnaires()
banks <- lapply(ex, read_questionnaire)
catr_model <- c(rsm = "RSM", pcm = "PCM", grm = "GRM", mgrm = "MGRM", dichotomous = NA, nrm = "NRM")

test_that("one example for each of the six models, every one readable", {
  expect_length(ex, 6)
  expect_true(all(file.exists(ex)))
  expect_setequal(vapply(banks, function(b) unique(b$model), ""), irt_models()$model)
  for (b in banks) {
    expect_true(all(b$n_options == b$n_cat | (b$model == "dichotomous" & !is.na(b$key))))
    expect_true(all(lengths(b$options) == b$n_options))
  }
  # only the SAT12 texts are not public
  is_sat <- grepl("SAT12", names(banks))
  expect_true(all(vapply(banks[is_sat], function(b) all(!b$public), TRUE)))
  expect_true(all(vapply(banks[!is_sat], function(b) all(b$public), TRUE)))
})

test_that("the engines give the same results as catR on every example", {
  skip_if_not_installed("catR")
  set.seed(42)
  for (b in banks) {
    d <- b[b$scale == b$scale[1], ]
    mat <- golemcat:::bank_matrix(d)
    model <- catr_model[[d$model[1]]]
    if (is.na(model)) model <- NULL
    e <- golemcat:::engine_of(d$model[1])
    for (th in c(-2.5, 0, 1.3)) {
      ours <- e$pi(th, mat)$Pi
      theirs <- catR::Pi(th, mat, model = model)$Pi
      if (is.null(model)) theirs <- cbind(1 - theirs, theirs)
      expect_equal(unname(ours), unname(theirs), tolerance = 1e-10)
    }
    j <- seq_len(min(8, nrow(mat)))
    x <- vapply(j, function(i) sample(0:(d$n_cat[i] - 1), 1), 0)
    prior <- c(d$prior_mean[1], d$prior_sd[1])
    th <- e$eap(mat[j, , drop = FALSE], x, priorPar = prior)
    expect_equal(th, catR::eapEst(mat[j, , drop = FALSE], x, model = model, priorPar = prior), tolerance = 1e-10)
    expect_equal(
      e$se(th, mat[j, , drop = FALSE], x, priorPar = prior),
      catR::eapSem(th, mat[j, , drop = FALSE], x, model = model, priorPar = prior),
      tolerance = 1e-10
    )
    expect_equal(
      e$next_item(0, mat, out = 1:2)$item,
      catR::nextItem(mat, model = model, theta = 0, out = 1:2, criterion = "MFI")$item
    )
  }
})

test_that("a whole test runs on every example", {
  set.seed(7)
  for (b in banks) {
    s <- cat_start(b, unique(b$scale), se_threshold = 0.5)
    while (s$stage == "testing") s <- cat_answer(s, sample(length(cat_item(s)$options), 1))
    r <- cat_results(s)
    expect_true(all(r$status == "completed"))
    expect_true(all(is.finite(r$theta) & r$se > 0))
    expect_true(all(s$log$score >= 0))
  }
})

test_that("answers are scored by key, by reversal and as given", {
  sat <- banks[["SAT12 science test · 3PL"]]
  row <- sat[1, ]
  expect_equal(golemcat:::score_answer(row, row$key), 1L)
  expect_equal(golemcat:::score_answer(row, if (row$key == 1) 2L else 1L), 0L)
  rsm <- banks[[1]]
  rev <- rsm[rsm$reverse, ][1, ]
  fwd <- rsm[!rsm$reverse, ][1, ]
  expect_equal(golemcat:::score_answer(fwd, 5L), 4L)
  expect_equal(golemcat:::score_answer(rev, 5L), 0L)
  nrm <- banks[["SAT12 science test · Nominal response model (NRM)"]]
  expect_equal(golemcat:::score_answer(nrm[1, ], 3L), 2L)
  expect_error(cat_answer(cat_start(sat, "Science (SAT12)"), 6), "1 to 5")
})

test_that("broken files stop with the row and the problem", {
  d <- utils::read.csv(ex[[3]], check.names = FALSE, stringsAsFactors = FALSE)
  expect_error(read_questionnaire(d[, setdiff(names(d), "itemtype")]), "missing columns: itemtype")
  bad <- d; bad$itemtype[2] <- "gpcm"
  expect_error(read_questionnaire(bad), "row 3: itemtype 'gpcm'")
  bad <- d; bad$option5 <- NA
  expect_error(read_questionnaire(bad), "4 answer options but the model has 5 categories")
  bad <- d; bad$d1[4] <- NA
  expect_error(read_questionnaire(bad), "row 5")
  bad <- d; bad$prior_sd[2] <- 2
  expect_error(read_questionnaire(bad), "prior_mean and prior_sd")
  mixed <- d[1:6, ]
  mixed$d0 <- NA
  mixed$itemtype[4:6] <- "Rasch"
  mixed$d0[4:6] <- 0
  expect_error(read_questionnaire(mixed), "one model per scale")
})

test_that("questionnaire_from_mirt writes a csv that reads back and matches mirt", {
  skip_if_not_installed("mirt")
  set.seed(1)
  resp <- mirt::simdata(matrix(runif(6, 1, 2)), matrix(c(1, 0, -1), 6, 3, byrow = TRUE) + rnorm(6, sd = 0.3), 400, itemtype = "graded")
  fit <- mirt::mirt(as.data.frame(resp), 1, itemtype = "graded", verbose = FALSE)
  q <- questionnaire_from_mirt(fit, "Simulated", options = c("Never", "Sometimes", "Often", "Always"))
  f <- tempfile(fileext = ".csv")
  write_questionnaire(q, f)
  b <- read_questionnaire(f)
  expect_equal(b$options[[1]], c("Never", "Sometimes", "Often", "Always"))
  expect_lt(validate_questionnaire_against_mirt(b, fit), 1e-10)
})
