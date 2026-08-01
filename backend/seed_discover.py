"""Seed recipes so every Discover cuisine + filter returns data."""
import sys
from app.core.database import SessionLocal
from app.models.recipe import Cuisine, Recipe, RecipeIngredient, DietType, DifficultyLevel, HealthCategory
from app.models.ingredient import Ingredient, IngredientCategoryType, IngredientStorageType

NEW_INGREDIENTS = {
    "chicken": ("Chicken", "Murgh", IngredientCategoryType.MEAT, IngredientStorageType.FRESH),
    "fish": ("Fish", "Machhli", IngredientCategoryType.MEAT, IngredientStorageType.FRESH),
    "soy_sauce": ("Soy Sauce", "Soya Sauce", IngredientCategoryType.CONDIMENT, IngredientStorageType.PANTRY),
    "khus_khus": ("Poppy Seeds", "Khus Khus", IngredientCategoryType.SPICE, IngredientStorageType.PANTRY),
    "curry_leaves": ("Curry Leaves", "Curry Patta", IngredientCategoryType.HERB, IngredientStorageType.FRESH),
    "tamarind": ("Tamarind", "Imli", IngredientCategoryType.CONDIMENT, IngredientStorageType.PANTRY),
    "cornflour": ("Cornflour", "Cornflour", IngredientCategoryType.GRAIN, IngredientStorageType.PANTRY),
    "pepper": ("Black Pepper", "Kali Mirch", IngredientCategoryType.SPICE, IngredientStorageType.PANTRY),
}

