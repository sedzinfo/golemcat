# Numerical integration by the trapezoidal rule

Integrates `y = f(x)` over the points `x`, as
[`catR::integrate.catR()`](https://rdrr.io/pkg/catR/man/integrate.catR.html)
does.

## Usage

``` r
integrate_cat(x, y)
```

## Arguments

- x:

  Numeric vector of the points of integration, in increasing order.

- y:

  Numeric vector of the values of the function at `x`.

## Value

The integral, a number.

## See also

Other rating scale model:
[`Ii_rsm()`](https://sedzinfo.github.io/golemcat/reference/Ii_rsm.md),
[`Pi_rsm()`](https://sedzinfo.github.io/golemcat/reference/Pi_rsm.md),
[`density_function()`](https://sedzinfo.github.io/golemcat/reference/density_function.md),
[`eap_est_rsm()`](https://sedzinfo.github.io/golemcat/reference/eap_est_rsm.md),
[`eap_se_rsm()`](https://sedzinfo.github.io/golemcat/reference/eap_se_rsm.md),
[`likelihood_rsm()`](https://sedzinfo.github.io/golemcat/reference/likelihood_rsm.md),
[`next_item_rsm()`](https://sedzinfo.github.io/golemcat/reference/next_item_rsm.md)

## Examples

``` r
x <- seq(from = -3, to = 3, length = 33)
integrate_cat(x = x, y = exp(x))
#> [1] 20.09441
exp(3) - exp(-3) # the exact value
#> [1] 20.03575
```
