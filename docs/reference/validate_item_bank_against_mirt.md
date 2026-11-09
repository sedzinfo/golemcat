# Check an item bank against its mirt model

Compares the response probabilities of the engine with those of the
fitted `mirt` model, item by item, so that a sign or mapping mistake
does not go unnoticed (a check on the first item alone passes either
way, since `mirt` fixes `c = 0` there). Items are matched by name:
[`make.names()`](https://rdrr.io/r/base/make.names.html) of the question
must be the item name in the model. Needs the `mirt` package.

## Usage

``` r
validate_item_bank_against_mirt(
  bank_scale,
  mirt_model,
  thetas = seq(-4, 4, 0.5),
  tol = 1e-06
)
```

## Arguments

- bank_scale:

  The rows of one scale of an item bank read with
  [`read_item_bank`](https://sedzinfo.github.io/golemcat/reference/read_item_bank.md).

- mirt_model:

  The `mirt` model fitted to that scale.

- thetas:

  Ability values at which the probabilities are compared.

- tol:

  Largest difference accepted.

## Value

The largest difference, invisibly; a warning when it is above `tol`.

## See also

Other item bank:
[`ipip50()`](https://sedzinfo.github.io/golemcat/reference/ipip50.md),
[`read_item_bank()`](https://sedzinfo.github.io/golemcat/reference/read_item_bank.md),
[`read_likert()`](https://sedzinfo.github.io/golemcat/reference/read_likert.md)

## Examples

``` r
if (FALSE) { # \dontrun{
bank <- read_item_bank("items.csv")
validate_item_bank_against_mirt(bank[bank$scale == "Openness", ], model_openness)
} # }
```