# (name, cuisine, meal_types, diet, prep, cook, total, difficulty, servings, health_score,
#  health_category, desc, tags, instructions, [(ingredient_name, quantity, unit)])
RECIPES = [
    # ---------------- BENGALI ----------------
    (
        "Cholar Dal", "bengali", ["lunch", "dinner"], "vegetarian", 10, 25, 35,
        "easy", 4, 78, "balanced",
        "Sweet-savoury Bengali chana dal simmered with coconut, raisins and ghee.",
        ["dal", "bengali", "sweet", "comfort", "healthy"],
        "1. Soak chana dal for 30 minutes, then pressure cook with haldi and salt until soft.\n"
        "2. Heat ghee, add jeera and grated ginger, cook for 30 seconds.\n"
        "3. Add green chilli, coconut and raisins, sauté for a minute.\n"
        "4. Stir in the cooked dal, add sugar and simmer for 5 minutes.\n"
        "5. Finish with garam masala and serve with luchi or rice.",
        [("chana_dal", "1 cup"), ("coconut", "2 tbsp"), ("raisins", "1 tbsp"),
         ("ghee", "2 tbsp"), ("ginger", "1 inch"), ("green_chilli", "1-2"),
         ("jeera", "1 tsp"), ("haldi", "1/2 tsp"), ("sugar", "1 tsp"),
         ("garam_masala", "1/2 tsp"), ("salt", "to taste")],
    ),
    (
        "Aloo Posto", "bengali", ["lunch", "dinner"], "vegetarian", 10, 20, 30,
        "easy", 4, 72, "balanced",
        "Bengali-style potatoes coated in a creamy poppy seed paste.",
        ["bengali", "aloo", "dry", "healthy"],
        "1. Soak khus khus in warm water, then grind into a fine paste.\n"
        "2. Heat oil, add mustard seeds and green chilli.\n"
        "3. Add cubed potatoes and stir-fry for 5 minutes.\n"
        "4. Mix in the poppy seed paste and haldi, cover and cook until potatoes are tender.\n"
        "5. Garnish with dhaniya and serve with rice.",
        [("potato", "3 medium"), ("khus_khus", "3 tbsp"), ("mustard_seeds", "1 tsp"),
         ("green_chilli", "1-2"), ("haldi", "1/2 tsp"), ("cooking_oil", "2 tbsp"),
         ("dhaniya", "handful"), ("salt", "to taste")],
    ),
    (
        "Doi Maach", "bengali", ["lunch", "dinner"], "non_vegetarian", 15, 25, 40,
        "medium", 4, 70, "balanced",
        "Bengali fish curry cooked in a tangy mustard-yogurt gravy.",
        ["fish", "bengali", "curry", "gravy", "non_veg"],
        "1. Marinate fish with haldi and salt for 10 minutes.\n"
        "2. Whisk curd with mustard seeds and haldi into a smooth marinade.\n"
        "3. Fry fish lightly in oil, set aside.\n"
        "4. In the same pan, sauté onion, ginger and garlic, add the curd mix.\n"
        "5. Add tomato and simmer, then slide the fish in and cook gently for 8 minutes.",
        [("fish", "500g"), ("curd", "1 cup"), ("onion", "1"), ("tomato", "1"),
         ("ginger", "1 inch"), ("garlic", "4 cloves"), ("mustard_seeds", "1 tsp"),
         ("haldi", "1/2 tsp"), ("red_chilli_powder", "1/2 tsp"), ("cooking_oil", "2 tbsp"),
         ("salt", "to taste")],
    ),
    # ---------------- GUJARATI ----------------
    (
        "Gujarati Kadhi", "gujarati", ["lunch", "dinner"], "vegetarian", 10, 25, 35,
        "easy", 4, 74, "balanced",
        "Sweet-sour yogurt curry with besan dumplings and curry leaves.",
        ["kadhi", "gujarati", "comfort", "sweet"],
        "1. Whisk curd with besan, haldi and 3 cups of water.\n"
        "2. Temper ghee with jeera, methi seeds and curry leaves.\n"
        "3. Pour in the yogurt mix, add ginger and green chilli.\n"
        "4. Simmer on low heat, stirring, for 20 minutes.\n"
        "5. Add sugar and salt, cook 2 more minutes and serve hot.",
        [("curd", "2 cups"), ("besan", "3 tbsp"), ("ginger", "1 inch"),
         ("green_chilli", "1-2"), ("sugar", "1 tbsp"), ("methi_seeds", "1/2 tsp"),
         ("jeera", "1 tsp"), ("curry_leaves", "8-10"), ("ghee", "1 tbsp"),
         ("haldi", "1/2 tsp"), ("salt", "to taste")],
    ),
    (
        "Methi Thepla", "gujarati", ["breakfast", "snacks"], "vegetarian", 15, 20, 35,
        "easy", 4, 76, "balanced",
        "Soft fenugreek flatbreads perfect for breakfast or travel.",
        ["flatbread", "gujarati", "breakfast", "kids"],
        "1. Mix atta, besan, methi seeds, haldi, jeera and salt.\n"
        "2. Add curd, ginger, green chilli and knead into a soft dough.\n"
        "3. Roll into thin circles.\n"
        "4. Cook on a hot griddle with oil until golden on both sides.",
        [("atta", "2 cups"), ("besan", "1/2 cup"), ("methi_seeds", "1 tsp"),
         ("curd", "1/2 cup"), ("ginger", "1 inch"), ("green_chilli", "1"),
         ("haldi", "1/2 tsp"), ("jeera", "1 tsp"), ("cooking_oil", "2 tbsp"),
         ("salt", "to taste")],
    ),
    (
        "Khaman Dhokla", "gujarati", ["breakfast", "snacks"], "vegetarian", 15, 20, 35,
        "medium", 4, 80, "balanced",
        "Steamed besan cakes with a sweet-tangy tempering.",
        ["gujarati", "snack", "healthy", "kids"],
        "1. Whisk besan with curd, water, haldi and salt into a smooth batter.\n"
        "2. Stir in sugar and lemon juice, rest for 10 minutes.\n"
        "3. Steam the batter in a greased tin for 15 minutes.\n"
        "4. Temper mustard seeds, curry leaves and green chilli in oil.\n"
        "5. Pour tempering over the steamed dhokla, cut and serve.",
        [("besan", "1.5 cups"), ("curd", "1/2 cup"), ("ginger", "1 inch"),
         ("green_chilli", "1-2"), ("haldi", "1/2 tsp"), ("mustard_seeds", "1 tsp"),
         ("sugar", "1 tbsp"), ("lemon", "1"), ("curry_leaves", "8-10"),
         ("cooking_oil", "1 tbsp"), ("salt", "to taste")],
    ),
    # ---------------- RAJASTHANI ----------------
    (
        "Dal Baati Churma", "rajasthani", ["dinner"], "vegetarian", 20, 60, 80,
        "hard", 4, 68, "indulgent",
        "Baked wheat baati served with spiced dal and sweet churma.",
        ["rajasthani", "comfort", "dal", "dinner"],
        "1. Knead atta with ghee and salt, shape into balls.\n"
        "2. Bake baatis in a preheated oven at 180C for 30 minutes.\n"
        "3. Meanwhile cook toor dal with onion, tomato, jeera and spices.\n"
        "4. For churma, crumble leftover baati, mix with ghee and jaggery.\n"
        "5. Serve baati with dal and churma.",
        [("atta", "3 cups"), ("ghee", "1/2 cup"), ("toor_dal", "1 cup"),
         ("onion", "1"), ("tomato", "1"), ("ginger", "1 inch"), ("garlic", "3 cloves"),
         ("jeera", "1 tsp"), ("haldi", "1 tsp"), ("red_chilli_powder", "1/2 tsp"),
         ("jaggery", "2 tbsp"), ("salt", "to taste")],
    ),
    (
        "Gatte ki Sabzi", "rajasthani", ["lunch", "dinner"], "vegetarian", 20, 30, 50,
        "medium", 4, 70, "balanced",
        "Besan dumplings simmered in a tangy yogurt gravy.",
        ["rajasthani", "curry", "comfort", "gravy"],
        "1. Knead besan with haldi, jeera, ghee and salt, roll into logs.\n"
        "2. Boil the logs for 10 minutes, slice into discs (gatte).\n"
        "3. Whisk curd with besan and spices.\n"
        "4. Sauté onion, tomato and ginger, pour in the curd mix.\n"
        "5. Add the gatte and simmer for 10 minutes.",
        [("besan", "2 cups"), ("curd", "1 cup"), ("tomato", "1"), ("onion", "1"),
         ("ginger", "1 inch"), ("haldi", "1/2 tsp"), ("red_chilli_powder", "1/2 tsp"),
         ("garam_masala", "1/2 tsp"), ("jeera", "1 tsp"), ("ghee", "1 tbsp"),
         ("salt", "to taste")],
    ),
    (
        "Missi Roti", "rajasthani", ["dinner"], "vegetarian", 10, 20, 30,
        "easy", 4, 74, "balanced",
        "Wholewheat-besan flatbread with onion and methi.",
        ["flatbread", "rajasthani", "dinner"],
        "1. Mix atta, besan, methi seeds, jeera, haldi and salt.\n"
        "2. Add chopped onion, green chilli and dhaniya.\n"
        "3. Knead with water into a firm dough.\n"
        "4. Roll and cook on a griddle with ghee until golden.",
        [("atta", "1.5 cups"), ("besan", "1 cup"), ("onion", "1"),
         ("green_chilli", "1"), ("methi_seeds", "1 tsp"), ("jeera", "1 tsp"),
         ("haldi", "1/2 tsp"), ("dhaniya", "handful"), ("ghee", "1 tbsp"),
         ("salt", "to taste")],
    ),
    # ---------------- INDO-CHINESE ----------------
    (
        "Veg Hakka Noodles", "indo_chinese", ["dinner", "snacks"], "vegetarian", 15, 15, 30,
        "easy", 4, 68, "moderate",
        "Stir-fried noodles tossed with crunchy vegetables and soy sauce.",
        ["indo_chinese", "noodles", "stir_fry", "kids"],
        "1. Boil noodles, drain and toss with a little oil.\n"
        "2. Stir-fry garlic and ginger in hot oil.\n"
        "3. Add cabbage, capsicum and carrot, stir-fry on high heat.\n"
        "4. Add soy sauce and salt, toss in the noodles.\n"
        "5. Cook for 2 minutes and serve hot.",
        [("noodles", "200g"), ("cabbage", "1 cup"), ("capsicum", "1"),
         ("carrot", "1"), ("onion", "1"), ("garlic", "4 cloves"), ("ginger", "1 inch"),
         ("soy_sauce", "2 tbsp"), ("cooking_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    (
        "Chilli Paneer", "indo_chinese", ["dinner", "snacks"], "vegetarian", 15, 20, 35,
        "medium", 4, 62, "moderate",
        "Crispy paneer cubes in a spicy soy-garlic sauce.",
        ["indo_chinese", "paneer", "spicy", "kids"],
        "1. Toss paneer cubes in cornflour and salt, shallow-fry until golden.\n"
        "2. Sauté garlic, ginger and green chilli.\n"
        "3. Add capsicum and onion, stir-fry for 2 minutes.\n"
        "4. Mix soy sauce with cornflour and water, pour in.\n"
        "5. Add paneer and toss until glossy. Serve hot.",
        [("paneer", "250g"), ("capsicum", "1"), ("onion", "1"), ("garlic", "5 cloves"),
         ("ginger", "1 inch"), ("green_chilli", "2"), ("soy_sauce", "2 tbsp"),
         ("cornflour", "2 tbsp"), ("cooking_oil", "3 tbsp"), ("salt", "to taste")],
    ),
    (
        "Veg Manchurian", "indo_chinese", ["dinner", "snacks"], "vegetarian", 20, 20, 40,
        "medium", 4, 60, "moderate",
        "Crisp vegetable dumplings in a garlicky soy-gravy.",
        ["indo_chinese", "starter", "kids"],
        "1. Grate cabbage, carrot and capsicum, squeeze out water.\n"
        "2. Mix with cornflour, maida, salt and form small balls.\n"
        "3. Deep-fry the balls until golden and crisp.\n"
        "4. Sauté garlic, ginger, onion and green chilli in a pan.\n"
        "5. Add soy sauce, cornflour slurry and the fried balls, toss well.",
        [("cabbage", "2 cups"), ("carrot", "1"), ("capsicum", "1"), ("onion", "1"),
         ("garlic", "5 cloves"), ("ginger", "1 inch"), ("green_chilli", "2"),
         ("soy_sauce", "2 tbsp"), ("maida", "3 tbsp"), ("cornflour", "3 tbsp"),
         ("cooking_oil", "3 tbsp"), ("salt", "to taste")],
    ),
    # ---------------- CONTINENTAL ----------------
    (
        "Creamy Mushroom Pasta", "continental", ["lunch", "dinner"], "vegetarian", 10, 20, 30,
        "easy", 2, 66, "moderate",
        "Pasta in a rich garlic-mushroom cream sauce.",
        ["continental", "pasta", "creamy", "kids"],
        "1. Boil pasta, drain and set aside.\n"
        "2. Melt butter, sauté garlic and onion.\n"
        "3. Add sliced mushrooms, cook until browned.\n"
        "4. Pour in cream, season with pepper and salt.\n"
        "5. Toss pasta in the sauce, garnish with cheese.",
        [("pasta", "200g"), ("mushroom", "200g"), ("cream", "1/2 cup"),
         ("cheese", "1/4 cup"), ("garlic", "3 cloves"), ("butter", "2 tbsp"),
         ("onion", "1"), ("pepper", "1/2 tsp"), ("salt", "to taste")],
    ),
    (
        "Masala Mac & Cheese", "continental", ["lunch", "dinner"], "vegetarian", 10, 25, 35,
        "easy", 4, 64, "indulgent",
        "Indian-spiced macaroni and cheese with a buttery crust.",
        ["continental", "pasta", "kids", "comfort"],
        "1. Cook macaroni, drain.\n"
        "2. Melt butter, add milk, haldi and red chilli powder.\n"
        "3. Stir in cheese until melted, season with salt.\n"
        "4. Mix in the pasta and pour into a baking dish.\n"
        "5. Top with breadcrumbs and bake at 180C for 10 minutes.",
        [("pasta", "250g"), ("cheese", "1 cup"), ("milk", "1.5 cups"),
         ("butter", "3 tbsp"), ("bread", "2 slices"), ("haldi", "1/2 tsp"),
         ("red_chilli_powder", "1/2 tsp"), ("salt", "to taste")],
    ),
    # ---------------- SOUTH INDIAN ----------------
    (
        "Upma", "south_indian", ["breakfast"], "vegetarian", 5, 15, 20,
        "easy", 4, 80, "balanced",
        "Fluffy semolina porridge tempered with curry leaves and nuts.",
        ["south_indian", "breakfast", "quick", "healthy"],
        "1. Roast suji in ghee until fragrant, set aside.\n"
        "2. Temper mustard seeds, curry leaves, ginger and green chilli.\n"
        "3. Add onion, carrot and peas, sauté for 2 minutes.\n"
        "4. Add 2 cups of water and salt, bring to a boil.\n"
        "5. Pour in suji slowly, stirring, cook until thick. Finish with lemon.",
        [("suji", "1 cup"), ("mustard_seeds", "1 tsp"), ("curry_leaves", "8-10"),
         ("onion", "1"), ("green_chilli", "1-2"), ("ginger", "1 inch"),
         ("carrot", "1/2"), ("peas", "1/4 cup"), ("lemon", "1/2"), ("ghee", "2 tbsp"),
         ("cooking_oil", "1 tbsp"), ("salt", "to taste")],
    ),
    (
        "Idli Sambar", "south_indian", ["breakfast", "lunch"], "vegetarian", 30, 45, 75,
        "hard", 4, 82, "balanced",
        "Steamed rice idlis with a tangy lentil-vegetable sambar.",
        ["south_indian", "breakfast", "comfort", "protein"],
        "1. Soak rice and urad dal, grind to a batter and ferment overnight.\n"
        "2. Steam the batter in idli moulds for 12 minutes.\n"
        "3. Cook toor dal with haldi until soft, mash.\n"
        "4. Temper mustard seeds, curry leaves and methi, add onion and tomato.\n"
        "5. Add tamarind water and the dal, simmer; serve with idlis.",
        [("rice", "1.5 cups"), ("urad_dal", "1/2 cup"), ("toor_dal", "1/2 cup"),
         ("tamarind", "small ball"), ("onion", "1"), ("tomato", "1"),
         ("curry_leaves", "8-10"), ("mustard_seeds", "1 tsp"), ("methi_seeds", "1/2 tsp"),
         ("haldi", "1/2 tsp"), ("red_chilli_powder", "1/2 tsp"), ("cooking_oil", "1 tbsp"),
         ("salt", "to taste")],
    ),
    # ---------------- PUNJABI ----------------
    (
        "Rajma Chawal", "punjabi", ["lunch", "dinner"], "vegetarian", 15, 45, 60,
        "medium", 4, 78, "balanced",
        "Creamy kidney bean curry served with steamed rice.",
        ["punjabi", "rajma", "comfort", "dinner"],
        "1. Pressure cook soaked rajma with salt until soft.\n"
        "2. Sauté onion, ginger and garlic in ghee.\n"
        "3. Add tomato, jeera, haldi, red chilli powder and garam masala.\n"
        "4. Stir in the rajma, mash a few beans to thicken.\n"
        "5. Simmer 15 minutes, garnish with dhaniya, serve with rice.",
        [("rajma", "1.5 cups"), ("rice", "2 cups"), ("onion", "1"), ("tomato", "2"),
         ("ginger", "1 inch"), ("garlic", "4 cloves"), ("jeera", "1 tsp"),
         ("haldi", "1/2 tsp"), ("red_chilli_powder", "1/2 tsp"),
         ("garam_masala", "1/2 tsp"), ("ghee", "2 tbsp"), ("dhaniya", "handful"),
         ("salt", "to taste")],
    ),
    # ---------------- NON-VEG ----------------
    (
        "Butter Chicken", "punjabi", ["lunch", "dinner"], "non_vegetarian", 20, 35, 55,
        "medium", 4, 60, "indulgent",
        "Tender chicken in a silky tomato-butter gravy.",
        ["chicken", "punjabi", "rich", "dinner", "non_veg"],
        "1. Marinate chicken in curd, haldi and spices for 30 minutes.\n"
        "2. Grill or pan-cook the chicken until charred.\n"
        "3. Sauté onion, garlic and ginger, add tomato and cook down.\n"
        "4. Blend into a smooth puree, add butter and cream.\n"
        "5. Add the chicken and simmer 10 minutes, finish with garam masala.",
        [("chicken", "500g"), ("tomato", "4"), ("onion", "1"), ("garlic", "4 cloves"),
         ("ginger", "1 inch"), ("curd", "1/2 cup"), ("cream", "1/2 cup"),
         ("butter", "3 tbsp"), ("haldi", "1/2 tsp"), ("red_chilli_powder", "1 tsp"),
         ("garam_masala", "1 tsp"), ("salt", "to taste")],
    ),
    # ---------------- DESSERTS / SWEET ----------------
    (
        "Gajar Halwa", "punjabi", ["dessert"], "vegetarian", 15, 45, 60,
        "medium", 4, 66, "indulgent",
        "Slow-cooked carrot pudding with ghee, nuts and raisins.",
        ["sweet", "dessert", "carrot", "comfort"],
        "1. Grate carrots and cook in ghee until soft.\n"
        "2. Add milk and simmer until absorbed.\n"
        "3. Stir in sugar and cook for 10 minutes.\n"
        "4. Add cashews, almonds and raisins.\n"
        "5. Cook until glossy, serve warm.",
        [("carrot", "4 medium"), ("milk", "2 cups"), ("ghee", "3 tbsp"),
         ("sugar", "3/4 cup"), ("cashews", "2 tbsp"), ("almonds", "2 tbsp"),
         ("raisins", "1 tbsp")],
    ),
    (
        "Rice Kheer", "north_indian", ["dessert"], "vegetarian", 5, 40, 45,
        "easy", 4, 72, "indulgent",
        "Creamy rice pudding with saffron-infused milk and nuts.",
        ["sweet", "dessert", "kheer", "comfort"],
        "1. Wash and soak rice for 20 minutes.\n"
        "2. Simmer rice in milk until soft and the milk thickens.\n"
        "3. Add sugar and cook for 5 minutes.\n"
        "4. Stir in almonds and raisins.\n"
        "5. Chill or serve warm.",
        [("rice", "1/2 cup"), ("milk", "1 liter"), ("sugar", "1/2 cup"),
         ("almonds", "2 tbsp"), ("raisins", "1 tbsp"), ("ghee", "1 tbsp")],
    ),
    (
        "Suji Halwa", "north_indian", ["breakfast", "dessert"], "vegetarian", 5, 15, 20,
        "easy", 4, 70, "indulgent",
        "Semolina pudding tempered with ghee, cashews and raisins.",
        ["sweet", "dessert", "halwa", "quick"],
        "1. Roast suji in ghee until lightly golden.\n"
        "2. Add cashews and raisins, roast briefly.\n"
        "3. Pour in hot water slowly, stirring continuously.\n"
        "4. Add sugar and cook until the halwa leaves the pan.\n"
        "5. Serve hot.",
        [("suji", "1 cup"), ("ghee", "1/2 cup"), ("sugar", "3/4 cup"),
         ("cashews", "2 tbsp"), ("raisins", "1 tbsp")],
    ),
]

EXISTING_KIDS_TAGS = {
    "Poha": ["kids"],
    "Aloo Paratha": ["kids"],
    "Dosa with Chutney": ["kids"],
    "Paneer Bhurji": ["kids"],
    "Veg Pulao": ["kids"],
}


def main(db=None):
    own_session = False
    if db is None:
        db = SessionLocal()
        own_session = True
    try:
        for name, (disp_en, disp_hi, cat, storage) in NEW_INGREDIENTS.items():
            if not db.query(Ingredient).filter(Ingredient.name == name).first():
                db.add(Ingredient(
                    name=name, display_name_en=disp_en, display_name_hi=disp_hi,
                    category=cat, storage_type=storage, is_common=True,
                ))
        db.commit()
        print("Ingredients synced.")

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

        for rname, extra in EXISTING_KIDS_TAGS.items():
            r = db.query(Recipe).filter(Recipe.name == rname).first()
            if r:
                current = r.tags or []
                merged = list(dict.fromkeys(current + extra))
                if merged != current:
                    r.tags = merged
                    print(f"tags updated: {rname} -> {merged}")

        db.commit()
        print(f"\nDone. {added} new recipes added.")
    finally:
        if own_session:
            db.close()


def seed_all(db):
    """Seed the database with ingredients and recipes. Can be called from API."""
    try:
        main(db)
        return "success"
    except Exception as e:
        return f"error: {e}"


if __name__ == "__main__":
    main()
