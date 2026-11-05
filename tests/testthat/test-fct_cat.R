q <- ipip50()

test_that("a session gives items of one trait at a time and ends after the last trait", {
  s <- cat_start(q$bank, c("Openness", "Neuroticism"), se_threshold = 0.45)
  expect_equal(s$stage, "testing")
  expect_equal(cat_item(s)$scale, "Openness")
  while (s$stage == "testing") s <- cat_answer(s, 3)
  expect_equal(s$stage, "done")
  expect_null(cat_item(s))
  expect_equal(s$progress$status, c("completed", "completed"))
  expect_equal(unique(s$log$scale), c("Openness", "Neuroticism"))
  expect_error(cat_answer(s, 3), "already done")
})

test_that("each estimate is the EAP of the answers so far, with the trait's prior, standardized", {
  s <- cat_start(q$bank, "Extraversion", se_threshold = 0.10)
  answers <- c(5, 4, 2, 5)
  for (a in answers) s <- cat_answer(s, a)
  d <- q$bank[q$bank$scale == "Extraversion", ]
  mat <- as.matrix(d[s$administered, c("lambdaj", "delta1", "delta2", "delta3", "delta4")])
  # reversed items are scored 5 - answer, the others answer - 1
  xs <- ifelse(d$reverse[s$administered], 5 - answers, answers - 1)
  sd <- d$prior_sd[1]
  theta <- eap_est_rsm(mat, xs, priorPar = c(0, sd), lower = -6 * sd, upper = 6 * sd, nqp = 61)
  expect_equal(s$progress$theta, theta / sd)
  se <- eap_se_rsm(theta, mat, xs, priorPar = c(0, sd), lower = -6 * sd, upper = 6 * sd, nqp = 61)
  expect_equal(s$progress$se, se / sd)
  expect_equal(nrow(s$log), 4)
})

test_that("a trait stops at the SE threshold, or when its items run out", {
  s <- cat_start(q$bank, "Agreeableness", se_threshold = 0.01) # never reached
  while (s$stage == "testing") s <- cat_answer(s, 4)
  expect_equal(s$progress$answered, 10)
  s <- cat_start(q$bank, "Agreeableness", se_threshold = 0.69) # reached quickly
  while (s$stage == "testing") s <- cat_answer(s, 4)
  expect_lt(s$progress$answered, 10)
  expect_lte(s$progress$se, 0.69)
})

test_that("reversed items move the estimate the other way", {
  rev_item <- which(q$bank$scale == "Neuroticism" & q$bank$reverse)[1]
  plain_item <- which(q$bank$scale == "Neuroticism" & !q$bank$reverse)[1]
  one <- function(i, answer) {
    s <- cat_start(q$bank, "Neuroticism", 0.01)
    s$current_item <- match(i, which(q$bank$scale == "Neuroticism"))
    cat_answer(s, answer)$progress$theta
  }
  expect_gt(one(plain_item, 5), 0) # "Get stressed out easily": very accurate -> higher
  expect_lt(one(rev_item, 5), 0)   # "Am relaxed most of the time": very accurate -> lower
})

test_that("cat_results() gives percentiles, and bad input is refused", {
  # "very accurate" on the plain items and "very inaccurate" on the reversed ones: high Openness
  s <- cat_start(q$bank, "Openness", 0.5)
  while (s$stage == "testing") s <- cat_answer(s, if (s$scale_meta$reverse[s$current_item]) 1 else 5)
  r <- cat_results(s)
  expect_equal(r$percentile, 100 * pnorm(r$theta))
  expect_gt(r$percentile, 50)
  expect_error(cat_start(q$bank, "Honesty"), "not in the item bank")
  expect_error(cat_start(q$bank, character(0)), "at least one scale")
  expect_error(cat_answer(cat_start(q$bank, "Openness"), 6), "must be 1, 2, 3, 4 or 5")
})

test_that("plot_trajectory() draws a plotly chart, one trace per trait in each panel", {
  s <- cat_start(q$bank, c("Openness", "Extraversion"), 0.6)
  while (s$stage == "testing") s <- cat_answer(s, 2)
  p <- plot_trajectory(s)
  expect_s3_class(p, "plotly")
  b <- plotly::plotly_build(p)$x
  expect_length(b$data, 5) # 2 traits x (theta, SE), and the stopping SE
  points <- Filter(function(t) !identical(t$name, "stopping SE"), b$data)
  expect_equal(sum(unlist(lapply(points, function(t) length(t$x)))), 2 * nrow(s$log))
  stop_line <- Filter(function(t) identical(t$name, "stopping SE"), b$data)[[1]]
  expect_equal(unique(stop_line$y), 0.6)
  # dark mode: light text
  expect_equal(plotly::plotly_build(plot_trajectory(s, dark = TRUE))$x$layout$font$color, "#dee2e6")
  expect_error(plot_trajectory(cat_start(q$bank, "Openness")), "no answers yet")
})
