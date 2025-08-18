# tests/testthat/test-generate_reports.R

# Test Case 1: Successful Rmd file generation with correct parameter substitution
test_that("generate_reports creates valid Rmd files with correct parameters", {
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
  # Check for correct file paths and names (now .Rmd)
  expected_filenames <- paste0("Report-", report_params$a, "_", report_params$b, ".Rmd")
  expect_equal(length(output_files), nrow(report_params))
  expect_true(all(file.exists(output_files)))
  expect_equal(basename(output_files), expected_filenames)

  # Check that files are not empty
  file_info <- file.info(output_files)
  expect_true(all(file_info$size > 0))

  # NEW: Check that parameters were correctly substituted into the Rmd file content
  first_file_content <- readLines(output_files[1])
  expect_true(any(grepl('author: "Test Author"', first_file_content, fixed = TRUE)))
  expect_true(any(grepl("a: 1", first_file_content, fixed = TRUE)))
  expect_true(any(grepl("b: 1", first_file_content, fixed = TRUE)))

  second_file_content <- readLines(output_files[2])
  expect_true(any(grepl("b: 2", second_file_content, fixed = TRUE)))
})

# ---
# Test Case 2: Graceful failure with invalid inputs (remains valid)
test_that("generate_reports errors correctly with bad inputs", {
  # --- 1. Setup ---
  temp_output_dir <- tempfile(pattern = "bad-inputs-")
  dir.create(temp_output_dir)
  on.exit(unlink(temp_output_dir, recursive = TRUE), add = TRUE)

  valid_params <- data.frame(a = 1, b = 1, author = "Test")

  # --- 2. Assertions for expected errors ---
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
