# tests/testthat/test-process_file.R

# Test Case 1: Successful bundling using a .qmd file from generate_reports
test_that("process_file correctly bundles a valid .qmd from generate_reports", {
  # --- 1. Setup: Use generate_reports to create a source .qmd file ---
  temp_dir <- tempfile("test-")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  # This will now generate a .qmd file
  doc_file_path <- generate_reports(
    params_df = data.frame(
      chapter = 1,
      problem_numbers = 1,
      author = "Test Author"
    ),
    template_name = "simple_report",
    template_package = "mariner",
    output_dir = temp_dir
  )

  expect_equal(tools::file_ext(doc_file_path), "qmd") # Verify it's a .qmd

  # --- 2. Execute ---
  output_zip_path <- file.path(temp_dir, "output_bundle.zip")
  suppressMessages({
    result_path <- process_file(doc_file_path, output_zip_path)
  })

  # --- 3. Assertions ---
  expect_equal(fs::path_norm(result_path), fs::path_norm(output_zip_path))
  expect_true(file.exists(output_zip_path))

  zip_contents <- utils::unzip(output_zip_path, list = TRUE)$Name
  # Check for the core files in the bundle
  expect_true(any(grepl("\\.qmd$", zip_contents)))
  expect_true(any(grepl("\\.R$", zip_contents)))
  expect_true(any(grepl("\\.pdf$", zip_contents)))
})

# Test Case 2: Default output path behavior (with .qmd)
test_that("process_file uses the default output path when output_zip is NULL", {
  temp_dir <- tempfile("test-")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  # Use generate_reports for setup (creates .qmd)
  doc_file_path <- generate_reports(
    params_df = data.frame(
      chapter = 1,
      problem_numbers = 1,
      author = "Test Author"
    ),
    template_name = "simple_report",
    output_dir = temp_dir
  )

  suppressMessages({
    result_path <- process_file(doc_file_path, output_zip = NULL)
  })

  expected_zip_path <- fs::path_ext_set(doc_file_path, ".zip")
  expect_equal(fs::path_norm(result_path), fs::path_norm(expected_zip_path))
  expect_true(file.exists(expected_zip_path))
})

# Test Case 3: Bundling .Rmd with plot outputs (Keep custom Rmd)
test_that("process_file bundles .Rmd output dependencies (e.g., _files directory)", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  # A custom Rmd is better here to test for the specific '_files' output.
  test_rmd_path <- file.path(temp_dir, "report_with_plot.Rmd")
  writeLines(
    c(
      "---",
      "title: 'Report with Plot'",
      "output: html_document",
      "---",
      "```{r}",
      "plot(1:10)",
      "```"
    ),
    test_rmd_path
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

# Test Case 4: Bundling .qmd with plot outputs (NEW)
test_that("process_file bundles .qmd output dependencies (e.g., _files directory)", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  test_qmd_path <- file.path(temp_dir, "report_with_plot.qmd")
  writeLines(
    c(
      "---",
      "title: 'Report with Plot'",
      "format: html",
      "---",
      "```{r}",
      "plot(1:10)",
      "```"
    ),
    test_qmd_path
  )

  output_zip_path <- file.path(temp_dir, "plot_bundle.zip")
  suppressMessages({
    process_file(test_qmd_path, output_zip_path)
  })

  zip_contents <- utils::unzip(output_zip_path, list = TRUE)$Name
  expect_true("report_with_plot.qmd" %in% zip_contents)
  expect_true("report_with_plot.html" %in% zip_contents)
  expect_true(any(grepl("report_with_plot_files", zip_contents)))
})


# Test Case 5: Graceful failure with invalid inputs
test_that("process_file errors correctly with bad inputs", {
  # Test non-existent file
  expect_error(process_file("non_existent_file.qmd"))

  # Test .qmd that will fail to render
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  invalid_qmd_path <- file.path(temp_dir, "invalid.qmd")
  writeLines(
    c("---", "title: 'Invalid'", "---", "```{r}", "stop('error')", "```"),
    invalid_qmd_path
  )
  expect_error(process_file(invalid_qmd_path))

  # Test invalid file type
  invalid_txt_path <- file.path(temp_dir, "invalid.txt")
  writeLines("hello", invalid_txt_path)
  expect_error(process_file(invalid_txt_path))
})
# Test Case 6: Graceful failure with invalid .Rmd file
test_that("process_file errors correctly with a failing .Rmd", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  invalid_rmd_path <- file.path(temp_dir, "invalid.Rmd")
  writeLines(
    c("---", "title: 'Invalid'", "---", "```{r}", "stop('error')", "```"),
    invalid_rmd_path
  )
  expect_error(process_file(invalid_rmd_path))
})

# Test Case 7: Bundling a simple, non-parameterized .qmd
test_that("process_file bundles a simple .qmd file", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  simple_qmd_path <- file.path(temp_dir, "simple.qmd")
  writeLines(
    c("---", "title: 'Simple'", "format: pdf", "---", "Hello world."),
    simple_qmd_path
  )

  suppressMessages({
    result_path <- process_file(simple_qmd_path, output_zip = NULL)
  })

  expect_true(file.exists(result_path))
  zip_contents <- utils::unzip(result_path, list = TRUE)$Name
  expect_true("simple.qmd" %in% zip_contents)
  expect_true("simple.pdf" %in% zip_contents)
})
