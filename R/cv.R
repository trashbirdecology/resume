# Helpers that turn data/*.yml into resume sections.
# Every template sources this file, then calls the render_* functions
# inside chunks with results = "asis".
#
# Only base R + yaml + knitr are used, so it renders anywhere.

library(yaml)

# ---- loading ---------------------------------------------------------------

cv_root <- function(start = getwd()) {
  d <- normalizePath(start)
  while (!file.exists(file.path(d, "data", "experience.yml"))) {
    parent <- dirname(d)
    if (parent == d) stop("Can't find data/experience.yml above ", start)
    d <- parent
  }
  d
}

load_cv <- function(root = cv_root()) {
  files <- list.files(file.path(root, "data"), pattern = "\\.yml$", full.names = TRUE)
  cv <- lapply(files, read_yaml)
  names(cv) <- sub("\\.yml$", "", basename(files))
  priv <- file.path(root, "private.yml")
  cv$private <- if (file.exists(priv)) read_yaml(priv) else list()
  cv$root <- root
  cv
}

# ---- small utilities -------------------------------------------------------

is_latex <- function() isTRUE(knitr::is_latex_output())

# Escape dollar signs so pandoc never reads "$40M ... $" as math.
esc <- function(x) gsub("(?<!\\\\)\\$", "\\\\$", x, perl = TRUE)

squish <- function(x) gsub("\\s+", " ", trimws(x))

fmt_ym <- function(x) {
  x <- as.character(x)
  if (tolower(x) == "present") return("Present")
  if (grepl("^\\d{4}-\\d{2}$", x)) {
    d <- as.Date(paste0(x, "-01"))
    return(format(d, "%b %Y"))
  }
  x
}

date_range <- function(role) {
  if (!is.null(role$dates_note)) return(role$dates_note)
  paste(fmt_ym(role$start), "--", fmt_ym(role$end))
}

# Pick accomplishments from a role.
#   max_priority: keep items with priority <= this
#   tags:         keep items with at least one of these tags (NULL = all)
#   n:            cap on number returned (after sorting by priority)
pick <- function(items, max_priority = 3, tags = NULL, n = Inf,
                 include_unverified = FALSE) {
  if (length(items) == 0) return(list())
  keep <- vapply(items, function(a) {
    p <- if (is.null(a$priority)) 3 else a$priority
    ok <- p <= max_priority
    if (!is.null(tags)) ok <- ok && any(unlist(a$tags) %in% tags)
    if (!include_unverified && !is.null(a$verify)) ok <- FALSE
    ok
  }, logical(1))
  items <- items[keep]
  if (length(items) == 0) return(list())
  pr <- vapply(items, function(a) if (is.null(a$priority)) 3 else a$priority, numeric(1))
  items <- items[order(pr)]          # stable: keeps file order within a priority
  head(items, n)
}

bullets <- function(texts) {
  if (length(texts) == 0) return(invisible())
  cat(paste0("- ", esc(squish(texts)), collapse = "\n"), "\n\n", sep = "")
}

# ---- header ----------------------------------------------------------------

render_header <- function(cv, email = NULL, extra = NULL) {
  p <- cv$profile
  email <- if (is.null(email)) p$email else email
  contact <- c(p$location, cv$private$phone, email)
  line2 <- c(cv$private$citizenship, cv$private$federal_status, extra)
  if (is_latex()) {
    cat("\\begin{center}\n{\\LARGE\\bfseries ", p$name, "}\\\\[2pt]\n",
        paste(contact, collapse = " \\textbar{} "), sep = "")
    if (length(line2)) cat("\\\\\n", paste(line2, collapse = " \\textbar{} "), sep = "")
    cat("\n\\end{center}\n\n")
  } else {
    cat("# ", p$name, "\n\n", paste(contact, collapse = " | "), sep = "")
    if (length(line2)) cat("  \n", paste(line2, collapse = " | "), sep = "")
    cat("\n\n")
  }
}

# ---- experience ------------------------------------------------------------

role_heading <- function(role, cv, federal = FALSE) {
  lines <- paste0("**", role$title, "**, ", role$org)
  sub <- c(role$unit, role$location, date_range(role))
  if (federal) {
    sub <- c(sub, role$series_grade,
             if (!is.null(role$hours)) paste(role$hours, "hrs/wk"))
    sup <- cv$private$supervisor
    if (identical(tolower(as.character(role$end)), "present") && length(sup)) {
      sub <- c(sub, paste0("Supervisor: ", sup$name, ", ", sup$phone,
                           if (isTRUE(sup$may_contact)) "; may contact" else "; contact me first"))
    }
  }
  cat(lines, "  \n", paste(sub, collapse = " | "), "\n\n", sep = "")
}

# Standard experience section.
#   roles:   ids to include (NULL = all)
#   compact: ids to render as one line (title, org, dates) with no bullets
render_experience <- function(cv, max_priority = 3, tags = NULL, n = Inf,
                              roles = NULL, compact = NULL, federal = FALSE,
                              summaries = TRUE, include_unverified = FALSE) {
  for (r in cv$experience) {
    if (!is.null(roles) && !(r$id %in% roles)) next
    if (r$id %in% compact) next
    role_heading(r, cv, federal)
    if (summaries && !is.null(r$summary)) cat(esc(squish(r$summary)), "\n\n")
    items <- pick(r$accomplishments, max_priority, tags, n, include_unverified)
    bullets(vapply(items, `[[`, "", "text"))
  }
  if (length(compact)) {
    cr <- Filter(function(r) r$id %in% compact, cv$experience)
    cat("**Earlier positions**\n\n")
    bullets(vapply(cr, function(r) paste0("**", r$title, "**, ", r$org, ", ", date_range(r)), ""))
  }
}

