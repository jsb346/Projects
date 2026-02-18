# ==============================================================================
# analysis_script.R
# Project: MLB 2025 Terminal Outcome Expectancy
# Logic: All Counts Reached (0-0 reflects League Average)
# ==============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(data.table)
  library(fs)
  library(glue)
})

# --- 1. Config & Folders ---
YEAR           <- 2025
THRESHOLD_OTHR <- 0.02
DIRS           <- c("data_raw", "data_processed", "outputs")
PROTECTED      <- c("1B", "2B", "3B", "HR", "SO", "BB", "HBP")

walk(DIRS, dir_create)

# --- 2. Helper Functions ---

# Logic: Expand a pitch string into every count state visited
get_counts_reached <- function(pitch_seq) {
  # Every PA starts at 0-0
  counts <- "0-0"
  if (is.na(pitch_seq) || pitch_seq == "" || pitch_seq == "??") return(counts)
  
  chars <- str_split(pitch_seq, "")[[1]]
  b <- 0
  s <- 0
  
  # We iterate through the string, but the terminal outcome 
  # is determined by the LAST pitch. We only record counts PRIOR to that.
  if (length(chars) > 1) {
    for (i in 1:(length(chars) - 1)) {
      p <- chars[i]
      
      # Retrosheet Pitch Codes
      if (p %in% c("B", "I", "P", "V")) {
        b <- b + 1
      } else if (p %in% c("C", "S", "K", "L", "M", "O", "Q", "T")) {
        s <- s + 1
      } else if (p %in% c("F", "R")) {
        if (s < 2) s <- s + 1
      }
      # Ignore non-pitch events: . (ball in dirt), * (blocked), etc.
      
      # Safety check for valid baseball counts
      if (b < 4 && s < 3) {
        counts <- c(counts, paste0(b, "-", s))
      }
    }
  }
  return(unique(counts))
}

# Mapping Retrosheet event codes to Stage 1 Raw Outcomes
map_outcomes_stage1 <- function(event_tx) {
  case_when(
    str_detect(event_tx, "^K") ~ "SO",
    str_detect(event_tx, "^(W|IW)") ~ "BB",
    str_detect(event_tx, "^HP") ~ "HBP",
    str_detect(event_tx, "^S\\d*") ~ "1B",
    str_detect(event_tx, "^D\\d*") ~ "2B",
    str_detect(event_tx, "^T\\d*") ~ "3B",
    str_detect(event_tx, "^(H\\d*|HR)") ~ "HR",
    str_detect(event_tx, "^(SH|SF)") ~ "Sacrifice",
    str_detect(event_tx, "^([1-9]|FC|E)") ~ "BIP_out",
    TRUE ~ "Other_raw"
  )
}

# --- 3. Data Acquisition ---
cat("--- Checking for Retrosheet Data --- \n")
zip_file <- path("data_raw", glue("{YEAR}eve.zip"))
url <- glue("https://www.retrosheet.org/events/{YEAR}eve.zip")

if (!file_exists(zip_file)) {
  message("Downloading data...")
  download.file(url, zip_file, mode = "wb")
}

unzip_path <- path("data_raw", "temp_unzip")
unzip(zip_file, exdir = unzip_path)
event_files <- dir_ls(unzip_path, regexp = "\\.(EVN|EVA)$")

# --- 4. Parsing Logic ---
cat("--- Parsing Event Files --- \n")
parse_pa_data <- function(f) {
  lines <- read_lines(f)
  # Retrosheet play lines: play, inning, side, playerid, count, pitches, event
  play_lines <- lines[str_detect(lines, "^play")]
  if(length(play_lines) == 0) return(NULL)
  
  fread(text = play_lines, header = FALSE, sep = ",") %>%
    select(batter = V4, pitches = V6, event_tx = V7)
}

raw_data <- map_dfr(event_files, parse_pa_data)
dir_delete(unzip_path) # Clean up

# --- 5. Outcome Processing (Stage 1 & 2) ---
cat("--- Processing Outcomes --- \n")
df_stg1 <- raw_data %>%
  mutate(outcome_raw = map_outcomes_stage1(event_tx))

# Calculate global frequencies for the <2% rule
outcome_meta <- df_stg1 %>%
  count(outcome_raw) %>%
  mutate(share = n / sum(n))

# Identify what to collapse (not protected AND < threshold)
to_collapse <- outcome_meta %>%
  filter(!(outcome_raw %in% PROTECTED), share < THRESHOLD_OTHR) %>%
  pull(outcome_raw)

df_stg2 <- df_stg1 %>%
  mutate(outcome = if_else(outcome_raw %in% to_collapse, "Others", outcome_raw))

# --- 6. Expansion (All Counts Reached) ---
cat("--- Expanding Counts (This may take a moment) --- \n")
# We use rowwise to handle the custom function expansion
df_expanded <- df_stg2 %>%
  mutate(count_list = map(pitches, get_counts_reached)) %>%
  unnest(count_list) %>%
  rename(count = count_list)

# --- 7. Aggregation & Export ---
cat("--- Final Aggregation --- \n")
agg_long <- df_expanded %>%
  group_by(count, outcome) %>%
  summarise(n = n(), .groups = "drop_last") %>%
  mutate(pct_within_count = n / sum(n)) %>%
  ungroup()

# Save Artifacts
saveRDS(df_stg2, path("data_processed", "pa_2025_terminal.rds"))
saveRDS(agg_long, path("outputs", "count_outcome_long_2025.rds"))
write_csv(agg_long, path("outputs", "count_outcome_long_2025.csv"))

cat("--- Script Complete! Outputs saved to /outputs --- \n")