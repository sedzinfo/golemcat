# The item to show now

The item to show now

## Usage

``` r
cat_item(s)
```

## Arguments

- s:

  A CAT session.

## Value

A list with the `scale`, the `stem` (`NA` when the bank has none) and
the `question` of the current item, or `NULL` when the test is done.

## See also

Other CAT session:
[`cat_answer()`](https://sedzinfo.github.io/golemcat/reference/cat_answer.md),
[`cat_results()`](https://sedzinfo.github.io/golemcat/reference/cat_results.md),
[`cat_start()`](https://sedzinfo.github.io/golemcat/reference/cat_start.md)

## Examples

``` r
s <- cat_start(ipip50()$bank, scales = "Openness")
cat_item(s)
#> $scale
#> [1] "Openness"
#> 
#> $stem
#> [1] "How accurately does this statement describe you?"
#> 
#> $question
#> [1] "I use difficult words."
#> 
```
