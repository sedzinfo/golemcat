# Normal density

The density of the normal distribution, used as the prior of the EAP
estimate. It returns the same result as
[`stats::dnorm()`](https://rdrr.io/r/stats/Normal.html).

## Usage

``` r
density_function(x, mean = 0, sd = 1)
```

## Arguments

- x:

  Numeric vector of values at which the density is evaluated.

- mean:

  Mean of the distribution.

- sd:

  Standard deviation of the distribution.

## Value

A numeric vector of densities.

## See also

Other rating scale model:
[`Ii_rsm()`](https://sedzinfo.github.io/golemcat/reference/Ii_rsm.md),
[`Pi_rsm()`](https://sedzinfo.github.io/golemcat/reference/Pi_rsm.md),
[`eap_est_rsm()`](https://sedzinfo.github.io/golemcat/reference/eap_est_rsm.md),
[`eap_se_rsm()`](https://sedzinfo.github.io/golemcat/reference/eap_se_rsm.md),
[`integrate_cat()`](https://sedzinfo.github.io/golemcat/reference/integrate_cat.md),
[`likelihood_rsm()`](https://sedzinfo.github.io/golemcat/reference/likelihood_rsm.md),
[`next_item_rsm()`](https://sedzinfo.github.io/golemcat/reference/next_item_rsm.md)

## Examples

``` r
v <- seq(-3, 3, by = 0.1)
all.equal(density_function(v), dnorm(v))
#> [1] TRUE
```
