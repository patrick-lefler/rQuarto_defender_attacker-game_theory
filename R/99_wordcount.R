# Prose word counter. Reader notes (::: {.reader-note} divs) are counted separately.
PAGE_LIMITS <- c("index.qmd" = 600, "01-the-game.qmd" = 750, "02-allocation.qmd" = 950,
                 "03-robustness.qmd" = 950, "04-governance.qmd" = 600)
TOTAL_LIMIT <- 4000
NOTE_SOFT_LIMIT <- 100

count_words <- function(txt) {
  txt <- gsub("`r [^`]*`", " X ", txt)
  txt <- gsub("\\$\\$[\\s\\S]*?\\$\\$", " ", txt, perl = TRUE)
  txt <- gsub("[!]?\\[([^]]*)\\]\\([^)]*\\)", " \\1 ", txt)
  txt <- gsub("[#*_]|:::+|\\{[^}]*\\}", " ", txt)
  w <- strsplit(trimws(txt), "[[:space:]]+")[[1]]
  sum(nzchar(w) & grepl("[[:alnum:]]", w))
}

split_prose <- function(path) {
  x <- readLines(path, warn = FALSE)
  txt <- paste(x, collapse = "\n")
  txt <- sub("^---\n[\\s\\S]*?\n---\n", "", txt, perl = TRUE)
  txt <- gsub("```\\{[^\n]*\\}\n[\\s\\S]*?\n```", "", txt, perl = TRUE)
  txt <- gsub("<!--[\\s\\S]*?-->", "", txt, perl = TRUE)
  notes <- regmatches(txt, gregexpr(":::\\s*\\{\\.reader-note\\}\n[\\s\\S]*?\n:::", txt, perl = TRUE))[[1]]
  txt <- gsub(":::\\s*\\{\\.reader-note\\}\n[\\s\\S]*?\n:::", "", txt, perl = TRUE)
  lines <- strsplit(txt, "\n")[[1]]
  lines <- lines[!grepl("^\\s*\\|", lines) & !grepl("^#\\|", lines)]
  list(prose = paste(lines, collapse = "\n"), notes = notes)
}

wordcount_table <- function(root = ".") {
  rows <- lapply(names(PAGE_LIMITS), function(f) {
    p <- file.path(root, f)
    if (!file.exists(p)) return(data.frame(page = f, prose = NA_integer_, limit = PAGE_LIMITS[[f]],
                                           notes = NA_integer_, n_notes = NA_integer_, max_note = NA_integer_))
    s <- split_prose(p)
    nw <- vapply(s$notes, count_words, numeric(1))
    data.frame(page = f, prose = count_words(s$prose), limit = PAGE_LIMITS[[f]],
               notes = sum(nw), n_notes = length(nw), max_note = if (length(nw)) max(nw) else 0)
  })
  do.call(rbind, rows)
}

wordcount_ok <- function(tbl) {
  have <- tbl[!is.na(tbl$prose), ]
  all(have$prose <= have$limit) && sum(have$prose) <= TOTAL_LIMIT
}

if (sys.nframe() == 0) {
  root <- if (file.exists("_quarto.yml")) "." else ".."
  tb <- wordcount_table(root)
  print(tb, row.names = FALSE)
  cat(sprintf("Prose total: %d / %d\n", sum(tb$prose, na.rm = TRUE), TOTAL_LIMIT))
  cat(sprintf("Reader notes (separate, soft limit %d words each): %d words in %d notes\n",
              NOTE_SOFT_LIMIT, sum(tb$notes, na.rm = TRUE), sum(tb$n_notes, na.rm = TRUE)))
  if (any(tb$max_note > NOTE_SOFT_LIMIT, na.rm = TRUE)) cat("WARNING: a reader note exceeds the soft limit\n")
  if (any(is.na(tb$prose))) cat("Note: missing pages skipped:", tb$page[is.na(tb$prose)], "\n")
  quit(status = if (wordcount_ok(tb)) 0 else 1)
}
