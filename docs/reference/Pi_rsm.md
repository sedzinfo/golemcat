# Category response probabilities of the rating scale model

The probability of each answer category, and its first derivative, at an
ability value, under the rating scale model of Andrich (1978): \$\$P(X =
k \mid \theta) = \frac{\exp \sum\_{t=1}^{k} D(\theta - (\lambda_j +
\delta_t))} {\sum\_{h=0}^{m} \exp \sum\_{t=1}^{h} D(\theta -
(\lambda_j + \delta_t))}\$\$ with the empty sum of category 0 equal to
zero. It returns the same result as `catR::Pi(model = "RSM")`.

## Usage

``` r
Pi_rsm(theta, bank, D = 1)
```

## Arguments

- theta:

  Ability.

- bank:

  Matrix of item parameters, one row per item: column 1 is the location
  of the item \\\lambda_j\\, the other columns the thresholds
  \\\delta_1\\ to \\\delta_m\\, the same in every row (which makes it
  the rating scale and not the partial credit model). A 5-point Likert
  item, scored 0 to 4, needs 5 columns.

- D:

  Metric constant, 1 or 1.702.

## Value

A list: `Pi`, the probabilities, one row per item and one column per
category, and `dPi`, their first derivatives.

## See also

Other rating scale model:
[`Ii_rsm()`](https://sedzinfo.github.io/golemcat/reference/Ii_rsm.md),
[`density_function()`](https://sedzinfo.github.io/golemcat/reference/density_function.md),
[`eap_est_rsm()`](https://sedzinfo.github.io/golemcat/reference/eap_est_rsm.md),
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
Pi_rsm(theta = 0, bank)$Pi
#>             cat0       cat1        cat2        cat3        cat4
#> Item1 0.08827106 0.02781046 0.030704594 0.190454305 0.662759579
#> Item2 0.23732018 0.05375358 0.042666335 0.190263548 0.475996359
#> Item3 0.95403130 0.03611457 0.004790796 0.003570467 0.001492864
#> Item4 0.45604320 0.07644622 0.044906724 0.148203679 0.274400176
#> Item5 0.50098691 0.07924783 0.043929232 0.136808204 0.239027827
rowSums(Pi_rsm(theta = 0, bank)$Pi) # each item's probabilities add up to 1
#> Item1 Item2 Item3 Item4 Item5 
#>     1     1     1     1     1 
```
