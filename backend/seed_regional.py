"""Seed all Indian regional cuisines + recipes so every Indian state's food is available."""
import sys
from app.core.database import SessionLocal
from app.models.recipe import Cuisine, Recipe, RecipeIngredient, DietType, DifficultyLevel, HealthCategory
from app.models.ingredient import Ingredient, IngredientCategoryType, IngredientStorageType

NEW_INGREDIENTS = {
    "mustard_oil": ("Mustard Oil", "Sarson Ka Tel", IngredientCategoryType.OIL, IngredientStorageType.PANTRY),
    "sesame_seeds": ("Sesame Seeds", "Til", IngredientCategoryType.SPICE, IngredientStorageType.PANTRY),
    "cardamom": ("Green Cardamom", "Elaichi", IngredientCategoryType.SPICE, IngredientStorageType.PANTRY),
    "cloves": ("Cloves", "Laung", IngredientCategoryType.SPICE, IngredientStorageType.PANTRY),
    "cinnamon": ("Cinnamon", "Dalchini", IngredientCategoryType.SPICE, IngredientStorageType.PANTRY),
    "bay_leaf": ("Bay Leaf", "Tej Patta", IngredientCategoryType.SPICE, IngredientStorageType.PANTRY),
    "dry_red_chilli": ("Dry Red Chilli", "Sukhi Lal Mirch", IngredientCategoryType.SPICE, IngredientStorageType.PANTRY),
    "rice_flour": ("Rice Flour", "Chawal Ka Atta", IngredientCategoryType.GRAIN, IngredientStorageType.PANTRY),
    "poha_flattened": ("Poha (Flattened Rice)", "Poha", IngredientCategoryType.GRAIN, IngredientStorageType.PANTRY),
}

NEW_CUISINES = {
    "kashmiri": "Kashmiri",
    "awadhi": "Awadhi (Lucknowi)",
    "bihari": "Bihari",
    "jharkhandi": "Jharkhandi",
    "himachali": "Himachali",
    "haryanvi": "Haryanvi",
    "uttarakhandi": "Uttarakhandi",
    "goan": "Goan",
    "kerala": "Kerala",
    "tamil": "Tamil Nadu",
    "telugu": "Telugu (Andhra)",
    "karnataka": "Karnataka",
    "assamese": "Assamese",
    "manipuri": "Manipuri",
    "naga": "Naga",
    "nepali": "Nepali",
    "sindhi": "Sindhi",
    "parsi": "Parsi",
    "hyderabadi": "Hyderabadi",
    "muglai": "Mughlai",
}

