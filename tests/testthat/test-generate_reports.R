# tests/testthat/test-generate_reports.R

# Test Case 1: Successful Rmd file generation with correct parameter substitution
test_that("generate_reports creates valid Rmd files with correct parameters", {
  # --- 1. Setup ---
  temp_output_dir <- tempfile(pattern = "test-reports-")
  dir.create(temp_output_dir)
  on.exit(unlink(temp_output_dir, recursive = TRUE), add = TRUE)

  report_params <- data.frame(
    chapter = 1,
    problem_numbers = 1:2,
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
  expected_filenames <- paste0("Report-", report_params$a, "_", report_params$b, ".Rmd")
  expect_equal(length(output_files), nrow(report_params))
  expect_true(all(file.exists(output_files)))
  expect_equal(basename(output_files), expected_filenames)

  first_file_content <- readLines(output_files[1])
  expect_true(any(grepl('author: "Test Author"', first_file_content, fixed = TRUE)))
  expect_true(any(grepl("chapter: 1", first_file_content, fixed = TRUE)))
  expect_true(any(grepl("problem_numbers: 1", first_file_content, fixed = TRUE)))
})

# ---
# Test Case 2: Graceful failure with invalid inputs
test_that("generate_reports errors correctly with bad inputs", {
  temp_output_dir <- tempfile(pattern = "bad-inputs-")
  dir.create(temp_output_dir)
  on.exit(unlink(temp_output_dir, recursive = TRUE), add = TRUE)

  valid_params <- data.frame(chapter = 1, problem_numbers = 1, author = "Test")

  expect_error(
    generate_reports(
      params_df = valid_params,
      template_name = "nonexistent_template",
      output_dir = temp_output_dir
    )
  )

  expect_error(
    generate_reports(
      params_df = valid_params,
      template_path = "non_existent_file.Rmd",
      output_dir = temp_output_dir
    )
  )
})

# ---
# Test Case 3: Successful generation from an external template_path
test_that("generate_reports works with a valid template_path", {
  # --- 1. Setup ---
  temp_dir <- tempfile("template-path-test-")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  custom_template_path <- file.path(temp_dir, "custom_template.Rmd")
  writeLines(
    c(
      "---",
      "params:",
      "  region: Midwest",
      "  author: Default",
      "---",
      "Region: `r params$region`"
    ),
    custom_template_path
  )

  report_params <- data.frame(
    chapter = 1,
    problem_numbers = 1,
    region = "West",
    author = "Custom Author"
  )

  # --- 2. Execute ---
  suppressMessages({
    output_files <- generate_reports(
      params_df = report_params,
      template_path = custom_template_path,
      output_dir = temp_dir
    )
  })

  # --- 3. Assertions ---
  expect_true(file.exists(output_files[1]))
  file_content <- readLines(output_files[1])
  expect_true(any(grepl('region: "West"', file_content, fixed = TRUE)))
  expect_true(any(grepl('author: "Custom Author"', file_content, fixed = TRUE)))
})


# ---
# Test Case 4: Handling of extra columns in params_df
test_that("generate_reports ignores extra columns in params_df", {
  temp_dir <- tempfile("extra-cols-")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  report_params <- data.frame(
    chapter = 1,
    problem_numbers = 1,
    author = "Test Author",
    extra_col = "should be ignored"
  )

  expect_no_error({
    suppressMessages({
      output_files <- generate_reports(
        params_df = report_params,
        template_name = "simple_report",
        output_dir = temp_dir
      )
    })
    expect_true(file.exists(output_files[1]))
  })
})

# ---
# Test Case 5: Handling of missing columns in params_df
test_that("generate_reports uses template defaults for missing columns", {
  temp_dir <- tempfile("missing-cols-")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  report_params <- data.frame(chapter = 1, problem_numbers = 1)

  suppressMessages({
    output_files <- generate_reports(
      params_df = report_params,
      template_name = "simple_report",
      output_dir = temp_dir
    )
  })

  expect_true(file.exists(output_files[1]))
  file_content <- readLines(output_files[1])

  expect_true(any(grepl("chapter: 1", file_content, fixed = TRUE)))
  expect_true(any(grepl("problem_numbers: 1", file_content, fixed = TRUE)))

  expect_true(any(grepl('author: "Default Author Name"', file_content, fixed = TRUE)))
})

# ---
# Test Case 6: Correctly substitutes author when provided in params_df
test_that("generate_reports correctly substitutes the author", {
  temp_dir <- tempfile("author-test-")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  report_params <- data.frame(
    chapter = 1,
    problem_numbers = 1,
    author = "New Author Name"
  )

  suppressMessages({
    output_files <- generate_reports(
      params_df = report_params,
      template_name = "simple_report",
      output_dir = temp_dir
    )
  })

  expect_true(file.exists(output_files[1]))
  file_content <- readLines(output_files[1])
  expect_true(any(grepl('author: "New Author Name"', file_content, fixed = TRUE)))
  expect_false(any(grepl('author: "Default Author Name"', file_content, fixed = TRUE)))
})
