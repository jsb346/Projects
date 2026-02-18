# MLB 2025 Count Analysis Tool

This project computes terminal plate-appearance outcomes based on every pitch count reached using 2025 Retrosheet event data.

## Project Structure
- `analysis_script.R`: Pure R script to download and parse Retrosheet event files.
- `app.R`: Shiny dashboard for visualizing outcome expectancy.
- `data_raw/`: Raw .EVN/.EVA event files (gitignored).
- `outputs/`: Processed RDS and CSV files for the app.

## How to Run
1. **Initialize Data:** Run `source("analysis_script.R")`. This will download the 2025 season data and generate the necessary artifacts.
2. **Launch App:** Run `shiny::runApp()`.

## Data Logic
- **Counts Reached:** We track every count state a batter enters (e.g., an 8-pitch PA that ends in a walk counts toward 0-0, 0-1, 1-1, 2-1, 2-2, 3-2).
- **Protected Outcomes:** Core stats (HR, SO, BB, etc.) are preserved even if they fall below the 2% global threshold to maintain analytical value.
