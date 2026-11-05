##########################################################################################
# RATING SCALE MODEL: response probabilities, information, item selection and EAP
# estimation. Each function returns the same result as its catR counterpart
# (catR::Pi, Ii, nextItem, eapEst, eapSem with model = "RSM").
##########################################################################################
#' Normal density
#'
#' The density of the normal distribution, used as the prior of the EAP estimate.
#' It returns the same result as \code{stats::dnorm()}.
#'
#' @param x Numeric vector of values at which the density is evaluated.
#' @param mean Mean of the distribution.
#' @param sd Standard deviation of the distribution.
#'
#' @return A numeric vector of densities.
#' @family rating scale model
#' @export
#'
#' @examples
#' v <- seq(-3, 3, by = 0.1)
#' all.equal(density_function(v), dnorm(v))
density_function <- function(x, mean = 0, sd = 1) {
  # exp(1), not the literal 2.71828, which is accurate to 6 digits only and moves the EAP
  # estimate in the 7th decimal
  e <- exp(1)
  result <- 1 / (sqrt(2 * pi) * sd) * e^-((x - mean)^2 / (2 * sd^2))
  return(result)
}
##########################################################################################
# INTEGRATION
##########################################################################################
#' Numerical integration by the trapezoidal rule
#'
#' Integrates \code{y = f(x)} over the points \code{x}, as \code{catR::integrate.catR()} does.
#'
#' @param x Numeric vector of the points of integration, in increasing order.
#' @param y Numeric vector of the values of the function at \code{x}.
#'
#' @return The integral, a number.
#' @family rating scale model
#' @export
#'
#' @examples
#' x <- seq(from = -3, to = 3, length = 33)
#' integrate_cat(x = x, y = exp(x))
#' exp(3) - exp(-3) # the exact value
integrate_cat <- function(x, y) {
  hauteur <- x[2:length(x)] - x[1:(length(x) - 1)]
  base <- apply(cbind(y[1:(length(y) - 1)], y[2:length(y)]), 1, mean)
  result <- sum(base * hauteur)
  return(result)
}
##########################################################################################
# RESPONSE PROBABILITIES
##########################################################################################
#' Category response probabilities of the rating scale model
#'
#' The probability of each answer category, and its first derivative, at an ability
#' value, under the rating scale model of Andrich (1978):
#' \deqn{P(X = k \mid \theta) = \frac{\exp \sum_{t=1}^{k} D(\theta - (\lambda_j + \delta_t))}
#'   {\sum_{h=0}^{m} \exp \sum_{t=1}^{h} D(\theta - (\lambda_j + \delta_t))}}
#' with the empty sum of category 0 equal to zero. It returns the same result as
#' \code{catR::Pi(model = "RSM")}.
#'
#' @param theta Ability.
#' @param bank Matrix of item parameters, one row per item: column 1 is the location
#'   of the item \eqn{\lambda_j}, the other columns the thresholds \eqn{\delta_1} to
#'   \eqn{\delta_m}, the same in every row (which makes it the rating scale and not
#'   the partial credit model). A 5-point Likert item, scored 0 to 4, needs 5 columns.
#' @param D Metric constant, 1 or 1.702.
#'
#' @return A list: \code{Pi}, the probabilities, one row per item and one column per
#'   category, and \code{dPi}, their first derivatives.
#' @family rating scale model
#' @export
#'
#' @examples
#' bank <- matrix(c(-0.560, -0.230, 1.559, 0.071, 0.129,
#'                  rep(1.715, 5), rep(0.461, 5), rep(-1.265, 5), rep(-0.687, 5)),
#'                nrow = 5,
#'                dimnames = list(1:5, c("lambdaj", "delta1", "delta2", "delta3", "delta4")))
#' Pi_rsm(theta = 0, bank)$Pi
#' rowSums(Pi_rsm(theta = 0, bank)$Pi) # each item's probabilities add up to 1
Pi_rsm <- function(theta, bank, D = 1) {
  bank <- rbind(bank)
  ncat <- ncol(bank)
  Pi <- dPi <- matrix(NA, nrow(bank), ncat)
  for (i in 1:nrow(bank)) {
    dj <- v <- 0
    for (t in 1:(ncat - 1)) {
      dj <- c(dj, dj[t] + D * (theta - (bank[i, 1] + bank[i, t + 1])))
      v <- c(v, t)
    }
    v <- v[!is.na(dj)]
    dj <- dj[!is.na(dj)]
    gamma <- exp(dj)
    dgamma <- gamma * v
    sum_gamma <- sum(gamma)
    sum_dgamma <- sum(dgamma)
    n <- length(gamma)
    Pi[i, 1:n] <- gamma / sum_gamma
    dPi[i, 1:n] <- dgamma / sum_gamma - gamma * sum_dgamma / sum_gamma^2
  }
  colnames(Pi) <- colnames(dPi) <- paste("cat", 0:(ncat - 1), sep = "")
  rownames(Pi) <- rownames(dPi) <- paste("Item", 1:nrow(bank), sep = "")
  result <- list(Pi = Pi, dPi = dPi)
  return(result)
}
##########################################################################################
# ITEM INFORMATION
##########################################################################################
#' Item information of the rating scale model
#'
#' The Fisher information of each item at an ability value,
#' \eqn{I_j(\theta) = \sum_k (dP_{jk}/d\theta)^2 / P_{jk}}. Under the rating scale
#' model every item shares the same thresholds, so every information curve has the
#' same shape and differs only by a shift of \eqn{\lambda_j}. The test information is
#' the sum of the item information. It returns the same result as
#' \code{catR::Ii(model = "RSM")}.
#'
#' @inheritParams Pi_rsm
#'
#' @return A list with \code{Ii}, the information of each item.
#' @family rating scale model
#' @export
#'
#' @examples
#' bank <- matrix(c(-0.560, -0.230, 1.559, 0.071, 0.129,
#'                  rep(1.715, 5), rep(0.461, 5), rep(-1.265, 5), rep(-0.687, 5)),
#'                nrow = 5,
#'                dimnames = list(1:5, c("lambdaj", "delta1", "delta2", "delta3", "delta4")))
#' Ii_rsm(theta = 0, bank)
#' sum(Ii_rsm(theta = 0, bank)$Ii) # test information
Ii_rsm <- function(theta, bank, D = 1) {
  bank <- rbind(bank)
  prob <- Pi_rsm(theta, bank, D = D)
  P <- prob$Pi
  dP <- prob$dPi
  Ii <- as.numeric(rowSums(dP^2 / P, na.rm = TRUE))
  result <- list(Ii = Ii)
  return(result)
}
##########################################################################################
# NEXT ITEM SELECTION
##########################################################################################
#' Next item by maximum Fisher information
#'
#' Picks, among the items not yet given, the one with the most information at the
#' current ability estimate. Under the rating scale model this is the item whose
#' \eqn{\lambda_j} is nearest to \eqn{\theta}. With \code{randomesque = 1} it returns
#' the same item as \code{catR::nextItem(model = "RSM", criterion = "MFI")}.
#'
#' @inheritParams Pi_rsm
#' @param theta Current ability estimate.
#' @param out Indices of the items already given.
#' @param randomesque Number of most informative items to draw one from at random:
#'   1 is pure maximum information, 3 to 5 spreads the exposure of the items.
#'
#' @return A list: \code{item}, the index of the selected item in the bank,
#'   \code{info}, its information at \code{theta}, and \code{available}, the indices of
#'   the items that were still available.
#' @family rating scale model
#' @export
#'
#' @examples
#' bank <- matrix(c(-0.560, -0.230, 1.559, 0.071, 0.129,
#'                  rep(1.715, 5), rep(0.461, 5), rep(-1.265, 5), rep(-0.687, 5)),
#'                nrow = 5,
#'                dimnames = list(1:5, c("lambdaj", "delta1", "delta2", "delta3", "delta4")))
#' next_item_rsm(theta = 0, bank)
#' next_item_rsm(theta = 1.5, bank, out = c(4, 5))
#' # a short adaptive test
#' responses <- c()
#' administered <- c()
#' theta <- 0
#' for (step in 1:4) {
#'   item <- next_item_rsm(theta, bank, out = administered)$item
#'   administered <- c(administered, item)
#'   responses <- c(responses, 4) # the answer, scored 0 to 4
#'   theta <- eap_est_rsm(bank[administered, , drop = FALSE], responses)
#'   cat("step", step, "item", item, "theta", round(theta, 4),
#'       "se", round(eap_se_rsm(theta, bank[administered, , drop = FALSE], responses), 4), "\n")
#' }
next_item_rsm <- function(theta, bank, out = NULL, D = 1, randomesque = 1) {
  bank <- rbind(bank)
  available <- setdiff(1:nrow(bank), out)
  if (length(available) == 0) stop("no item left in the bank", call. = FALSE)
  info <- Ii_rsm(theta, bank[available, , drop = FALSE], D = D)$Ii
  k <- min(randomesque, length(available))
  top <- order(info, decreasing = TRUE)[1:k]
  pick <- if (k == 1) top else sample(top, 1)
  result <- list(item = available[pick], info = info[pick], available = available)
  return(result)
}
##########################################################################################
# LIKELIHOOD
##########################################################################################
#' Likelihood of a response pattern under the rating scale model
#'
#' The product, over the items, of the probability of the category given, under local
#' independence.
#'
#' @inheritParams Pi_rsm
#' @param x Vector of the answers, scored 0 to m, one per row of \code{bank}.
#'
#' @return The likelihood, a number.
#' @family rating scale model
#' @export
#'
#' @examples
#' bank <- matrix(c(-0.560, -0.230, 1.559, 0.071, 0.129,
#'                  rep(1.715, 5), rep(0.461, 5), rep(-1.265, 5), rep(-0.687, 5)),
#'                nrow = 5,
#'                dimnames = list(1:5, c("lambdaj", "delta1", "delta2", "delta3", "delta4")))
#' likelihood_rsm(theta = 0, bank = bank, x = c(4, 3, 2, 1, 0))
likelihood_rsm <- function(theta, bank, x, D = 1) {
  prob <- Pi_rsm(theta, bank, D = D)$Pi
  result <- 1
  for (i in 1:length(x)) result <- result * prob[i, x[i] + 1]
  return(result)
}
##########################################################################################
# EAP ESTIMATION
##########################################################################################
#' EAP ability estimate under the rating scale model
#'
#' The expected a posteriori estimate of ability, the mean of the posterior, by
#' quadrature over \code{nqp} points from \code{lower} to \code{upper}. It returns the
#' same result as \code{catR::eapEst(model = "RSM")}.
#'
#' @inheritParams likelihood_rsm
#' @param priorPar Mean and standard deviation of the normal prior.
#' @param lower,upper Range of the quadrature.
#' @param nqp Number of quadrature points.
#'
#' @return The estimate, a number.
#' @family rating scale model
#' @export
#'
#' @examples
#' bank <- matrix(c(-0.560, -0.230, 1.559, 0.071, 0.129,
#'                  rep(1.715, 5), rep(0.461, 5), rep(-1.265, 5), rep(-0.687, 5)),
#'                nrow = 5,
#'                dimnames = list(1:5, c("lambdaj", "delta1", "delta2", "delta3", "delta4")))
#' eap_est_rsm(bank, c(4, 3, 2, 1, 0))
eap_est_rsm <- function(bank, x, D = 1, priorPar = c(0, 1), lower = -4, upper = 4, nqp = 33) {
  g <- function(s) {
    res <- NULL
    for (i in 1:length(s))
      res[i] <- s[i] * density_function(s[i], priorPar[1], priorPar[2]) * likelihood_rsm(s[i], bank, x, D = D)
    return(res)
  }
  h <- function(s) {
    res <- NULL
    for (i in 1:length(s))
      res[i] <- density_function(s[i], priorPar[1], priorPar[2]) * likelihood_rsm(s[i], bank, x, D = D)
    return(res)
  }
  X <- seq(from = lower, to = upper, length = nqp)
  Y1 <- g(X)
  Y2 <- h(X)
  result <- integrate_cat(X, Y1) / integrate_cat(X, Y2)
  return(result)
}
##########################################################################################
# STANDARD ERROR ESTIMATION
##########################################################################################
#' Standard error of the EAP estimate under the rating scale model
#'
#' The posterior standard deviation when \code{theta} is the EAP estimate; at any other
#' value, the posterior root mean squared deviation around it. It returns the same
#' result as \code{catR::eapSem(model = "RSM")}.
#'
#' @inheritParams eap_est_rsm
#' @param theta The EAP estimate.
#'
#' @return The standard error, a number.
#' @family rating scale model
#' @export
#'
#' @examples
#' bank <- matrix(c(-0.560, -0.230, 1.559, 0.071, 0.129,
#'                  rep(1.715, 5), rep(0.461, 5), rep(-1.265, 5), rep(-0.687, 5)),
#'                nrow = 5,
#'                dimnames = list(1:5, c("lambdaj", "delta1", "delta2", "delta3", "delta4")))
#' x <- c(4, 3, 2, 1, 0)
#' eap_se_rsm(theta = eap_est_rsm(bank, x), bank = bank, x = x)
eap_se_rsm <- function(theta, bank, x, D = 1, priorPar = c(0, 1), lower = -4, upper = 4, nqp = 33) {
  g <- function(X) {
    res <- NULL
    for (i in 1:length(X))
      res[i] <- (X[i] - theta)^2 * density_function(X[i], priorPar[1], priorPar[2]) * likelihood_rsm(X[i], bank, x, D = D)
    return(res)
  }
  h <- function(X) {
    res <- NULL
    for (i in 1:length(X))
      res[i] <- density_function(X[i], priorPar[1], priorPar[2]) * likelihood_rsm(X[i], bank, x, D = D)
    return(res)
  }
  X <- seq(from = lower, to = upper, length = nqp)
  Y1 <- g(X)
  Y2 <- h(X)
  result <- sqrt(integrate_cat(X, Y1) / integrate_cat(X, Y2))
  return(result)
}