# SES style: the current role's bullets are organized by ECQ, one strongest
# accomplishment per ECQ, never repeating an accomplishment.
ECQ_NAMES <- c(
  "1" = "Commitment to the Rule of Law and the Principles of the American Founding",
  "2" = "Driving Efficiency",
  "3" = "Merit and Competence",
  "4" = "Leading People",
  "5" = "Achieving Results"
)

render_ecq_role <- function(cv, role_id, per_ecq = 1, include_unverified = FALSE) {
  r <- Filter(function(x) x$id == role_id, cv$experience)[[1]]
  role_heading(r, cv, federal = TRUE)
  if (!is.null(r$summary)) cat(esc(squish(r$summary)), "\n\n")
  items <- pick(r$accomplishments, 2, include_unverified = include_unverified)
  used <- character(0)
  out <- character(0)
  for (k in names(ECQ_NAMES)) {
    hits <- Filter(function(a) as.integer(k) %in% unlist(a$ecq) && !(a$text %in% used), items)
    hits <- head(hits, per_ecq)
    if (!length(hits)) next
    used <- c(used, vapply(hits, `[[`, "", "text"))
    out <- c(out, paste0("**ECQ ", k, ", ", ECQ_NAMES[[k]], ":** ",
                         paste(squish(vapply(hits, `[[`, "", "text")), collapse = " ")))
  }
  bullets(out)
}

# ---- other sections --------------------------------------------------------

render_education <- function(cv, federal = FALSE, details = FALSE, inline = FALSE) {
  ed <- cv$education
  if (inline) {
    cat(paste(vapply(ed[1:3], function(e) paste0("**", e$degree, "**, ", e$school, ", ", e$year), ""),
              collapse = if (is_latex()) " \\textbar{} " else " | "), "\n\n")
    return(invisible())
  }
  for (e in ed) {
    cat("**", e$degree, "**, ", e$school, ", ", e$location, ", ", e$year, sep = "")
    if (federal && !is.null(e$federal_hours)) cat("  \n", e$federal_hours, sep = "")
    if (details && !is.null(e$details)) cat("  \n", e$details, sep = "")
    cat("\n\n")
  }
}

render_awards <- function(cv, max_priority = 3, inline = FALSE, amounts = TRUE,
                          include_unverified = FALSE) {
  a <- pick(cv$awards, max_priority, include_unverified = include_unverified)
  txt <- vapply(a, function(x) {
    s <- paste0(x$text, " (", x$year, ")")
    if (amounts && !is.null(x$amount)) s <- paste0(s, ", ", x$amount)
    s
  }, "")
  if (inline) {
    cat(esc(paste(txt, collapse = if (is_latex()) " \\textbar{} " else " | ")), "\n\n")
  } else bullets(txt)
}

render_simple <- function(items, field = "text", year_field = NULL) {
  bullets(vapply(items, function(x) {
    s <- x[[field]]
    y <- x[[year_field %||% "years"]] %||% x$year
    if (!is.null(y)) s <- paste0(s, ", ", y)
    s
  }, ""))
}

`%||%` <- function(a, b) if (is.null(a)) b else a

render_talks <- function(cv, type) {
  t <- Filter(function(x) x$type %in% type, cv$talks)
  cat(paste0(seq_along(t), ". ", vapply(t, function(x) paste0(x$text, ", ", x$year), ""),
             collapse = "\n"), "\n\n")
}

render_software <- function(cv) {
  bullets(vapply(cv$software, function(s) {
    paste0("[`", s$name, "`](", s$url, "). ", s$authors,
           if (!is.null(s$year)) paste0(" (", s$year, ")") else "",
           ". ", s$description, " *Status: ", s$status, ".*")
  }, ""))
}

pub_counts <- function(cv) {
  bib <- readLines(file.path(cv$root, "data", "publications.bib"), warn = FALSE)
  types <- tolower(sub("^\\s*@\\s*(\\w+).*", "\\1", grep("^\\s*@", bib, value = TRUE)))
  list(articles = sum(types == "article"), chapters = sum(types %in% c("inbook", "incollection")),
       total = length(types))
}

render_pub_line <- function(cv) {
  k <- pub_counts(cv)
  cat(k$total, " publications and software releases, including ", k$articles,
      " journal articles and ", k$chapters, " book chapter",
      if (k$chapters != 1) "s", ". Full list: ", cv$profile$scholar, "\n\n", sep = "")
}

# Lists every accomplishment that still has a verify note.
render_verify_list <- function(cv) {
  out <- character(0)
  for (r in cv$experience) for (a in r$accomplishments)
    if (!is.null(a$verify)) out <- c(out, paste0(r$id, ": ", a$verify))
  for (a in cv$awards) if (!is.null(a$verify)) out <- c(out, paste0("awards: ", a$verify))
  bullets(out)
}
