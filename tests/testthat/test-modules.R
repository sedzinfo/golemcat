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
    expect_match(as.character(output$page$html), "Download PDF report", fixed = TRUE)
    session$setInputs(restart = 1)
    expect_equal(rv$stage, "intro")
  })
})

test_that("CAT: an example questionnaire, only the chosen scales, with the chosen threshold", {
  testServer(mod_lab_server, {
    session$setInputs(source = names(example_questionnaires())[3]) # GRM
    session$flushReact()
    expect_equal(unique(loaded()$bank$model), "grm")
    session$setInputs(scales_include = c("Neuroticism", "Openness"), se_threshold = 0.5, start = 1)
    # in the order of the bank, not the order ticked
    expect_equal(rv$s$scales, c("Openness", "Neuroticism"))
    expect_equal(rv$s$se_threshold, 0.5)
    expect_equal(rv$s$model, "grm")
    session$setInputs(response = "2", submit = 1)
    expect_equal(nrow(rv$s$log), 1)
    expect_match(as.character(output$overall_ui$html), "1 of 20 items", fixed = TRUE)
    expect_s3_class(output$traj_plot, "json")
  })
})

test_that("CAT: the SAT12 examples show the options and the key", {
  testServer(mod_lab_server, {
    session$setInputs(source = "SAT12 science test \u00b7 3PL")
    session$flushReact()
    session$setInputs(scales_include = "Science (SAT12)", se_threshold = 0.5, start = 1)
    html <- as.character(output$question_ui$html)
    expect_match(html, "Option E", fixed = TRUE)
    expect_match(html, "Correct answer", fixed = TRUE)
    key <- rv$s$scale_meta$key[rv$s$current_item]
    session$setInputs(response = as.character(key), submit = 1)
    expect_equal(rv$s$log$score, 1L)
  })
})

test_that("CAT: an uploaded csv, and a broken one", {
  testServer(mod_lab_server, {
    session$setInputs(source = "upload")
    session$flushReact()
    expect_null(loaded()$bank)
    f <- example_questionnaires()[["SAT12 science test \u00b7 Nominal response model (NRM)"]]
    session$setInputs(upload = list(datapath = f, name = "mine.csv"))
    expect_equal(unique(loaded()$bank$model), "nrm")
    bad <- tempfile(fileext = ".csv")
    d <- utils::read.csv(f, check.names = FALSE)
    d$itemtype[3] <- "gpcm"
    utils::write.csv(d, bad, row.names = FALSE)
    session$setInputs(upload = list(datapath = bad, name = "bad.csv"))
    expect_null(loaded()$bank)
    expect_match(loaded()$error, "row 4", fixed = TRUE)
  })
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
