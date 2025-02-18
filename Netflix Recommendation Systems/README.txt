# Movie Recommendation System

## Overview

This notebook explores and implements various movie recommendation systems using the MovieLens dataset. The goal is to predict user preferences for movies they haven't seen and provide personalized recommendations.

## Dataset

The notebook uses the MovieLens ratings dataset, which contains user ratings for movies. It's preprocessed to remove unnecessary columns and ensure data integrity.

## Recommendation Systems Implemented

The notebook implements three main types of recommendation systems:

1. **Rank-Based:** Recommends movies based on their overall popularity and average rating. Useful for addressing the cold start problem.

2. **Collaborative Filtering (User-User & Item-Item):** Predicts user preferences by identifying similar users or movies. Utilizes cosine and MSD similarity measures and the KNN algorithm. Hyperparameter tuning is performed to optimize performance.

3. **Matrix Factorization (SVD):** Uses latent features to represent users and movies, enabling personalized recommendations. Hyperparameter tuning is applied to enhance prediction accuracy.

## Evaluation Metrics

The notebook evaluates the recommendation systems using metrics such as:

- **RMSE (Root Mean Squared Error):** Measures the accuracy of predicted ratings.
- **Precision@k:** Evaluates the proportion of recommended items that are relevant among the top k recommendations.
- **Recall@k:** Measures the proportion of relevant items that are actually recommended among the top k recommendations.
- **F1-score@k:** Provides a balanced measure considering both precision and recall.

## Usage

The notebook provides functions for:

- **Generating top-n movie recommendations** based on different algorithms.
- **Predicting ratings** for specific user-movie pairs.
- **Identifying similar users or movies** using nearest neighbor approaches.
- **Correcting predicted ratings** based on movie popularity and rating count.

## Conclusion

The notebook demonstrates the implementation and evaluation of various recommendation systems for movie recommendations. It showcases the use of different algorithms and hyperparameter tuning techniques to improve recommendation quality.
