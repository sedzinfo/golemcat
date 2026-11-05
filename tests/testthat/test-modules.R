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
