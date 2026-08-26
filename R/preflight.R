# Answering "will a branded report actually render on this machine?" in one call.
#
# WHY THIS EXISTS. Every way this package fails on a student's machine fails
# LATE and fails OBSCURELY. There is no LaTeX engine, so quarto reports a
# non-zero exit and a wall of pandoc output. The fonts are not installed, so the
# page text is Lora and every figure is Helvetica, and nothing anywhere says so.
# mariner_setup_project() was never run, so xelatex aborts with "the font
# Lora-Regular cannot be found" -- a font error for what is really a missing
# directory.
#
# Each of those is a five-second check ahead of time and a half-hour of
# confusion afterwards. This file is the five seconds.
#
# It reports and does not repair. Every remedy is a line the reader can copy,
# which is a deliberate choice: this is the function a vignette opens with and
# the one a student runs when something is wrong, and neither is a good moment
# to start writing to their font directory. mariner_install_fonts() already
# exists and already asks.

# The families a report draws in. Named as _brand.yml names them, because that
# is the name theme_mariner() asks the device for.
DISPLAY_FAMILIES <- c("Atkinson Hyperlegible", "Lora", "JetBrains Mono")

# Packages that ship with R. A template naming one of these needs no Suggests
# entry, so they are excluded from what template_packages() reports.
BASE_PACKAGES <- c(
  "base", "compiler", "datasets", "graphics", "grDevices", "grid", "methods",
  "parallel", "splines", "stats", "stats4", "tcltk", "tools", "utils"
)

# One row of the report. Kept as a constructor rather than written inline at
# each site so a new column is one edit, and so `remedy` is never accidentally
# NA -- the printer tests it with nzchar().
check_row <- function(check, status, detail, remedy = "") {
  data.frame(
    check = check, status = status, detail = detail, remedy = remedy,
    stringsAsFactors = FALSE
  )
}

# Which packages a .qmd needs in order to render.
#
# Textual, deliberately, and not a call to parse(). A .qmd's chunks are not R
# code until knitr has extracted them; the same file can carry chunks in other
# engines; and an inline `r ...` span is not valid R in the surrounding
# markdown. A regex over the source answers the question actually being asked --
# "which package names does this document mention?" -- without needing the
# document to be executable first.
#
# Over-reporting is the safe direction: a name picked up from a comment costs a
# Suggests entry, whereas a name missed costs a student a render failure naming
# a package they have never heard of.
template_packages <- function(path) {
  text <- paste(readLines(path, warn = FALSE), collapse = "\n")

  # library(x), require(x), requireNamespace("x"), with any spacing or quoting.
  # Matched whole and then trimmed, rather than with a lookbehind: PCRE
  # lookbehind is fixed-width, so `library(  x` would slip past one.
  hits <- unlist(regmatches(text, gregexpr(
    "\\b(?:library|require|requireNamespace)\\s*\\(\\s*[\"']?[A-Za-z][A-Za-z0-9._]*",
    text, perl = TRUE
  )))
  from_calls <- sub("^.*[([:space:]\"']", "", hits)

  # pkg:: and pkg:::. The lookahead demands an identifier character after the
  # colons so that a URL -- `https://quarto.org` -- does not read as a package
  # named `https`.
  qualified <- unlist(regmatches(text, gregexpr(
    "[A-Za-z][A-Za-z0-9._]*(?=:::?[A-Za-z.])", text, perl = TRUE
  )))

  sort(setdiff(unique(c(from_calls, qualified)), c("mariner", BASE_PACKAGES)))
}

# --- the individual checks ---------------------------------------------------

