# Path to a mariner template skeleton

Resolves a template name to its `skeleton.qmd`.

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

  Package that ships the template. Defaults to `"mariner"`.

- call:

  Caller environment for error reporting.

## Value

An absolute path to the template's `skeleton.qmd`.

## Examples

``` r
mariner_template_path("report")
#> [1] "/private/var/folders/k3/k8hfzfxd11j6vy0_t2rx27yw0000gn/T/RtmpKLq8Um/temp_libpath8a402186f9c/mariner/templates/report/skeleton.qmd"
```
