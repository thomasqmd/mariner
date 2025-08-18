# tests/testthat/test-process_files.R
library(future)

# Test Case 1: Sequential processing with mixed success and failure
test_that("process_files works sequentially with mixed success and failure", {
  # --- 1. Setup ---
  temp_dir <- tempfile("test-")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  # Create one valid Rmd using the package's workflow
  valid_rmd <- generate_reports(
    params_df = data.frame(a = 1, b = 1, author = "Valid Author"),
    template_name = "simple_report",
    output_dir = temp_dir
  )

  # Create one Rmd designed to fail
  invalid_rmd <- file.path(temp_dir, "invalid.Rmd")
  writeLines(
    c("---", "title: 'Invalid'", "---", "```{r}", "stop('error')", "```"),
    invalid_rmd
  )

  input_list <- c(valid_rmd, invalid_rmd)

  # --- 2. Execute ---
  suppressMessages({
    output_paths <- process_files(input_list)
  })

  # --- 3. Assertions ---
  expect_length(output_paths, 2)
  expect_true(!is.na(output_paths[1])) # The first file should succeed
  expect_true(is.na(output_paths[2])) # The second file should fail
  expect_true(file.exists(output_paths[1]))
})


# Test Case 2: Parallel processing with all successful files
test_that("process_files works correctly in parallel with a future plan", {
  # --- 1. Setup ---
  # Set a parallel plan for this test only
  old_plan <- future::plan(future::multisession, workers = 2)
  on.exit(future::plan(old_plan), add = TRUE)

  temp_dir <- tempfile("test-")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  # Create several valid Rmd files using generate_reports
  input_list <- generate_reports(
    params_df = tidyr::expand_grid(a = 1, b = 1:3, author = "Parallel Author"),
    template_name = "simple_report",
    output_dir = temp_dir
  )

  # --- 2. Execute in parallel ---
  suppressMessages({
    output_paths <- process_files(input_list)
  })

  # --- 3. Assertions ---
  expect_length(output_paths, 3)
  expect_true(all(!is.na(output_paths))) # All files should succeed
  expect_true(all(file.exists(output_paths)))
})

# Test Case 3: Empty input list
test_that("process_files handles an empty input vector gracefully", {
  suppressMessages({
    output_paths <- process_files(character(0))
  })
  expect_length(output_paths, 0)
})
