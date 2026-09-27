# Fetch the published dataset from Mendeley Data and verify it has not changed.
#
# Eni A., Efekemo O., Onile-ere O., Pita J. (2021)
# "Survey of cassava mosaic begomoviruses across South-west and North central
#  regions of Nigeria in 2015 and 2017", Mendeley Data V1, CC BY 4.0
# doi:10.17632/mpj2nxk3tk.1

DATA_DIR  <- "data/raw"
DATA_FILE <- file.path(DATA_DIR, "Data.xlsx")

# sha256 of the file as published; the script stops if this ever changes
EXPECTED_SHA256 <- "8a6bfe3f90114ccfb4cf91f25097ab2fe7dcf41491214ae889c848a02651a84a"

DOWNLOAD_URL <- paste0(
  "https://data.mendeley.com/public-files/datasets/mpj2nxk3tk/files/",
  "823410b5-b2c4-4b37-8822-c28582baded7/file_downloaded"
)

dir.create(DATA_DIR, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(DATA_FILE)) {
  message("downloading Data.xlsx from Mendeley Data ...")
  utils::download.file(DOWNLOAD_URL, DATA_FILE, mode = "wb", quiet = TRUE)
}

observed <- digest::digest(DATA_FILE, algo = "sha256", file = TRUE)

if (!identical(observed, EXPECTED_SHA256)) {
  stop(
    "Data.xlsx does not match the published version.\n",
    "  expected sha256: ", EXPECTED_SHA256, "\n",
    "  observed sha256: ", observed, "\n",
    "Every number in this repository refers to the file with the expected hash.",
    call. = FALSE
  )
}

message("Data.xlsx verified against the published sha256.")
