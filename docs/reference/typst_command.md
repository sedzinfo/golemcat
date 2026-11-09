# The typst compiler

Finds the `typst` command line: the `GOLEMCAT_TYPST` environment
variable, then `typst` on the path, then the copy that comes with
'quarto' (`quarto typst`).

## Usage

``` r
typst_command()
```

## Value

A list with `cmd`, the program, and `args`, the arguments that go before
`compile`; `NULL` when none is found.

## Examples

``` r
golemcat:::typst_command()
#> $cmd
#> [1] "/usr/local/bin/typst"
#> 
#> $args
#> character(0)
#> 
```
