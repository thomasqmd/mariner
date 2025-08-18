# tests/testthat/test-process_file.R

# Helper function to create a temporary Rmd file for tests
create_temp_rmd <- function(dir, file_name, content) {
  path <- file.path(dir, file_name)
  writeLines(content, path)
  return(path)
}

# Test Case 1: Successful bundling with a specified output path
test_that("process_file correctly bundles a valid Rmd", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  test_rmd_path <- create_temp_rmd(
    dir = temp_dir,
    file_name = "test_report.Rmd",
    content = c(
      "---",
      "title: 'Test Report'",
      "output: pdf_document",
      "---",
      "print('Hello')"
    )
  )

  output_zip_path <- file.path(temp_dir, "output_bundle.zip")
  suppressMessages({
    result_path <- process_file(test_rmd_path, output_zip_path)
  })

  # --- THE FIX ---
  # Normalize both paths before comparing to avoid issues with extra slashes.
  expect_equal(fs::path_norm(result_path), fs::path_norm(output_zip_path))

  expect_true(file.exists(output_zip_path))

  zip_contents <- utils::unzip(output_zip_path, list = TRUE)$Name
  expect_true(all(c("test_report.Rmd", "test_report.R", "test_report.pdf") %in% zip_contents))
})

# (The rest of your tests can remain the same)

# Test Case 2: Default output path behavior
test_that("process_file uses the default output path when output_zip is NULL", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  test_rmd_path <- create_temp_rmd(
    dir = temp_dir,
    file_name = "default_name.Rmd",
    content = c("---", "title: 'Default'", "---")
  )

  suppressMessages({
    result_path <- process_file(test_rmd_path, output_zip = NULL)
  })

  expected_zip_path <- fs::path_ext_set(test_rmd_path, ".zip")
  expect_equal(fs::path_norm(result_path), fs::path_norm(expected_zip_path))
  expect_true(file.exists(expected_zip_path))
})

# Test Case 3: Bundling Rmd with plot outputs
test_that("process_file bundles Rmd output dependencies (e.g., _files directory)", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  test_rmd_path <- create_temp_rmd(
    dir = temp_dir,
    file_name = "report_with_plot.Rmd",
    content = c(
      "---",
      "title: 'Report with Plot'",
      "output: html_document",
      "---",
      "```{r}",
      "plot(1:10)",
      "```"
    )
  )

  output_zip_path <- file.path(temp_dir, "plot_bundle.zip")
  suppressMessages({
    process_file(test_rmd_path, output_zip_path)
  })

  zip_contents <- utils::unzip(output_zip_path, list = TRUE)$Name

  expect_true("report_with_plot.Rmd" %in% zip_contents)
  expect_true("report_with_plot.html" %in% zip_contents)
  expect_true(any(grepl("report_with_plot_files", zip_contents)))
})

# Test Case 4: Graceful failure with invalid inputs
test_that("process_file errors correctly with bad inputs", {
  expect_error(process_file("non_existent_file.Rmd"))

  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  invalid_rmd_path <- create_temp_rmd(
    dir = temp_dir,
    file_name = "invalid.Rmd",
    content = c("---", "title: 'Invalid'", "---", "```{r}", "stop('error')", "```")
  )
  expect_error(process_file(invalid_rmd_path))
})
