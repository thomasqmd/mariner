# Generating parameterized .qmd sources from a template.
#
# The front matter is parsed, modified and re-emitted as YAML. The version this
# replaced walked lines looking for `^params:` and gsub()ed
# `(\s*name:\s*).+` over the block that followed, which broke on:
#
#   * a param whose default is empty or null    -- `.+` matches nothing
#   * a list- or multi-line value                -- only the first line rewritten
#   * a column absent from the template          -- silently dropped
#   * a `---` inside a code chunk                -- mistaken for the closing fence
#
# All four are structural, not edge cases: the first two are ordinary YAML, and
# the fourth happens in any document that shows a horizontal rule.

# Split a document into front matter and body.
#
# Returns NULL when there is no front matter, which is not an error -- a
# template without a YAML header is written through unchanged.
#
# The opening fence must be line 1. That is what makes a `---` inside a code
# chunk harmless: only the FIRST fence after line 1 closes the block, so a rule
# 40 lines down is body text, not a delimiter. The closing fence may be `...`,
# which YAML allows and Pandoc accepts.
split_front_matter <- function(lines) {
  if (!length(lines) || !grepl("^---\\s*$", lines[[1]])) return(NULL)

  fences <- which(grepl("^(---|\\.\\.\\.)\\s*$", lines))
  fences <- fences[fences > 1L]
  if (!length(fences)) return(NULL)

  close <- fences[[1]]
  list(
    header = if (close > 2L) lines[2:(close - 1L)] else character(),
    body   = if (close < length(lines)) lines[(close + 1L):length(lines)] else character()
  )
}

# Force inline-R values to emit in DOUBLE-quoted YAML style.
#
# This is not cosmetic. knitr pulls `` `r ... ` `` out of the front matter by
# reading the RAW LINE, before any YAML unescaping happens. yaml::as.yaml()
# defaults to single-quoted style, where an inner quote is escaped by doubling
# it, so
#
#   title: "`r paste('Report', params$chapter)`"
#
# came back as
#
#   title: '`r paste(''Report'', params$chapter)`'
#
# which is a correct YAML round trip -- yaml.load() returns the identical
# string -- and a broken document: knitr evaluates `paste(''Report''` and dies
# with "unexpected symbol". Verifying the YAML round trip is not enough; the
# quoting STYLE is part of the contract with knitr.
#
# Double-quoted style leaves inner single quotes untouched, which is what the
# templates use. An inline-R value containing a literal double quote cannot be
# expressed this way -- it would have to be escaped as \" and knitr would read
# the backslash -- but neither can it be expressed in single-quoted style, so
# there is no representation to lose.
# Done in two phases, with a sentinel, rather than by handing as.yaml a
# pre-quoted string. The yaml package's `verbatim` class looks like the right
# tool and is not: it suppresses quoting only for content the emitter considers
# plain, and a string starting with `"` is not plain, so a pre-quoted value
# comes back single-quoted around its own quotes. Substituting a bare token and
# swapping the real value in afterwards sidesteps the emitter's style choice
# entirely, and never parses the YAML it produced with a regex.
INLINE_R_PATTERN <- "`r[ #]"

hide_inline_r <- function(x) {
  found <- new.env(parent = emptyenv())
  found$values <- character()

  walk <- function(v) {
    if (is.list(v)) return(lapply(v, walk))
    if (is.character(v) && length(v) == 1L && !is.na(v) &&
        grepl(INLINE_R_PATTERN, v)) {
      # Plain alphanumerics and underscores, so the emitter writes it bare.
      token <- sprintf("mariner_inline_r_%d_sentinel", length(found$values) + 1L)
      found$values[[token]] <- v
      return(token)
    }
    v
  }

  list(header = walk(x), values = found$values)
}

# Swap the sentinels back, double-quoted.
#
# Double-quoted style leaves inner single quotes untouched, which is what
# templates use. A value containing a literal double quote cannot be expressed
# for knitr in either style -- the escape it needs is a backslash, which knitr
# reads as part of the R code -- so it is left as the sentinel's plain form
# rather than silently producing a document that fails to render.
restore_inline_r <- function(text, values) {
  for (token in names(values)) {
    value <- values[[token]]
    replacement <- if (grepl("[\"\\\\]", value)) value else paste0("\"", value, "\"")
    text <- sub(token, replacement, text, fixed = TRUE)
  }
  text
}

