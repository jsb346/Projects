from pybaseball import statcast_batter, statcast_pitcher
import pandas as pd

# Pulling Hitter Data (2023 season)
hitters = statcast_batter('2023-03-30', '2023-10-01')
hitters.to_csv("../data/mlb_hitting_2023.csv", index=False)

# Pulling Pitcher Data (2023 season)
pitchers = statcast_pitcher('2023-03-30', '2023-10-01')
pitchers.to_csv("../data/mlb_pitching_2023.csv", index=False)

print("Data saved successfully!")
