import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.services.recommendation_engine import RECOMMENDATION_WEIGHTS


def test_weights_are_positive():
    for key, weight in RECOMMENDATION_WEIGHTS.items():
        if "penalty" in key:
            assert weight < 0, f"{key} should be negative"
        else:
            assert weight >= 0, f"{key} should be non-negative"


def test_ingredient_match_weight_exists():
    assert "ingredient_match_weight" in RECOMMENDATION_WEIGHTS
    assert RECOMMENDATION_WEIGHTS["ingredient_match_weight"] > 0


def test_recent_meal_penalty_exists():
    assert "recent_meal_penalty" in RECOMMENDATION_WEIGHTS
    assert RECOMMENDATION_WEIGHTS["recent_meal_penalty"] < 0


def test_use_soon_bonus_exists():
    assert "use_soon_bonus" in RECOMMENDATION_WEIGHTS
    assert RECOMMENDATION_WEIGHTS["use_soon_bonus"] > 0


def test_missing_ingredient_penalty_exists():
    assert "missing_ingredient_penalty" in RECOMMENDATION_WEIGHTS
    assert RECOMMENDATION_WEIGHTS["missing_ingredient_penalty"] < 0
