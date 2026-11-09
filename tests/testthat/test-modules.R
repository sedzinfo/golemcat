q <- ipip50()

test_that("Take the test: intro, answers until done, results, restart", {
  testServer(mod_test_server, args = list(questionnaire = q, se_threshold = 0.6), {
    expect_equal(rv$stage, "intro")
    session$setInputs(start = 1)
    expect_equal(rv$stage, "testing")
    # Next without an answer keeps the same item
    session$setInputs(submit = 1)
    expect_equal(nrow(rv$s$log), 0)
    n <- 1
    while (rv$stage == "testing") {
      n <- n + 1
      session$setInputs(response = "4", submit = n)
    }
    expect_equal(rv$stage, "done")
    expect_equal(rv$s$progress$status, rep("completed", 5))
    expect_match(as.character(output$page$html), "Your profile", fixed = TRUE)
    expect_match(as.character(output$page$html), "How is my score calculated?", fixed = TRUE)
    session$setInputs(explain = 1)
    expect_match(as.character(output$page$html), "Download PDF report", fixed = TRUE)
    session$setInputs(restart = 1)
    expect_equal(rv$stage, "intro")
  })
})

test_that("CAT: only the chosen traits, with the chosen threshold", {
  testServer(mod_lab_server, args = list(questionnaire = q), {
    session$setInputs(scales_include = c("Neuroticism", "Openness"), se_threshold = 0.5, start = 1)
    # in the order of the bank, not the order ticked
    expect_equal(rv$s$scales, c("Openness", "Neuroticism"))
    expect_equal(rv$s$se_threshold, 0.5)
    session$setInputs(response = "2", submit = 1)
    expect_equal(nrow(rv$s$log), 1)
    expect_match(as.character(output$overall_ui$html), "1 of 20 statements", fixed = TRUE)
    expect_s3_class(output$traj_plot, "json")
  })
})

test_that("the explanation shows one row per trait with the numbers of the profile", {
  s <- cat_start(q$bank, unique(q$bank$scale), se_threshold = 0.6)
  while (s$stage == "testing") s <- cat_answer(s, 4)
  res <- cat_results(s)
  html <- as.character(golemcat:::test_explain(res, q$bank))
  expect_match(html, "How your scores are calculated", fixed = TRUE)
  expect_equal(lengths(regmatches(html, gregexpr("<tr>", html))), nrow(res) + 1)
  for (i in seq_len(nrow(res))) expect_match(html, sprintf("%+.2f", res$theta[i]), fixed = TRUE)
})

test_that("the PDF report: one row of data per trait, and a pdf when typst is there", {
  s <- cat_start(q$bank, unique(q$bank$scale), se_threshold = 0.6)
  while (s$stage == "testing") s <- cat_answer(s, 2)
  res <- cat_results(s)
  d <- golemcat:::report_data(res, q$bank)
  expect_equal(d$scale, res$scale)
  expect_true(all(d$lo <= d$pct & d$pct <= d$hi))
  expect_true(all(nzchar(d$reading)))
  skip_if(is.null(typst_command()), "typst is not installed")
  f <- tempfile(fileext = ".pdf")
  report_pdf(res, f, q$bank, date = "1 January 2026")
  expect_true(file.exists(f))
  expect_identical(readBin(f, "raw", 4), charToRaw("%PDF"))
})
