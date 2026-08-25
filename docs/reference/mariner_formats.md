# Formats shipped by mariner

The Quarto formats the vendored extension contributes.

## Usage

``` r
mariner_formats
```

## Format

A character vector.

## Details

There is one: `pdf`, rendered through xelatex. mariner exists to turn a
parameterized `.qmd` into a bundled report, and a report is a PDF.

It stays a vector, and `format` stays a named argument on the functions
that take one, for the same reason
[mariner_themes](https://thomasqmd.github.io/mariner/reference/mariner_themes.md)
does: a second target later is an entry here rather than a signature
change across the package.
