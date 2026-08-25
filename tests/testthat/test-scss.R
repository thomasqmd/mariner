# The stylesheet stack has to actually compile.
#
# Assembling it the way Quarto does and running dart-sass over the result
# catches a broken partial here, in a second, rather than in the middle of a
# render where the error arrives attached to a document that has nothing wrong
# with it.

test_that("every format's stylesheet stack compiles", {
  sass <- skip_if_no_sass()

  for (theme in mariner_themes) {
    for (format in c("html", "revealjs")) {
      paths <- mariner_scss_files(theme, format)
      expect_true(all(file.exists(paths)),
                  info = paste("missing partial for", theme, format))

      combined <- assemble_scss(paths)

      src <- withr::local_tempfile(fileext = ".scss")
      writeLines(combined, src)

      # --load-path so a relative partial reference resolves the way it does
      # under Quarto, which puts each theme file's directory on the load path.
      #
      # Every path is shQuote()d, including the load paths. The package's own
      # development checkout lives under a directory with spaces in its name, so
      # an unquoted --load-path= is split by the shell and dart-sass reports
      # "Only two positional args may be passed" -- an error that says nothing
      # about the actual cause.
      load_paths <- unique(dirname(paths))
      out <- suppressWarnings(system2(
        sass,
        c("--no-source-map",
          paste0("--load-path=", shQuote(load_paths)),
          shQuote(src)),
        stdout = TRUE, stderr = TRUE
      ))
      status <- attr(out, "status")

      expect_null(
        status,
        info = paste0(
          theme, "/", format, " stylesheet failed to compile:\n",
          paste(utils::head(out, 20), collapse = "\n")
        )
      )
      # A stylesheet that compiles to nothing has silently lost its rules.
      expect_gt(sum(nchar(out)), 1000)
    }
  }
})

test_that("the token file is last in the stack", {
  # Quarto concatenates the `defaults` layer in REVERSE list order, so the
  # generated token file has to be listed last for its variables to come first.
  # Every partial's defaults reference $qmd-*, so getting this wrong is a
  # compile error -- but a confusing one, pointing at a partial rather than at
  # the ordering.
  for (format in c("html", "revealjs")) {
    files <- mariner_scss_files("baylor", format, absolute = FALSE)
    expect_identical(files[[length(files)]], "_qmd-tokens.scss")
  }
})

test_that("the format partial slots into the middle of the stack", {
  html <- mariner_scss_files("baylor", "html", absolute = FALSE)
  reveal <- mariner_scss_files("baylor", "revealjs", absolute = FALSE)

  expect_true("qmd-html.scss" %in% html)
  expect_true("qmd-revealjs.scss" %in% reveal)
  expect_false("qmd-revealjs.scss" %in% html)

  # The two stacks differ in exactly one slot.
  expect_identical(setdiff(html, reveal), "qmd-html.scss")
  expect_identical(setdiff(reveal, html), "qmd-revealjs.scss")
})
