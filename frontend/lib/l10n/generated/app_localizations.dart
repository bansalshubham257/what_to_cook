import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('pa'),
    Locale('ta'),
    Locale('te'),
    Locale('ur')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'What to Cook?'**
  String get appTitle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get tabKitchen;

  /// No description provided for @tabSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get tabSuggestions;

  /// No description provided for @tabInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get tabInsights;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon,'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening,'**
  String get goodEvening;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @everything.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get everything;

  /// No description provided for @nothingPlannedYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned yet'**
  String get nothingPlannedYet;

  /// No description provided for @openYourMealPlanner.
  ///
  /// In en, this message translates to:
  /// **'Open your meal planner'**
  String get openYourMealPlanner;

  /// No description provided for @reviewUpcomingMeals.
  ///
  /// In en, this message translates to:
  /// **'Review your upcoming meals for the week.'**
  String get reviewUpcomingMeals;

  /// No description provided for @planYourWeek.
  ///
  /// In en, this message translates to:
  /// **'Plan your week of meals in the planner.'**
  String get planYourWeek;

  /// No description provided for @openPlanner.
  ///
  /// In en, this message translates to:
  /// **'Open planner'**
  String get openPlanner;

  /// No description provided for @addDishToGetSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Add a dish to get suggestions'**
  String get addDishToGetSuggestions;

  /// No description provided for @addDishesInExplore.
  ///
  /// In en, this message translates to:
  /// **'Add dishes in Explore or pick cuisines in Profile.'**
  String get addDishesInExplore;

  /// No description provided for @aTastyPickForYou.
  ///
  /// In en, this message translates to:
  /// **'A tasty pick for you'**
  String get aTastyPickForYou;

  /// No description provided for @surpriseMeAgain.
  ///
  /// In en, this message translates to:
  /// **'Surprise me again'**
  String get surpriseMeAgain;

  /// No description provided for @notPlanned.
  ///
  /// In en, this message translates to:
  /// **'Not planned'**
  String get notPlanned;

  /// No description provided for @markMade.
  ///
  /// In en, this message translates to:
  /// **'Mark made'**
  String get markMade;

  /// No description provided for @niceMarkedAsMade.
  ///
  /// In en, this message translates to:
  /// **'Nice! {name} marked as made today'**
  String niceMarkedAsMade(Object name);

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @notesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesTitle;

  /// No description provided for @checklistNotes.
  ///
  /// In en, this message translates to:
  /// **'Checklist / Notes'**
  String get checklistNotes;

  /// No description provided for @checklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get checklist;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @searchNotes.
  ///
  /// In en, this message translates to:
  /// **'Search notes...'**
  String get searchNotes;

  /// No description provided for @addChecklistItem.
  ///
  /// In en, this message translates to:
  /// **'Add checklist item...'**
  String get addChecklistItem;

  /// No description provided for @addSimpleChecklist.
  ///
  /// In en, this message translates to:
  /// **'Add a simple checklist and tick items off.'**
  String get addSimpleChecklist;

  /// No description provided for @createTitledNotes.
  ///
  /// In en, this message translates to:
  /// **'Create titled notes like Food, Recipes or Shopping Ideas, then add detailed notes inside.'**
  String get createTitledNotes;

  /// No description provided for @addDetailedNote.
  ///
  /// In en, this message translates to:
  /// **'Add detailed note'**
  String get addDetailedNote;

  /// No description provided for @newNote.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get newNote;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get editNote;

  /// No description provided for @noteListTitle.
  ///
  /// In en, this message translates to:
  /// **'Note list title'**
  String get noteListTitle;

  /// No description provided for @noteListTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get noteListTitleHint;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @writeFreely.
  ///
  /// In en, this message translates to:
  /// **'Write freely'**
  String get writeFreely;

  /// No description provided for @writeFreelyHint.
  ///
  /// In en, this message translates to:
  /// **'Select text and use Bold/Italic, add bullets, links, images and recipe details.'**
  String get writeFreelyHint;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @linkHint.
  ///
  /// In en, this message translates to:
  /// **'https://...'**
  String get linkHint;

  /// No description provided for @recipeFoodDetails.
  ///
  /// In en, this message translates to:
  /// **'Recipe / food details'**
  String get recipeFoodDetails;

  /// No description provided for @noNotesFound.
  ///
  /// In en, this message translates to:
  /// **'No notes found'**
  String get noNotesFound;

  /// No description provided for @recipeLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipe: {name}'**
  String recipeLabel(Object name);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @cook.
  ///
  /// In en, this message translates to:
  /// **'Cook'**
  String get cook;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @foodPreference.
  ///
  /// In en, this message translates to:
  /// **'Food Preference'**
  String get foodPreference;

  /// No description provided for @cuisinePreferences.
  ///
  /// In en, this message translates to:
  /// **'Cuisine Preferences'**
  String get cuisinePreferences;

  /// No description provided for @kitchenProfile.
  ///
  /// In en, this message translates to:
  /// **'Kitchen Profile'**
  String get kitchenProfile;

  /// No description provided for @household.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get household;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @useSoonReminders.
  ///
  /// In en, this message translates to:
  /// **'Use-Soon Reminders'**
  String get useSoonReminders;

  /// No description provided for @mealSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Meal Suggestions'**
  String get mealSuggestions;

  /// No description provided for @weeklyReport.
  ///
  /// In en, this message translates to:
  /// **'Weekly Report'**
  String get weeklyReport;

  /// No description provided for @shoppingList.
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get shoppingList;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @mealHistory.
  ///
  /// In en, this message translates to:
  /// **'Meal History'**
  String get mealHistory;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @vegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get vegetarian;

  /// No description provided for @vegetarianEgg.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian + Egg'**
  String get vegetarianEgg;

  /// No description provided for @nonVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Non-Vegetarian'**
  String get nonVegetarian;

  /// No description provided for @vegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get vegan;

  /// No description provided for @adult.
  ///
  /// In en, this message translates to:
  /// **'Adult'**
  String get adult;

  /// No description provided for @adults.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get adults;

  /// No description provided for @child.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get child;

  /// No description provided for @children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get children;

  /// No description provided for @childrenInHousehold.
  ///
  /// In en, this message translates to:
  /// **'Children in household'**
  String get childrenInHousehold;

  /// No description provided for @basicNorthIndianVeg.
  ///
  /// In en, this message translates to:
  /// **'Basic North Indian Veg'**
  String get basicNorthIndianVeg;

  /// No description provided for @northIndianNonVeg.
  ///
  /// In en, this message translates to:
  /// **'North Indian Non-Veg'**
  String get northIndianNonVeg;

  /// No description provided for @southIndian.
  ///
  /// In en, this message translates to:
  /// **'South Indian'**
  String get southIndian;

  /// No description provided for @mixedIndian.
  ///
  /// In en, this message translates to:
  /// **'Mixed Indian'**
  String get mixedIndian;

  /// No description provided for @buildManually.
  ///
  /// In en, this message translates to:
  /// **'Build Manually'**
  String get buildManually;

  /// No description provided for @adultsLabel.
  ///
  /// In en, this message translates to:
  /// **'Adults: '**
  String get adultsLabel;

  /// No description provided for @childrenLabel.
  ///
  /// In en, this message translates to:
  /// **'Children: '**
  String get childrenLabel;

  /// No description provided for @exploreTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreTitle;

  /// No description provided for @searchRecipes.
  ///
  /// In en, this message translates to:
  /// **'Search recipes...'**
  String get searchRecipes;

  /// No description provided for @myFavorites.
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get myFavorites;

  /// No description provided for @searchByVoice.
  ///
  /// In en, this message translates to:
  /// **'Search by voice'**
  String get searchByVoice;

  /// No description provided for @tellUsWhatYouHave.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you have or want, e.g. \"i have dal, aloo, paneer\"'**
  String get tellUsWhatYouHave;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'Results ({count})'**
  String resultsCount(Object count);

  /// No description provided for @noRecipesFound.
  ///
  /// In en, this message translates to:
  /// **'No recipes found'**
  String get noRecipesFound;

  /// No description provided for @favourite.
  ///
  /// In en, this message translates to:
  /// **'Favourite'**
  String get favourite;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// No description provided for @balanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get balanced;

  /// No description provided for @browseByMeal.
  ///
  /// In en, this message translates to:
  /// **'Browse by meal'**
  String get browseByMeal;

  /// No description provided for @cuisines.
  ///
  /// In en, this message translates to:
  /// **'Cuisines'**
  String get cuisines;

  /// No description provided for @buyMissingItems.
  ///
  /// In en, this message translates to:
  /// **'Buy Missing Items & Unlock Meals'**
  String get buyMissingItems;

  /// No description provided for @noMissingItems.
  ///
  /// In en, this message translates to:
  /// **'No missing items found'**
  String get noMissingItems;

  /// No description provided for @addToList.
  ///
  /// In en, this message translates to:
  /// **'Add to List'**
  String get addToList;

  /// No description provided for @recipes.
  ///
  /// In en, this message translates to:
  /// **'recipes'**
  String get recipes;

  /// No description provided for @breakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get breakfast;

  /// No description provided for @lunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get lunch;

  /// No description provided for @snacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get snacks;

  /// No description provided for @dinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get dinner;

  /// No description provided for @sweets.
  ///
  /// In en, this message translates to:
  /// **'Sweets'**
  String get sweets;

  /// No description provided for @specialDishes.
  ///
  /// In en, this message translates to:
  /// **'Special Dishes'**
  String get specialDishes;

  /// No description provided for @myKitchen.
  ///
  /// In en, this message translates to:
  /// **'My Kitchen'**
  String get myKitchen;

  /// No description provided for @searchIngredients.
  ///
  /// In en, this message translates to:
  /// **'Search ingredients...'**
  String get searchIngredients;

  /// No description provided for @tellWhatsInKitchen.
  ///
  /// In en, this message translates to:
  /// **'Tell us what\'s in your kitchen'**
  String get tellWhatsInKitchen;

  /// No description provided for @useSoon.
  ///
  /// In en, this message translates to:
  /// **'Use Soon'**
  String get useSoon;

  /// No description provided for @useWithinDays.
  ///
  /// In en, this message translates to:
  /// **'Use within {days} days'**
  String useWithinDays(Object days);

  /// No description provided for @cookNow.
  ///
  /// In en, this message translates to:
  /// **'Cook Now'**
  String get cookNow;

  /// No description provided for @yourKitchenEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your kitchen looks empty'**
  String get yourKitchenEmpty;

  /// No description provided for @addIngredientsVoice.
  ///
  /// In en, this message translates to:
  /// **'Add ingredients using the voice button above'**
  String get addIngredientsVoice;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @couldNotLoadKitchen.
  ///
  /// In en, this message translates to:
  /// **'Could not load your kitchen inventory'**
  String get couldNotLoadKitchen;

  /// No description provided for @updateKitchen.
  ///
  /// In en, this message translates to:
  /// **'Update Kitchen'**
  String get updateKitchen;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @tapToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Tap to speak'**
  String get tapToSpeak;

  /// No description provided for @orTypeHere.
  ///
  /// In en, this message translates to:
  /// **'Or type here...\ne.g. \"Mere paas aloo pyaz tomato hai\"'**
  String get orTypeHere;

  /// No description provided for @kitchenUpdated.
  ///
  /// In en, this message translates to:
  /// **'Kitchen Updated!'**
  String get kitchenUpdated;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @foodInsights.
  ///
  /// In en, this message translates to:
  /// **'Food Insights'**
  String get foodInsights;

  /// No description provided for @yourLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Your Last 7 Days'**
  String get yourLast7Days;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @basedOnMeals.
  ///
  /// In en, this message translates to:
  /// **'Based on {count} {count, plural, =1{meal} other{meals}} you logged'**
  String basedOnMeals(num count);

  /// No description provided for @balancedHealth.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get balancedHealth;

  /// No description provided for @moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderate;

  /// No description provided for @indulgent.
  ///
  /// In en, this message translates to:
  /// **'Indulgent'**
  String get indulgent;

  /// No description provided for @daysLabel.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysLabel;

  /// No description provided for @noCuisineData.
  ///
  /// In en, this message translates to:
  /// **'No cuisine data available'**
  String get noCuisineData;

  /// No description provided for @whatShouldICook.
  ///
  /// In en, this message translates to:
  /// **'What should I cook?'**
  String get whatShouldICook;

  /// No description provided for @addDish.
  ///
  /// In en, this message translates to:
  /// **'Add Dish'**
  String get addDish;

  /// No description provided for @noRecommendations.
  ///
  /// In en, this message translates to:
  /// **'No recommendations found'**
  String get noRecommendations;

  /// No description provided for @recentlyEnjoyed.
  ///
  /// In en, this message translates to:
  /// **'Recently Enjoyed'**
  String get recentlyEnjoyed;

  /// No description provided for @noMealHistory.
  ///
  /// In en, this message translates to:
  /// **'No meal history yet'**
  String get noMealHistory;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// No description provided for @addedToCategory.
  ///
  /// In en, this message translates to:
  /// **'{name} added to {category}'**
  String addedToCategory(Object category, Object name);

  /// No description provided for @minLabel.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minLabel;

  /// No description provided for @shoppingListTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get shoppingListTitle;

  /// No description provided for @yourShoppingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your shopping list is empty'**
  String get yourShoppingEmpty;

  /// No description provided for @addItemsPlus.
  ///
  /// In en, this message translates to:
  /// **'Add items using the + button below'**
  String get addItemsPlus;

  /// No description provided for @toBuy.
  ///
  /// In en, this message translates to:
  /// **'To Buy'**
  String get toBuy;

  /// No description provided for @bought.
  ///
  /// In en, this message translates to:
  /// **'Bought'**
  String get bought;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @itemRemoved.
  ///
  /// In en, this message translates to:
  /// **'Item removed'**
  String get itemRemoved;

  /// No description provided for @errorUpdatingItem.
  ///
  /// In en, this message translates to:
  /// **'Error updating item: {error}'**
  String errorUpdatingItem(Object error);

  /// No description provided for @errorRemovingItem.
  ///
  /// In en, this message translates to:
  /// **'Error removing item: {error}'**
  String errorRemovingItem(Object error);

  /// No description provided for @errorAddingItem.
  ///
  /// In en, this message translates to:
  /// **'Error adding item: {error}'**
  String errorAddingItem(Object error);

  /// No description provided for @couldNotLoadShopping.
  ///
  /// In en, this message translates to:
  /// **'Could not load your shopping list'**
  String get couldNotLoadShopping;

  /// No description provided for @mealPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal Plan'**
  String get mealPlanTitle;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'Per Day'**
  String get perDay;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'bn',
        'en',
        'gu',
        'hi',
        'kn',
        'ml',
        'mr',
        'pa',
        'ta',
        'te',
        'ur'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'pa':
      return AppLocalizationsPa();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
