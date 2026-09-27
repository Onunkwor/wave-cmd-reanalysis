# Reproduce the published descriptive results in R.
#
# The original analysis is a Python notebook (DIB.ipynb, pandas + seaborn)
# published alongside the data. Recomputing the same quantities in R with an
# independent Excel reader is a check that the published numbers follow from
# the deposited file, not a criticism of the original work.

suppressPackageStartupMessages({ library(dplyr); library(tidyr) })

sink_table <- function(x, title) {
  cat("\n== ", title, " ==\n", sep = "")
  print(as.data.frame(x), row.names = FALSE, digits = 4)
}

# --- CMD incidence and symptom severity by year (their cells 12 and 13) ------
by_year <- field |>
  group_by(Year) |>
  summarise(
    fields          = n(),
    incidence_mean  = mean(CMD_Incidence),
    incidence_sd    = sd(CMD_Incidence),
    severity_n      = sum(!is.na(Mean_CMD_Severity)),
    severity_mean   = mean(Mean_CMD_Severity, na.rm = TRUE),
    .groups = "drop"
  )
sink_table(by_year, "CMD incidence and severity by year")

# --- origin of infection by year (their cells 19, 20 and 26) -----------------
origin_year <- field |>
  filter(diseased) |>
  group_by(Year) |>
  summarise(
    fields        = n(),
    cutting_mean  = mean(Cutting_Infection),
    cutting_sd    = sd(Cutting_Infection),
    whitefly_mean = mean(Whitefly_Infection),
    .groups = "drop"
  )
sink_table(origin_year, "Origin of infection by year")

# --- origin of infection by zone (their cell 24) -----------------------------
origin_zone <- field |>
  filter(diseased) |>
  group_by(Zone, Year) |>
  summarise(fields = n(),
            cutting_mean = mean(Cutting_Infection),
            whitefly_mean = mean(Whitefly_Infection), .groups = "drop")
sink_table(origin_zone, "Origin of infection by zone and year")

# --- whitefly abundance by zone (their cell 27) ------------------------------
wf_zone <- field |>
  group_by(Zone, Year) |>
  summarise(fields = n(),
            whitefly_median = median(Total_whitefly),
            whitefly_mean = mean(Total_whitefly),
            whitefly_max = max(Total_whitefly), .groups = "drop")
sink_table(wf_zone, "Whitefly abundance by zone and year")

# --- how much of the disease arrives on the cutting? -------------------------
cut_share <- field |> filter(diseased) |> pull(Cutting_Infection)
cat("\n== Share of infection attributable to planting material ==\n")
cat(sprintf("  diseased fields                        : %d\n", length(cut_share)))
cat(sprintf("  median cutting-borne share             : %.3f\n", median(cut_share)))
cat(sprintf("  mean cutting-borne share               : %.3f\n", mean(cut_share)))
for (thr in c(1.0, 0.9, 0.5)) {
  n <- sum(cut_share >= thr)
  cat(sprintf("  fields where cuttings are >= %3.0f%% of it: %3d (%.1f%%)\n",
              thr * 100, n, 100 * n / length(cut_share)))
}

saveRDS(list(by_year = by_year, origin_year = origin_year,
             origin_zone = origin_zone, wf_zone = wf_zone),
        "output/reproduced.rds")
