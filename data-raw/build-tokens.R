# Regenerate every derived artefact, and re-sync the shared partials into the
# extension directory.
#
# Run after ANY edit to a source of truth:
#
#   inst/brand/<theme>/_brand.yml   the colours, the type families, the logo files
#   inst/assets/logos/              the marks themselves -- a mark whose pixel
#                                   dimensions change moves every derived width
#   R/slides.R                      the slide box, and everything measured on it
#   R/scss.R                        the stylesheet layer order
#   R/logos.R                       the per-placement target heights
#   inst/scss/, inst/typst/, inst/tex/, inst/html/
#                                   the shared partials, which are COPIED in
#
#   Rscript data-raw/build-tokens.R
#
# tests/testthat/test-no-drift.R re-runs the same generators into a temporary
# directory and diffs against what is committed, so forgetting this step fails
# R CMD check rather than shipping a stylesheet that disagrees with the brand.

if (!requireNamespace("pkgload", quietly = TRUE)) {
  stop("pkgload is required to run this script: install.packages('pkgload')")
}

pkgload::load_all(".", quiet = TRUE, export_all = TRUE)

cli::cli_h1("Token files")
build_tokens(root = ".")

cli::cli_h2("Derived logo sizes")

# Printed rather than asserted, because these are the numbers a person needs to
# sanity-check by eye after swapping a mark. A logo replaced by one with a
# different aspect ratio changes them silently and correctly -- which is the
# point of deriving them -- but it is still worth seeing.
for (theme in mariner_themes) {
  for (slot in c("small", "medium", "large")) {
    d <- png_dims(mariner_logo_file(theme, slot))
    cli::cli_alert_info(
      "{theme}/{slot}: {.file {mariner_logo_name(theme, slot)}} \\
       {d$width}x{d$height} ({num_str(d$width / d$height)}:1)"
    )
  }
  cli::cli_alert_info(
    "pdf corner: {num_str(LOGO_HEIGHT$pdf_corner_in)}in tall \\
     -> {num_str(mariner_logo_width(LOGO_HEIGHT$pdf_corner_in, theme, 'medium'))}in wide"
  )
}

cli::cli_alert_success("done")
cli::cli_alert_info("Now run: devtools::document(); devtools::test()")
