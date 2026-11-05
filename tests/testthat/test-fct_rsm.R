bank <- matrix(c(-0.560, -0.230, 1.559, 0.071, 0.129,
                 rep(1.715, 5), rep(0.461, 5), rep(-1.265, 5), rep(-0.687, 5)),
               nrow = 5)
x <- c(4, 3, 2, 1, 0)

test_that("density_function() is dnorm()", {
  v <- seq(-4, 4, by = 0.25)
  expect_equal(density_function(v, 0.5, 1.3), dnorm(v, 0.5, 1.3))
})

test_that("integrate_cat() integrates by the trapezoidal rule", {
  x <- seq(0, 1, length = 101)
  expect_equal(integrate_cat(x, x), 0.5)
  expect_equal(integrate_cat(x, x^2), 1 / 3, tolerance = 1e-4)
})

test_that("Pi_rsm() gives probabilities that add up to 1, with derivatives that add up to 0", {
  p <- Pi_rsm(0.7, bank)
  expect_equal(dim(p$Pi), c(5, 5))
  expect_equal(unname(rowSums(p$Pi)), rep(1, 5))
  expect_equal(unname(rowSums(p$dPi)), rep(0, 5))
})

test_that("Ii_rsm() is positive, and the same curve shifted by lambdaj", {
  i <- Ii_rsm(0.7, bank)$Ii
  expect_true(all(i > 0))
  # under the RSM an item's information at theta equals the first item's at theta shifted by the lambda gap
  expect_equal(Ii_rsm(0.7, bank[2, ])$Ii, Ii_rsm(0.7 - (bank[2, 1] - bank[1, 1]), bank[1, ])$Ii)
})

test_that("next_item_rsm() picks the most informative item left", {
  info <- Ii_rsm(0.3, bank)$Ii
  expect_equal(next_item_rsm(0.3, bank)$item, which.max(info))
  left <- setdiff(1:5, which.max(info))
  expect_equal(next_item_rsm(0.3, bank, out = which.max(info))$item, left[which.max(info[left])])
  expect_error(next_item_rsm(0, bank, out = 1:5), "no item left")
})

test_that("EAP estimate and standard error match catR (pinned values)", {
  theta <- eap_est_rsm(bank, x)
  expect_equal(theta, 0.0916537776, tolerance = 1e-9)
  expect_equal(eap_se_rsm(theta, bank, x), 0.3218064989, tolerance = 1e-9)
})

test_that("the engine matches catR when it is installed", {
  skip_if_not_installed("catR")
  expect_equal(unname(Pi_rsm(0.7, bank)$Pi), unname(catR::Pi(0.7, bank, model = "RSM")$Pi))
  expect_equal(Ii_rsm(0.7, bank)$Ii, as.numeric(catR::Ii(0.7, bank, model = "RSM")$Ii))
  expect_equal(eap_est_rsm(bank, x), catR::eapEst(bank, x, model = "RSM"))
  expect_equal(next_item_rsm(-1.2, bank)$item, catR::nextItem(bank, model = "RSM", theta = -1.2, criterion = "MFI")$item)
})
