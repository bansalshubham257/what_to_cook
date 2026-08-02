// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'What to Cook?';

  @override
  String get close => 'Close';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get search => 'Search';

  @override
  String get done => 'Done';

  @override
  String get edit => 'Edit';

  @override
  String get retry => 'Retry';

  @override
  String get update => 'Update';

  @override
  String get delete => 'Delete';

  @override
  String get tabHome => 'Home';

  @override
  String get tabKitchen => 'Kitchen';

  @override
  String get tabSuggestions => 'Suggestions';

  @override
  String get tabInsights => 'Insights';

  @override
  String get tabProfile => 'Profile';

  @override
  String get goodMorning => 'Good morning,';

  @override
  String get goodAfternoon => 'Good afternoon,';

  @override
  String get goodEvening => 'Good evening,';

  @override
  String get today => 'Today';

  @override
  String get everything => 'Everything';

  @override
  String get nothingPlannedYet => 'Nothing planned yet';

  @override
  String get openYourMealPlanner => 'Open your meal planner';

  @override
  String get reviewUpcomingMeals => 'Review your upcoming meals for the week.';

  @override
  String get planYourWeek => 'Plan your week of meals in the planner.';

  @override
  String get openPlanner => 'Open planner';

  @override
  String get addDishToGetSuggestions => 'Add a dish to get suggestions';

  @override
  String get addDishesInExplore =>
      'Add dishes in Explore or pick cuisines in Profile.';

  @override
  String get aTastyPickForYou => 'A tasty pick for you';

  @override
  String get surpriseMeAgain => 'Surprise me again';

  @override
  String get notPlanned => 'Not planned';

  @override
  String get markMade => 'Mark made';

  @override
  String niceMarkedAsMade(Object name) {
    return 'Nice! $name marked as made today';
  }

  @override
  String get now => 'Now';

  @override
  String get notesTitle => 'Notes';

  @override
  String get checklistNotes => 'Checklist / Notes';

  @override
  String get checklist => 'Checklist';

  @override
  String get notes => 'Notes';

  @override
  String get seeAll => 'See all';

  @override
  String get searchNotes => 'Search notes...';

  @override
  String get addChecklistItem => 'Add checklist item...';

  @override
  String get addSimpleChecklist => 'Add a simple checklist and tick items off.';

  @override
  String get createTitledNotes =>
      'Create titled notes like Food, Recipes or Shopping Ideas, then add detailed notes inside.';

  @override
  String get addDetailedNote => 'Add detailed note';

  @override
  String get newNote => 'New note';

  @override
  String get editNote => 'Edit note';

  @override
  String get noteListTitle => 'Note list title';

  @override
  String get noteListTitleHint => 'Food';

  @override
  String get title => 'Title';

  @override
  String get writeFreely => 'Write freely';

  @override
  String get writeFreelyHint =>
      'Select text and use Bold/Italic, add bullets, links, images and recipe details.';

  @override
  String get link => 'Link';

  @override
  String get linkHint => 'https://...';

  @override
  String get recipeFoodDetails => 'Recipe / food details';

  @override
  String get noNotesFound => 'No notes found';

  @override
  String recipeLabel(Object name) {
    return 'Recipe: $name';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get cook => 'Cook';

  @override
  String get preferences => 'Preferences';

  @override
  String get notifications => 'Notifications';

  @override
  String get account => 'Account';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get foodPreference => 'Food Preference';

  @override
  String get cuisinePreferences => 'Cuisine Preferences';

  @override
  String get kitchenProfile => 'Kitchen Profile';

  @override
  String get household => 'Household';

  @override
  String get language => 'Language';

  @override
  String get useSoonReminders => 'Use-Soon Reminders';

  @override
  String get mealSuggestions => 'Meal Suggestions';

  @override
  String get weeklyReport => 'Weekly Report';

  @override
  String get shoppingList => 'Shopping List';

  @override
  String get favorites => 'Favorites';

  @override
  String get mealHistory => 'Meal History';

  @override
  String get about => 'About';

  @override
  String get vegetarian => 'Vegetarian';

  @override
  String get vegetarianEgg => 'Vegetarian + Egg';

  @override
  String get nonVegetarian => 'Non-Vegetarian';

  @override
  String get vegan => 'Vegan';

  @override
  String get adult => 'Adult';

  @override
  String get adults => 'Adults';

  @override
  String get child => 'Child';

  @override
  String get children => 'Children';

  @override
  String get childrenInHousehold => 'Children in household';

  @override
  String get basicNorthIndianVeg => 'Basic North Indian Veg';

  @override
  String get northIndianNonVeg => 'North Indian Non-Veg';

  @override
  String get southIndian => 'South Indian';

  @override
  String get mixedIndian => 'Mixed Indian';

  @override
  String get buildManually => 'Build Manually';

  @override
  String get adultsLabel => 'Adults: ';

  @override
  String get childrenLabel => 'Children: ';

  @override
  String get exploreTitle => 'Explore';

  @override
  String get searchRecipes => 'Search recipes...';

  @override
  String get myFavorites => 'My Favorites';

  @override
  String get searchByVoice => 'Search by voice';

  @override
  String get tellUsWhatYouHave =>
      'Tell us what you have or want, e.g. \"i have dal, aloo, paneer\"';

  @override
  String get searching => 'Searching...';

  @override
  String resultsCount(Object count) {
    return 'Results ($count)';
  }

  @override
  String get noRecipesFound => 'No recipes found';

  @override
  String get favourite => 'Favourite';

  @override
  String get easy => 'Easy';

  @override
  String get balanced => 'Balanced';

  @override
  String get browseByMeal => 'Browse by meal';

  @override
  String get cuisines => 'Cuisines';

  @override
  String get buyMissingItems => 'Buy Missing Items & Unlock Meals';

  @override
  String get noMissingItems => 'No missing items found';

  @override
  String get addToList => 'Add to List';

  @override
  String get recipes => 'recipes';

  @override
  String get breakfast => 'Breakfast';

  @override
  String get lunch => 'Lunch';

  @override
  String get snacks => 'Snacks';

  @override
  String get dinner => 'Dinner';

  @override
  String get sweets => 'Sweets';

  @override
  String get specialDishes => 'Special Dishes';

  @override
  String get myKitchen => 'My Kitchen';

  @override
  String get searchIngredients => 'Search ingredients...';

  @override
  String get tellWhatsInKitchen => 'Tell us what\'s in your kitchen';

  @override
  String get useSoon => 'Use Soon';

  @override
  String useWithinDays(Object days) {
    return 'Use within $days days';
  }

  @override
  String get cookNow => 'Cook Now';

  @override
  String get yourKitchenEmpty => 'Your kitchen looks empty';

  @override
  String get addIngredientsVoice =>
      'Add ingredients using the voice button above';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get couldNotLoadKitchen => 'Could not load your kitchen inventory';

  @override
  String get updateKitchen => 'Update Kitchen';

  @override
  String get listening => 'Listening...';

  @override
  String get tapToSpeak => 'Tap to speak';

  @override
  String get orTypeHere =>
      'Or type here...\ne.g. \"Mere paas aloo pyaz tomato hai\"';

  @override
  String get kitchenUpdated => 'Kitchen Updated!';

  @override
  String get other => 'Other';

  @override
  String get foodInsights => 'Food Insights';

  @override
  String get yourLast7Days => 'Your Last 7 Days';

  @override
  String get thisMonth => 'This Month';

  @override
  String basedOnMeals(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'meals',
      one: 'meal',
    );
    return 'Based on $count $_temp0 you logged';
  }

  @override
  String get balancedHealth => 'Balanced';

  @override
  String get moderate => 'Moderate';

  @override
  String get indulgent => 'Indulgent';

  @override
  String get daysLabel => 'days';

  @override
  String get noCuisineData => 'No cuisine data available';

  @override
  String get whatShouldICook => 'What should I cook?';

  @override
  String get addDish => 'Add Dish';

  @override
  String get noRecommendations => 'No recommendations found';

  @override
  String get recentlyEnjoyed => 'Recently Enjoyed';

  @override
  String get noMealHistory => 'No meal history yet';

  @override
  String get medium => 'Medium';

  @override
  String get hard => 'Hard';

  @override
  String addedToCategory(Object category, Object name) {
    return '$name added to $category';
  }

  @override
  String get minLabel => 'min';

  @override
  String get shoppingListTitle => 'Shopping List';

  @override
  String get yourShoppingEmpty => 'Your shopping list is empty';

  @override
  String get addItemsPlus => 'Add items using the + button below';

  @override
  String get toBuy => 'To Buy';

  @override
  String get bought => 'Bought';

  @override
  String get addItem => 'Add Item';

  @override
  String get itemRemoved => 'Item removed';

  @override
  String errorUpdatingItem(Object error) {
    return 'Error updating item: $error';
  }

  @override
  String errorRemovingItem(Object error) {
    return 'Error removing item: $error';
  }

  @override
  String errorAddingItem(Object error) {
    return 'Error adding item: $error';
  }

  @override
  String get couldNotLoadShopping => 'Could not load your shopping list';

  @override
  String get mealPlanTitle => 'Meal Plan';

  @override
  String get perDay => 'Per Day';

  @override
  String get week => 'Week';
}