# (name, cuisine, meal_types, diet, prep, cook, total, difficulty, servings, health_score,
#  health_category, desc, tags, instructions, [(ingredient_name, quantity)])
RECIPES = [
    # ---------------- KASHMIRI ----------------
    (
        "Kashmiri Dum Aloo", "kashmiri", ["lunch", "dinner"], "vegetarian", 20, 30, 50,
        "medium", 4, 64, "moderate",
        "Baby potatoes simmered in a rich fennel-yogurt gravy.",
        ["kashmiri", "potato", "rich", "festive"],
        "1. Boil and peel small potatoes, deep fry until golden.\n"
        "2. Whisk curd with ginger, haldi and red chilli powder.\n"
        "3. Temper whole spices in oil, add the curd mix.\n"
        "4. Add potatoes and simmer on low heat for 20 minutes.\n"
        "5. Finish with garam masala and serve hot.",
        [("potato", "500g"), ("curd", "1 cup"), ("ginger", "1 inch"),
         ("haldi", "1/2 tsp"), ("red_chilli_powder", "1 tsp"), ("garam_masala", "1/2 tsp"),
         ("saunf", "1 tsp"), ("cardamom", "3"), ("cloves", "3"), ("cinnamon", "1 inch"),
         ("cooking_oil", "3 tbsp"), ("salt", "to taste")],
    ),
    (
        "Kashmiri Pulao", "kashmiri", ["dinner"], "vegetarian", 10, 25, 35,
        "easy", 4, 70, "indulgent",
        "Fragrant rice with dry fruits, rose-milk and whole spices.",
        ["kashmiri", "rice", "festive", "sweet"],
        "1. Soak rice for 30 minutes.\n"
        "2. Heat ghee, add cardamom, cloves and cinnamon.\n"
        "3. Add rice and stir-fry for 2 minutes.\n"
        "4. Add milk and water, cook until rice is done.\n"
        "5. Fold in almonds, cashews and raisins.",
        [("rice", "1.5 cups"), ("ghee", "3 tbsp"), ("milk", "1/2 cup"),
         ("almonds", "2 tbsp"), ("cashews", "2 tbsp"), ("raisins", "2 tbsp"),
         ("cardamom", "4"), ("cloves", "3"), ("cinnamon", "1 inch"), ("salt", "to taste")],
    ),
    # ---------------- AWADHI / LUCKNOWI ----------------
    (
        "Lucknowi Biryani", "awadhi", ["lunch", "dinner"], "non_vegetarian", 30, 60, 90,
        "hard", 4, 62, "indulgent",
        "Layered aromatic rice and chicken biryani from the royal Awadh kitchens.",
        ["awadhi", "biryani", "chicken", "royal", "non_veg", "dinner"],
        "1. Marinate chicken with curd, ginger, garlic and spices for 1 hour.\n"
        "2. Par-boil rice with cardamom, cloves, cinnamon and bay leaf.\n"
        "3. Fry onions until golden, layer rice and chicken.\n"
        "4. Add pudina, dhaniya, lemon juice and ghee.\n"
        "5. Seal and cook on dum for 25 minutes.",
        [("chicken", "500g"), ("rice", "2 cups"), ("curd", "1/2 cup"),
         ("onion", "2"), ("ginger", "1 inch"), ("garlic", "6 cloves"),
         ("pudina", "handful"), ("dhaniya", "handful"), ("lemon", "1"),
         ("cardamom", "4"), ("cloves", "4"), ("cinnamon", "1 inch"), ("bay_leaf", "2"),
         ("garam_masala", "1 tsp"), ("ghee", "3 tbsp"), ("cooking_oil", "2 tbsp"),
         ("red_chilli_powder", "1/2 tsp"), ("haldi", "1/2 tsp"), ("salt", "to taste")],
    ),
    (
        "Shahi Paneer", "awadhi", ["lunch", "dinner"], "vegetarian", 15, 25, 40,
        "medium", 4, 62, "indulgent",
        "Rich Mughlai paneer in a creamy cashew-tomato gravy.",
        ["awadhi", "paneer", "rich", "royal", "dinner"],
        "1. Soak cashews, blend with cream into a smooth paste.\n"
        "2. Sauté onion, ginger and garlic in butter.\n"
        "3. Add tomato puree and cook until oil separates.\n"
        "4. Stir in the cashew-cream paste and spices.\n"
        "5. Add paneer cubes, simmer 5 minutes, finish with cardamom.",
        [("paneer", "250g"), ("cashews", "1/4 cup"), ("cream", "1/2 cup"),
         ("onion", "1"), ("tomato", "3"), ("ginger", "1 inch"), ("garlic", "4 cloves"),
         ("butter", "2 tbsp"), ("cardamom", "3"), ("garam_masala", "1/2 tsp"),
         ("red_chilli_powder", "1/2 tsp"), ("sugar", "1 tsp"), ("salt", "to taste")],
    ),
    # ---------------- BIHARI ----------------
    (
        "Litti Chokha", "bihari", ["lunch", "dinner"], "vegetarian", 25, 35, 60,
        "hard", 4, 68, "indulgent",
        "Roasted wheat-flour balls with spiced gram flour, served with mashed vegetables.",
        ["bihari", "comfort", "dinner", "traditional"],
        "1. Knead atta with ghee, salt and water.\n"
        "2. Mix besan, onion, green chilli and spices for stuffing.\n"
        "3. Fill the dough balls with stuffing and roll.\n"
        "4. Bake or roast the littis until golden, brush with ghee.\n"
        "5. Roast eggplant, potato and tomato, mash with garlic and dhaniya for chokha.",
        [("atta", "2 cups"), ("besan", "1/2 cup"), ("ghee", "3 tbsp"),
         ("eggplant", "1"), ("potato", "2"), ("tomato", "2"), ("onion", "1"),
         ("garlic", "5 cloves"), ("green_chilli", "1-2"), ("dhaniya", "handful"),
         ("jeera", "1 tsp"), ("cooking_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    (
        "Sattu Paratha", "bihari", ["breakfast", "lunch"], "vegetarian", 15, 20, 35,
        "easy", 4, 76, "balanced",
        "Wholewheat flatbread stuffed with spiced roasted gram flour.",
        ["bihari", "flatbread", "breakfast", "protein"],
        "1. Mix besan with onion, green chilli, jeera, dhaniya and salt.\n"
        "2. Knead atta into soft dough, divide into balls.\n"
        "3. Stuff each ball with the sattu filling.\n"
        "4. Roll out and cook on a griddle with ghee until golden.",
        [("atta", "2 cups"), ("besan", "1 cup"), ("onion", "1"),
         ("green_chilli", "1"), ("jeera", "1 tsp"), ("dhaniya", "handful"),
         ("ghee", "2 tbsp"), ("salt", "to taste")],
    ),
    # ---------------- HIMACHALI ----------------
    (
        "Chana Madra", "himachali", ["lunch", "dinner"], "vegetarian", 20, 40, 60,
        "medium", 4, 78, "balanced",
        "Kala chana cooked in a tangy yogurt gravy from Himachal.",
        ["himachali", "chana", "comfort", "traditional"],
        "1. Soak kala chana overnight, pressure cook until soft.\n"
        "2. Whisk curd with haldi, red chilli powder and ginger.\n"
        "3. Temper jeera, cardamom, cloves and cinnamon in ghee.\n"
        "4. Add the curd mix and simmer for 5 minutes.\n"
        "5. Add chana and cook until the gravy thickens.",
        [("kala_chana", "1.5 cups"), ("curd", "1 cup"), ("ginger", "1 inch"),
         ("jeera", "1 tsp"), ("haldi", "1/2 tsp"), ("red_chilli_powder", "1/2 tsp"),
         ("cardamom", "3"), ("cloves", "3"), ("cinnamon", "1 inch"), ("ghee", "2 tbsp"),
         ("salt", "to taste")],
    ),
    # ---------------- HARYANVI ----------------
    (
        "Haryanvi Kadhi", "haryanvi", ["lunch"], "vegetarian", 10, 25, 35,
        "easy", 4, 74, "balanced",
        "Thick yogurt-besan kadhi tempered with methi and ginger.",
        ["haryanvi", "kadhi", "comfort", "lunch"],
        "1. Whisk curd with besan, haldi and water.\n"
        "2. Temper ghee with jeera, methi seeds and curry leaves.\n"
        "3. Add ginger and green chilli, pour in the curd mix.\n"
        "4. Simmer on low heat for 20 minutes, stirring often.\n"
        "5. Serve hot with rice.",
        [("curd", "2 cups"), ("besan", "3 tbsp"), ("ginger", "1 inch"),
         ("green_chilli", "1"), ("methi_seeds", "1 tsp"), ("jeera", "1 tsp"),
         ("curry_leaves", "6-8"), ("ghee", "1 tbsp"), ("haldi", "1/2 tsp"),
         ("salt", "to taste")],
    ),
    (
        "Bajra Khichdi", "haryanvi", ["lunch", "dinner"], "vegetarian", 10, 30, 40,
        "easy", 4, 72, "balanced",
        "Comforting pearl-millet and moong dal khichdi.",
        ["haryanvi", "khichdi", "comfort", "healthy"],
        "1. Soak bajra and moong dal for 1 hour.\n"
        "2. Temper jeera and haldi in ghee.\n"
        "3. Add the soaked grains and water.\n"
        "4. Pressure cook until soft and mushy.\n"
        "5. Finish with ghee and serve with curd.",
        [("suji", "1 cup"), ("moong_dal", "1/2 cup"), ("ghee", "2 tbsp"),
         ("jeera", "1 tsp"), ("haldi", "1/2 tsp"), ("curd", "1/2 cup"), ("salt", "to taste")],
    ),
    # ---------------- GOAN ----------------
    (
        "Goan Fish Curry", "goan", ["lunch", "dinner"], "non_vegetarian", 15, 25, 40,
        "medium", 4, 70, "balanced",
        "Coconut-tamarind fish curry from the Goan coast.",
        ["goan", "fish", "coconut", "coastal", "non_veg"],
        "1. Grind coconut, red chillies, garlic and haldi into a paste.\n"
        "2. Temper mustard seeds and curry leaves in oil.\n"
        "3. Add onion and sauté, then the coconut paste.\n"
        "4. Add tamarind water and simmer.\n"
        "5. Slide in fish pieces and cook for 8 minutes.",
        [("fish", "500g"), ("coconut", "1/2 cup"), ("tamarind", "small ball"),
         ("onion", "1"), ("garlic", "5 cloves"), ("green_chilli", "2"),
         ("mustard_seeds", "1 tsp"), ("curry_leaves", "8-10"), ("haldi", "1/2 tsp"),
         ("red_chilli_powder", "1/2 tsp"), ("cooking_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    (
        "Veg Xacuti", "goan", ["lunch", "dinner"], "vegetarian", 20, 30, 50,
        "hard", 4, 66, "moderate",
        "Goan vegetable curry with roasted coconut and poppy seeds.",
        ["goan", "coconut", "spicy", "coastal"],
        "1. Roast coconut, khus khus, onion and spices.\n"
        "2. Grind with garlic and ginger into a paste.\n"
        "3. Sauté the paste in oil until fragrant.\n"
        "4. Add mixed vegetables and water, simmer.\n"
        "5. Cook until tender, serve with rice.",
        [("potato", "1"), ("cauliflower", "1 cup"), ("carrot", "1"),
         ("peas", "1/4 cup"), ("coconut", "1/2 cup"), ("khus_khus", "1 tbsp"),
         ("onion", "1"), ("garlic", "4 cloves"), ("ginger", "1 inch"),
         ("red_chilli_powder", "1 tsp"), ("garam_masala", "1/2 tsp"),
         ("cooking_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    # ---------------- KERALA ----------------
    (
        "Avial", "kerala", ["lunch", "dinner"], "vegetarian", 20, 25, 45,
        "medium", 4, 82, "balanced",
        "Mixed vegetables in a coconut-curd gravy with curry leaves.",
        ["kerala", "coconut", "healthy", "sadya"],
        "1. Steam mixed vegetables until tender.\n"
        "2. Grind coconut with green chilli and jeera.\n"
        "3. Add the paste and curd to the vegetables.\n"
        "4. Temper mustard seeds and curry leaves in coconut oil.\n"
        "5. Pour tempering over the avial and serve.",
        [("potato", "1"), ("carrot", "1"), ("beans", "100g"), ("lauki", "1 cup"),
         ("coconut", "1/2 cup"), ("curd", "1/2 cup"), ("green_chilli", "1-2"),
         ("jeera", "1/2 tsp"), ("mustard_seeds", "1 tsp"), ("curry_leaves", "8-10"),
         ("cooking_oil", "1 tbsp"), ("salt", "to taste")],
    ),
    (
        "Kerala Kadala Curry", "kerala", ["breakfast", "dinner"], "vegetarian", 20, 30, 50,
        "medium", 4, 78, "balanced",
        "Black chickpeas in a coconut gravy, a classic with appam.",
        ["kerala", "chana", "coconut", "breakfast"],
        "1. Soak kala chana overnight, pressure cook until soft.\n"
        "2. Grind coconut, onion, garlic, ginger and spices.\n"
        "3. Temper mustard seeds and curry leaves.\n"
        "4. Add the ground paste and cook for 5 minutes.\n"
        "5. Add chana and simmer until thick.",
        [("kala_chana", "1.5 cups"), ("coconut", "1/2 cup"), ("onion", "1"),
         ("garlic", "4 cloves"), ("ginger", "1 inch"), ("green_chilli", "1-2"),
         ("mustard_seeds", "1 tsp"), ("curry_leaves", "8-10"), ("haldi", "1/2 tsp"),
         ("red_chilli_powder", "1/2 tsp"), ("cooking_oil", "1 tbsp"), ("salt", "to taste")],
    ),
    # ---------------- TAMIL ----------------
    (
        "Ven Pongal", "tamil", ["breakfast"], "vegetarian", 5, 25, 30,
        "easy", 4, 84, "balanced",
        "Creamy rice-moong dal pongal tempered with pepper and ghee.",
        ["tamil", "breakfast", "healthy", "comfort"],
        "1. Roast moong dal until aromatic, wash with rice.\n"
        "2. Cook rice and dal together until very soft.\n"
        "3. Mash well, add ghee.\n"
        "4. Temper pepper, jeera, ginger and curry leaves in ghee.\n"
        "5. Mix the tempering in, top with cashews.",
        [("rice", "1 cup"), ("moong_dal", "1/2 cup"), ("ghee", "3 tbsp"),
         ("pepper", "1 tsp"), ("jeera", "1 tsp"), ("ginger", "1 inch"),
         ("curry_leaves", "8-10"), ("cashews", "1 tbsp"), ("salt", "to taste")],
    ),
    (
        "Lemon Rice", "tamil", ["lunch"], "vegetarian", 10, 15, 25,
        "easy", 4, 80, "balanced",
        "Tangy tempered rice with peanuts and curry leaves.",
        ["tamil", "rice", "quick", "lunch"],
        "1. Cook rice and spread on a plate to cool.\n"
        "2. Temper mustard seeds, curry leaves, peanuts and green chilli.\n"
        "3. Add haldi and salt, turn off heat.\n"
        "4. Add lemon juice and the rice, toss well.\n"
        "5. Serve with pickle.",
        [("rice", "2 cups"), ("lemon", "2"), ("peanuts", "2 tbsp"),
         ("mustard_seeds", "1 tsp"), ("curry_leaves", "8-10"), ("green_chilli", "1-2"),
         ("haldi", "1/2 tsp"), ("cooking_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    # ---------------- TELUGU / ANDHRA ----------------
    (
        "Pulihora", "telugu", ["lunch"], "vegetarian", 20, 20, 40,
        "medium", 4, 72, "balanced",
        "Andhra-style tamarind rice with peanuts and curry leaves.",
        ["telugu", "rice", "tamarind", "festive", "lunch"],
        "1. Cook rice and cool.\n"
        "2. Soak tamarind, extract thick pulp.\n"
        "3. Temper mustard seeds, curry leaves, peanuts and chillies.\n"
        "4. Add tamarind pulp, jaggery and haldi, cook until thick.\n"
        "5. Mix the sauce into the rice.",
        [("rice", "2 cups"), ("tamarind", "gooseberry size"), ("peanuts", "3 tbsp"),
         ("mustard_seeds", "1 tsp"), ("curry_leaves", "8-10"), ("green_chilli", "2"),
         ("jaggery", "1 tbsp"), ("haldi", "1/2 tsp"), ("cooking_oil", "2 tbsp"),
         ("salt", "to taste")],
    ),
    (
        "Gutti Vankaya", "telugu", ["lunch", "dinner"], "vegetarian", 20, 25, 45,
        "medium", 4, 66, "moderate",
        "Stuffed baby eggplant curry in a peanut-sesame gravy.",
        ["telugu", "eggplant", "spicy", "peanut"],
        "1. Slit eggplants, stuff with peanut-coconut spice mix.\n"
        "2. Grind onion, garlic, ginger and tamarind into a paste.\n"
        "3. Sauté the paste in oil.\n"
        "4. Add stuffed eggplants and water.\n"
        "5. Cover and cook until tender.",
        [("eggplant", "4 small"), ("peanuts", "2 tbsp"), ("coconut", "2 tbsp"),
         ("sesame_seeds", "1 tbsp"), ("onion", "1"), ("garlic", "4 cloves"),
         ("ginger", "1 inch"), ("tamarind", "small ball"), ("red_chilli_powder", "1 tsp"),
         ("haldi", "1/2 tsp"), ("cooking_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    # ---------------- KARNATAKA ----------------
    (
        "Bisi Bele Bath", "karnataka", ["lunch", "dinner"], "vegetarian", 15, 30, 45,
        "medium", 4, 76, "balanced",
        "Hot-spicy rice and lentil dish from Karnataka.",
        ["karnataka", "rice", "comfort", "one_pot"],
        "1. Cook rice and toor dal with haldi.\n"
        "2. Grind roasted coconut, chillies and spices.\n"
        "3. Temper mustard seeds, curry leaves and peanuts.\n"
        "4. Add tamarind pulp, jaggery and the ground paste.\n"
        "5. Mix in the rice-dal, simmer until thick.",
        [("rice", "1 cup"), ("toor_dal", "1/2 cup"), ("coconut", "1/4 cup"),
         ("tamarind", "small ball"), ("jaggery", "1 tbsp"), ("peanuts", "2 tbsp"),
         ("mustard_seeds", "1 tsp"), ("curry_leaves", "8-10"), ("haldi", "1/2 tsp"),
         ("red_chilli_powder", "1 tsp"), ("garam_masala", "1/2 tsp"),
         ("cooking_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    (
        "Rava Idli", "karnataka", ["breakfast"], "vegetarian", 15, 15, 30,
        "easy", 4, 82, "balanced",
        "Steamed semolina idlis with tempering, served with chutney.",
        ["karnataka", "breakfast", "steamed", "healthy"],
        "1. Roast suji in ghee, add curd and water.\n"
        "2. Temper mustard seeds, curry leaves, ginger and chilli.\n"
        "3. Mix tempering and cashews into the batter.\n"
        "4. Rest for 15 minutes, pour into idli moulds.\n"
        "5. Steam for 12 minutes and serve.",
        [("suji", "1.5 cups"), ("curd", "1/2 cup"), ("mustard_seeds", "1 tsp"),
         ("curry_leaves", "8-10"), ("ginger", "1 inch"), ("green_chilli", "1"),
         ("cashews", "1 tbsp"), ("ghee", "1 tbsp"), ("cooking_oil", "1 tsp"),
         ("salt", "to taste")],
    ),
    # ---------------- ASSAMESE ----------------
    (
        "Aloo Pitika", "assamese", ["lunch", "dinner"], "vegetarian", 10, 20, 30,
        "easy", 4, 78, "balanced",
        "Mashed potatoes with mustard oil, onion and green chilli.",
        ["assamese", "potato", "quick", "comfort"],
        "1. Boil and peel potatoes.\n"
        "2. Mash with salt, green chilli, onion and dhaniya.\n"
        "3. Drizzle mustard oil over the mash.\n"
        "4. Mix well and adjust seasoning.\n"
        "5. Serve with steamed rice.",
        [("potato", "3 medium"), ("mustard_oil", "1 tbsp"), ("onion", "1"),
         ("green_chilli", "1-2"), ("dhaniya", "handful"), ("salt", "to taste")],
    ),
    (
        "Masor Tenga", "assamese", ["lunch", "dinner"], "non_vegetarian", 15, 25, 40,
        "medium", 4, 72, "balanced",
        "Tangy Assamese fish curry with tomato and lemon.",
        ["assamese", "fish", "tangy", "non_veg"],
        "1. Marinate fish with haldi and salt.\n"
        "2. Temper mustard seeds in mustard oil.\n"
        "3. Add tomato, green chilli and garlic.\n"
        "4. Add water and lemon, simmer for 5 minutes.\n"
        "5. Slide in fish and cook gently for 8 minutes.",
        [("fish", "500g"), ("tomato", "2"), ("mustard_oil", "2 tbsp"),
         ("mustard_seeds", "1 tsp"), ("garlic", "4 cloves"), ("green_chilli", "2"),
         ("lemon", "1"), ("haldi", "1/2 tsp"), ("salt", "to taste")],
    ),
    # ---------------- NEPALI ----------------
    (
        "Veg Momo", "nepali", ["snacks", "dinner"], "vegetarian", 30, 20, 50,
        "hard", 4, 68, "moderate",
        "Steamed dumplings stuffed with cabbage-carrot, with soy dipping.",
        ["nepali", "momo", "snack", "dumpling"],
        "1. Knead maida with water into a soft dough.\n"
        "2. Sauté cabbage, carrot, onion, garlic and ginger.\n"
        "3. Season with soy sauce and salt, cool the filling.\n"
        "4. Roll dough into circles, fill and pleat.\n"
        "5. Steam momos for 12 minutes, serve with soy-chilli dip.",
        [("maida", "2 cups"), ("cabbage", "1.5 cups"), ("carrot", "1"),
         ("onion", "1"), ("garlic", "4 cloves"), ("ginger", "1 inch"),
         ("green_chilli", "1"), ("soy_sauce", "2 tbsp"), ("cooking_oil", "2 tbsp"),
         ("salt", "to taste")],
    ),
    (
        "Aloo Dum", "nepali", ["lunch", "dinner"], "vegetarian", 15, 30, 45,
        "medium", 4, 70, "moderate",
        "Spicy Nepali potato curry with tomato-garlic gravy.",
        ["nepali", "potato", "spicy", "gravy"],
        "1. Boil potatoes and lightly fry until golden.\n"
        "2. Grind tomato, garlic, ginger and chillies.\n"
        "3. Temper jeera in oil, add the paste.\n"
        "4. Add haldi, red chilli powder and water.\n"
        "5. Add potatoes and simmer until thick.",
        [("potato", "4 medium"), ("tomato", "2"), ("garlic", "4 cloves"),
         ("ginger", "1 inch"), ("green_chilli", "2"), ("jeera", "1 tsp"),
         ("haldi", "1/2 tsp"), ("red_chilli_powder", "1 tsp"), ("cooking_oil", "2 tbsp"),
         ("salt", "to taste")],
    ),
    # ---------------- SINDHI ----------------
    (
        "Sindhi Kadhi", "sindhi", ["lunch", "dinner"], "vegetarian", 20, 30, 50,
        "medium", 4, 74, "balanced",
        "Tangy besan-yogurt kadhi with vegetables, a Sindhi favourite.",
        ["sindhi", "kadhi", "comfort", "tangy"],
        "1. Whisk besan with curd and water.\n"
        "2. Temper mustard seeds, curry leaves and methi.\n"
        "3. Add ginger, green chilli and mixed vegetables.\n"
        "4. Pour in the besan mix, add tamarind and jaggery.\n"
        "5. Simmer until vegetables are tender and thick.",
        [("besan", "1/2 cup"), ("curd", "1 cup"), ("lauki", "1 cup"),
         ("potato", "1"), ("okra", "8-10"), ("tamarind", "small ball"),
         ("jaggery", "1 tbsp"), ("mustard_seeds", "1 tsp"), ("curry_leaves", "8-10"),
         ("ginger", "1 inch"), ("green_chilli", "1-2"), ("cooking_oil", "2 tbsp"),
         ("salt", "to taste")],
    ),
    # ---------------- PARSI ----------------
    (
        "Parsi Dhansak", "parsi", ["lunch", "dinner"], "vegetarian", 20, 50, 70,
        "hard", 4, 74, "balanced",
        "Parsi-style lentils and vegetables served with caramelised rice.",
        ["parsi", "dal", "comfort", "traditional"],
        "1. Soak toor, moong and masoor dal.\n"
        "2. Pressure cook dal with lauki, spinach, potato and spices.\n"
        "3. Temper curry leaves, mustard seeds and ginger.\n"
        "4. Add tamarind pulp, jaggery and garam masala.\n"
        "5. Simmer and serve with plain rice.",
        [("toor_dal", "1/2 cup"), ("moong_dal", "1/2 cup"), ("masoor_dal", "1/2 cup"),
         ("lauki", "1 cup"), ("spinach", "1 cup"), ("potato", "1"),
         ("tamarind", "small ball"), ("jaggery", "1 tbsp"), ("curry_leaves", "8-10"),
         ("mustard_seeds", "1 tsp"), ("ginger", "1 inch"), ("garam_masala", "1/2 tsp"),
         ("cooking_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    # ---------------- HYDERABADI ----------------
    (
        "Hyderabadi Chicken Biryani", "hyderabadi", ["lunch", "dinner"], "non_vegetarian", 30, 60, 90,
        "hard", 4, 60, "indulgent",
        "Spicy layered chicken biryani with saffron and fried onions.",
        ["hyderabadi", "biryani", "chicken", "spicy", "non_veg", "dinner"],
        "1. Marinate chicken with curd, ginger, garlic and biryani spices.\n"
        "2. Par-boil rice with whole spices and bay leaf.\n"
        "3. Layer marinated chicken and rice in a heavy pot.\n"
        "4. Add fried onions, pudina, dhaniya and saffron milk.\n"
        "5. Cook on dum for 30 minutes.",
        [("chicken", "500g"), ("rice", "2 cups"), ("curd", "1/2 cup"),
         ("onion", "2"), ("ginger", "1 inch"), ("garlic", "6 cloves"),
         ("pudina", "handful"), ("dhaniya", "handful"), ("cardamom", "4"),
         ("cloves", "4"), ("cinnamon", "1 inch"), ("bay_leaf", "2"),
         ("red_chilli_powder", "1 tsp"), ("garam_masala", "1 tsp"), ("lemon", "1"),
         ("ghee", "3 tbsp"), ("cooking_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    (
        "Bagara Baingan", "hyderabadi", ["lunch", "dinner"], "vegetarian", 20, 30, 50,
        "hard", 4, 64, "moderate",
        "Hyderabadi stuffed eggplant in a sesame-peanut-tamarind gravy.",
        ["hyderabadi", "eggplant", "spicy", "rich"],
        "1. Slit eggplants, stuff with peanut-sesame-coconut mix.\n"
        "2. Grind onion, garlic, ginger, tamarind and spices.\n"
        "3. Fry the stuffed eggplants in oil.\n"
        "4. Add the ground gravy and simmer.\n"
        "5. Cook until oil separates, serve with rice.",
        [("eggplant", "4 small"), ("peanuts", "2 tbsp"), ("sesame_seeds", "1 tbsp"),
         ("coconut", "2 tbsp"), ("onion", "1"), ("garlic", "4 cloves"),
         ("ginger", "1 inch"), ("tamarind", "small ball"), ("red_chilli_powder", "1 tsp"),
         ("haldi", "1/2 tsp"), ("cooking_oil", "3 tbsp"), ("salt", "to taste")],
    ),
    # ---------------- MUGHLAI ----------------
    (
        "Malai Kofta", "muglai", ["lunch", "dinner"], "vegetarian", 25, 30, 55,
        "hard", 4, 58, "indulgent",
        "Paneer-potato koftas in a rich creamy Mughlai gravy.",
        ["muglai", "rich", "paneer", "royal", "dinner"],
        "1. Mash paneer and potato, season, shape into balls.\n"
        "2. Deep-fry koftas until golden.\n"
        "3. Cook onion, tomato, ginger and garlic into a gravy.\n"
        "4. Blend with cashews and cream, simmer.\n"
        "5. Add koftas just before serving.",
        [("paneer", "250g"), ("potato", "1"), ("cream", "1/2 cup"),
         ("cashews", "1/4 cup"), ("onion", "1"), ("tomato", "3"), ("ginger", "1 inch"),
         ("garlic", "4 cloves"), ("butter", "2 tbsp"), ("cardamom", "3"),
         ("garam_masala", "1/2 tsp"), ("red_chilli_powder", "1/2 tsp"),
         ("cooking_oil", "for frying"), ("salt", "to taste")],
    ),
]


def main():
    db = SessionLocal()
    try:
        for name, (disp_en, disp_hi, cat, storage) in NEW_INGREDIENTS.items():
            if not db.query(Ingredient).filter(Ingredient.name == name).first():
                db.add(Ingredient(
                    name=name, display_name_en=disp_en, display_name_hi=disp_hi,
                    category=cat, storage_type=storage, is_common=True,
                ))
        db.commit()

        for slug, disp in NEW_CUISINES.items():
            if not db.query(Cuisine).filter(Cuisine.name == slug).first():
                db.add(Cuisine(name=slug, display_name_en=disp, region="India", sort_order=20))
        db.commit()
        print("Ingredients + cuisines synced.")

        ingredient_map = {i.name: i for i in db.query(Ingredient).all()}
        cuisine_map = {c.name: c for c in db.query(Cuisine).all()}

        added = 0
        for (name, cuisine, meal_types, diet, prep, cook, total, difficulty,
             servings, hscore, hcat, desc, tags, instructions, ings) in RECIPES:
            if db.query(Recipe).filter(Recipe.name == name).first():
                print(f"skip (exists): {name}")
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
    finally:
        db.close()


if __name__ == "__main__":
    main()
