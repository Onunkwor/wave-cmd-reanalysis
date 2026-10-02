# The relationship the published notebook does not draw.
#
# DIB.ipynb reports "Origin of infection" (cells 18-26) and "Whitefly
# Abundance" (cells 27-28) in separate sections. It does not relate the two.
# This script asks whether the whitefly count at survey predicts the share of
# a field's infection that was acquired in the field rather than planted.

suppressPackageStartupMessages({ library(dplyr); library(ggplot2); library(scales) })

dis <- field |> filter(diseased)

# --- correlation, overall and within every subgroup --------------------------
sp <- function(d) {
  if (nrow(d) < 6) return(NA_real_)
  suppressWarnings(cor(d$Total_whitefly, d$Whitefly_Infection, method = "spearman"))
}

groups <- bind_rows(
  tibble(group = "all diseased fields", n = nrow(dis), rho = sp(dis)),
  dis |> group_by(Year) |> group_modify(~ tibble(n = nrow(.x), rho = sp(.x))) |>
    ungroup() |> transmute(group = paste("year", Year), n, rho),
  dis |> group_by(Zone) |> group_modify(~ tibble(n = nrow(.x), rho = sp(.x))) |>
    ungroup() |> transmute(group = Zone, n, rho),
  # every state, not only the well-sampled ones: filtering them out silently
  # would overstate how consistent the relationship is
  dis |> group_by(State) |> group_modify(~ tibble(n = nrow(.x), rho = sp(.x))) |>
    ungroup() |> arrange(desc(n)) |>
    transmute(group = paste0(State, if_else(n >= 20, "", " (small n)")), n, rho)
)
cat("\n== Spearman correlation: whitefly count vs whitefly-borne share ==\n")
print(as.data.frame(groups), row.names = FALSE, digits = 3)

# --- the same thing as a dose-response over abundance bands ------------------
bands <- dis |>
  mutate(band = cut(Total_whitefly,
                    breaks = c(-1, 0, 9, 99, 499, Inf),
                    labels = c("0", "1-9", "10-99", "100-499", "500+"))) |>
  group_by(band) |>
  summarise(fields = n(),
            median_share = median(Whitefly_Infection),
            mean_share = mean(Whitefly_Infection), .groups = "drop")
cat("\n== Whitefly-borne share by whitefly abundance band ==\n")
print(as.data.frame(bands), row.names = FALSE, digits = 3)

# --- where the snapshot and the season disagree ------------------------------
# The route is read from the distribution of symptoms on the plant, which
# records the whole season. The whitefly count is one visit, five leaves on
# each of thirty plants. They are not measuring the same interval, and the
# disagreements show where that matters.
zero_wf   <- dis |> filter(Total_whitefly == 0)
zero_but  <- zero_wf |> filter(Whitefly_Infection > 0)
many_none <- dis |> filter(Total_whitefly >= 100, Whitefly_Infection == 0)

cat("\n== Where a point count and a season-long record disagree ==\n")
cat(sprintf("  fields with no whiteflies counted            : %d\n", nrow(zero_wf)))
cat(sprintf("  of those, still showing whitefly-borne infn  : %d (%.1f%%)\n",
            nrow(zero_but), 100 * nrow(zero_but) / nrow(zero_wf)))
cat(sprintf("    their whitefly-borne share, median / mean  : %.3f / %.3f\n",
            median(zero_but$Whitefly_Infection), mean(zero_but$Whitefly_Infection)))
cat(sprintf("  fields with >= 100 whiteflies and no whitefly-borne infection: %d\n",
            nrow(many_none)))
cat(sprintf("    largest count among them                   : %d whiteflies (%s, %d)\n",
            max(many_none$Total_whitefly),
            many_none$State[which.max(many_none$Total_whitefly)],
            many_none$Year[which.max(many_none$Total_whitefly)]))

# --- figures ------------------------------------------------------------------
dir.create("figures", showWarnings = FALSE)

p1 <- ggplot(dis, aes(Total_whitefly + 1, Whitefly_Infection)) +
  geom_point(alpha = 0.45, size = 1.8) +
  geom_smooth(method = "loess", formula = y ~ x, se = TRUE, colour = "#1b6b4a") +
  scale_x_log10(labels = label_comma()) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(x = "whiteflies counted at survey (+1, log scale)",
       y = "share of infection acquired in the field",
       title = "A one-visit vector count against a season's worth of infection",
       subtitle = sprintf("%d diseased fields, Nigeria, 2015 and 2017", nrow(dis))) +
  theme_minimal(base_size = 11)
ggsave("figures/route_vs_whitefly.png", p1, width = 7, height = 5, dpi = 150)

p2 <- ggplot(bands, aes(band, median_share)) +
  geom_col(fill = "#1b6b4a") +
  geom_text(aes(label = sprintf("n=%d", fields)), vjust = -0.5, size = 3.2) +
  scale_y_continuous(labels = percent_format(accuracy = 1),
                     expand = expansion(mult = c(0, 0.12))) +
  labs(x = "whiteflies counted at survey", y = "median whitefly-borne share",
       title = "Median share of infection acquired in the field, by vector count") +
  theme_minimal(base_size = 11)
ggsave("figures/route_by_band.png", p2, width = 7, height = 4.5, dpi = 150)

write.csv(groups, "output/correlations.csv", row.names = FALSE)
write.csv(bands,  "output/abundance_bands.csv", row.names = FALSE)
message("wrote figures/ and output/")
