# Path to a mariner template skeleton

Resolves the path to a template's `skeleton.qmd` file.

## Usage

``` r
mariner_template_path(
  template = "report",
  package = "mariner",
  call = rlang::caller_env()
)
```

## Arguments

- template:

  Name of the template directory under `inst/templates/`. Defaults to
  `"report"`.

- package:

  Package shipping the template. Defaults to `"mariner"`.

- call:

  Caller environment for error reporting.

## Value

An absolute file path to the template's `skeleton.qmd`.

## Examples

``` r
mariner_template_path("report")
#> [1] "/private/var/folders/k3/k8hfzfxd11j6vy0_t2rx27yw0000gn/T/RtmpFg9v31/temp_libpath22c63e83e139/mariner/templates/report/skeleton.qmd"
```
