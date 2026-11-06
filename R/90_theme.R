# Site theme: strategy names, colors, ggplot theme, gt style.
STRAT_ORDER <- c("robust", "textbook", "proportional", "uniform", "risk_ranked")
STRAT_COLS <- c(robust = "#0166CC", textbook = "#D98C3A", proportional = "#8C8C8C",
                uniform = "#B5B5B5", risk_ranked = "#4D4D4D")
STRAT_LABELS <- c(risk_ranked = "Risk-ranked", proportional = "Proportional", uniform = "Uniform",
                  textbook = "Textbook equilibrium", robust = "Robust equilibrium")
STRAT_LTY <- c(robust = "solid", textbook = "dashed", proportional = "dotted",
               uniform = "dotdash", risk_ranked = "longdash")
ASSET_SHORT <- c(PLAT = "Platform", PIPE = "Pipeline", DATA = "Client data",
                 IDP = "Identity", CORP = "Corporate IT", VEND = "Vendor")

theme_se <- function(base_size = 12) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", hjust = 0),
      plot.title.position = "plot",
      plot.subtitle = ggplot2::element_text(color = "gray40", hjust = 0),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "top"
    )
}
ggplot2::theme_set(theme_se())

gt_se <- function(tbl) {
  tbl |>
    gt::tab_options(
      table.font.size = gt::px(13),
      container.overflow.x = TRUE,
      column_labels.background.color = "#F2F2F2",
      row.striping.include_table_body = FALSE,
      table.border.top.style = "none",
      data_row.padding = gt::px(4)
    ) |>
    gt::cols_align(align = "right", columns = tidyselect::where(is.numeric))
}
ASSET_COLS <- c("Platform" = "#5B3A70", "Pipeline" = "#2E7D6B", "Client data" = "#A23B48",
                "Identity" = "#6B6B2E", "Corporate IT" = "#5F7385", "Vendor" = "#9C6A8E")