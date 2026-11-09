# Next item by maximum Fisher information

Picks, among the items not yet given, the one with the most information
at the current ability estimate. Under the rating scale model this is
the item whose \\\lambda_j\\ is nearest to \\\theta\\. With
`randomesque = 1` it returns the same item as
`catR::nextItem(model = "RSM", criterion = "MFI")`.

## Usage

``` r
next_item_rsm(theta, bank, out = NULL, D = 1, randomesque = 1)
```

## Arguments

- theta:

  Current ability estimate.

- bank:

  Matrix of item parameters, one row per item: column 1 is the location
  of the item \\\lambda_j\\, the other columns the thresholds
  \\\delta_1\\ to \\\delta_m\\, the same in every row (which makes it
  the rating scale and not the partial credit model). A 5-point Likert
  item, scored 0 to 4, needs 5 columns.

- out:

  Indices of the items already given.

- D:

  Metric constant, 1 or 1.702.

- randomesque:

  Number of most informative items to draw one from at random: 1 is pure
  maximum information, 3 to 5 spreads the exposure of the items.

## Value

A list: `item`, the index of the selected item in the bank, `info`, its
information at `theta`, and `available`, the indices of the items that
were still available.

## See also

Other rating scale model:
[`Ii_rsm()`](https://sedzinfo.github.io/golemcat/reference/Ii_rsm.md),
[`Pi_rsm()`](https://sedzinfo.github.io/golemcat/reference/Pi_rsm.md),
[`density_function()`](https://sedzinfo.github.io/golemcat/reference/density_function.md),
[`eap_est_rsm()`](https://sedzinfo.github.io/golemcat/reference/eap_est_rsm.md),
[`eap_se_rsm()`](https://sedzinfo.github.io/golemcat/reference/eap_se_rsm.md),
[`integrate_cat()`](https://sedzinfo.github.io/golemcat/reference/integrate_cat.md),
[`likelihood_rsm()`](https://sedzinfo.github.io/golemcat/reference/likelihood_rsm.md)

## Examples

``` r
bank <- matrix(c(-0.560, -0.230, 1.559, 0.071, 0.129,
                 rep(1.715, 5), rep(0.461, 5), rep(-1.265, 5), rep(-0.687, 5)),
               nrow = 5,
               dimnames = list(1:5, c("lambdaj", "delta1", "delta2", "delta3", "delta4")))
next_item_rsm(theta = 0, bank)
#> $item
#> [1] 4
#> 
#> $info
#> [1] 3.061434
#> 
#> $available
#> [1] 1 2 3 4 5
#> 
next_item_rsm(theta = 1.5, bank, out = c(4, 5))
#> $item
#> [1] 3
#> 
#> $info
#> [1] 3.076108
#> 
#> $available
#> [1] 1 2 3
#> 
# a short adaptive test
responses <- c()
administered <- c()
theta <- 0
for (step in 1:4) {
  item <- next_item_rsm(theta, bank, out = administered)$item
  administered <- c(administered, item)
  responses <- c(responses, 4) # the answer, scored 0 to 4
  theta <- eap_est_rsm(bank[administered, , drop = FALSE], responses)
  cat("step", step, "item", item, "theta", round(theta, 4),
      "se", round(eap_se_rsm(theta, bank[administered, , drop = FALSE], responses), 4), "\n")
}
#> step 1 item 4 theta 0.8477 se 0.6921 
#> step 2 item 5 theta 1.0943 se 0.6324 
#> step 3 item 3 theta 1.8299 se 0.5575 
#> step 4 item 2 theta 1.8537 se 0.553 
```
