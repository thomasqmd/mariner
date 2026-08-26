# The shared helpers, and the guards every entry point runs first.
#
# Each of these is called from several places, so a failure here surfaces as a
# failure somewhere else entirely.

# --- num_str -----------------------------------------------------------------

test_that("num_str rounds to four places and drops the trailing zeros", {
  # The drift test compares bytes, so the point of this function is that the
  # same number formats the same way on every platform and every run.
  expect_identical(num_str(1.405325), "1.4053")
  expect_identical(num_str(2), "2")
  expect_identical(num_str(2.5000), "2.5")
  expect_identical(num_str(0.000012), "0")
})

test_that("num_str never emits scientific notation", {
  # A LaTeX length of "1e+05in" is not a length.
  expect_identical(num_str(100000), "100000")
  expect_false(grepl("e", num_str(0.0001), fixed = TRUE))
})

# --- copy_file_safe ----------------------------------------------------------

test_that("copy_file_safe reports a failed copy rather than returning FALSE", {
  # FALSE is the answer for "the destination was already there". A copy that
  # could not happen has to be told apart from one that was declined, or the
  # scaffolder claims credit for a file it never wrote.
  dir <- withr::local_tempdir()
  expect_error(
    suppressWarnings(copy_file_safe(
      file.path(dir, "no-such-source"), file.path(dir, "dst.txt")
    )),
    "Could not write"
  )
})

test_that("copy_file_safe overwrites when asked", {
  dir <- withr::local_tempdir()
  src <- file.path(dir, "src.txt")
  dst <- file.path(dir, "dst.txt")
  writeLines("new", src)
  writeLines("old", dst)

  expect_false(copy_file_safe(src, dst))
  expect_identical(readLines(dst), "old")

  expect_true(copy_file_safe(src, dst, overwrite = TRUE))
  expect_identical(readLines(dst), "new")
})

# --- mariner_path ------------------------------------------------------------

test_that("mariner_path errors on a path the install does not have", {
  # system.file() returns "" on a miss, which turns a broken install into a
  # confusing error somewhere downstream.
  expect_error(mariner_path("no-such-directory", "no-such-file"), "install may be incomplete")
})

test_that("mariner_path resolves a directory the package ships", {
  expect_true(dir.exists(mariner_path("brand", "mariner")))
})

# --- the argument guards -----------------------------------------------------

test_that("check_theme and check_format accept the shipped values", {
  expect_identical(check_theme("mariner"), "mariner")
  expect_identical(check_format("pdf"), "pdf")
  # The default is the whole vector, which arg_match() reads as "take the first".
  expect_identical(check_theme(mariner_themes), mariner_themes[[1]])
  expect_identical(check_format(mariner_formats), mariner_formats[[1]])
})

test_that("check_theme and check_format reject anything else", {
  expect_error(check_theme("marinerr"), "mariner")
  expect_error(check_format("html"), "pdf")
})

# --- extension path composition ----------------------------------------------

test_that("the extension path is POSIX for the document and native for the disk", {
  # mariner_ext_rel() goes into generated LaTeX, where the separator is "/" on
  # every platform. mariner_ext_dir() goes into file.copy(), where it is the
  # platform's own.
  expect_identical(mariner_ext_name("mariner"), "mariner")
  expect_identical(mariner_ext_rel("mariner"), "_extensions/mariner")
  expect_false(grepl("\\", mariner_ext_rel("mariner"), fixed = TRUE))
  expect_identical(
    mariner_ext_dir("proj", "mariner"),
    file.path("proj", "_extensions", "mariner")
  )
})

# --- %||% --------------------------------------------------------------------

test_that("%||% falls back on NULL and on nothing else", {
  expect_identical(NULL %||% "b", "b")
  expect_identical("a" %||% "b", "a")
  expect_identical(NA %||% "b", NA)
  expect_identical(character() %||% "b", character())
})
