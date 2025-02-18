import pandas as pd

# Load the raw data
df = pd.read_csv("../data/mlb_hitting_2023.csv")

# Select key columns
df_clean = df[['player_name', 'launch_speed', 'launch_angle', 'hard_hit_percent', 'estimated_ba_using_speedangle']]

# Remove missing values
df_clean = df_clean.dropna()

# Save cleaned data
df_clean.to_csv("../data/mlb_hitting_cleaned.csv", index=False)

print("Cleaned data saved successfully!")
