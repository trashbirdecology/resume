#!/usr/bin/env Rscript
# Render resumes from the data in data/.
#
#   Rscript build.R extended          -> extended-cv.md (the public running list)
#   Rscript build.R federal           -> output/burnett_federal.pdf
#   Rscript build.R ses industry      -> several at once
#   Rscript build.R all               -> everything
#   Rscript build.R federal --docx    -> also write a .docx
#
# output/ is gitignored. Put private.yml (see private.example.yml) in the repo
# root to include your phone and supervisor contact in application versions.

args <- commandArgs(trailingOnly = TRUE)
docx <- "--docx" %in% args
args <- setdiff(args, "--docx")
if (!length(args) || "all" %in% args) args <- c("extended", "federal", "ses", "industry")

root <- normalizePath(dirname(sub("--file=", "", grep("--file=", commandArgs(), value = TRUE)[1])))
if (is.na(root)) root <- getwd()
dir.create(file.path(root, "output"), showWarnings = FALSE)

for (a in args) {
  if (a == "extended") {
    rmarkdown::render(file.path(root, "templates", "extended-cv.Rmd"),
                      output_format = "md_document", output_dir = root,
                      output_file = "extended-cv.md", quiet = TRUE)
    message("wrote extended-cv.md")
    next
  }
  src <- file.path(root, "templates", paste0(a, ".Rmd"))
  if (!file.exists(src)) stop("No template called ", a)
  fmts <- c("pdf_document", if (docx) "word_document")
  for (f in fmts) {
    out <- rmarkdown::render(src, output_format = f, output_dir = file.path(root, "output"),
                             output_file = paste0("burnett_", a), quiet = TRUE)
    message("wrote ", sub(paste0(root, "/"), "", out))
  }
}
