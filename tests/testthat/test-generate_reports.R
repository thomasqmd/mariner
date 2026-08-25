# generate_reports(): YAML-aware param splicing and glue file naming.

# Read a generated document's front matter back as a list.
#
# The assertions go through this rather than grepping for `author: "Name"`.
# yaml::as.yaml() quotes only what YAML requires quoting, so the old
# byte-level assertions were testing the emitter's style choices, not whether
# the parameter had been substituted -- and they broke the moment the
# implementation stopped writing the quotes by hand.
front_matter <- function(path) {
  lines <- readLines(path, warn = FALSE)
  fences <- which(grepl("^(---|\\.\\.\\.)\\s*$", lines))
  yaml::yaml.load(paste(lines[(fences[1] + 1):(fences[2] - 1)], collapse = "\n"))
}

local_dir <- function(env = parent.frame()) {
  withr::local_tempdir(.local_envir = env)
}

# --- the happy path ----------------------------------------------------------

test_that("generate_reports splices params into .qmd files", {
  dir <- local_dir()
  params <- data.frame(
    chapter = 1, problem_numbers = 1:2, author = "Test Author"
  )

  files <- suppressMessages(generate_reports(
    params_df = params,
    template_name = "simple_report",
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

# --- what the regex version got wrong ----------------------------------------

test_that("whole numbers do not emit as 3.0", {
  # expand_grid(chapter = 1) gives a DOUBLE. yaml::as.yaml() writes a double as
  # `3.0`, and the template's title pastes params$chapter straight in, so the
  # rendered heading would read "Report.3.0.7".
  dir <- local_dir()
  file <- suppressMessages(generate_reports(
    params_df = data.frame(chapter = 3, problem_numbers = 7, author = "A"),
    output_dir = dir
  ))

  expect_false(any(grepl("3.0", readLines(file), fixed = TRUE)))
  expect_identical(front_matter(file)$params$chapter, 3L)
})

test_that("logicals elsewhere in the header survive as true, not yes", {
  # `yes` is a boolean under YAML 1.1 but a plain STRING under the 1.2 spec
  # Pandoc follows, so keep-tex: yes would quietly stop keeping the .tex.
  dir <- local_dir()
  file <- suppressMessages(generate_reports(
    params_df = data.frame(chapter = 1, problem_numbers = 1, author = "A"),
    output_dir = dir
  ))

  expect_true(any(grepl("keep-tex: true", readLines(file), fixed = TRUE)))
  expect_identical(front_matter(file)$format$pdf$`keep-tex`, TRUE)
})

test_that("inline R in the title survives the round trip", {
  dir <- local_dir()
  template <- file.path(dir, "t.qmd")
  title <- "`r paste('Report', params$chapter, sep = '.')`"
  writeLines(
    c("---", paste0("title: \"", title, "\""), "params:", "  chapter: 1",
      "---", "Body."),
    template
  )

  file <- suppressMessages(generate_reports(
    params_df = data.frame(chapter = 4),
    template_path = template, output_dir = dir, file_name = "{chapter}"
  ))

  expect_identical(front_matter(file)$title, title)

  # The YAML round trip is NOT the whole contract. knitr pulls inline R out of
  # the raw line before any unescaping, so as.yaml's default single-quoted
  # style -- which doubles the inner quotes -- parses back identically and
  # still fails to render with "unexpected symbol". Assert the STYLE.
  emitted <- grep("^title:", readLines(file), value = TRUE)
  expect_match(emitted, "\"`r paste('Report', params$chapter, sep = '.')`\"",
               fixed = TRUE)
  expect_false(grepl("''", emitted, fixed = TRUE))
})

test_that("a param with a null or empty default is substituted", {
  # `(\s*name:\s*).+` could not match a value that was not there, so the regex
  # version left these at the template default.
  dir <- local_dir()
  template <- file.path(dir, "t.qmd")
  writeLines(
    c("---", "params:", "  region:", "  note: ~", "---", "Body."),
    template
  )

  file <- suppressMessages(generate_reports(
    params_df = data.frame(region = "West", note = "hi"),
    template_path = template, output_dir = dir, file_name = "{region}"
  ))

  fm <- front_matter(file)
  expect_equal(fm$params$region, "West")
  expect_equal(fm$params$note, "hi")
})

test_that("a list-valued param is replaced wholesale, not line by line", {
  dir <- local_dir()
  template <- file.path(dir, "t.qmd")
  writeLines(
    c("---", "params:", "  tags:", "    - one", "    - two",
      "  region: Midwest", "---", "Body."),
    template
  )

  file <- suppressMessages(generate_reports(
    params_df = data.frame(region = "West"),
    template_path = template, output_dir = dir, file_name = "{region}"
  ))

  fm <- front_matter(file)
  expect_equal(fm$params$region, "West")
  # The untouched sequence still has both entries.
  expect_equal(fm$params$tags, c("one", "two"))
})

test_that("a --- inside a code chunk is not mistaken for the closing fence", {
  dir <- local_dir()
  template <- file.path(dir, "t.qmd")
  writeLines(
    c("---", "params:", "  region: Midwest", "---", "",
      "Some text.", "", "---", "", "More text after a horizontal rule."),
    template
  )

  file <- suppressMessages(generate_reports(
    params_df = data.frame(region = "West"),
    template_path = template, output_dir = dir, file_name = "{region}"
  ))

  expect_equal(front_matter(file)$params$region, "West")
  # The rule survives in the body rather than being eaten as a delimiter.
  expect_true("More text after a horizontal rule." %in% readLines(file))
})

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
    )))
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
    "simple_report"
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

test_that("a template with no front matter is copied through", {
  dir <- local_dir()
  template <- file.path(dir, "plain.qmd")
  writeLines(c("Just a body.", "No YAML here."), template)

  file <- suppressWarnings(suppressMessages(generate_reports(
    params_df = data.frame(chapter = 1, problem_numbers = 1),
    template_path = template, output_dir = dir
  )))

  expect_equal(readLines(file), c("Just a body.", "No YAML here."))
})

test_that("output_dir is created if absent", {
  dir <- file.path(local_dir(), "nested", "reports")
  files <- suppressMessages(generate_reports(
    params_df = data.frame(chapter = 1, problem_numbers = 1, author = "A"),
    output_dir = dir
  ))
  expect_true(file.exists(files))
})
