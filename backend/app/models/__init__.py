from app.models.user import User
from app.models.household import Household, HouseholdMember
from app.models.ingredient import Ingredient, IngredientAlias, IngredientCategory
from app.models.kitchen_profile import KitchenProfile, KitchenProfileItem
from app.models.inventory import InventoryItem
from app.models.recipe import Recipe, RecipeIngredient, RecipeTag, Cuisine
from app.models.meal import MealHistory, MealFeedback
from app.models.shopping_list import ShoppingList, ShoppingListItem
from app.models.notification import NotificationPreference, DeviceToken
from app.models.analytics import RecommendationEvent, AiParsingLog
from app.models.freshness import FreshnessRule
from app.models.favorite import UserFavorite
from app.models.recommendation_history import RecommendationHistory