# The two facts are arguments, for the reason check_fonts()'s are: the answer
# belongs to the machine, so a test reading the real ones would assert something
# about the runner rather than about this function.
check_quarto <- function(path = tryCatch(quarto::quarto_path(), error = function(e) NULL),
                         version = tryCatch(quarto::quarto_version(), error = function(e) NULL)) {
  if (is.null(path) || !nzchar(path) || !file.exists(path)) {
    return(check_row(
      "Quarto", "fail", "not found on this machine",
      "Install Quarto: https://quarto.org/docs/get-started/"
    ))
  }

  # `version` is a promise until here, so a machine with no Quarto is never
  # asked for one -- the guard above returns first.
  if (is.null(version)) {
    return(check_row("Quarto", "warn", "found, but its version could not be read"))
  }
  # 1.4 is where the extension format this package emits settled. Older Quarto
  # reads _extension.yml and quietly ignores what it does not recognise, so the
  # failure is a document that renders WITHOUT the theme rather than an error.
  if (version < "1.4") {
    return(check_row(
      "Quarto", "fail", paste0("version ", version, "; mariner needs 1.4 or newer"),
      "Update Quarto: https://quarto.org/docs/get-started/"
    ))
  }
  check_row("Quarto", "ok", paste0("version ", version))
}

# Is there an engine that can typeset the preamble this package emits?
#
# Both, because neither alone is sufficient. TinyTeX installs into the user's
# home directory and is put on the PATH by the tinytex package at load time, so
# it can be present and invisible to Sys.which() in a session that has not
# loaded it; a system TeX Live is on the PATH and invisible to is_tinytex().
#
# Arguments, for the reason check_fonts()'s are.
check_latex <- function(tiny = requireNamespace("tinytex", quietly = TRUE) &&
                          isTRUE(tryCatch(tinytex::is_tinytex(), error = function(e) FALSE)),
                        xelatex = Sys.which("xelatex")) {
  # xelatex specifically, not "a LaTeX engine". brand-preamble.tex loads
  # fontspec and points it at .ttf files by path, which pdflatex cannot do at
  # all -- a distribution with only pdflatex fails on the first \setmainfont.
  if (tiny) {
    return(check_row("LaTeX", "ok", "TinyTeX"))
  }
  if (nzchar(xelatex)) {
    return(check_row("LaTeX", "ok", paste0("xelatex at ", xelatex)))
  }
  check_row(
    "LaTeX", "fail", "no xelatex on this machine",
    'install.packages("tinytex"); tinytex::install_tinytex()'
  )
}

# Does asking for this family actually get this family?
#
# systemfonts::match_font() ALWAYS returns a font. Asked for a family that is
# not installed it returns the system fallback and says nothing about the
# substitution, so "did it return something?" is not the question -- the answer
# has to be read back off the file it chose.
font_resolves <- function(family) {
  if (!requireNamespace("systemfonts", quietly = TRUE)) return(FALSE)

  # match_fonts(), not match_font(): the singular form is soft-deprecated as of
  # systemfonts 1.1.0 and warns once per session, which in a preflight would
  # print a deprecation notice in the middle of the report it is writing.
  path <- tryCatch(systemfonts::match_fonts(family)$path, error = function(e) NULL)
  if (is.null(path) || !nzchar(path)) return(FALSE)

  got <- tryCatch(
    systemfonts::font_info(path = path, index = 0)$family[[1]],
    error = function(e) ""
  )
  # startsWith rather than identical: the bundled variable files carry
  # "Atkinson Hyperlegible Next", and matching the shorter name against it is a
  # hit, not a fallback.
  nzchar(got) && startsWith(tolower(got), tolower(family))
}

