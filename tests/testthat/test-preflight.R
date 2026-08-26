# mariner_check_setup(): the five seconds that replace a half-hour of confusion.
#
# Most of what this function reports is a property of the MACHINE -- whether
# Quarto is installed, whether the fonts are there -- and a test cannot assert
# either answer without asserting something about the runner. So the tests below
# split in two: the checks whose answer is under the test's control are asserted
# outright, and the rest are asserted for SHAPE, which is what the printer and
# the caller actually depend on.

local_dir <- function(env = parent.frame()) {
  withr::local_tempdir(.local_envir = env)
}

# --- template_packages -------------------------------------------------------

test_that("template_packages finds every way a document names a package", {
  dir <- local_dir()
  path <- file.path(dir, "t.qmd")
  writeLines(c(
    "---", "title: T", "---",
    "```{r}",
    "library(tidyverse)",
    "require( patchwork )",
    "requireNamespace(\"tidyr\")",
    "conflicted::conflict_prefer('filter', 'dplyr')",
    "```"
  ), path)

  expect_setequal(
    template_packages(path),
    c("tidyverse", "patchwork", "tidyr", "conflicted")
  )
})

test_that("template_packages does not read package names out of string arguments", {
  # `conflict_prefer("filter", "dplyr")` names dplyr, and this does not find it.
  # The alternative is treating every string literal as a candidate package,
  # which would find "filter" too -- and the miss is covered anyway: nothing
  # calls conflict_prefer without having loaded the package it is arbitrating
  # for, so the `library()` line is picked up instead. Asserted so the limit is
  # a decision rather than something rediscovered later.
  dir <- local_dir()
  path <- file.path(dir, "t.qmd")
  writeLines(c(
    "```{r}",
    "library(conflicted)",
    "conflict_prefer('filter', 'dplyr')",
    "```"
  ), path)

  expect_equal(template_packages(path), "conflicted")
})

test_that("template_packages ignores base packages, mariner and URLs", {
  # `https://quarto.org` is the reason the :: lookahead demands an identifier
  # character after the colons -- without it this file declares a dependency on
  # a package called `https`.
  dir <- local_dir()
  path <- file.path(dir, "t.qmd")
  writeLines(c(
    "See <https://quarto.org/docs/> for more.",
    "```{r}",
    "library(stats)",
    "library(mariner)",
    "utils::head(mtcars)",
    "library(ggplot2)",
    "```"
  ), path)

  expect_equal(template_packages(path), "ggplot2")
})

test_that("every package the packaged template loads is declared in DESCRIPTION", {
  # The invariant P5.5 asks for, written as a test rather than a one-time
  # confirmation. When the setup chunk grows -- rstan, brms, whatever the course
  # needs next -- this is what says "and add it to Suggests" at the moment the
  # line is added, instead of a student on a clean machine saying it later.
  declared <- {
    fields <- utils::packageDescription(
      "mariner", fields = c("Depends", "Imports", "Suggests")
    )
    deps <- unlist(strsplit(unlist(fields[!is.na(fields)]), ","))
    trimws(sub("\\(.*", "", deps))
  }

  pkgs <- template_packages(mariner_template_path("report"))
  expect_gt(length(pkgs), 0L)
  expect_equal(setdiff(pkgs, declared), character())
})

# --- the checks whose answer the test controls -------------------------------

test_that("check_zip round-trips an archive", {
  got <- check_zip()
  expect_equal(got$status, "ok")
})

test_that("check_folders reports what is absent, by directory name", {
  dir <- local_dir()

  absent <- check_folders(dir)
  expect_equal(absent$status, "warn")
  # The DIRECTORY name, not the list-element key: a student reads `zip_files`
  # in the files pane and would not recognise `zips`.
  expect_match(absent$detail, "zip_files", fixed = TRUE)
  expect_equal(absent$remedy, "mariner_setup_project()")

  for (d in mariner_dirs(dir)) dir.create(d, recursive = TRUE)
  expect_equal(check_folders(dir)$status, "ok")
})

