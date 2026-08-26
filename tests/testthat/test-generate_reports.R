# generate_reports(): YAML-aware param splicing and glue file naming.

# front_matter() and local_dir() come from helper-front-matter.R.

# --- the happy path ----------------------------------------------------------

test_that("generate_reports splices params into .qmd files", {
  dir <- local_dir()
  params <- data.frame(
    chapter = 1, problem_numbers = 1:2, author = "Test Author"
  )

  files <- suppressMessages(generate_reports(
    params_df = params,
    template_name = "report",
    template_package = "mariner",
    output_dir = dir
  ))

  expect_length(files, 2L)
  expect_true(all(file.exists(files)))
  expect_equal(basename(files), c("Report-1_1.qmd", "Report-1_2.qmd"))

  fm <- front_matter(files[[1]])
  expect_equal(fm$params$author, "Test Author")
  expect_equal(fm$params$chapter, 1L)
  expect_equal(fm$params$problem_numbers, 1L)

  expect_equal(front_matter(files[[2]])$params$problem_numbers, 2L)
})

test_that("the returned paths are the ones actually written", {
  # The old implementation recomputed the return value from two hardcoded
  # columns instead of collecting it from the map, so the two could disagree.
  dir <- local_dir()
  files <- suppressMessages(generate_reports(
    params_df = data.frame(chapter = 2, problem_numbers = 5, author = "A"),
    output_dir = dir
  ))

  expect_equal(normalizePath(files), normalizePath(list.files(dir, full.names = TRUE)))
})

# --- warnings and errors -----------------------------------------------------

test_that("an unmatched params_df column warns instead of vanishing", {
  dir <- local_dir()

  expect_warning(
    suppressMessages(generate_reports(
      params_df = data.frame(chapter = 1, problem_numbers = 1, authr = "Typo"),
      output_dir = dir
    )),
    "authr"
  )
})

test_that("unmatched columns warn once, not once per row", {
  dir <- local_dir()
  warnings <- testthat::capture_warnings(
    suppressMessages(generate_reports(
      params_df = data.frame(chapter = 1, problem_numbers = 1:5, authr = "Typo"),
      output_dir = dir
    ))
  )
  expect_length(warnings, 1L)
})

test_that("an unmatched column is still usable in file_name", {
  dir <- local_dir()
  files <- suppressWarnings(suppressMessages(generate_reports(
    params_df = data.frame(chapter = 1, problem_numbers = 1, section = "b"),
    output_dir = dir,
    file_name = "Ch{chapter}-{section}"
  )))
  expect_equal(basename(files), "Ch1-b.qmd")
})

# --- file naming -------------------------------------------------------------

test_that("file_name is a glue template over each row", {
  dir <- local_dir()
  files <- suppressMessages(generate_reports(
    params_df = data.frame(
      chapter = c(1, 2), problem_numbers = c(3, 4), author = "A"
    ),
    output_dir = dir,
    file_name = "ch{chapter}-prob{problem_numbers}"
  ))

  expect_equal(basename(files), c("ch1-prob3.qmd", "ch2-prob4.qmd"))
})

test_that("a params_df without chapter or problem_numbers is an error, not Report-_.qmd", {
  # The old hardcoded name silently produced "Report-_.qmd" -- and every row
  # produced the SAME name, so n rows left one file.
  dir <- local_dir()
  expect_error(
    suppressWarnings(suppressMessages(generate_reports(
      params_df = data.frame(region = "West"),
      output_dir = dir
    ))),
    "chapter"
  )
  expect_length(list.files(dir), 0L)
})

test_that("a file_name that resolves to nothing is refused", {
  # The stem, not the columns: this one names no column at all, so glue
  # succeeds and hands back an empty string. Writing it would produce ".qmd",
  # and every row would produce the same one.
  dir <- local_dir()
  expect_error(
    suppressMessages(generate_reports(
      params_df = data.frame(chapter = 1, problem_numbers = 1),
      output_dir = dir,
      file_name = ""
    )),
    "produced an empty file name"
  )
  expect_length(list.files(dir), 0L)
})

test_that("a file_name of nothing but whitespace is refused too", {
  # "  .qmd" is a legal filename and an unusable one.
  dir <- local_dir()
  expect_error(
    suppressMessages(generate_reports(
      params_df = data.frame(chapter = 1, problem_numbers = 1),
      output_dir = dir,
      file_name = "   "
    )),
    "produced an empty file name"
  )
  expect_length(list.files(dir), 0L)
})

# --- template resolution -----------------------------------------------------

test_that("an unknown template names the ones that exist", {
  expect_error(
    generate_reports(
      params_df = data.frame(chapter = 1, problem_numbers = 1),
      template_name = "nonexistent_template",
      output_dir = local_dir()
    ),
    "report"
  )
})

test_that("a missing template_path errors", {
  expect_error(
    generate_reports(
      params_df = data.frame(chapter = 1, problem_numbers = 1),
      template_path = "non_existent_file.qmd",
      output_dir = local_dir()
    ),
    "not found"
  )
})

test_that("a .Rmd template is refused outright", {
  dir <- local_dir()
  legacy <- file.path(dir, "legacy.Rmd")
  writeLines(c("---", "title: Legacy", "---", "Hello."), legacy)

  expect_error(
    generate_reports(
      params_df = data.frame(chapter = 1, problem_numbers = 1),
      template_path = legacy, output_dir = dir
    ),
    "must be a .qmd file",
    fixed = TRUE
  )
})

test_that("a custom template_path works", {
  dir <- local_dir()
  template <- file.path(dir, "custom.qmd")
  writeLines(
    c("---", "params:", "  region: Midwest", "  author: Default", "---",
      "Region: `r params$region`"),
    template
  )

  file <- suppressMessages(generate_reports(
    params_df = data.frame(region = "West", author = "Custom Author"),
    template_path = template,
    output_dir = dir,
    file_name = "{region}"
  ))

  fm <- front_matter(file)
  expect_equal(fm$params$region, "West")
  expect_equal(fm$params$author, "Custom Author")
})

test_that("missing columns fall back to the template's defaults", {
  dir <- local_dir()
  file <- suppressMessages(generate_reports(
    params_df = data.frame(chapter = 1, problem_numbers = 1),
    output_dir = dir
  ))

  fm <- front_matter(file)
  expect_equal(fm$params$chapter, 1L)
  expect_equal(fm$params$author, "Default Author Name")
})

test_that("output_dir is created if absent", {
  dir <- file.path(local_dir(), "nested", "reports")
  files <- suppressMessages(generate_reports(
    params_df = data.frame(chapter = 1, problem_numbers = 1, author = "A"),
    output_dir = dir
  ))
  expect_true(file.exists(files))
})
