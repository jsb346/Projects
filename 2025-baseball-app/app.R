library(shiny)
library(tidyverse)
library(bslib)
library(scales)

# 1. Load Data
# This assumes the artifact from the analysis script exists.
data_path <- "outputs/count_outcome_long_2025.rds"
if (!file_exists(data_path)) {
  stop("Data artifact not found. Please run the terminal outcome analysis script first.")
}

df_all <- readRDS(data_path)

# 2. Pre-calculate League Baseline (0-0 Count)
league_baseline <- df_all %>%
  filter(count == "0-0") %>%
  select(outcome, baseline_pct = pct_within_count)

# 3. UI Definition
ui <- page_sidebar(
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  title = "MLB 2025: Terminal Outcome Expectancy",
  
  sidebar = sidebar(
    title = "Analysis Controls",
    selectInput(
      "selected_count",
      "Current Pitch Count:",
      choices = sort(unique(df_all$count)),
      selected = "0-0"
    ),
    hr(),
    helpText("Export current count data to CSV:"),
    downloadButton("download_report", "Download Report", class = "btn-primary w-100"),
    hr(),
    markdown(
      "**Legend:**
      - **Current:** Probability from this count.
      - **League Avg:** Season-wide average (0-0).
      - **Delta:** Difference between the two."
    )
  ),
  
  layout_column_wrap(
    width = 1,
    card(
      card_header("Outcome Expectancy vs. League Baseline"),
      plotOutput("comparison_plot", height = "400px")
    ),
    card(
      card_header("Statistical Breakdown"),
      tableOutput("stats_table")
    )
  )
)

# 4. Server Logic
server <- function(input, output) {
  
  # Reactive 1: Process the 'Wide' data first (The Foundation)
  # This ensures baseline_pct and pct_within_count are always available for math/sorting.
  processed_data <- reactive({
    df_all %>%
      filter(count == input$selected_count) %>%
      left_join(league_baseline, by = "outcome") %>%
      mutate(delta = pct_within_count - baseline_pct)
  })
  
  # Reactive 2: Transform to 'Long' only for the ggplot
  plot_data <- reactive({
    processed_data() %>%
      pivot_longer(
        cols = c(pct_within_count, baseline_pct),
        names_to = "data_type",
        values_to = "percentage"
      ) %>%
      mutate(
        data_type = if_else(data_type == "baseline_pct", "League Average", "Selected Count")
      )
  })
  
  # --- Plot Output ---
  output$comparison_plot <- renderPlot({
    ggplot(plot_data(), aes(x = reorder(outcome, -percentage), y = percentage, fill = data_type)) +
      geom_col(position = "dodge", alpha = 0.9) +
      scale_y_continuous(labels = percent_format(accuracy = 1)) +
      scale_fill_manual(values = c("League Average" = "#bdc3c7", "Selected Count" = "#2c3e50")) +
      labs(x = "Outcome", y = "Probability", fill = "Reference") +
      theme_minimal(base_size = 15) +
      theme(legend.position = "top")
  })
  
  # --- Table Output (FIXED: Arrange before Select) ---
  output$stats_table <- renderTable({
    processed_data() %>%
      # 1. Arrange by the raw numeric value FIRST
      arrange(desc(pct_within_count)) %>%
      # 2. Format columns into strings
      mutate(
        `Current Rate` = percent(pct_within_count, accuracy = 0.1),
        `League Avg` = percent(baseline_pct, accuracy = 0.1),
        `Delta` = sprintf("%+0.1f%%", delta * 100)
      ) %>%
      # 3. Select final display columns LAST
      select(Outcome = outcome, `Current Rate`, `League Avg`, Delta)
  }, align = "lrrr")
  
  # --- Download Handler ---
  output$download_report <- downloadHandler(
    filename = function() {
      paste0("MLB_Expectancy_", input$selected_count, "_", Sys.Date(), ".csv")
    },
    content = function(file) {
      final_export <- processed_data() %>%
        arrange(desc(pct_within_count)) %>%
        select(count, outcome, n, current_rate = pct_within_count, league_avg = baseline_pct, delta)
      
      write.csv(final_export, file, row.names = FALSE)
    }
  )
}

shinyApp(ui = ui, server = server)