test_that("check_extension fails when the theme is not beside the documents", {
  # §0.4. This is a fail rather than a warn because the render does not degrade,
  # it dies -- and it dies naming a font, which says nothing about the cause.
  dir <- local_dir()
  dir.create(mariner_dirs(dir)$reports, recursive = TRUE)

  missing <- check_extension(dir, "mariner")
  expect_equal(missing$status, "fail")
  expect_equal(missing$detail, "not assembled")

  mariner_build_extension(mariner_dirs(dir)$reports, "mariner", quiet = TRUE)
  expect_equal(check_extension(dir, "mariner")$status, "ok")
})

test_that("check_extension notices a half-assembled extension", {
  # The failure mode a bare dir.exists() misses: the directory is there, one
  # font cut is not, and xelatex aborts with "the font Lora-Regular cannot be
  # found" without ever mentioning the extension.
  dir <- local_dir()
  ext <- mariner_build_extension(mariner_dirs(dir)$reports, "mariner", quiet = TRUE)
  file.remove(file.path(ext, "fonts", "Lora-Regular.ttf"))

  got <- check_extension(dir, "mariner")
  expect_equal(got$status, "fail")
  expect_match(got$detail, "1 file missing")
})

test_that("extension_manifest agrees with what the builder writes", {
  # The point of deriving both from EXTENSION_SOURCES: a checker with its own
  # inventory goes stale the first time a font cut or logo slot is added.
  dir <- local_dir()
  ext <- mariner_build_extension(dir, "mariner", quiet = TRUE)

  expect_equal(extension_missing(ext, "mariner"), character())
  expect_true("fonts/Lora-Regular.ttf" %in% extension_manifest("mariner"))
  expect_true("brand-preamble.tex" %in% extension_manifest("mariner"))
  expect_true("_extension.yml" %in% extension_manifest("mariner"))
})

test_that("check_ggplot builds the figure theme", {
  expect_equal(check_ggplot("mariner")$status, "ok")
})

# --- fonts -------------------------------------------------------------------

test_that("check_fonts separates 'not installed' from 'not there at all'", {
  # Both facts are passed in, because on any machine that has loaded mariner the
  # registry answer is TRUE -- .onLoad() put it there -- and a test reading the
  # real ones would be asserting something about the runner.
  all_three <- rep(TRUE, length(DISPLAY_FAMILIES))

  expect_equal(check_fonts(all_three, pdf_ok = TRUE)$status, "ok")

  # The ordinary state of a fresh machine, and the one that matters: mariner
  # can find its own bundled files, cairo_pdf() cannot.
  bundled_only <- check_fonts(all_three, pdf_ok = FALSE)
  expect_equal(bundled_only$status, "warn")
  expect_match(bundled_only$detail, "not installed system-wide")
  expect_equal(bundled_only$remedy, "mariner_install_fonts()")

  # A different problem: the bundled copies are unreachable too.
  broken <- check_fonts(c(TRUE, FALSE, TRUE), pdf_ok = FALSE)
  expect_match(broken$detail, "not resolvable")
  expect_match(broken$detail, DISPLAY_FAMILIES[[2]], fixed = TRUE)
})

test_that("font_resolves reads the family back off the file match_fonts chose", {
  # match_font() ALWAYS returns a font. Asked for a family nobody has, it
  # returns the system fallback and says nothing, so a check that only asked
  # "did it return a path?" would report every machine as fully equipped.
  skip_if_not_installed("systemfonts")
  expect_false(font_resolves("Definitely Not A Real Font 8827"))
})

test_that("the Windows registry value carries the font's own name", {
  # Windows writes `<Full Font Name> (TrueType)`, taken from the font's name
  # table. Deriving it from the filename would give "Lora-Bold (TrueType)" --
  # close enough to look right and wrong enough to leave a duplicate entry when
  # the same face is later installed through Explorer.
  #
  # Pure over the file, so it is checkable from any platform. The registry write
  # itself is not, and is not tested here.
  skip_if_not_installed("systemfonts")
  file <- file.path(mariner_font_dir(), "Lora-Bold.ttf")
  skip_if_not(file.exists(file))

  expect_equal(windows_font_value_name(file), "Lora Bold (TrueType)")
})

