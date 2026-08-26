# The four helpers generate_reports() splices a template with.
#
# test-yaml.R drives them through generate_reports(), which is the behaviour
# that matters. These drive them directly, for the shapes a template would have
# to be malformed to produce and for the branches a whole-file test cannot
# arrange.

# --- split_front_matter ------------------------------------------------------

test_that("a header on line 1 is split from the body that follows it", {
  parts <- split_front_matter(c("---", "title: T", "---", "Body.", "More."))
  expect_identical(parts$header, "title: T")
  expect_identical(parts$body, c("Body.", "More."))
})

test_that("a fence anywhere but line 1 is not front matter", {
  # A document that opens with prose and shows a horizontal rule later has no
  # header, and rewriting from the rule down would destroy it.
  expect_null(split_front_matter(c("Some prose.", "---", "title: T", "---")))
  expect_null(split_front_matter(character()))
  expect_null(split_front_matter("Just a line."))
})

test_that("an unclosed header is not front matter", {
  expect_null(split_front_matter(c("---", "title: T")))
})

test_that("only the first fence after line 1 closes the header", {
  # This is what makes a `---` inside a code chunk harmless.
  parts <- split_front_matter(c(
    "---", "title: T", "---",
    "```{r}", "cat('---')", "```",
    "---",
    "Trailing."
  ))
  expect_identical(parts$header, "title: T")
  expect_identical(parts$body[[1]], "```{r}")
  expect_length(parts$body, 5L)
})

test_that("YAML's other closing fence is accepted", {
  parts <- split_front_matter(c("---", "title: T", "...", "Body."))
  expect_identical(parts$header, "title: T")
  expect_identical(parts$body, "Body.")
})

test_that("an empty header and an empty body are both representable", {
  expect_identical(split_front_matter(c("---", "---"))$header, character())
  expect_identical(split_front_matter(c("---", "title: T", "---"))$body, character())
})

test_that("trailing whitespace on a fence does not hide it", {
  expect_identical(split_front_matter(c("--- ", "title: T", "---  "))$header, "title: T")
})

# --- hide_inline_r / restore_inline_r ----------------------------------------

test_that("an inline-R value is swapped for a bare token", {
  # The token has to be plain alphanumerics, or the emitter quotes it and the
  # substitution afterwards has quotes to step around.
  hidden <- hide_inline_r(list(title = "`r params$chapter`", format = "pdf"))

  expect_length(hidden$values, 1L)
  expect_match(hidden$header$title, "^mariner_inline_r_[0-9]+_sentinel$")
  expect_identical(hidden$header$format, "pdf")
  expect_identical(unname(hidden$values[[1]]), "`r params$chapter`")
})

test_that("inline R is found at any depth", {
  hidden <- hide_inline_r(list(params = list(a = "`r 1`", b = list(c = "`r 2`"))))
  expect_length(hidden$values, 2L)
  expect_false(grepl("`r", hidden$header$params$a, fixed = TRUE))
  expect_false(grepl("`r", hidden$header$params$b$c, fixed = TRUE))
})

test_that("nothing else is touched", {
  header <- list(title = "A report", toc = TRUE, depth = 3L, empty = NULL)
  hidden <- hide_inline_r(header)
  expect_identical(hidden$header, header)
  expect_identical(hidden$values, character())
})

test_that("restore puts the value back in double-quoted style", {
  # knitr reads the RAW LINE. Single-quoted YAML escapes an inner quote by
  # doubling it, so `paste('Report', x)` comes back as `paste(''Report'', x)`
  # and knitr dies on "unexpected symbol".
  values <- c(mariner_inline_r_1_sentinel = "`r paste('Report', params$chapter)`")
  out <- restore_inline_r("title: mariner_inline_r_1_sentinel\n", values)

  expect_identical(out, "title: \"`r paste('Report', params$chapter)`\"\n")
})

test_that("a value carrying a double quote is left bare rather than broken", {
  # There is no representation for it: double-quoted style needs a backslash
  # escape, and knitr would read the backslash as R code.
  values <- c(mariner_inline_r_1_sentinel = '`r paste("Report")`')
  out <- restore_inline_r("title: mariner_inline_r_1_sentinel\n", values)

  expect_identical(out, 'title: `r paste("Report")`\n')
})

test_that("hide and restore are inverses across the round trip", {
  header <- list(title = "`r params$chapter`", author = "A. Name")
  hidden <- hide_inline_r(header)
  text <- yaml::as.yaml(hidden$header)

  expect_match(restore_inline_r(text, hidden$values), "`r params$chapter`", fixed = TRUE)
})

# --- as_param_value ----------------------------------------------------------

test_that("a whole-number double emits as an integer", {
  # R's default numeric type is double, so `chapter = 1` is 1 and not 1L, and
  # `3.0` in the header renders as "Report 3.0" in the title.
  expect_identical(as_param_value(3), 3L)
  expect_identical(as_param_value(-3), -3L)
  expect_identical(as_param_value(0), 0L)
})

test_that("a fractional double stays a double", {
  expect_identical(as_param_value(3.5), 3.5)
})

test_that("a double too large for an integer stays a double", {
  expect_type(as_param_value(.Machine$integer.max + 1), "double")
})

test_that("a factor emits as its label, not its code", {
  expect_identical(as_param_value(factor("Fall", levels = c("Spring", "Fall"))), "Fall")
})

test_that("everything else comes through untouched", {
  expect_identical(as_param_value("A. Name"), "A. Name")
  expect_identical(as_param_value(TRUE), TRUE)
  expect_identical(as_param_value(NA_real_), NA_real_)
  expect_identical(as_param_value(c(1, 2)), c(1, 2))
})
