test_that("ipip50() has 50 items, 10 per trait, in OCEAN order, and 5 answer options", {
  q <- ipip50()
  expect_equal(nrow(q$bank), 50)
  expect_equal(unique(q$bank$scale),
               c("Openness", "Conscientiousness", "Extraversion", "Agreeableness", "Neuroticism"))
  expect_true(all(table(q$bank$scale) == 10))
  expect_equal(sum(q$bank$reverse), 18)
  expect_equal(q$likert$value, 1:5)
  # mirt's c becomes the engine's lambdaj with the sign flipped
  raw <- utils::read.csv(app_sys("extdata", "ipip50_items.csv"))
  expect_equal(sort(q$bank$lambdaj), sort(-raw$c))
})

write_bank <- function(d) {
  f <- tempfile(fileext = ".csv")
  utils::write.csv(d, f, row.names = FALSE, fileEncoding = "UTF-8")
  f
}
good <- utils::read.csv(system.file("extdata", "ipip50_items.csv", package = "golemcat"))

test_that("read_item_bank() stops with a message naming the problem", {
  expect_error(read_item_bank(write_bank(good[, names(good) != "prior_sd"])), "missing columns: prior_sd")
  d <- good; d$a1[3] <- 1.2
  expect_error(read_item_bank(write_bank(d)), "a1 != 1")
  d <- good; d$b2[1] <- d$b2[1] + 0.1
  expect_error(read_item_bank(write_bank(d)), "must be the same for every item")
  d <- good; d$prior_sd[2] <- -1
  expect_error(read_item_bank(write_bank(d)), "invalid parameters in rows 3")
  d <- good; d$b5 <- 1
  expect_error(read_item_bank(write_bank(d)), "more than 4 thresholds")
  d <- good; d$reverse[1] <- "maybe"
  expect_error(read_item_bank(write_bank(d)), "reverse must be TRUE or FALSE")
})

test_that("read_likert() needs exactly the values 1 to 5", {
  f <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(value = 1:4, label = letters[1:4]), f, row.names = FALSE)
  expect_error(read_likert(f), "value must be 1, 2, 3, 4, 5")
  utils::write.csv(data.frame(value = 5:1, label = letters[1:5]), f, row.names = FALSE)
  expect_equal(read_likert(f)$label, rev(letters[1:5]))
})
