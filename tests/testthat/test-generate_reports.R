# tests/testthat/test-generate_reports.R

# Test Case 1: Successful report generation with valid inputs
test_that("generate_reports creates valid PDF files", {
  # --- 1. Setup ---
  temp_output_dir <- tempfile(pattern = "test-reports-")
  dir.create(temp_output_dir)
  on.exit(unlink(temp_output_dir, recursive = TRUE), add = TRUE)

  report_params <- data.frame(
    a = 1,
    b = 1:2,
    author = "Test Author"
  )

  # --- 2. Execute ---
  suppressMessages({
    output_files <- generate_reports(
      params_df = report_params,
      template_name = "simple_report",
      template_package = "mariner",
      output_dir = temp_output_dir
    )
  })

  # --- 3. Assertions ---
  # Check for correct file paths and names
  expected_filenames <- paste0("Report-", report_params$a, "_", report_params$b, ".pdf")
  expect_equal(length(output_files), nrow(report_params))
  expect_true(all(file.exists(output_files)))
  expect_equal(basename(output_files), expected_filenames)

  # IMPROVEMENT 1: Check file integrity
  # Verify that the generated files are not empty. This is a simple but
  # effective way to catch rendering failures that produce a zero-byte file.
  file_info <- file.info(output_files)
  expect_true(all(file_info$size > 0))
})

# ---
# Test Case 2: Graceful failure with invalid inputs
test_that("generate_reports errors correctly with bad inputs", {
  # --- 1. Setup ---
  temp_output_dir <- tempfile(pattern = "bad-inputs-")
  dir.create(temp_output_dir)
  on.exit(unlink(temp_output_dir, recursive = TRUE), add = TRUE)

  valid_params <- data.frame(a = 1, b = 1, author = "Test")

  # --- 2. Assertions for expected errors ---
  # IMPROVEMENT 2: Check error handling
  # The function should stop with an informative error if the template
  # or package cannot be found. testthat::expect_error() checks this.

  # Test for a non-existent template name
  expect_error(
    generate_reports(
      params_df = valid_params,
      template_name = "nonexistent_template",
      template_package = "mariner",
      output_dir = temp_output_dir
    )
  )

  # Test for a non-existent package name
  expect_error(
    generate_reports(
      params_df = valid_params,
      template_name = "simple_report",
      template_package = "nonexistent_package",
      output_dir = temp_output_dir
    )
  )
})