# The two font questions, and why both are asked.
#
# `resolved` is what systemfonts can find by name. That includes the REGISTRY,
# which this package populates from its own bundled files at load time -- so on
# a machine that has never installed a thing, all three families resolve. This
# is not the same as reassurance; it is mariner agreeing with itself.
#
# `pdf_ok` is mariner_fonts_available("pdf"), which asks whether the faces are
# INSTALLED, because cairo_pdf() reads fontconfig and ignores the registry
# entirely (the long note at the top of R/fonts.R). That is the question the
# device drawing a PDF figure will actually ask.
#
# So the interesting state is not the two disagreeing -- it is the ordinary one:
# resolved yes, installed no. Page text comes out in Lora, because fontspec
# reads the bundled files by path, and every figure comes out in the device
# default. One document, two typefaces, and nothing anywhere saying so.
#
# Both facts are arguments so the branches can be tested without the test
# asserting something about the machine it happens to be running on.
check_fonts <- function(resolved = vapply(DISPLAY_FAMILIES, font_resolves, logical(1)),
                        pdf_ok = mariner_fonts_available("pdf")) {
  remedy <- "mariner_install_fonts()"

  if (all(resolved) && pdf_ok) {
    return(check_row("Figure fonts", "ok", "all three families installed"))
  }

  # Unresolvable means even the bundled copies are unreachable -- a broken
  # install rather than an un-installed font, and a different problem from the
  # one below.
  if (!all(resolved)) {
    return(check_row(
      "Figure fonts", "warn",
      paste0("not resolvable: ", paste(DISPLAY_FAMILIES[!resolved], collapse = ", ")),
      remedy
    ))
  }

  # A warning, not a failure: the report still renders, just not as intended.
  check_row(
    "Figure fonts", "warn",
    paste0(
      "bundled but not installed system-wide; PDF figures will fall back to ",
      "the device default. Install, then restart R"
    ),
    remedy
  )
}

check_zip <- function() {
  # Round-tripped rather than assumed present. zip is an Imports, so the
  # namespace is always there; what this proves is that it can write and read
  # back on this filesystem, which is the part that fails on a locked-down
  # machine or a full disk.
  dir <- tempfile("mariner-zip-check-")
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(dir, recursive = TRUE, force = TRUE), add = TRUE)

  writeLines("mariner", file.path(dir, "probe.txt"))
  archive <- file.path(dir, "probe.zip")

  ok <- tryCatch({
    zip::zip(zipfile = archive, files = "probe.txt", root = dir)
    "probe.txt" %in% zip::zip_list(archive)$filename
  }, error = function(e) FALSE)

  if (isTRUE(ok)) {
    return(check_row("Zip archives", "ok", "created and read back"))
  }
  check_row(
    "Zip archives", "fail", "could not create a zip archive in the temp directory",
    "Check that R can write to tempdir()"
  )
}

check_folders <- function(root) {
  dirs <- mariner_dirs(root)
  absent <- names(dirs)[!dir.exists(unlist(dirs, use.names = FALSE))]

  if (!length(absent)) {
    return(check_row("Project folders", "ok", "assets/, reports/, zip_files/"))
  }
  # Warn, not fail: generate_reports() and process_file() create what they need.
  # What is missing is the setup, and saying so is more useful than saying the
  # render will break, because it will not.
  check_row(
    "Project folders", "warn",
    paste0("missing: ", paste(unlist(MARINER_DIR_NAMES[absent]), collapse = ", ")),
    "mariner_setup_project()"
  )
}

check_extension <- function(root, theme) {
  ext <- mariner_ext_dir(mariner_dirs(root)$reports, theme)
  missing <- extension_missing(ext, theme)

  if (!length(missing)) {
    return(check_row("Theme in reports/", "ok", mariner_ext_rel(theme)))
  }
  # A failure, unlike the folders. This is §0.4: the extension has to sit beside
  # the documents, and a render that cannot find it dies naming a font.
  detail <- if (!dir.exists(ext)) {
    "not assembled"
  } else {
    paste0(length(missing), " file", if (length(missing) > 1) "s", " missing, ",
           "starting with ", missing[[1]])
  }
  check_row("Theme in reports/", "fail", detail, "mariner_setup_project()")
}

check_ggplot <- function(theme) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    return(check_row(
      "Figure theme", "fail", "ggplot2 is not installed",
      'install.packages("ggplot2")'
    ))
  }
  err <- NULL
  ok <- tryCatch({ theme_mariner(theme = theme); TRUE },
                 error = function(e) { err <<- conditionMessage(e); FALSE })

  if (isTRUE(ok)) {
    return(check_row("Figure theme", "ok", "theme_mariner() builds"))
  }
  check_row("Figure theme", "fail", paste0("theme_mariner() failed: ", err))
}

