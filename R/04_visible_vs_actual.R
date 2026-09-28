# What a visual survey can and cannot see.
#
# CMD_Incidence in the Field sheet counts plants showing symptoms. The Lab
# sheet tests individual plants for the viruses themselves. Setting one against
# the other says how much of the infection a walk through the field can detect.

suppressPackageStartupMessages({ library(dplyr); library(ggplot2); library(scales) })

cassava <- lab |>
  filter(Host == "Cassava", !is.na(Symptom)) |>
  mutate(
    Year       = as.integer(Year),
    symptomatic = Symptom == 1,
    infected    = Result != "Negative"
  )

# --- the eye against the laboratory ------------------------------------------
tab <- cassava |>
  group_by(symptomatic) |>
  summarise(virus_detected = sum(infected),
            no_virus = sum(!infected),
            total = n(),
            pct_positive = 100 * sum(infected) / n(), .groups = "drop")
cat("\n== Eye versus laboratory (cassava samples) ==\n")
print(as.data.frame(tab), row.names = FALSE, digits = 3)

infected <- cassava |> filter(infected)
hidden   <- infected |> filter(!symptomatic)
cat(sprintf("\n  infected plants                         : %d\n", nrow(infected)))
cat(sprintf("  of those, showing no symptoms at all    : %d (%.1f%%)\n",
            nrow(hidden), 100 * nrow(hidden) / nrow(infected)))
cat(sprintf("  healthy-looking plants carrying virus   : %d of %d (%.1f%%)\n",
            nrow(hidden), sum(!cassava$symptomatic),
            100 * nrow(hidden) / sum(!cassava$symptomatic)))
symp_neg <- cassava |> filter(symptomatic, !infected)
cat(sprintf("  symptomatic plants with no virus found  : %d (%.1f%% of symptomatic)\n",
            nrow(symp_neg), 100 * nrow(symp_neg) / sum(cassava$symptomatic)))

# --- and it moved between the two surveys ------------------------------------
by_year <- infected |>
  group_by(Year) |>
  summarise(infected = n(),
            symptomless = sum(!symptomatic),
            pct_symptomless = 100 * sum(!symptomatic) / n(), .groups = "drop")
cat("\n== Share of infections that were symptomless, by year ==\n")
print(as.data.frame(by_year), row.names = FALSE, digits = 3)

# --- IMPORTANT CAVEAT, quantified --------------------------------------------
# The tested plants are not a random sample of the field. If symptomatic plants
# were preferentially collected, then among infected plants the sample
# over-represents the visible ones, and the figures above are a floor.
lab_symp   <- mean(cassava$symptomatic)
field_vis  <- mean(field$CMD_Incidence)
cat("\n== Was the tested subsample enriched for symptomatic plants? ==\n")
cat(sprintf("  symptomatic share of tested plants     : %.1f%% (n = %d)\n",
            100 * lab_symp, nrow(cassava)))
cat(sprintf("  mean visual incidence across 512 fields: %.1f%%\n", 100 * field_vis))
cat(sprintf("  enrichment                             : %.2fx\n", lab_symp / field_vis))
cat("  The sample favours visible infections, so the symptomless shares above\n")
cat("  are a lower bound rather than an estimate.\n")

# --- fields that looked clean ------------------------------------------------
# Field_Lab is not usable for this: it contains no Negative rows at all, so it
# appears to list only fields where something was found. The Lab sheet does
# record negatives, so the question is asked there instead.
cat(sprintf("\n  (Field_Lab holds %d 'Negative' rows out of %d, hence unusable here)\n",
            sum(field_lab$Result == "Negative"), nrow(field_lab)))

key <- function(d) paste(as.integer(d$Year), d$State, d$Field, sep = "|")
clean_keys <- key(field)[field$CMD_Incidence == 0]
clean_tested <- cassava |>
  mutate(k = key(cassava)) |>
  filter(k %in% clean_keys) |>
  group_by(k) |>
  summarise(plants_tested = n(), any_positive = any(infected), .groups = "drop")

cat("\n== Fields with no visible symptoms at all ==\n")
cat(sprintf("  such fields with at least one plant tested: %d\n", nrow(clean_tested)))
cat(sprintf("  at least one plant virus-positive         : %d (%.1f%%)\n",
            sum(clean_tested$any_positive),
            100 * mean(clean_tested$any_positive)))
cat(sprintf("  plants tested per field                   : %s\n",
            paste(sprintf("%d plants: %d fields", as.integer(names(table(clean_tested$plants_tested))),
                          as.vector(table(clean_tested$plants_tested))), collapse = "; ")))

# --- non-cassava hosts --------------------------------------------------------
alt <- lab |> filter(Host == "Alternate Host")
cat("\n== Non-cassava plants sampled ==\n")
cat(sprintf("  sampled: %d, carrying a cassava mosaic virus: %d (%.1f%%)\n",
            nrow(alt), sum(alt$Result != "Negative"),
            100 * mean(alt$Result != "Negative")))
print(table(alt$Result))

# --- figure -------------------------------------------------------------------
plotdat <- cassava |>
  count(symptomatic, infected) |>
  mutate(looks = ifelse(symptomatic, "showed symptoms", "looked healthy"),
         lab   = ifelse(infected, "virus detected", "no virus"))
p <- ggplot(plotdat, aes(looks, n, fill = lab)) +
  geom_col(position = "stack", width = 0.6) +
  geom_text(aes(label = n), position = position_stack(vjust = 0.5),
            colour = "white", size = 4) +
  scale_fill_manual(values = c("virus detected" = "#1b6b4a", "no virus" = "#b8c4bd"),
                    name = NULL) +
  labs(x = NULL, y = "cassava plants tested",
       title = "A quarter of the infected plants showed nothing",
       subtitle = sprintf("%d plants tested across 13 Nigerian states, 2015 and 2017",
                          nrow(cassava))) +
  theme_minimal(base_size = 11) + theme(legend.position = "top")
ggsave("figures/visible_vs_actual.png", p, width = 7, height = 4.5, dpi = 150)

write.csv(tab, "output/eye_vs_lab.csv", row.names = FALSE)
message("wrote figures/visible_vs_actual.png and output/eye_vs_lab.csv")