test_that("the fontspec Path= is POSIX, on every platform", {
  # fontspec wants forward slashes everywhere, and nothing translates
  # separators for it. The path is a literal in build_preamble() rather than a
  # file.path() call for exactly this reason, and this is what keeps it that
  # way: a backslash here is a Windows-only render failure that no macOS or
  # Linux run would ever show.
  dir <- local_dir()
  ext <- mariner_build_extension(dir, "mariner", quiet = TRUE)
  preamble <- readLines(file.path(ext, "brand-preamble.tex"), warn = FALSE)

  paths <- grep("^\\s*Path=", preamble, value = TRUE)
  expect_gt(length(paths), 0L)
  expect_false(any(grepl("\\", paths, fixed = TRUE)))
  expect_true(all(grepl("Path=_extensions/mariner/fonts/", paths, fixed = TRUE)))
})

# --- the whole report --------------------------------------------------------

test_that("mariner_check_setup returns one row per check, in the vocabulary", {
  dir <- local_dir()
  report <- mariner_check_setup(root = dir, quiet = TRUE)

  expect_s3_class(report, "data.frame")
  expect_equal(names(report), c("check", "status", "detail", "remedy"))
  expect_gte(nrow(report), 8L)
  # The printer switches on this, and its fallback branch is cli_alert_danger --
  # so an unrecognised status would print as a failure without being one.
  expect_true(all(report$status %in% c("ok", "warn", "fail")))
  expect_false(any(is.na(report$remedy)))
  # Every check is named once; a duplicate means two checks are reporting under
  # the same heading and one of them is invisible.
  expect_equal(anyDuplicated(report$check), 0L)
})

test_that("an unset-up directory reports the extension as blocking", {
  dir <- local_dir()
  report <- mariner_check_setup(root = dir, quiet = TRUE)

  folders <- report[report$check == "Project folders", ]
  expect_equal(folders$status, "warn")
  expect_equal(report[report$check == "Theme in reports/", ]$status, "fail")
})

test_that("mariner_check_setup prints without evaluating what it prints", {
  # The P4 lesson, in the one place it would otherwise recur. A detail carrying
  # a brace -- an error message quoting `list(a = 1)`, say -- must be
  # interpolated as a VALUE, not spliced into the format string, or cli reads it
  # back as glue syntax and the whole report dies reporting the problem.
  rows <- rbind(
    check_row("Braces", "fail", "failed with {not_a_variable}", "fix()"),
    check_row("Fine", "ok", "nothing to do")
  )
  expect_no_error(print_check_setup(rows, root = tempdir()))
})

test_that("mariner_check_setup rejects an unknown theme", {
  expect_error(mariner_check_setup(root = local_dir(), theme = "not-a-theme"))
})

# --- quarto and latex --------------------------------------------------------
#
# Both take the machine's answer as an argument, for the reason check_fonts()
# does: the answer belongs to the runner, and a test reading the real one would
# assert something about it.

test_that("check_quarto reports an absent Quarto without asking for a version", {
  # The version argument is a promise. Forcing it on a machine with no Quarto
  # would be a second failed lookup reported as the wrong problem.
  expect_equal(check_quarto(path = NULL)$status, "fail")
  expect_equal(check_quarto(path = "")$status, "fail")
  expect_equal(check_quarto(path = tempfile())$status, "fail")

  row <- check_quarto(path = NULL)
  expect_match(row$detail, "not found")
  expect_match(row$remedy, "quarto.org")
})

test_that("check_quarto warns when the binary is there and the version is not", {
  here <- withr::local_tempfile()
  file.create(here)

  row <- check_quarto(path = here, version = NULL)
  expect_equal(row$status, "warn")
  expect_match(row$detail, "version could not be read")
  # A warn with no remedy: there is nothing to paste.
  expect_identical(row$remedy, "")
})

test_that("check_quarto fails below 1.4 and passes at or above it", {
  # 1.4 is where the extension format this package emits settled. Older Quarto
  # ignores what it does not recognise, so the failure is a document that
  # renders WITHOUT the theme rather than an error.
  here <- withr::local_tempfile()
  file.create(here)

  old <- check_quarto(path = here, version = package_version("1.3.450"))
  expect_equal(old$status, "fail")
  expect_match(old$detail, "1.4 or newer")
  expect_match(old$remedy, "quarto.org")

  expect_equal(check_quarto(path = here, version = package_version("1.4.0"))$status, "ok")
  expect_equal(check_quarto(path = here, version = package_version("1.6.42"))$status, "ok")
  expect_match(check_quarto(path = here, version = package_version("1.6.42"))$detail, "1.6.42")
})