# Coerce one params_df cell into something yaml::as.yaml emits sensibly.
#
# Two conversions, both of which are visible in the rendered report if skipped:
#
#   * A whole-number DOUBLE emits as `3.0`. R's default numeric type is double,
#     so `expand_grid(chapter = 1)` gives 1, not 1L, and the template's
#     `paste('Report', params$chapter, ...)` title then renders "Report.3.0.7".
#   * A FACTOR emits as its integer code. data.frame() no longer creates factors
#     by default, but a params_df built by other means still can.
as_param_value <- function(x) {
  if (is.factor(x)) return(as.character(x))
  if (is.double(x) && length(x) == 1L && !is.na(x) &&
      x == trunc(x) && abs(x) < .Machine$integer.max) {
    return(as.integer(x))
  }
  x
}

#' Create Quarto sources from a template
#'
#' @description
#' Writes one Quarto (`.qmd`) source file per row of `params_df`. Each file gets
#' that row's values in its YAML `params:` block.
#'
#' The template is either one a package ships or a `.qmd` path.
#'
#' @details
#' mariner parses the template front matter as YAML, merges the row into its
#' `params` entry, and re-emits it. Only `params` changes. `title`, `format` and
#' the rest come across untouched, inline R included:
#' `` title: "`r paste('Report', params$chapter)`" ``.
#'
#' A column of `params_df` with no counterpart in the template's `params` block
#' is not substituted, and warns. That case is a typo or a template mismatch,
#' and the old behaviour dropped it in silence.
#'
#' @param params_df A data frame, one row per report. Column names match the
#'   parameter names in the template's `params:` block.
#' @param template_name A template directory that `template_package` ships.
#'   Ignored when `template_path` is given.
#' @param template_package Installed package to look for `template_name` in.
#' @param output_dir Where the `.qmd` files go. Defaults to the project's
#'   `reports/` folder. See [mariner_dirs()]. Created if it is missing.
#' @param template_path A `.qmd` path to use instead of a packaged template.
#' @param file_name A [glue::glue()] template for the output names, evaluated
#'   against each row of `params_df`. Leave off the `.qmd` extension; mariner
#'   adds it. Every column that varies has to appear here, or two rows resolve to
#'   one name and the second overwrites the first.
#'
#' @return Invisibly, a character vector of the paths written.
#' @export
#' @importFrom purrr pmap_chr
#' @importFrom fs dir_create
#' @importFrom tools file_ext
#'
#' @examples
#' temp_dir <- tempfile("mariner-example-")
#'
#' report_params <- data.frame(
#'   chapter = 1,
#'   problem_numbers = 1:2,
#'   author = "Firstname Lastname"
#' )
#'
#' qmd_files <- generate_reports(
#'   params_df = report_params,
#'   template_name = "report",
#'   output_dir = temp_dir
#' )
#'
#' basename(qmd_files)
#'
#' # A different naming scheme:
#' generate_reports(
#'   params_df = report_params,
#'   output_dir = temp_dir,
#'   file_name = "ch{chapter}-prob{problem_numbers}"
#' ) |> basename()
#'
#' unlink(temp_dir, recursive = TRUE)
generate_reports <- function(
  params_df,
  template_name = "report",
  template_package = "mariner",
  output_dir = mariner_dirs()$reports,
  template_path = NULL,
  file_name = "Report-{chapter}_{problem_numbers}"
) {
  template_file <- resolve_template(
    template_name, template_package, template_path
  )

  lines <- readLines(template_file, warn = FALSE)
  parts <- split_front_matter(lines)

  # A template with no front matter has no params to splice. It is still copied
  # once per row, because the file names differ and the caller asked for n
  # files -- but there is nothing to warn about beyond that.
  header <- if (is.null(parts)) NULL else {
    yaml::yaml.load(paste(parts$header, collapse = "\n"))
  }
  template_params <- header$params

  # Warned once, listing every offender, rather than once per row. A 50-row
  # params_df with a mistyped column would otherwise emit 50 identical warnings
  # and bury whatever else the call had to say.
  unmatched <- setdiff(names(params_df), names(template_params))
  if (length(unmatched)) {
    cli::cli_warn(c(
      "{length(unmatched)} column{?s} in {.arg params_df} {?has/have} no matching \\
       parameter in the template: {.val {unmatched}}.",
      i = "The template's {.code params:} block declares: \\
           {.val {names(template_params)}}.",
      # qty() supplies the count for the plurals in this bullet. cli resolves
      # {?a/b} against a quantity in the SAME string, and there is no
      # interpolated vector here to infer one from.
      i = "{cli::qty(length(unmatched))}{?This value was/These values were} \\
           not substituted."
    ))
  }
  matched <- intersect(names(params_df), names(template_params))

  fs::dir_create(output_dir)

  write_one <- function(...) {
    row <- list(...)

    # glue over the row, not over params_df, so `file_name` can reference any
    # column -- including one the template has no parameter for, which is a
    # perfectly good thing to name a file after.
    stem <- as.character(glue::glue_data(row, file_name, .na = "NA"))
    if (!nzchar(stem) || grepl("^\\s+$", stem)) {
      cli::cli_abort(c(
        "{.arg file_name} produced an empty file name.",
        i = "Template: {.val {file_name}}.",
        i = "Available columns: {.val {names(params_df)}}."
      ))
    }
    target <- file.path(output_dir, paste0(stem, ".qmd"))

    if (is.null(parts)) {
      writeLines(lines, target)
      return(target)
    }

    out_header <- header
    if (length(matched)) {
      out_header$params <- utils::modifyList(
        template_params,
        lapply(row[matched], as_param_value)
      )
    }

    writeLines(
      c(
        "---",
        # verbatim_logical, or every logical in the header emits as `yes`/`no`.
        # Those are booleans under YAML 1.1 but plain STRINGS under the 1.2
        # spec Pandoc follows, so `keep-tex: yes` would silently stop keeping
        # the .tex -- a setting that fails by doing nothing.
        {
          hidden <- hide_inline_r(out_header)
          emitted <- yaml::as.yaml(
            hidden$header,
            handlers = list(logical = yaml::verbatim_logical)
          )
          sub("\n$", "", restore_inline_r(emitted, hidden$values))
        },
        "---",
        parts$body
      ),
      target
    )
    target
  }

  cli::cli_alert_info("Generating {nrow(params_df)} qmd file{?s}...")

  # pmap_chr, not pwalk plus a recomputed vector of expected names. The old
  # version built the return value a second time from the same two hardcoded
  # columns, so a change to either naming site drifted from the other and the
  # function returned paths that did not exist.
  output_paths <- purrr::pmap_chr(params_df, write_one)

  cli::cli_alert_success(
    "Wrote {length(output_paths)} file{?s} to {.file {output_dir}}"
  )
  invisible(output_paths)
}

# Find the template to generate from, as a path to a .qmd file.
#
# P6 replaces the inst/rmarkdown/templates/ lookup with a registry
# (mariner_templates(), mariner_template_path()). Both callers -- this and
# mariner_setup_project() -- go through one function each so that is one edit.
resolve_template <- function(template_name, template_package, template_path,
                             call = rlang::caller_env()) {
  if (!is.null(template_path)) {
    if (!file.exists(template_path)) {
      cli::cli_abort("Template file not found: {.file {template_path}}.", call = call)
    }
    if (!identical(tolower(tools::file_ext(template_path)), "qmd")) {
      cli::cli_abort(
        c(
          "Template must be a .qmd file.",
          x = "Got {.file {basename(template_path)}}.",
          i = "mariner is Quarto-only as of 0.2.0."
        ),
        call = call
      )
    }
    return(template_path)
  }

  mariner_template_path(template_name, package = template_package, call = call)
}
