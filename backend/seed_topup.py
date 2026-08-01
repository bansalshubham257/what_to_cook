"""Top-up seed: bring every cuisine to at least 5 hardcoded recipes spanning meal categories."""
import sys
from app.core.database import SessionLocal
from app.models.recipe import Cuisine, Recipe, RecipeIngredient
from app.models.ingredient import Ingredient, IngredientCategoryType, IngredientStorageType

# (name, cuisine, meal_types, diet, prep, cook, total, difficulty, servings, health_score,
#  health_category, desc, tags, instructions, [(ingredient_name, quantity)])
RECIPES = [
    # ---------------- ASSAMESE ----------------
    (
        "Til Pitha", "assamese", ["breakfast"], "vegetarian", 20, 15, 35,
        "medium", 4, 62, "moderate",
        "Assamese rice-rolls stuffed with sweet sesame and jaggery, made during Magh Bihu.",
        ["assamese", "sweet", "rice", "festive"],
        "1. Roast sesame seeds and grind with jaggery into a coarse filling.\n"
        "2. Soak rice and grind to a smooth dough, knead with water.\n"
        "3. Flatten dough and wrap around the sesame filling into rolls.\n"
        "4. Steam the pithas for 15 minutes.\n"
        "5. Serve warm or cool, drizzled with ghee.",
        [("rice", "2 cups"), ("sesame_seeds", "1/2 cup"), ("jaggery", "1/2 cup"),
         ("ghee", "2 tbsp"), ("salt", "a pinch")],
    ),
    (
        "Khar (Assamese)", "assamese", ["lunch"], "vegetarian", 10, 25, 35,
        "easy", 4, 74, "balanced",
        "Alkaline Assamese vegetable stew, served first in every traditional thali.",
        ["assamese", "healthy", "stew", "simple"],
        "1. Boil mustard-alkali water (khar) until it froths.\n"
        "2. Add pumpkin, beans and raw papaya, simmer until soft.\n"
        "3. Season with salt and a little mustard oil.\n"
        "4. Serve with steamed rice.",
        [("pumpkin", "200g"), ("beans", "100g"), ("mustard_oil", "1 tbsp"),
         ("mustard_seeds", "1 tsp"), ("green_chilli", "2"), ("salt", "to taste")],
    ),
    (
        "Narikol Laru", "assamese", ["dessert"], "vegetarian", 15, 10, 25,
        "easy", 4, 58, "indulgent",
        "Coconut-ghee ladoos that melt in the mouth, an Assamese festival favourite.",
        ["assamese", "sweet", "coconut", "ladoo"],
        "1. Grate fresh coconut and dry-roast lightly.\n"
        "2. Add sugar and cardamom, cook until it comes together.\n"
        "3. Let it cool slightly, then shape into small balls.\n"
        "4. Roll in desiccated coconut and set.",
        [("coconut", "2 cups"), ("sugar", "3/4 cup"), ("cardamom", "4"),
         ("ghee", "1 tbsp")],
    ),
    # ---------------- AWADHI ----------------
    (
        "Sheermal", "awadhi", ["breakfast"], "vegetarian", 25, 20, 45,
        "medium", 4, 55, "moderate",
        "Saffron-scented leavened flatbread from the Lucknowi kitchens.",
        ["awadhi", "bread", "saffron", "breakfast"],
        "1. Dissolve yeast and sugar in warm milk, rest for 10 minutes.\n"
        "2. Knead with maida, ghee and saffron into a soft dough.\n"
        "3. Rest the dough for 30 minutes and divide into balls.\n"
        "4. Roll thin and bake or cook on a tawa until golden.\n"
        "5. Brush with ghee and serve with nihari or korma.",
        [("maida", "2 cups"), ("milk", "1/2 cup"), ("ghee", "2 tbsp"),
         ("sugar", "1 tbsp"), ("saffron", "a pinch"), ("salt", "to taste")],
    ),
    (
        "Kakori Kebab", "awadhi", ["dinner"], "non_vegetarian", 30, 25, 55,
        "hard", 4, 48, "moderate",
        "Velvety minced mutton kebabs from Kakori, Lucknow's royal grill.",
        ["awadhi", "kebab", "non_veg", "royal"],
        "1. Marinate minced mutton with raw papaya paste and spices overnight.\n"
        "2. Grind with ghee and cardamom into a silky paste.\n"
        "3. Shape onto skewers into long kebabs.\n"
        "4. Grill on a charcoal or tawa until charred and juicy.\n"
        "5. Serve with mint chutney and sheermal.",
        [("chicken", "500g"), ("onion", "1"), ("garlic", "6 cloves"), ("ginger", "1 inch"),
         ("curd", "2 tbsp"), ("ghee", "2 tbsp"), ("cardamom", "4"),
         ("red_chilli_powder", "1 tsp"), ("salt", "to taste")],
    ),
    (
        "Nawabi Paneer Curry", "awadhi", ["dinner"], "vegetarian", 15, 25, 40,
        "medium", 4, 66, "balanced",
        "Creamy Lucknowi paneer curry perfumed with saffron and kewra.",
        ["awadhi", "paneer", "curry", "royal"],
        "1. Marinate paneer cubes in curd, cream and spices.\n"
        "2. Cook onions with ghee and cashews into a silky gravy.\n"
        "3. Add the marinated paneer and simmer gently.\n"
        "4. Finish with saffron milk and crushed cardamom.\n"
        "5. Serve with sheermal or jeera rice.",
        [("paneer", "250g"), ("onion", "2"), ("curd", "1/2 cup"), ("cream", "2 tbsp"),
         ("cashews", "10"), ("ghee", "2 tbsp"), ("garam_masala", "1/2 tsp"),
         ("red_chilli_powder", "1/2 tsp"), ("milk", "1/4 cup"), ("salt", "to taste")],
    ),
    # ---------------- BENGALI ----------------
    (
        "Kosha Mangsho", "bengali", ["dinner"], "non_vegetarian", 20, 60, 80,
        "hard", 4, 52, "moderate",
        "Bengali-style slow-cooked mutton curry, dark and intensely spiced.",
        ["bengali", "non_veg", "mutton", "curry"],
        "1. Marinate mutton with curd and salt for 30 minutes.\n"
        "2. Fry onion paste in mustard oil until deeply golden.\n"
        "3. Add ginger-garlic, dry spices and marinated mutton.\n"
        "4. Cook covered on low heat, stirring often, until tender.\n"
        "5. Finish with ghee and garam masala, serve with luchi.",
        [("chicken", "500g"), ("onion", "3"), ("curd", "1/2 cup"), ("ginger", "1 inch"),
         ("garlic", "6 cloves"), ("mustard_oil", "3 tbsp"), ("garam_masala", "1 tsp"),
         ("red_chilli_powder", "1 tsp"), ("haldi", "1/2 tsp"), ("ghee", "1 tbsp"),
         ("salt", "to taste")],
    ),
    (
        "Mishti Doi", "bengali", ["dessert"], "vegetarian", 10, 30, 40,
        "easy", 4, 60, "indulgent",
        "Bengal's caramelised jaggery yogurt, set in clay pots.",
        ["bengali", "sweet", "dessert", "yogurt"],
        "1. Boil milk and reduce to half its volume.\n"
        "2. Caramelise jaggery into a thick syrup and mix in.\n"
        "3. Cool to lukewarm and whisk in curd culture.\n"
        "4. Pour into clay pots and set in a warm place for 6 hours.\n"
        "5. Chill before serving.",
        [("milk", "1 litre"), ("jaggery", "3/4 cup"), ("curd", "3 tbsp"), ("sugar", "2 tbsp")],
    ),
    # ---------------- BIHARI ----------------
    (
        "Ghughni", "bihari", ["snacks"], "vegetarian", 15, 25, 40,
        "easy", 4, 68, "balanced",
        "Spicy Bihari chickpea curry topped with onions and sev.",
        ["bihari", "snack", "chickpea", "street_food"],
        "1. Soak chickpeas overnight and pressure cook until soft.\n"
        "2. Temper mustard oil with jeera, bay leaf and hing.\n"
        "3. Add onion-tomato masala and cook well.\n"
        "4. Stir in the chickpeas and simmer for 10 minutes.\n"
        "5. Top with chopped onion, dhaniya and a squeeze of lemon.",
        [("chickpeas", "1.5 cups"), ("onion", "1"), ("tomato", "1"), ("jeera", "1/2 tsp"),
         ("bay_leaf", "1"), ("hing", "1/4 tsp"), ("mustard_oil", "2 tbsp"),
         ("red_chilli_powder", "1/2 tsp"), ("dhaniya", "handful"), ("lemon", "1"),
         ("salt", "to taste")],
    ),
    (
        "Bihari Khichdi", "bihari", ["dinner"], "vegetarian", 10, 30, 40,
        "easy", 4, 76, "balanced",
        "Comforting moong-rice khichdi served with ghee and achaar.",
        ["bihari", "khichdi", "healthy", "one_pot"],
        "1. Wash rice and moong dal together.\n"
        "2. Cook with ghee, haldi and salt until mushy.\n"
        "3. Temper with jeera, dry red chilli and curry leaves.\n"
        "4. Serve hot with ghee, pickle and papad.",
        [("rice", "1 cup"), ("moong_dal", "1/2 cup"), ("ghee", "2 tbsp"),
         ("haldi", "1/2 tsp"), ("jeera", "1 tsp"), ("dry_red_chilli", "1"),
         ("curry_leaves", "1 sprig"), ("salt", "to taste")],
    ),
    (
        "Malpua", "bihari", ["dessert"], "vegetarian", 15, 15, 30,
        "medium", 4, 55, "indulgent",
        "Crisp-edged wheat pancakes soaked in sugar syrup.",
        ["bihari", "sweet", "dessert", "festive"],
        "1. Whisk maida, sugar and milk into a thick batter.\n"
        "2. Rest for 20 minutes, add fennel seeds.\n"
        "3. Fry spoonfuls in ghee until golden on both sides.\n"
        "4. Dip the hot malpuas in warm sugar syrup.\n"
        "5. Serve topped with rabri or crushed nuts.",
        [("maida", "1.5 cups"), ("milk", "3/4 cup"), ("sugar", "1/2 cup"),
         ("saunf", "1 tsp"), ("ghee", "3 tbsp"), ("raisins", "2 tbsp")],
    ),
    # ---------------- CONTINENTAL ----------------
    (
        "Veggie Pizza", "continental", ["dinner"], "vegetarian", 20, 20, 40,
        "medium", 4, 58, "moderate",
        "Homemade pizza loaded with capsicum, corn and gooey cheese.",
        ["continental", "pizza", "comfort", "baked"],
        "1. Knead maida with yeast, sugar and water into a soft dough.\n"
        "2. Rest for 30 minutes, then roll into a base.\n"
        "3. Spread pizza sauce and top with veggies and cheese.\n"
        "4. Bake at 220C until crust is golden and cheese bubbles.\n"
        "5. Slice and serve hot.",
        [("maida", "2 cups"), ("yeast", "1 tsp"), ("tomato", "2"), ("capsicum", "1"),
         ("capsicum_red", "1"), ("capsicum_yellow", "1"), ("sweet_corn", "1/2 cup"),
         ("cheese", "1 cup"), ("cooking_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    (
        "Garlic Bread", "continental", ["snacks"], "vegetarian", 10, 10, 20,
        "easy", 4, 50, "moderate",
        "Crusty bread brushed with garlic butter and toasted.",
        ["continental", "snack", "baked", "quick"],
        "1. Mix softened butter with crushed garlic and parsley.\n"
        "2. Slice bread and spread the garlic butter generously.\n"
        "3. Sprinkle grated cheese and grill until golden.\n"
        "4. Serve hot with soup or dip.",
        [("bread", "6 slices"), ("butter", "3 tbsp"), ("garlic", "4 cloves"),
         ("cheese", "1/2 cup"), ("dhaniya", "handful")],
    ),
    # ---------------- GOAN ----------------
    (
        "Sanna", "goan", ["breakfast"], "vegetarian", 20, 20, 40,
        "medium", 4, 58, "moderate",
        "Fluffy steamed Goan rice cakes, sweet and spongy.",
        ["goan", "breakfast", "steamed", "rice"],
        "1. Soak rice and coconut together, grind to a batter.\n"
        "2. Add sugar and a little yeast, let it ferment briefly.\n"
        "3. Pour into small moulds lined with leaves.\n"
        "4. Steam for 15 minutes until fluffy.\n"
        "5. Serve with sorpotel or chicken curry.",
        [("rice", "2 cups"), ("coconut", "1 cup"), ("sugar", "3 tbsp"),
         ("milk", "1/2 cup"), ("salt", "a pinch")],
    ),
    (
        "Prawn Balchao", "goan", ["lunch"], "non_vegetarian", 20, 25, 45,
        "medium", 4, 55, "moderate",
        "Pungent Goan prawn pickle-curry, fiery and tangy.",
        ["goan", "seafood", "spicy", "pickle"],
        "1. Grind dry red chillies, garlic and spices with vinegar.\n"
        "2. Fry onions in oil until dark and jammy.\n"
        "3. Add the balchao masala and cook till it releases oil.\n"
        "4. Add prawns and simmer until coated and cooked.\n"
        "5. Serve with sanna or rice.",
        [("fish", "300g"), ("onion", "3"), ("garlic", "8 cloves"), ("dry_red_chilli", "6"),
         ("tamarind", "1 tbsp"), ("cooking_oil", "3 tbsp"), ("sugar", "1 tsp"),
         ("salt", "to taste")],
    ),
    (
        "Bebinca", "goan", ["dessert"], "vegetarian", 40, 45, 85,
        "hard", 6, 48, "indulgent",
        "Layered Goan coconut-egg pudding, a Christmas classic.",
        ["goan", "dessert", "coconut", "layered"],
        "1. Make a batter of coconut milk, flour, eggs and sugar.\n"
        "2. Grease a deep dish and pour a thin layer of batter.\n"
        "3. Grill until set, then pour another layer and repeat.\n"
        "4. Continue layering and grilling until all batter is used.\n"
        "5. Cool, slice and serve with a dusting of nutmeg.",
        [("coconut", "2 cups"), ("maida", "1/2 cup"), ("eggs", "6"), ("sugar", "1 cup"),
         ("ghee", "3 tbsp"), ("cardamom", "3")],
    ),
    # ---------------- GUJARATI ----------------
    (
        "Handvo", "gujarati", ["breakfast"], "vegetarian", 15, 35, 50,
        "medium", 4, 66, "balanced",
        "Gujarati lentil-rice savoury cake studded with bottle gourd.",
        ["gujarati", "breakfast", "baked", "steamed"],
        "1. Soak rice and dals, grind to a coarse batter.\n"
        "2. Mix in grated lauki, curd and spices.\n"
        "3. Temper mustard seeds, curry leaves and sesame in oil.\n"
        "4. Bake or steam the batter until golden and firm.\n"
        "5. Cut into squares and serve with chutney.",
        [("rice", "1.5 cups"), ("chana_dal", "1/2 cup"), ("toor_dal", "1/2 cup"),
         ("lauki", "1 cup grated"), ("curd", "1/2 cup"), ("mustard_seeds", "1 tsp"),
         ("curry_leaves", "1 sprig"), ("sesame_seeds", "1 tsp"), ("green_chilli", "2"),
         ("cooking_oil", "3 tbsp"), ("salt", "to taste")],
    ),
    (
        "Mohanthal", "gujarati", ["dessert"], "vegetarian", 20, 25, 45,
        "medium", 4, 50, "indulgent",
        "Rich besan-ghee fudge perfumed with cardamom, a Gujarati mithai.",
        ["gujarati", "sweet", "mithai", "festive"],
        "1. Roast besan in ghee on low heat until aromatic.\n"
        "2. Add milk and cook to a thick lumpy mixture.\n"
        "3. Mix in sugar and cardamom, cook for 5 minutes.\n"
        "4. Pour into a greased tray and press flat.\n"
        "5. Cool, cut into diamonds and garnish with pistachio.",
        [("besan", "2 cups"), ("ghee", "1 cup"), ("milk", "1/2 cup"), ("sugar", "1 cup"),
         ("cardamom", "4"), ("cashews", "10")],
    ),
    # ---------------- HARYANVI ----------------
    (
        "Besan Masala Roti", "haryanvi", ["breakfast"], "vegetarian", 15, 20, 35,
        "easy", 4, 66, "balanced",
        "Haryanvi gram-flour roti spiced with onion and chilli.",
        ["haryanvi", "roti", "breakfast", "rustic"],
        "1. Mix besan with atta, onion, chilli and spices.\n"
        "2. Knead into a soft dough with water.\n"
        "3. Roll into thick rotis.\n"
        "4. Cook on a hot tawa with ghee until golden.\n"
        "5. Serve with white butter and jaggery.",
        [("besan", "1 cup"), ("atta", "1 cup"), ("onion", "1/2"), ("green_chilli", "2"),
         ("dhaniya", "handful"), ("jeera", "1 tsp"), ("ghee", "2 tbsp"), ("salt", "to taste")],
    ),
    (
        "Bajre ki Khichdi", "haryanvi", ["dinner"], "vegetarian", 15, 35, 50,
        "medium", 4, 72, "balanced",
        "Rustic pearl-millet khichdi from Haryana's winter kitchens.",
        ["haryanvi", "khichdi", "healthy", "winter"],
        "1. Wash bajra and moong dal together.\n"
        "2. Pressure cook with ghee, ginger and haldi until soft.\n"
        "3. Temper with jeera and dry red chilli in ghee.\n"
        "4. Stir and cook down to a thick porridge.\n"
        "5. Serve with white butter and jaggery.",
        [("bajra", "1 cup"), ("moong_dal", "1/2 cup"), ("ghee", "2 tbsp"),
         ("ginger", "1 inch"), ("haldi", "1/2 tsp"), ("jeera", "1 tsp"),
         ("dry_red_chilli", "1"), ("salt", "to taste")],
    ),
    (
        "Haryanvi Saag", "haryanvi", ["lunch"], "vegetarian", 15, 30, 45,
        "easy", 4, 74, "balanced",
        "Mustard-spinach saag slow-cooked with ghee and cornmeal.",
        ["haryanvi", "saag", "healthy", "winter"],
        "1. Blanch spinach and chop finely.\n"
        "2. Cook with ginger, garlic and green chilli in ghee.\n"
        "3. Add besan and simmer until the saag thickens.\n"
        "4. Season with salt and finish with butter.\n"
        "5. Serve with bajra roti.",
        [("spinach", "4 cups"), ("ginger", "1 inch"), ("garlic", "4 cloves"),
         ("green_chilli", "2"), ("ghee", "3 tbsp"), ("besan", "2 tbsp"),
         ("butter", "1 tbsp"), ("salt", "to taste")],
    ),
    (
        "Churma", "haryanvi", ["dessert"], "vegetarian", 20, 25, 45,
        "medium", 4, 52, "indulgent",
        "Sweet crushed wheat-rolls in ghee and jaggery, eaten with dal baati.",
        ["haryanvi", "sweet", "festive", "dessert"],
        "1. Knead atta with ghee into a stiff dough.\n"
        "2. Shape into small baatis and bake until golden.\n"
        "3. Crush the baked baatis finely.\n"
        "4. Mix with warm ghee and jaggery, add cardamom.\n"
        "5. Shape into balls and garnish with raisins.",
        [("atta", "2 cups"), ("ghee", "1/2 cup"), ("jaggery", "1/2 cup"),
         ("cardamom", "3"), ("raisins", "2 tbsp")],
    ),
    # ---------------- HIMACHALI ----------------
    (
        "Babru", "himachali", ["breakfast"], "vegetarian", 20, 15, 35,
        "medium", 4, 58, "moderate",
        "Himachali black-gram stuffed puris, golden and puffy.",
        ["himachali", "breakfast", "fried", "pahadi"],
        "1. Soak urad dal for 4 hours and grind to a paste.\n"
        "2. Season the paste with ajwain and salt.\n"
        "3. Knead a stiff dough of atta and make small balls.\n"
        "4. Stuff each ball with dal paste and roll out.\n"
        "5. Deep-fry until golden, serve with chutney.",
        [("urad_dal", "1 cup"), ("atta", "2 cups"), ("cooking_oil", "for frying"),
         ("saunf", "1/2 tsp"), ("salt", "to taste")],
    ),
    (
        "Pahadi Kadhi", "himachali", ["lunch"], "vegetarian", 15, 30, 45,
        "medium", 4, 70, "balanced",
        "Himachali yogurt curry thickened with besan and chickpea pakoras.",
        ["himachali", "kadhi", "healthy", "pahadi"],
        "1. Whisk curd with besan, haldi and salt.\n"
        "2. Simmer while stirring until it thickens.\n"
        "3. Drop in onion-besan pakoras and cook.\n"
        "4. Temper with jeera, hing and dry red chilli in ghee.\n"
        "5. Serve with steamed rice.",
        [("curd", "2 cups"), ("besan", "3 tbsp"), ("onion", "1"), ("haldi", "1/2 tsp"),
         ("jeera", "1/2 tsp"), ("hing", "1/4 tsp"), ("dry_red_chilli", "2"),
         ("ghee", "2 tbsp"), ("salt", "to taste")],
    ),
    (
        "Sepu Badi", "himachali", ["dinner"], "vegetarian", 20, 35, 55,
        "medium", 4, 66, "balanced",
        "Himachali black-gram dumplings simmered in a mild yogurt gravy.",
        ["himachali", "dal", "badi", "pahadi"],
        "1. Grind soaked urad dal and shape into small dumplings.\n"
        "2. Sun-dry or roast the badis.\n"
        "3. Cook the badis in a curd-besan gravy.\n"
        "4. Temper with jeera, hing and dry red chilli.\n"
        "5. Serve hot with rice.",
        [("urad_dal", "1 cup"), ("curd", "1.5 cups"), ("besan", "2 tbsp"),
         ("jeera", "1/2 tsp"), ("hing", "1/4 tsp"), ("dry_red_chilli", "2"),
         ("ghee", "2 tbsp"), ("salt", "to taste")],
    ),
    (
        "Chha Gosht", "himachali", ["dinner"], "non_vegetarian", 20, 60, 80,
        "hard", 4, 55, "moderate",
        "Pahadi yogurt-mutton curry with a garlic chilli finish.",
        ["himachali", "non_veg", "mutton", "curry"],
        "1. Marinate mutton in curd and salt.\n"
        "2. Cook onions and spices in ghee until fragrant.\n"
        "3. Add the mutton and cook covered until tender.\n"
        "4. Whisk in curd and simmer to a thick gravy.\n"
        "5. Finish with fried garlic and green chilli, serve with rice.",
        [("chicken", "500g"), ("curd", "1 cup"), ("onion", "2"), ("garlic", "8 cloves"),
         ("ginger", "1 inch"), ("green_chilli", "3"), ("ghee", "3 tbsp"),
         ("red_chilli_powder", "1 tsp"), ("haldi", "1/2 tsp"), ("salt", "to taste")],
    ),
    # ---------------- HYDERABADI ----------------
    (
        "Mirchi ka Salan", "hyderabadi", ["lunch"], "vegetarian", 20, 30, 50,
        "medium", 4, 60, "moderate",
        "Hyderabadi green chilli curry in a peanut-sesame gravy.",
        ["hyderabadi", "spicy", "curry", "royal"],
        "1. Fry green chillies in oil until blistered.\n"
        "2. Grind peanuts, sesame and coconut into a paste.\n"
        "3. Cook the paste with tamarind and spices.\n"
        "4. Add the fried chillies and simmer.\n"
        "5. Serve with biryani or phulka.",
        [("green_chilli", "8"), ("peanuts", "1/2 cup"), ("sesame_seeds", "2 tbsp"),
         ("coconut", "1/4 cup"), ("tamarind", "1 tbsp"), ("onion", "1"),
         ("cooking_oil", "3 tbsp"), ("red_chilli_powder", "1 tsp"), ("salt", "to taste")],
    ),
    (
        "Hyderabadi Nihari", "hyderabadi", ["breakfast"], "non_vegetarian", 25, 120, 145,
        "hard", 4, 45, "moderate",
        "Slow-simmered bone-in mutton gravy, a Hyderabadi breakfast classic.",
        ["hyderabadi", "non_veg", "mutton", "slow_cooked"],
        "1. Marinate mutton with ginger-garlic and spices overnight.\n"
        "2. Slow-cook with wheat flour until the gravy thickens.\n"
        "3. Shred the tender meat back into the nihari.\n"
        "4. Finish with fried ginger and green chilli.\n"
        "5. Serve with khameeri roti and lemon.",
        [("chicken", "500g"), ("onion", "2"), ("ginger", "2 inch"), ("garlic", "8 cloves"),
         ("atta", "2 tbsp"), ("ghee", "3 tbsp"), ("garam_masala", "1 tsp"),
         ("red_chilli_powder", "1 tsp"), ("lemon", "1"), ("salt", "to taste")],
    ),
    (
        "Double ka Meetha", "hyderabadi", ["dessert"], "vegetarian", 15, 25, 40,
        "medium", 4, 50, "indulgent",
        "Hyderabadi bread pudding soaked in saffron sugar syrup.",
        ["hyderabadi", "dessert", "sweet", "royal"],
        "1. Fry bread slices in ghee until golden.\n"
        "2. Boil sugar and water with cardamom into syrup.\n"
        "3. Soak the fried bread in the warm syrup.\n"
        "4. Layer with khoya and toasted cashews.\n"
        "5. Drizzle with saffron milk and serve.",
        [("bread", "6 slices"), ("ghee", "3 tbsp"), ("sugar", "3/4 cup"),
         ("cardamom", "3"), ("milk", "1/2 cup"), ("cashews", "10"), ("saffron", "a pinch")],
    ),
    # ---------------- INDO-CHINESE ----------------
    (
        "Schezwan Fried Rice", "indo_chinese", ["lunch"], "vegetarian", 15, 15, 30,
        "easy", 4, 60, "moderate",
        "Fiery Indo-Chinese fried rice tossed in schezwan sauce.",
        ["indo_chinese", "spicy", "fried_rice", "street_food"],
        "1. Cook rice and cool completely.\n"
        "2. Stir-fry garlic, onion and capsicum in hot oil.\n"
        "3. Add schezwan sauce, soy sauce and vinegar.\n"
        "4. Toss in the rice on high flame.\n"
        "5. Finish with spring onions and serve hot.",
        [("rice", "2 cups"), ("capsicum", "1"), ("capsicum_red", "1"), ("onion", "1"),
         ("garlic", "6 cloves"), ("soy_sauce", "2 tbsp"), ("green_chilli", "3"),
         ("cooking_oil", "3 tbsp"), ("salt", "to taste")],
    ),
    (
        "Veg Spring Rolls", "indo_chinese", ["snacks"], "vegetarian", 25, 15, 40,
        "medium", 4, 55, "moderate",
        "Crisp fried rolls stuffed with spicy cabbage-vegetable filling.",
        ["indo_chinese", "snack", "fried", "starter"],
        "1. Shred cabbage, carrot and capsicum, stir-fry with soy.\n"
        "2. Thicken with cornflour slurry and cool.\n"
        "3. Wrap the filling in thin maida sheets.\n"
        "4. Deep-fry until golden and crisp.\n"
        "5. Serve with schezwan chutney.",
        [("cabbage", "2 cups"), ("carrot", "1"), ("capsicum", "1"), ("maida", "1 cup"),
         ("cornflour", "1 tbsp"), ("soy_sauce", "1 tbsp"), ("ginger", "1 inch"),
         ("green_chilli", "2"), ("cooking_oil", "for frying"), ("salt", "to taste")],
    ),
    # ---------------- JHARKHANDI ----------------
    (
        "Aloo Chokha", "jharkhandi", ["lunch"], "vegetarian", 10, 20, 30,
        "easy", 4, 70, "balanced",
        "Smoky mashed potato with green chilli and mustard oil.",
        ["jharkhandi", "simple", "healthy", "comfort"],
        "1. Roast potatoes over flame until the skin is charred.\n"
        "2. Peel and mash roughly.\n"
        "3. Mix in chopped onion, green chilli and salt.\n"
        "4. Drizzle with hot mustard oil and dhaniya.\n"
        "5. Serve with dhuska or rice.",
        [("potato", "4"), ("onion", "1/2"), ("green_chilli", "2"), ("mustard_oil", "2 tbsp"),
         ("dhaniya", "handful"), ("salt", "to taste")],
    ),
    (
        "Rugra ki Sabzi", "jharkhandi", ["dinner"], "vegetarian", 15, 25, 40,
        "medium", 4, 66, "balanced",
        "Jharkhand's monsoon wild mushroom curry, earthy and rustic.",
        ["jharkhandi", "mushroom", "curry", "tribal"],
        "1. Clean and halve mushrooms.\n"
        "2. Cook onions with ginger and garlic in mustard oil.\n"
        "3. Add tomatoes and spices, cook till soft.\n"
        "4. Add mushrooms and simmer until tender.\n"
        "5. Finish with dhaniya and serve with rice.",
        [("mushroom", "300g"), ("onion", "1"), ("tomato", "2"), ("ginger", "1 inch"),
         ("garlic", "4 cloves"), ("mustard_oil", "3 tbsp"), ("haldi", "1/2 tsp"),
         ("red_chilli_powder", "1 tsp"), ("dhaniya", "handful"), ("salt", "to taste")],
    ),
    (
        "Arsa", "jharkhandi", ["dessert"], "vegetarian", 20, 20, 40,
        "medium", 4, 55, "indulgent",
        "Jharkhand's jaggery rice-flour fritters, crisp and sweet.",
        ["jharkhandi", "sweet", "festive", "fritter"],
        "1. Melt jaggery with water to a syrup.\n"
        "2. Mix with rice flour and milk into a thick batter.\n"
        "3. Rest for 20 minutes.\n"
        "4. Drop spoonfuls into hot oil and fry till brown.\n"
        "5. Cool and store in an airtight jar.",
        [("rice_flour", "1.5 cups"), ("jaggery", "3/4 cup"), ("milk", "1/2 cup"),
         ("ghee", "1 tbsp"), ("cooking_oil", "for frying"), ("sesame_seeds", "1 tbsp")],
    ),
    # ---------------- KARNATAKA ----------------
    (
        "Mysore Masala Dosa", "karnataka", ["breakfast"], "vegetarian", 20, 20, 40,
        "medium", 4, 60, "moderate",
        "Crisp dosa smeared with fiery red chutney and potato filling.",
        ["karnataka", "dosa", "breakfast", "spicy"],
        "1. Grind soaked rice and urad dal into a fermented batter.\n"
        "2. Make a red chutney of chillies, garlic and coconut.\n"
        "3. Spread the batter thin on a hot tawa.\n"
        "4. Smear chutney, add potato filling, fold.\n"
        "5. Serve with chutney and sambar.",
        [("rice", "2 cups"), ("urad_dal", "1/2 cup"), ("dry_red_chilli", "4"),
         ("garlic", "4 cloves"), ("coconut", "1/4 cup"), ("potato", "2"),
         ("cooking_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    (
        "Maddur Vada", "karnataka", ["snacks"], "vegetarian", 15, 20, 35,
        "easy", 4, 60, "moderate",
        "Crunchy onion-semolina vadas from the Maddur railway station.",
        ["karnataka", "snack", "vada", "street_food"],
        "1. Mix suji, maida and rice flour.\n"
        "2. Add chopped onion, curry leaves and ghee.\n"
        "3. Knead with water into a stiff dough.\n"
        "4. Shape into flat discs and deep-fry.\n"
        "5. Serve hot with coconut chutney.",
        [("suji", "1 cup"), ("maida", "1/2 cup"), ("rice_flour", "2 tbsp"),
         ("onion", "1"), ("curry_leaves", "1 sprig"), ("ghee", "1 tbsp"),
         ("cooking_oil", "for frying"), ("salt", "to taste")],
    ),
    (
        "Mysore Pak", "karnataka", ["dessert"], "vegetarian", 15, 25, 40,
        "hard", 6, 48, "indulgent",
        "The legendary melt-in-mouth ghee-gram flour sweet of Mysore.",
        ["karnataka", "sweet", "mithai", "royal"],
        "1. Roast besan lightly and keep aside.\n"
        "2. Make sugar syrup to one-string consistency.\n"
        "3. Add ghee and besan alternately, stirring on low flame.\n"
        "4. Pour into a greased tray when it turns frothy.\n"
        "5. Cool and cut into squares.",
        [("besan", "2 cups"), ("ghee", "1.5 cups"), ("sugar", "2 cups"),
         ("cardamom", "3"), ("water", "1/2 cup")],
    ),
    # ---------------- KASHMIRI ----------------
    (
        "Rogan Josh", "kashmiri", ["dinner"], "non_vegetarian", 20, 60, 80,
        "hard", 4, 50, "moderate",
        "Kashmir's world-famous red lamb curry, mild heat, deep colour.",
        ["kashmiri", "non_veg", "mutton", "royal"],
        "1. Marinate mutton in curd, salt and ginger-garlic.\n"
        "2. Fry whole spices in ghee until fragrant.\n"
        "3. Add the mutton and brown well.\n"
        "4. Stir in curd, red chilli and kashmiri masala.\n"
        "5. Simmer covered until tender, serve with naan.",
        [("chicken", "500g"), ("curd", "3/4 cup"), ("onion", "1"), ("ginger", "1 inch"),
         ("garlic", "6 cloves"), ("ghee", "3 tbsp"), ("red_chilli_powder", "1 tbsp"),
         ("garam_masala", "1 tsp"), ("cloves", "3"), ("cardamom", "3"), ("salt", "to taste")],
    ),
    (
        "Nadir Yakhni", "kashmiri", ["lunch"], "vegetarian", 15, 35, 50,
        "medium", 4, 64, "balanced",
        "Delicate Kashmiri lotus-stem curry in a fennel-yogurt gravy.",
        ["kashmiri", "curry", "healthy", "royal"],
        "1. Peel and slice lotus stem, soak in water.\n"
        "2. Whisk curd with fennel and dried ginger.\n"
        "3. Cook lotus stem in ghee with whole spices.\n"
        "4. Add the curd mixture and simmer gently.\n"
        "5. Serve with steamed rice.",
        [("lotus_stem", "300g"), ("curd", "1.5 cups"), ("saunf", "1 tbsp"),
         ("ghee", "2 tbsp"), ("ginger", "1 inch"), ("dry_red_chilli", "2"),
         ("milk", "1/4 cup"), ("salt", "to taste")],
    ),
    (
        "Kashmiri Kahwa", "kashmiri", ["snacks"], "vegetarian", 5, 10, 15,
        "easy", 4, 70, "balanced",
        "Saffron-green tea with almonds and cardamom, served warm.",
        ["kashmiri", "tea", "healthy", "warm"],
        "1. Boil water with green tea leaves and saffron.\n"
        "2. Add crushed cardamom and cinnamon.\n"
        "3. Sweeten with honey and simmer for 2 minutes.\n"
        "4. Strain into cups, top with crushed almonds.\n"
        "5. Serve hot.",
        [("tea", "2 tsp"), ("saffron", "a pinch"), ("cardamom", "3"),
         ("cinnamon", "1 stick"), ("honey", "2 tbsp"), ("almonds", "10"), ("water", "4 cups")],
    ),
    # ---------------- KERALA ----------------
    (
        "Appam", "kerala", ["breakfast"], "vegetarian", 20, 20, 40,
        "medium", 4, 60, "moderate",
        "Lacy-edged Kerala rice pancakes with soft spongy centres.",
        ["kerala", "breakfast", "rice", "steamed"],
        "1. Soak rice and coconut, grind into a batter.\n"
        "2. Add a little yeast and ferment overnight.\n"
        "3. Pour a ladle of batter into a hot appam pan.\n"
        "4. Swirl to coat the sides, cover and steam till done.\n"
        "5. Serve with kadala curry or stew.",
        [("rice", "2 cups"), ("coconut", "1 cup"), ("sugar", "1 tbsp"),
         ("curd", "1 tbsp"), ("salt", "a pinch")],
    ),
    (
        "Kerala Fish Curry", "kerala", ["lunch"], "non_vegetarian", 15, 25, 40,
        "medium", 4, 62, "balanced",
        "Fiery Kerala fish curry in coconut milk and kokum.",
        ["kerala", "seafood", "spicy", "coconut"],
        "1. Grind dry red chillies, coriander and coconut into masala.\n"
        "2. Cook onions and tomatoes with the masala.\n"
        "3. Add coconut milk and tamarind, bring to a boil.\n"
        "4. Slide in fish pieces and simmer gently.\n"
        "5. Serve with steaming rice.",
        [("fish", "400g"), ("coconut", "1 cup"), ("onion", "1"), ("tomato", "2"),
         ("dry_red_chilli", "4"), ("tamarind", "1 tbsp"), ("curry_leaves", "1 sprig"),
         ("mustard_seeds", "1/2 tsp"), ("cooking_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    (
        "Palada Payasam", "kerala", ["dessert"], "vegetarian", 10, 40, 50,
        "easy", 6, 55, "indulgent",
        "Creamy rice-flake kheer, the grand finale of Kerala feasts.",
        ["kerala", "dessert", "kheer", "festive"],
        "1. Roast rice flakes in ghee lightly.\n"
        "2. Boil milk and add the roasted flakes.\n"
        "3. Simmer until the milk reduces and thickens.\n"
        "4. Add sugar and cardamom, cook 5 more minutes.\n"
        "5. Garnish with fried cashews and raisins.",
        [("milk", "1 litre"), ("poha_flattened", "1/2 cup"), ("sugar", "1 cup"),
         ("ghee", "2 tbsp"), ("cardamom", "4"), ("cashews", "10"), ("raisins", "2 tbsp")],
    ),
    # ---------------- MAHARASHTRIAN ----------------
    (
        "Misal Pav", "maharashtrian", ["lunch"], "vegetarian", 20, 30, 50,
        "medium", 4, 64, "balanced",
        "Pune's fiery sprouted-moth curry topped with farsan and pav.",
        ["maharashtrian", "spicy", "street_food", "curry"],
        "1. Pressure cook sprouts with salt and haldi.\n"
        "2. Grind onions, coconut and spices into the misal masala.\n"
        "3. Cook the masala, add sprouts and simmer.\n"
        "4. Top with farsan, onion and lemon.\n"
        "5. Serve with buttered pav.",
        [("chana_dal", "1 cup"), ("onion", "2"), ("coconut", "1/2 cup"),
         ("tomato", "1"), ("garlic", "6 cloves"), ("red_chilli_powder", "1 tsp"),
         ("cooking_oil", "3 tbsp"), ("bread", "4 slices"), ("lemon", "1"), ("salt", "to taste")],
    ),
    (
        "Sabudana Khichdi", "maharashtrian", ["breakfast"], "vegetarian", 20, 15, 35,
        "easy", 4, 68, "balanced",
        "Pearls of tapioca tossed with peanuts and green chilli.",
        ["maharashtrian", "breakfast", "fasting", "simple"],
        "1. Soak sabudana for 3 hours, drain well.\n"
        "2. Roast peanuts and crush coarsely.\n"
        "3. Temper ghee with jeera and green chilli.\n"
        "4. Add sabudana and peanuts, toss till translucent.\n"
        "5. Season with salt and lemon, serve warm.",
        [("sabudana", "1.5 cups"), ("peanuts", "1/2 cup"), ("ghee", "2 tbsp"),
         ("jeera", "1 tsp"), ("green_chilli", "2"), ("lemon", "1"), ("salt", "to taste")],
    ),
    (
        "Kothimbir Vadi", "maharashtrian", ["snacks"], "vegetarian", 25, 20, 45,
        "medium", 4, 62, "moderate",
        "Maharashtrian coriander-gram fritters, steamed then fried.",
        ["maharashtrian", "snack", "coriander", "fritter"],
        "1. Mix besan, chopped dhaniya, chilli and spices.\n"
        "2. Steam the mixture into a firm loaf.\n"
        "3. Cool and slice into pieces.\n"
        "4. Shallow-fry until crisp and golden.\n"
        "5. Serve with garlic chutney.",
        [("besan", "1.5 cups"), ("dhaniya", "1 cup"), ("green_chilli", "3"),
         ("curd", "1/2 cup"), ("ginger", "1 inch"), ("turmeric", "1/2 tsp"),
         ("cooking_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    (
        "Puran Poli", "maharashtrian", ["dessert"], "vegetarian", 30, 25, 55,
        "hard", 4, 58, "indulgent",
        "Sweet chana-dal stuffed flatbread, a festival essential.",
        ["maharashtrian", "sweet", "roti", "festive"],
        "1. Pressure cook chana dal and mash with jaggery.\n"
        "2. Cook the mixture with cardamom until thick.\n"
        "3. Knead a soft atta dough.\n"
        "4. Stuff each ball with the sweet filling and roll out.\n"
        "5. Cook on a tawa with ghee till golden.",
        [("chana_dal", "1.5 cups"), ("jaggery", "1 cup"), ("atta", "2 cups"),
         ("cardamom", "4"), ("ghee", "3 tbsp"), ("milk", "1/2 cup")],
    ),
    # ---------------- MANIPURI ----------------
    (
        "Singju", "manipuri", ["snacks"], "vegetarian", 20, 10, 30,
        "easy", 4, 72, "balanced",
        "Manipuri shredded-vegetable salad with toasted sesame.",
        ["manipuri", "salad", "healthy", "raw"],
        "1. Shred cabbage, onion and cabbage finely.\n"
        "2. Roast and crush sesame and red chilli.\n"
        "3. Toss the vegetables with the crush.\n"
        "4. Season with salt and a splash of lemon.\n"
        "5. Serve fresh.",
        [("cabbage", "2 cups"), ("onion", "1"), ("sesame_seeds", "2 tbsp"),
         ("dry_red_chilli", "2"), ("lemon", "1"), ("salt", "to taste")],
    ),
    (
        "Morok Metpa", "manipuri", ["dinner"], "vegetarian", 15, 20, 35,
        "medium", 4, 66, "balanced",
        "Manipuri green-chilli chutney, an intense table condiment.",
        ["manipuri", "chutney", "spicy", "condiment"],
        "1. Roast green chillies and garlic on a dry pan.\n"
        "2. Grind with salt and a little mustard oil.\n"
        "3. Blend to a coarse paste.\n"
        "4. Serve alongside rice and vegetables.",
        [("green_chilli", "8"), ("garlic", "6 cloves"), ("mustard_oil", "2 tbsp"),
         ("dry_red_chilli", "2"), ("salt", "to taste")],
    ),
    (
        "Alu Kangmet", "manipuri", ["breakfast"], "vegetarian", 15, 20, 35,
        "easy", 4, 70, "balanced",
        "Manipuri potato curry with crushed chilli and herbs.",
        ["manipuri", "potato", "curry", "simple"],
        "1. Boil and cube potatoes.\n"
        "2. Fry garlic and green chilli in mustard oil.\n"
        "3. Add potatoes and crushed chilli.\n"
        "4. Season with salt and dhaniya.\n"
        "5. Serve with rice or paratha.",
        [("potato", "4"), ("garlic", "4 cloves"), ("green_chilli", "3"),
         ("mustard_oil", "2 tbsp"), ("dhaniya", "handful"), ("salt", "to taste")],
    ),
    # ---------------- MUGLAI ----------------
    (
        "Shahi Tukda", "muglai", ["dessert"], "vegetarian", 15, 25, 40,
        "medium", 4, 52, "indulgent",
        "Royal fried bread layered with rabri and saffron.",
        ["muglai", "dessert", "sweet", "royal"],
        "1. Fry bread slices in ghee till golden.\n"
        "2. Reduce milk with sugar into thick rabri.\n"
        "3. Layer the bread with rabri in a dish.\n"
        "4. Top with saffron milk, pistachio and cardamom.\n"
        "5. Chill and serve.",
        [("bread", "6 slices"), ("ghee", "3 tbsp"), ("milk", "2 cups"),
         ("sugar", "1/2 cup"), ("saffron", "a pinch"), ("cardamom", "3"),
         ("cashews", "10")],
    ),
    (
        "Mutton Korma", "muglai", ["dinner"], "non_vegetarian", 20, 60, 80,
        "hard", 4, 50, "moderate",
        "Mughlai mutton korma in a velvet cashew-cream gravy.",
        ["muglai", "non_veg", "mutton", "royal"],
        "1. Marinate mutton in curd and spices.\n"
        "2. Fry onions golden, grind to a paste.\n"
        "3. Cook the onion paste with ghee and whole spices.\n"
        "4. Add mutton and cashew cream, simmer till tender.\n"
        "5. Finish with saffron and serve with naan.",
        [("chicken", "500g"), ("onion", "3"), ("curd", "1/2 cup"), ("cashews", "12"),
         ("ghee", "3 tbsp"), ("cream", "2 tbsp"), ("cardamom", "4"),
         ("cloves", "3"), ("cinnamon", "1 stick"), ("salt", "to taste")],
    ),
    (
        "Mughlai Paratha", "muglai", ["breakfast"], "vegetarian", 20, 15, 35,
        "medium", 2, 62, "moderate",
        "Layered Lucknowi paratha stuffed with spiced paneer-egg mix.",
        ["muglai", "paratha", "breakfast", "royal"],
        "1. Knead a soft maida dough.\n"
        "2. Mash paneer with egg, chilli and dhaniya.\n"
        "3. Roll out dough, spoon the filling and seal.\n"
        "4. Roll thin and shallow-fry in ghee.\n"
        "5. Serve with mint chutney.",
        [("maida", "1.5 cups"), ("paneer", "150g"), ("eggs", "2"),
         ("green_chilli", "2"), ("dhaniya", "handful"), ("ghee", "3 tbsp"),
         ("salt", "to taste")],
    ),
    (
        "Paneer Khurchan", "muglai", ["dinner"], "vegetarian", 20, 25, 45,
        "medium", 4, 64, "balanced",
        "Mughlai shredded paneer tossed with onion, capsicum and spices.",
        ["muglai", "paneer", "dry_curry", "royal"],
        "1. Crumble paneer into bite-size chunks.\n"
        "2. Fry onions and capsicum in ghee.\n"
        "3. Add tomato, ginger and spices, cook well.\n"
        "4. Toss in paneer and finish with butter.\n"
        "5. Serve with rumali or naan.",
        [("paneer", "300g"), ("onion", "2"), ("capsicum", "1"), ("tomato", "2"),
         ("ginger", "1 inch"), ("ghee", "2 tbsp"), ("garam_masala", "1/2 tsp"),
         ("red_chilli_powder", "1/2 tsp"), ("dhaniya", "handful"), ("salt", "to taste")],
    ),
    # ---------------- NAGA ----------------
    (
        "Galho", "naga", ["breakfast"], "vegetarian", 10, 30, 40,
        "easy", 4, 74, "balanced",
        "Naga rice and vegetable porridge, slow-stirred comfort food.",
        ["naga", "breakfast", "healthy", "porridge"],
        "1. Boil rice with plenty of water.\n"
        "2. Add chopped greens, beans and chilli.\n"
        "3. Stir continuously until it turns thick and sticky.\n"
        "4. Season with salt.\n"
        "5. Serve hot with fermented pickle.",
        [("rice", "1.5 cups"), ("spinach", "1 cup"), ("beans", "100g"),
         ("green_chilli", "2"), ("salt", "to taste")],
    ),
    (
        "Smoked Chicken Chilli", "naga", ["dinner"], "non_vegetarian", 20, 30, 50,
        "medium", 4, 58, "moderate",
        "Fiery Naga-style smoked chicken with dry red chilli.",
        ["naga", "chicken", "spicy", "smoky"],
        "1. Cut chicken into pieces and smoke briefly.\n"
        "2. Fry ginger, garlic and spring onion in oil.\n"
        "3. Add the smoked chicken and dry red chillies.\n"
        "4. Cook uncovered until caramelised and tender.\n"
        "5. Serve with steamed rice.",
        [("chicken", "500g"), ("ginger", "2 inch"), ("garlic", "6 cloves"),
         ("dry_red_chilli", "6"), ("onion", "1"), ("cooking_oil", "2 tbsp"),
         ("salt", "to taste")],
    ),
    (
        "Naga Vegetable Stew", "naga", ["lunch"], "vegetarian", 15, 30, 45,
        "easy", 4, 76, "balanced",
        "Naga one-pot vegetable stew, lightly spiced and healthy.",
        ["naga", "stew", "healthy", "simple"],
        "1. Chop potato, pumpkin and beans.\n"
        "2. Boil with ginger and green chilli.\n"
        "3. Season with salt and a drizzle of mustard oil.\n"
        "4. Simmer until the vegetables are tender.\n"
        "5. Serve with sticky rice.",
        [("potato", "2"), ("pumpkin", "200g"), ("beans", "100g"), ("ginger", "1 inch"),
         ("green_chilli", "2"), ("mustard_oil", "1 tbsp"), ("salt", "to taste")],
    ),
    # ---------------- NEPALI ----------------
    (
        "Dal Bhat", "nepali", ["dinner"], "vegetarian", 15, 35, 50,
        "easy", 4, 78, "balanced",
        "Nepal's national meal of lentil soup, rice and tarkari.",
        ["nepali", "dal", "rice", "staple"],
        "1. Pressure cook toor dal with turmeric and salt.\n"
        "2. Temper with ghee, jeera, garlic and dry chilli.\n"
        "3. Stir-fry a simple potato-cabbage tarkari.\n"
        "4. Steam the rice.\n"
        "5. Serve dal poured over rice with tarkari.",
        [("toor_dal", "1 cup"), ("rice", "2 cups"), ("potato", "2"), ("cabbage", "1 cup"),
         ("jeera", "1 tsp"), ("garlic", "4 cloves"), ("ghee", "2 tbsp"),
         ("dry_red_chilli", "2"), ("haldi", "1/2 tsp"), ("salt", "to taste")],
    ),
    (
        "Sel Roti", "nepali", ["breakfast"], "vegetarian", 15, 20, 35,
        "medium", 4, 60, "moderate",
        "Ring-shaped crispy-soft Nepali rice doughnut, a festival breakfast.",
        ["nepali", "breakfast", "fried", "festive"],
        "1. Soak rice and grind with ripe banana into a batter.\n"
        "2. Sweeten with sugar and a pinch of cardamom.\n"
        "3. Pipe rings of batter into hot oil.\n"
        "4. Fry until golden and crisp.\n"
        "5. Drain and serve with achaar.",
        [("rice", "2 cups"), ("banana", "1"), ("sugar", "1/2 cup"),
         ("cardamom", "3"), ("ghee", "1 tbsp"), ("cooking_oil", "for frying")],
    ),
    (
        "Gundruk", "nepali", ["dinner"], "vegetarian", 15, 25, 40,
        "medium", 4, 66, "balanced",
        "Fermented-leaf Nepali soup, tangy and warming.",
        ["nepali", "soup", "fermented", "healthy"],
        "1. Soak dried fermented leaves in water.\n"
        "2. Fry garlic, ginger and chilli in oil.\n"
        "3. Add the soaked gundruk and cook 5 minutes.\n"
        "4. Add water and simmer to a light soup.\n"
        "5. Serve hot with rice.",
        [("spinach", "2 cups"), ("garlic", "4 cloves"), ("ginger", "1 inch"),
         ("green_chilli", "2"), ("mustard_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    # ---------------- ODIA ----------------
    (
        "Chhena Poda", "odia", ["dessert"], "vegetarian", 25, 45, 70,
        "hard", 6, 52, "indulgent",
        "Odia baked caramelised cottage-cheese cake.",
        ["odia", "dessert", "paneer", "baked"],
        "1. Press fresh paneer to remove excess water.\n"
        "2. Mash with sugar, cardamom and raisins.\n"
        "3. Grease a pan and press the mixture in.\n"
        "4. Bake at 180C until the top caramelises.\n"
        "5. Cool, invert and serve in wedges.",
        [("paneer", "500g"), ("sugar", "1/2 cup"), ("cardamom", "3"),
         ("raisins", "2 tbsp"), ("ghee", "2 tbsp"), ("milk", "2 tbsp")],
    ),
    (
        "Dahi Baingana", "odia", ["lunch"], "vegetarian", 15, 25, 40,
        "easy", 4, 68, "balanced",
        "Odia eggplant in a tangy yogurt-curry gravy.",
        ["odia", "curry", "healthy", "yogurt"],
        "1. Roast eggplants, peel and mash.\n"
        "2. Whisk curd with roasted jeera powder.\n"
        "3. Temper mustard seeds, curry leaves and chilli in oil.\n"
        "4. Fold the mashed eggplant into the curd.\n"
        "5. Season and serve with steamed rice.",
        [("eggplant", "2"), ("curd", "1.5 cups"), ("jeera", "1 tsp"),
         ("mustard_seeds", "1/2 tsp"), ("curry_leaves", "1 sprig"),
         ("dry_red_chilli", "2"), ("cooking_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    # ---------------- PARSI ----------------
    (
        "Sali Murghi", "parsi", ["dinner"], "non_vegetarian", 20, 45, 65,
        "hard", 4, 52, "moderate",
        "Parsi chicken curry crowned with crisp potato straws.",
        ["parsi", "non_veg", "chicken", "curry"],
        "1. Fry potatoes into fine golden straws (sali).\n"
        "2. Grind onion, ginger, garlic and chilli into a masala.\n"
        "3. Cook the masala with tomatoes and spices.\n"
        "4. Add chicken and simmer until cooked through.\n"
        "5. Top with sali and serve with rice.",
        [("chicken", "500g"), ("potato", "2"), ("onion", "2"), ("ginger", "1 inch"),
         ("garlic", "6 cloves"), ("tomato", "2"), ("green_chilli", "2"),
         ("cooking_oil", "3 tbsp"), ("red_chilli_powder", "1 tsp"), ("salt", "to taste")],
    ),
    (
        "Parsi Akuri", "parsi", ["breakfast"], "vegetarian_egg", 10, 10, 20,
        "easy", 4, 60, "balanced",
        "Soft, buttery Parsi scrambled eggs with tomato and onion.",
        ["parsi", "breakfast", "eggs", "quick"],
        "1. Fry onions, tomatoes and green chilli in butter.\n"
        "2. Whisk eggs with a splash of milk and salt.\n"
        "3. Pour into the pan and stir gently.\n"
        "4. Cook until soft-scrambled, not dry.\n"
        "5. Serve on toast with a drizzle of cream.",
        [("eggs", "4"), ("onion", "1/2"), ("tomato", "1"), ("green_chilli", "1"),
         ("butter", "2 tbsp"), ("milk", "2 tbsp"), ("dhaniya", "handful"),
         ("salt", "to taste")],
    ),
    (
        "Parsi Papeta Bhaaji", "parsi", ["lunch"], "vegetarian", 15, 25, 40,
        "easy", 4, 66, "balanced",
        "Cumin-spiced Parsi potatoes with a sweet-sour finish.",
        ["parsi", "potato", "curry", "simple"],
        "1. Parboil potatoes and cube them.\n"
        "2. Temper oil with jeera, mustard seeds and garlic.\n"
        "3. Add potatoes and salt, toss well.\n"
        "4. Add a little jaggery and lemon for sweet-sour tang.\n"
        "5. Finish with dhaniya and serve with dal-rice.",
        [("potato", "4"), ("jeera", "1 tsp"), ("mustard_seeds", "1/2 tsp"),
         ("garlic", "4 cloves"), ("jaggery", "1 tbsp"), ("lemon", "1"),
         ("cooking_oil", "2 tbsp"), ("dhaniya", "handful"), ("salt", "to taste")],
    ),
    (
        "Lagan Nu Custard", "parsi", ["dessert"], "vegetarian", 20, 30, 50,
        "hard", 6, 55, "indulgent",
        "Parsi baked custard with raisins, cherries and a nutmeg top.",
        ["parsi", "dessert", "baked", "wedding"],
        "1. Scald milk and mix with sugar.\n"
        "2. Whisk in eggs and a pinch of nutmeg.\n"
        "3. Fold in raisins, almonds and cherries.\n"
        "4. Pour into a buttered dish and bake at 160C.\n"
        "5. Cool and dust with nutmeg before serving.",
        [("milk", "2 cups"), ("eggs", "4"), ("sugar", "3/4 cup"), ("raisins", "2 tbsp"),
         ("almonds", "10"), ("butter", "1 tbsp"), ("nutmeg", "a pinch")],
    ),
    # ---------------- RAJASTHANI ----------------
    (
        "Pyaaz Kachori", "rajasthani", ["snacks"], "vegetarian", 30, 25, 55,
        "hard", 4, 52, "moderate",
        "Jodhpur's flaky pastry stuffed with spiced onion filling.",
        ["rajasthani", "snack", "fried", "street_food"],
        "1. Knead a flaky maida dough with ghee.\n"
        "2. Cook onions with ginger, chilli and spices till dry.\n"
        "3. Stuff the dough balls with the onion masala.\n"
        "4. Deep-fry on low flame until crisp.\n"
        "5. Serve hot with tamarind chutney.",
        [("maida", "2 cups"), ("onion", "3"), ("ginger", "1 inch"), ("green_chilli", "3"),
         ("ghee", "2 tbsp"), ("cooking_oil", "for frying"), ("dhaniya", "handful"),
         ("salt", "to taste")],
    ),
    (
        "Mohan Maas", "rajasthani", ["dinner"], "non_vegetarian", 20, 60, 80,
        "hard", 4, 48, "moderate",
        "Royal Rajasthani mutton simmered in whole milk and saffron.",
        ["rajasthani", "non_veg", "mutton", "royal"],
        "1. Marinate mutton with ginger, garlic and salt.\n"
        "2. Brown it in ghee with whole spices.\n"
        "3. Add milk and cook very low and slow.\n"
        "4. Finish with saffron and dry red chilli.\n"
        "5. Serve with bajra roti or rice.",
        [("chicken", "500g"), ("milk", "2 cups"), ("ginger", "1 inch"),
         ("garlic", "6 cloves"), ("ghee", "3 tbsp"), ("cloves", "3"),
         ("cardamom", "4"), ("saffron", "a pinch"), ("dry_red_chilli", "2"),
         ("salt", "to taste")],
    ),
    # ---------------- SINDHI ----------------
    (
        "Sindhi Koki", "sindhi", ["breakfast"], "vegetarian", 15, 15, 30,
        "easy", 4, 64, "balanced",
        "Flaky Sindhi whole-wheat griddle bread with onion and chilli.",
        ["sindhi", "breakfast", "roti", "rustic"],
        "1. Knead atta with onion, chilli and spices.\n"
        "2. Add a little water and ghee to a soft dough.\n"
        "3. Roll thick and prick with a fork.\n"
        "4. Cook on a tawa, flipping and basting with ghee.\n"
        "5. Serve with curd and pickle.",
        [("atta", "2 cups"), ("onion", "1/2"), ("green_chilli", "2"), ("jeera", "1 tsp"),
         ("ghee", "3 tbsp"), ("dhaniya", "handful"), ("salt", "to taste")],
    ),
    (
        "Sai Bhaji", "sindhi", ["lunch"], "vegetarian", 20, 30, 50,
        "medium", 4, 74, "balanced",
        "Sindhi mixed greens curry cooked with dal and spices.",
        ["sindhi", "saag", "healthy", "curry"],
        "1. Chop spinach, cabbage, onion and tomato.\n"
        "2. Pressure cook with chana dal, ginger and chilli.\n"
        "3. Mash the cooked greens into a soft bhaji.\n"
        "4. Temper with garlic, cumin and red chilli.\n"
        "5. Serve with koki and rice.",
        [("spinach", "3 cups"), ("cabbage", "1 cup"), ("onion", "1"), ("tomato", "2"),
         ("chana_dal", "1/4 cup"), ("ginger", "1 inch"), ("green_chilli", "2"),
         ("garlic", "4 cloves"), ("cooking_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    (
        "Aloo Tuk", "sindhi", ["snacks"], "vegetarian", 10, 20, 30,
        "easy", 4, 62, "moderate",
        "Crisp Sindhi potato tikkis with a garlic-red chilli rub.",
        ["sindhi", "snack", "potato", "fried"],
        "1. Boil and mash potatoes with salt.\n"
        "2. Shape into thick flat tikkis.\n"
        "3. Pan-fry in oil until golden and crisp.\n"
        "4. Grind garlic and red chilli into a paste.\n"
        "5. Smear the paste over the hot tukkis and serve.",
        [("potato", "4"), ("garlic", "4 cloves"), ("red_chilli_powder", "1 tsp"),
         ("cooking_oil", "3 tbsp"), ("dhaniya", "handful"), ("salt", "to taste")],
    ),
    (
        "Sindhi Bhee", "sindhi", ["dinner"], "vegetarian", 15, 25, 40,
        "medium", 4, 66, "balanced",
        "Sindhi lotus-stem curry, crisp and tangy.",
        ["sindhi", "curry", "lotus_stem", "sindhi_special"],
        "1. Slice lotus stem into rings and soak in water.\n"
        "2. Pressure cook with onion, ginger and spices.\n"
        "3. Add tamarind and simmer till the stems absorb the masala.\n"
        "4. Temper with mustard seeds and curry leaves.\n"
        "5. Serve with koki or rice.",
        [("lotus_stem", "300g"), ("onion", "1"), ("ginger", "1 inch"),
         ("tamarind", "1 tbsp"), ("mustard_seeds", "1/2 tsp"), ("curry_leaves", "1 sprig"),
         ("cooking_oil", "2 tbsp"), ("red_chilli_powder", "1/2 tsp"), ("salt", "to taste")],
    ),
    # ---------------- SOUTH INDIAN ----------------
    (
        "Curd Rice", "south_indian", ["lunch"], "vegetarian", 10, 15, 25,
        "easy", 4, 74, "balanced",
        "Cooling South Indian yogurt rice with a mustard tempering.",
        ["south_indian", "rice", "yogurt", "healthy"],
        "1. Cook rice and mash with salt.\n"
        "2. Fold in beaten curd and milk.\n"
        "3. Temper mustard seeds, curry leaves and ginger in oil.\n"
        "4. Pour the tempering over and add pomegranate.\n"
        "5. Chill and serve.",
        [("rice", "2 cups"), ("curd", "1.5 cups"), ("milk", "1/4 cup"),
         ("mustard_seeds", "1/2 tsp"), ("curry_leaves", "1 sprig"), ("ginger", "1 inch"),
         ("green_chilli", "1"), ("cooking_oil", "1 tbsp"), ("salt", "to taste")],
    ),
    (
        "Medu Vada", "south_indian", ["snacks"], "vegetarian", 20, 20, 40,
        "medium", 4, 58, "moderate",
        "Crisp urad-dal doughnuts, a classic breakfast companion.",
        ["south_indian", "snack", "vada", "crispy"],
        "1. Soak urad dal and grind to a fluffy batter.\n"
        "2. Fold in pepper, curry leaves and ginger.\n"
        "3. Shape rings with wet hands.\n"
        "4. Deep-fry until golden and crisp.\n"
        "5. Serve with coconut chutney and sambar.",
        [("urad_dal", "1.5 cups"), ("pepper", "1 tsp"), ("curry_leaves", "1 sprig"),
         ("ginger", "1 inch"), ("green_chilli", "2"), ("cooking_oil", "for frying"),
         ("salt", "to taste")],
    ),
    # ---------------- TAMIL ----------------
    (
        "Chettinad Chicken", "tamil", ["dinner"], "non_vegetarian", 20, 40, 60,
        "hard", 4, 54, "moderate",
        "Fiery Chettinad chicken with roasted masala and curry leaves.",
        ["tamil", "non_veg", "chicken", "spicy"],
        "1. Roast and grind peppercorn, fennel, chilli and coriander.\n"
        "2. Cook onions, tomato and ginger-garlic in oil.\n"
        "3. Add the ground masala and fry well.\n"
        "4. Add chicken and simmer till tender.\n"
        "5. Finish with curry leaves and coconut milk.",
        [("chicken", "500g"), ("onion", "2"), ("tomato", "2"), ("pepper", "1 tsp"),
         ("saunf", "1 tsp"), ("dry_red_chilli", "4"), ("coconut", "1/2 cup"),
         ("curry_leaves", "1 sprig"), ("cooking_oil", "3 tbsp"), ("salt", "to taste")],
    ),
    (
        "Tomato Rasam", "tamil", ["lunch"], "vegetarian", 10, 20, 30,
        "easy", 4, 72, "balanced",
        "Peppery Tamil tomato rasam, soul-warming and light.",
        ["tamil", "rasam", "soup", "healthy"],
        "1. Boil tomatoes with tamarind and haldi.\n"
        "2. Mash and add rasam powder, pepper and salt.\n"
        "3. Simmer, then add a jaggery piece.\n"
        "4. Temper mustard seeds, jeera and curry leaves.\n"
        "5. Garnish with dhaniya and serve with rice.",
        [("tomato", "4"), ("tamarind", "1 tbsp"), ("pepper", "1 tsp"),
         ("mustard_seeds", "1/2 tsp"), ("jeera", "1 tsp"), ("curry_leaves", "1 sprig"),
         ("jaggery", "1 tbsp"), ("cooking_oil", "1 tbsp"), ("dhaniya", "handful"),
         ("salt", "to taste")],
    ),
    (
        "Sakkarai Pongal", "tamil", ["dessert"], "vegetarian", 10, 30, 40,
        "easy", 4, 56, "indulgent",
        "Sweet Pongal with jaggery, ghee and cardamom, a harvest delight.",
        ["tamil", "sweet", "pongal", "festive"],
        "1. Pressure cook rice and moong dal together.\n"
        "2. Melt jaggery with water and strain.\n"
        "3. Mix the jaggery syrup into the pongal.\n"
        "4. Temper cashews and raisins in ghee, add to the mix.\n"
        "5. Stir in cardamom and coconut, serve warm.",
        [("rice", "1 cup"), ("moong_dal", "1/4 cup"), ("jaggery", "3/4 cup"),
         ("ghee", "3 tbsp"), ("cashews", "10"), ("raisins", "2 tbsp"),
         ("cardamom", "3"), ("coconut", "1/4 cup")],
    ),
    # ---------------- TELUGU ----------------
    (
        "Pesarattu", "telugu", ["breakfast"], "vegetarian", 15, 15, 30,
        "easy", 4, 70, "balanced",
        "Andhra green-gram crepe, protein-packed breakfast.",
        ["telugu", "breakfast", "dosa", "healthy"],
        "1. Soak moong dal overnight and grind with ginger.\n"
        "2. Add green chilli, jeera and salt to the batter.\n"
        "3. Spread thin on a hot tawa.\n"
        "4. Drizzle oil and flip, cook till crisp.\n"
        "5. Serve with upma or chutney.",
        [("moong_dal", "1.5 cups"), ("ginger", "1 inch"), ("green_chilli", "2"),
         ("jeera", "1/2 tsp"), ("cooking_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    (
        "Gongura Pachadi", "telugu", ["lunch"], "vegetarian", 20, 20, 40,
        "medium", 4, 64, "balanced",
        "Andhra sorrel-leaves chutney, tangy and spicy.",
        ["telugu", "chutney", "spicy", "andhra"],
        "1. Cook sorrel leaves with a little water.\n"
        "2. Fry garlic, red chilli and onion in oil.\n"
        "3. Grind all together with salt and tamarind.\n"
        "4. Temper with mustard seeds and curry leaves.\n"
        "5. Serve with rice and ghee.",
        [("spinach", "3 cups"), ("garlic", "6 cloves"), ("dry_red_chilli", "4"),
         ("onion", "1"), ("tamarind", "1 tbsp"), ("mustard_seeds", "1/2 tsp"),
         ("curry_leaves", "1 sprig"), ("cooking_oil", "3 tbsp"), ("salt", "to taste")],
    ),
    (
        "Bobbatlu", "telugu", ["dessert"], "vegetarian", 30, 20, 50,
        "hard", 6, 52, "indulgent",
        "Andhra chana-dal stuffed sweet flatbread.",
        ["telugu", "sweet", "roti", "festive"],
        "1. Pressure cook chana dal and mash.\n"
        "2. Cook with jaggery and cardamom till thick.\n"
        "3. Knead a soft maida dough.\n"
        "4. Stuff and roll the sweet filling into flatbreads.\n"
        "5. Griddle with ghee till golden on both sides.",
        [("chana_dal", "1.5 cups"), ("jaggery", "1 cup"), ("maida", "2 cups"),
         ("cardamom", "3"), ("ghee", "3 tbsp")],
    ),
    # ---------------- UTTARAKHANDI ----------------
    (
        "Bhatt ki Churkani", "uttarakhandi", ["dinner"], "vegetarian", 20, 45, 65,
        "hard", 4, 72, "balanced",
        "Kumaoni black-soybean dal with a rustic stone-ground flavour.",
        ["uttarakhandi", "dal", "healthy", "pahadi"],
        "1. Soak black soybeans overnight.\n"
        "2. Pressure cook with salt and haldi.\n"
        "3. Grind ginger, garlic and spices into a paste.\n"
        "4. Temper in ghee with jeera and dry red chilli.\n"
        "5. Add to the dal, simmer and serve with rice.",
        [("kala_chana", "1.5 cups"), ("ginger", "1 inch"), ("garlic", "4 cloves"),
         ("ghee", "2 tbsp"), ("jeera", "1/2 tsp"), ("dry_red_chilli", "2"),
         ("haldi", "1/2 tsp"), ("salt", "to taste")],
    ),
    (
        "Jhangora Kheer", "uttarakhandi", ["dessert"], "vegetarian", 10, 30, 40,
        "easy", 4, 58, "indulgent",
        "Uttarakhand foxtail-millet kheer, nutty and comforting.",
        ["uttarakhandi", "kheer", "dessert", "millet"],
        "1. Roast millet in ghee lightly.\n"
        "2. Add milk and simmer until the millet softens.\n"
        "3. Sweeten with jaggery.\n"
        "4. Add cardamom and coconut.\n"
        "5. Garnish with almonds and serve.",
        [("suji", "1/2 cup"), ("milk", "1 litre"), ("jaggery", "1/2 cup"),
         ("cardamom", "3"), ("coconut", "2 tbsp"), ("ghee", "2 tbsp"), ("almonds", "10")],
    ),
    (
        "Aloo Ke Gutke", "uttarakhandi", ["breakfast"], "vegetarian", 15, 15, 30,
        "easy", 4, 66, "balanced",
        "Kumaoni spiced potatoes with jhuniya masala, a Pahadi breakfast.",
        ["uttarakhandi", "potato", "breakfast", "pahadi"],
        "1. Boil and cube potatoes.\n"
        "2. Temper oil with mustard seeds and asafoetida.\n"
        "3. Add potatoes, red chilli and salt.\n"
        "4. Toss till coated and slightly crisp.\n"
        "5. Finish with dhaniya and serve with curd.",
        [("potato", "4"), ("mustard_seeds", "1/2 tsp"), ("hing", "1/4 tsp"),
         ("red_chilli_powder", "1 tsp"), ("cooking_oil", "2 tbsp"),
         ("dhaniya", "handful"), ("salt", "to taste")],
    ),
]


# New ingredients auto-created by this seed: name -> (display_name, category, storage)
NEW_INGREDIENTS = {
    "bajra": ("Bajra", IngredientCategoryType.GRAIN, IngredientStorageType.PANTRY),
    "lotus_stem": ("Lotus Stem", IngredientCategoryType.VEGETABLE, IngredientStorageType.FRESH),
    "sabudana": ("Sabudana", IngredientCategoryType.GRAIN, IngredientStorageType.PANTRY),
}


def main():
    db = SessionLocal()
    try:
        ingredient_map = {i.name: i for i in db.query(Ingredient).all()}
        for name, (display, cat, storage) in NEW_INGREDIENTS.items():
            if name not in ingredient_map:
                ing = Ingredient(
                    name=name,
                    display_name_en=display,
                    display_name_hi=name,
                    category=cat,
                    storage_type=storage,
                    is_common=True,
                    is_active=True,
                )
                db.add(ing)
                db.flush()
                ingredient_map[name] = ing
                print(f"ingredient created: {name}")
        db.commit()

        cuisine_map = {c.name: c for c in db.query(Cuisine).all()}

        added = 0
        skipped = []
        for (name, cuisine, meal_types, diet, prep, cook, total, difficulty,
             servings, hscore, hcat, desc, tags, instructions, ings) in RECIPES:
            if db.query(Recipe).filter(Recipe.name == name).first():
                skipped.append(name)
                continue
            c = cuisine_map.get(cuisine)
            if not c:
                print(f"!! missing cuisine {cuisine} for {name}")
                continue
            recipe = Recipe(
                name=name,
                description=desc,
                cuisine_id=c.id,
                meal_types=meal_types,
                diet_type=diet,
                prep_time_minutes=prep,
                cook_time_minutes=cook,
                total_time_minutes=total,
                difficulty=difficulty,
                servings=servings,
                instructions=instructions,
                health_score=hscore,
                health_category=hcat,
                tags=tags,
                source="seeded",
            )
            db.add(recipe)
            db.flush()
            for order, (ing_name, qty) in enumerate(ings):
                ing = ingredient_map.get(ing_name)
                if not ing:
                    print(f"!! missing ingredient {ing_name} for {name}")
                    continue
                db.add(RecipeIngredient(
                    recipe_id=recipe.id,
                    ingredient_id=ing.id,
                    quantity=qty,
                    unit=None,
                    is_required=True,
                    sort_order=order,
                ))
            added += 1
            print(f"added: {name}")

        db.commit()
        print(f"\nDone. {added} new recipes added.")
        if skipped:
            print(f"Skipped (already exist): {skipped}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