test_that("check_latex accepts TinyTeX or a system xelatex, and nothing else", {
  # xelatex specifically: brand-preamble.tex points fontspec at .ttf files by
  # path, which pdflatex cannot do at all.
  expect_equal(check_latex(tiny = TRUE, xelatex = "")$status, "ok")
  expect_equal(check_latex(tiny = TRUE, xelatex = "")$detail, "TinyTeX")

  found <- check_latex(tiny = FALSE, xelatex = "/usr/local/bin/xelatex")
  expect_equal(found$status, "ok")
  expect_match(found$detail, "/usr/local/bin/xelatex", fixed = TRUE)

  none <- check_latex(tiny = FALSE, xelatex = "")
  expect_equal(none$status, "fail")
  expect_match(none$remedy, "install_tinytex", fixed = TRUE)
})

# --- template packages -------------------------------------------------------

test_that("check_template_packages passes when every package is installed", {
  # A template naming a package this test suite already needs, so the answer is
  # not a property of the runner.
  dir <- local_dir()
  path <- file.path(dir, "t.qmd")
  writeLines(c("```{r}", "library(testthat)", "```"), path)
  local_mocked_bindings(mariner_template_path = function(...) path)

  row <- check_template_packages("report")
  expect_equal(row$status, "ok")
  expect_match(row$detail, "all 1 installed")
  expect_identical(row$remedy, "")
})

test_that("the packaged template reports in the vocabulary either way", {
  # Whether the template's Suggests are installed is the runner's business;
  # that the row is well formed is not.
  row <- check_template_packages("report")
  expect_true(row$status %in% c("ok", "warn"))
  expect_false(is.na(row$remedy))
})

test_that("check_template_packages names what is missing and how to get it", {
  dir <- local_dir()
  path <- file.path(dir, "t.qmd")
  writeLines(c("```{r}", "library(definitelyNotAPackage8827)", "```"), path)
  local_mocked_bindings(mariner_template_path = function(...) path)

  row <- check_template_packages("report")
  expect_equal(row$status, "warn")
  expect_match(row$detail, "definitelyNotAPackage8827")
  expect_match(row$remedy, "install.packages", fixed = TRUE)
})

test_that("a template that does not exist is a warning, not a crash", {
  expect_equal(check_template_packages("not-a-template")$status, "warn")
  expect_match(check_template_packages("not-a-template")$detail, "not found")
})

# --- the printer -------------------------------------------------------------

test_that("the printer closes with the worst status it was given", {
  ok <- rbind(check_row("A", "ok", "fine"), check_row("B", "ok", "fine"))
  expect_match(paste(capture_messages(print_check_setup(ok, tempdir())), collapse = ""),
               "Everything checks out")

  warned <- rbind(check_row("A", "ok", "fine"), check_row("B", "warn", "not quite"))
  expect_match(paste(capture_messages(print_check_setup(warned, tempdir())), collapse = ""),
               "still render")

  failed <- rbind(check_row("A", "warn", "not quite"), check_row("B", "fail", "no"))
  expect_match(paste(capture_messages(print_check_setup(failed, tempdir())), collapse = ""),
               "blocking")
})

test_that("the printer prints a remedy only where there is one", {
  rows <- rbind(check_row("A", "fail", "no", "do_this()"), check_row("B", "ok", "fine"))
  said <- paste(capture_messages(print_check_setup(rows, tempdir())), collapse = "")
  expect_match(said, "do_this()", fixed = TRUE)
})

test_that("print_check_setup returns its input", {
  rows <- check_row("A", "ok", "fine")
  expect_identical(suppressMessages(print_check_setup(rows, tempdir())), rows)
})

test_that("mariner_check_setup prints by default and is silent when told to be", {
  dir <- local_dir()
  expect_message(mariner_check_setup(root = dir), "mariner setup")
  expect_no_message(mariner_check_setup(root = dir, quiet = TRUE))
})
