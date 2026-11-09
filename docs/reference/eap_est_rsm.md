# EAP ability estimate under the rating scale model

The expected a posteriori estimate of ability, the mean of the
posterior, by quadrature over `nqp` points from `lower` to `upper`. It
returns the same result as `catR::eapEst(model = "RSM")`.

## Usage

``` r
eap_est_rsm(
  bank,
  x,
  D = 1,
  priorPar = c(0, 1),
  lower = -4,
  upper = 4,
  nqp = 33
)
```

## Arguments

- bank:

  Matrix of item parameters, one row per item: column 1 is the location
  of the item \\\lambda_j\\, the other columns the thresholds
  \\\delta_1\\ to \\\delta_m\\, the same in every row (which makes it
  the rating scale and not the partial credit model). A 5-point Likert
  item, scored 0 to 4, needs 5 columns.

- x:

  Vector of the answers, scored 0 to m, one per row of `bank`.

- D:

  Metric constant, 1 or 1.702.

- priorPar:

  Mean and standard deviation of the normal prior.

- lower, upper:

  Range of the quadrature.

- nqp:

  Number of quadrature points.

## Value

The estimate, a number.

## See also

Other rating scale model:
[`Ii_rsm()`](https://sedzinfo.github.io/golemcat/reference/Ii_rsm.md),
[`Pi_rsm()`](https://sedzinfo.github.io/golemcat/reference/Pi_rsm.md),
[`density_function()`](https://sedzinfo.github.io/golemcat/reference/density_function.md),
[`eap_se_rsm()`](https://sedzinfo.github.io/golemcat/reference/eap_se_rsm.md),
[`integrate_cat()`](https://sedzinfo.github.io/golemcat/reference/integrate_cat.md),
[`likelihood_rsm()`](https://sedzinfo.github.io/golemcat/reference/likelihood_rsm.md),
[`next_item_rsm()`](https://sedzinfo.github.io/golemcat/reference/next_item_rsm.md)

## Examples

``` r
bank <- matrix(c(-0.560, -0.230, 1.559, 0.071, 0.129,
                 rep(1.715, 5), rep(0.461, 5), rep(-1.265, 5), rep(-0.687, 5)),
               nrow = 5,
               dimnames = list(1:5, c("lambdaj", "delta1", "delta2", "delta3", "delta4")))
eap_est_rsm(bank, c(4, 3, 2, 1, 0))
#> [1] 0.09165378
```
