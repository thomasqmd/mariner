# End-to-end Quarto PDF rendering tests.

local_dir <- function(env = parent.frame()) {
  withr::local_tempdir(.local_envir = env)
}

test_that("full PDF report renders end-to-end with theme", {
  skip_if_no_quarto()
  skip_if_no_latex()

  root <- local_dir()
  file.create(file.path(root, "DESCRIPTION"))
  dirs <- suppressMessages(mariner_setup_project(root = root))

  doc <- file.path(dirs$reports, "report.qmd")
  expect_true(file.exists(doc))

  out_zip <- file.path(dirs$zips, "report.zip")
  result <- suppressMessages(process_file(doc, output_zip = out_zip, assets_dir = dirs$assets))

  expect_true(file.exists(result))
  contents <- utils::unzip(result, list = TRUE)$Name
  expect_true("report.qmd" %in% contents)
  expect_true("report.pdf" %in% contents)
  expect_true("report.R" %in% contents)
  expect_false(any(grepl("_extensions", contents, fixed = TRUE)))
})

test_that("rendering succeeds under a path with spaces", {
  skip_if_no_quarto()
  skip_if_no_latex()

  spaced_root <- withr::local_tempdir(pattern = "mariner render space ")
  file.create(file.path(spaced_root, "DESCRIPTION"))
  dirs <- suppressMessages(mariner_setup_project(root = spaced_root))

  doc <- file.path(dirs$reports, "report.qmd")
  out_zip <- file.path(dirs$zips, "report.zip")
  result <- suppressMessages(process_file(doc, output_zip = out_zip, assets_dir = dirs$assets))

  expect_true(file.exists(result))
  contents <- utils::unzip(result, list = TRUE)$Name
  expect_true("report.pdf" %in% contents)
})
