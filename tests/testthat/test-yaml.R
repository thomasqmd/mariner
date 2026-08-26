# YAML parsing, front matter extraction, and parameter splicing.

front_matter <- function(path) {
  lines <- readLines(path, warn = FALSE)
  fences <- which(grepl("^(---|\\.\\.\\.)\\s*$", lines))
  yaml::yaml.load(paste(lines[(fences[1] + 1):(fences[2] - 1)], collapse = "\n"))
}

local_dir <- function(env = parent.frame()) {
  withr::local_tempdir(.local_envir = env)
}

test_that("whole numbers do not emit as 3.0", {
  dir <- local_dir()
  file <- suppressMessages(generate_reports(
    params_df = data.frame(chapter = 3, problem_numbers = 7, author = "A"),
    output_dir = dir
  ))

  expect_false(any(grepl("3.0", readLines(file), fixed = TRUE)))
  expect_identical(front_matter(file)$params$chapter, 3L)
})

test_that("logicals in the header survive as true, not yes", {
  dir <- local_dir()
  file <- suppressMessages(generate_reports(
    params_df = data.frame(chapter = 1, problem_numbers = 1, author = "A"),
    output_dir = dir
  ))

  expect_true(any(grepl("keep-tex: true", readLines(file), fixed = TRUE)))
  expect_identical(front_matter(file)$format$`mariner-pdf`$`keep-tex`, TRUE)
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

  emitted <- grep("^title:", readLines(file), value = TRUE)
  expect_match(emitted, "\"`r paste('Report', params$chapter, sep = '.')`\"",
               fixed = TRUE)
  expect_false(grepl("''", emitted, fixed = TRUE))
})

test_that("a param with a null or empty default is substituted", {
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
  expect_true("More text after a horizontal rule." %in% readLines(file))
})

test_that("a template with no front matter is copied through unchanged", {
  dir <- local_dir()
  template <- file.path(dir, "plain.qmd")
  writeLines(c("Just a body.", "No YAML here."), template)

  file <- suppressWarnings(suppressMessages(generate_reports(
    params_df = data.frame(chapter = 1, problem_numbers = 1),
    template_path = template, output_dir = dir
  )))

  expect_equal(readLines(file), c("Just a body.", "No YAML here."))
})