check_template_packages <- function(template) {
  path <- tryCatch(mariner_template_path(template), error = function(e) NULL)
  if (is.null(path)) {
    return(check_row(
      "Template packages", "warn", paste0("template ", template, " not found")
    ))
  }

  pkgs <- template_packages(path)
  have <- vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)
  missing <- pkgs[!have]

  if (!length(missing)) {
    return(check_row(
      "Template packages", "ok",
      paste0("all ", length(pkgs), " installed")
    ))
  }
  check_row(
    "Template packages", "warn",
    paste0("missing: ", paste(missing, collapse = ", ")),
    paste0('install.packages(c("', paste(missing, collapse = '", "'), '"))')
  )
}

#' Check that this machine can render a mariner report
#'
#' Checks what a report needs: Quarto, a LaTeX engine, the fonts, the project
#' folders, the theme, and the packages the template loads. One line per check,
#' with the fix to paste for anything that is wrong.
#'
#' Nothing is installed or changed. You run the remedies.
#'
#' @section What the statuses mean:
#' \describe{
#'   \item{ok}{Nothing to do.}
#'   \item{warn}{The report renders, but not as intended. Usually the figures
#'     come out in the device's default typeface while the page text does not.}
#'   \item{fail}{The render will not complete.}
#' }
#'
#' @param root Project root to check. `NULL` (the default) resolves it with
#'   [mariner_project_root()].
#' @param theme One of [mariner_themes].
#' @param template Starter template whose package dependencies to check.
#' @param quiet Return the data frame without printing it.
#' @return Invisibly, a data frame with one row per check and the columns
#'   `check`, `status` (`"ok"`, `"warn"` or `"fail"`), `detail` and `remedy`.
#' @seealso [mariner_setup_project()], [mariner_install_fonts()]
#' @export
#' @examples
#' \dontrun{
#' mariner_check_setup()
#'
#' # Just the problems:
#' report <- mariner_check_setup(quiet = TRUE)
#' subset(report, status != "ok")
#' }
mariner_check_setup <- function(root = NULL,
                                theme = mariner_themes,
                                template = "report",
                                quiet = FALSE) {
  theme <- check_theme(theme)
  # Resolved once and passed down, so two checks cannot report on two different
  # projects if the working directory moves under them.
  root <- if (is.null(root)) mariner_project_root() else root

  out <- rbind(
    check_quarto(),
    check_latex(),
    check_fonts(),
    check_zip(),
    check_folders(root),
    check_extension(root, theme),
    check_ggplot(theme),
    check_template_packages(template)
  )

  if (!quiet) print_check_setup(out, root)
  invisible(out)
}

print_check_setup <- function(out, root) {
  cli::cli_h1("mariner setup")
  cli::cli_alert_info("Project: {.file {root}}")

  for (i in seq_len(nrow(out))) {
    # The detail is interpolated as a VALUE, not spliced into the format string:
    # an error message carrying a brace would otherwise be re-read as glue
    # syntax and taken down the whole report with it.
    line <- "{.strong {out$check[[i]]}}: {out$detail[[i]]}"
    switch(
      out$status[[i]],
      ok   = cli::cli_alert_success(line),
      warn = cli::cli_alert_warning(line),
      cli::cli_alert_danger(line)
    )
    if (nzchar(out$remedy[[i]])) {
      cli::cli_bullets(c(" " = "{.code {out$remedy[[i]]}}"))
    }
  }

  fails <- sum(out$status == "fail")
  warns <- sum(out$status == "warn")

  if (fails) {
    cli::cli_alert_danger(
      "{fails} check{?s} {?is/are} blocking: a report will not render until \\
       {?it is/they are} fixed."
    )
  } else if (warns) {
    cli::cli_alert_warning(
      "{warns} check{?s} {?needs/need} attention; reports will still render."
    )
  } else {
    cli::cli_alert_success("Everything checks out.")
  }

  invisible(out)
}
