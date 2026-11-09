# Answer the current item

Scores the answer (category `answer - 1`, or `5 - answer` on a reversed
item), estimates the ability and its standard error again, and either
selects the next item of the scale or, when the scale stops, moves to
the next scale or ends the test.

## Usage

``` r
cat_answer(s, answer)
```

## Arguments

- s:

  A CAT session.

- answer:

  The answer, 1 to 5, as shown to the person (before any reversal).

## Value

The updated session.

## See also

Other CAT session:
[`cat_item()`](https://sedzinfo.github.io/golemcat/reference/cat_item.md),
[`cat_results()`](https://sedzinfo.github.io/golemcat/reference/cat_results.md),
[`cat_start()`](https://sedzinfo.github.io/golemcat/reference/cat_start.md)

## Examples

``` r
s <- cat_start(ipip50()$bank, scales = "Openness")
s <- cat_answer(s, 5)
s$progress
#>      scale total answered     theta        se      status
#> 1 Openness    10        1 0.8563326 0.8264911 in progress
```
