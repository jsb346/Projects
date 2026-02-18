library(shiny)
library(tidyverse)
library(bslib)
library(scales)

# 1. Load Data (Assumes artifacts exist in /outputs)
data_path <- "outputs/count_outcome_long_2025.rds"
if (!file_exists(data_path)) {
  stop("Data not found. Run the terminal outcome analysis script first.")
}

df_all <- readRDS(data_path)

# 2. Pre-calculate League Baseline (0-0 Count)
league_baseline <- df_all %>%
  filter(count == "0-0") %>%
  select(outcome, baseline_pct = pct_within_count)

# 3. UI
ui <- page_sidebar(
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  title = "MLB 2025: Terminal Outcome Expectancy",
  sidebar = sidebar(
    title = "Analysis Controls",
    selectInput("selected_count", "Current Pitch Count:",
                choices = sort(unique(df_all$count)), selected = "0-0"),
    hr(),
    helpText("Baseline = League Average (0-0 Count)")
  ),
  layout_column_wrap(
    width = 1,
    card(card_header("Outcome Comparison"), plotOutput("comparison_plot")),
    card(card_header("Statistical Breakdown"), tableOutput("stats_table"))
  )
)

# 4. Server Logic (The Fix)
server <- function(input, output) {
  
  # Reactive: Keep data WIDE for the table calculations
  wide_data <- reactive({
    df_all %>%
      filter(count == input$selected_count) %>%
      left_join(league_baseline, by = "outcome") %>%
      mutate(delta = pct_within_count - baseline_pct)
  })
  
  # Reactive: Pivot to LONG specifically for the ggplot
  plot_data <- reactive({
    wide_data() %>%
      pivot_longer(
        cols = c(pct_within_count, baseline_pct),
        names_to = "data_type",
        values_to = "percentage"
      ) %>%
      mutate(data_type = if_else(data_type == "baseline_pct", "League Average", "Selected Count"))
  })
  
  output$comparison_plot <- renderPlot({
    ggplot(plot_data(), aes(x = reorder(outcome, -percentage), y = percentage, fill = data_type)) +
      geom_col(position = "dodge") +
      scale_y_continuous(labels = percent_format(accuracy = 1)) +
      scale_fill_manual(values = c("League Average" = "#bdc3c7", "Selected Count" = "#2c3e50")) +
      labs(x = "Outcome", y = "Probability", fill = "Reference") +
      theme_minimal(base_size = 14)
  })
  
  output$stats_table <- renderTable({
    wide_data() %>%
      mutate(
        `Current Rate` = percent(pct_within_count, accuracy = 0.1),
        `League Avg` = percent(baseline_pct, accuracy = 0.1),
        `Delta` = sprintf("%+0.1f%%", delta * 100)
      ) %>%
      select(Outcome = outcome, `Current Rate`, `League Avg`, Delta) %>%
      arrange(desc(`Current Rate`))
  }, align = "lrrr")
}

shinyApp(ui, server)