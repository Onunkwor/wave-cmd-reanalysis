# Load the three sheets and add the zone mapping used by the original authors.

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
})

DATA_FILE <- "data/raw/Data.xlsx"

# State to zone, exactly as in the authors' own notebook (DIB.ipynb, cell 5)
ZONES <- c(
  Benue = "North Central", FCT = "North Central", Kogi = "North Central",
  Kwara = "North Central", Nassarawa = "North Central", Niger = "North Central",
  Plateau = "North Central",
  Ekiti = "South West", Lagos = "South West", Ogun = "South West",
  Ondo = "South West", Osun = "South West", Oyo = "South West"
)

field <- read_excel(DATA_FILE, sheet = "Field") |>
  mutate(
    Zone = unname(ZONES[State]),
    Year = as.integer(Year),
    # a field is "diseased" if any plant showed symptoms; the route columns are
    # only populated for these, which is why they carry 152 NAs
    diseased = CMD_Incidence > 0
  )

lab      <- read_excel(DATA_FILE, sheet = "Lab")
field_lab <- read_excel(DATA_FILE, sheet = "Field_Lab")

# Structural checks. These are assertions, not decoration: if any fails, the
# file is not the one this analysis was written against.
stopifnot(
  nrow(field) == 512L,
  nrow(lab) == 1344L,
  nrow(field_lab) == 496L,
  # the two route columns are shares of the same whole
  all(abs(with(field[!is.na(field$Cutting_Infection), ],
               Cutting_Infection + Whitefly_Infection) - 1) < 1e-9),
  # routes are recorded exactly when there is disease to attribute
  identical(is.na(field$Cutting_Infection), !field$diseased),
  !any(is.na(field$Zone))
)

message(sprintf(
  "loaded: %d fields (%d diseased), %d lab samples, %d field-lab rows",
  nrow(field), sum(field$diseased), nrow(lab), nrow(field_lab)
))
