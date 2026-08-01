"""Seed recipes for the remaining empty cuisines: Odia, Jharkhandi, Uttarakhandi, Manipuri, Naga."""
import sys
from app.core.database import SessionLocal
from app.models.recipe import Cuisine, Recipe, RecipeIngredient
from app.models.ingredient import Ingredient

# (name, cuisine, meal_types, diet, prep, cook, total, difficulty, servings, health_score,
#  health_category, desc, tags, instructions, [(ingredient_name, quantity)])
RECIPES = [
    # ---------------- ODIA ----------------
    (
        "Dalma", "odia", ["lunch", "dinner"], "vegetarian", 10, 30, 40,
        "easy", 4, 78, "balanced",
        "Odia dal cooked with vegetables, a staple of the Jagannath temple kitchen.",
        ["odia", "dal", "healthy", "one_pot"],
        "1. Pressure cook toor dal with turmeric until soft.\n"
        "2. Cook potato, pumpkin, papaya and beans in a little water.\n"
        "3. Add the cooked dal and mash lightly together.\n"
        "4. Temper with jeera, dry red chilli and curry leaves in ghee.\n"
        "5. Pour tempering over the dalma and serve with rice.",
        [("toor_dal", "1 cup"), ("potato", "1"), ("pumpkin", "200g"),
         ("beans", "100g"), ("haldi", "1/2 tsp"), ("jeera", "1 tsp"),
         ("dry_red_chilli", "2"), ("curry_leaves", "1 sprig"), ("ghee", "2 tbsp"),
         ("salt", "to taste")],
    ),
    (
        "Chingudi Jhola", "odia", ["lunch", "dinner"], "non_vegetarian", 15, 25, 40,
        "medium", 4, 66, "moderate",
        "Odia prawn curry in a light mustard-turmeric gravy.",
        ["odia", "seafood", "spicy", "curry"],
        "1. Marinate prawns with haldi and salt for 10 minutes.\n"
        "2. Grind mustard seeds, saunf and green chilli into a paste.\n"
        "3. Cook onion and tomato, add the mustard paste.\n"
        "4. Add prawns and simmer until just cooked.\n"
        "5. Finish with mustard oil and serve with rice.",
        [("fish", "300g"), ("onion", "1"), ("tomato", "2"), ("mustard_seeds", "1 tbsp"),
         ("saunf", "1 tsp"), ("green_chilli", "2"), ("haldi", "1/2 tsp"),
         ("mustard_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    (
        "Pakhaala", "odia", ["lunch"], "vegetarian", 5, 15, 20,
        "easy", 4, 72, "balanced",
        "Fermented rice and water served with bhaja, a cooling Odia summer meal.",
        ["odia", "rice", "healthy", "simple"],
        "1. Wash rice and cook with extra water.\n"
        "2. Cool and let it ferment overnight.\n"
        "3. Temper with jeera, dry red chilli and curry leaves.\n"
        "4. Serve the fermented rice water with fried vegetables.",
        [("rice", "2 cups"), ("curd", "1/2 cup"), ("jeera", "1/2 tsp"),
         ("dry_red_chilli", "1"), ("curry_leaves", "1 sprig"), ("ghee", "1 tbsp"),
         ("salt", "to taste")],
    ),
    # ---------------- JHARKHANDI ----------------
    (
        "Thekua", "jharkhandi", ["breakfast"], "vegetarian", 15, 20, 35,
        "medium", 4, 55, "indulgent",
        "Crisp wheat and jaggery discs, a Jharkhand festive snack.",
        ["jharkhandi", "sweet", "snack", "festive"],
        "1. Melt jaggery with a little water.\n"
        "2. Mix in atta and carom seeds to form a stiff dough.\n"
        "3. Shape into small discs.\n"
        "4. Deep-fry until golden and crisp.\n"
        "5. Cool and store in an airtight jar.",
        [("atta", "2 cups"), ("jaggery", "3/4 cup"), ("ghee", "2 tbsp"),
         ("sesame_seeds", "2 tbsp"), ("cardamom", "3"), ("cooking_oil", "for frying")],
    ),
    (
        "Dhuska", "jharkhandi", ["breakfast", "dinner"], "vegetarian", 10, 20, 30,
        "easy", 4, 68, "moderate",
        "Soft rice-besan dumplings from Jharkhand, served with chana.",
        ["jharkhandi", "breakfast", "rice"],
        "1. Soak rice and grind to a thick paste.\n"
        "2. Mix in besan, jeera and green chilli.\n"
        "3. Add water to make a thick batter.\n"
        "4. Deep-fry spoonfuls until golden.\n"
        "5. Serve with aloo chokha or chana.",
        [("rice", "1 cup"), ("besan", "1/2 cup"), ("jeera", "1/2 tsp"),
         ("green_chilli", "1"), ("cooking_oil", "for frying"), ("salt", "to taste")],
    ),
    # ---------------- UTTARAKHANDI ----------------
    (
        "Gahat ki Dal", "uttarakhandi", ["lunch", "dinner"], "vegetarian", 10, 30, 40,
        "medium", 4, 74, "balanced",
        "Himalayan horse-gram dal cooked the Pahadi way.",
        ["uttarakhandi", "dal", "healthy", "winter"],
        "1. Pressure cook gahat (horse gram) with salt until soft.\n"
        "2. Temper with mustard seeds, jeera, hing and dry red chilli in ghee.\n"
        "3. Add garlic and fry until golden.\n"
        "4. Add the dal and simmer for 10 minutes.\n"
        "5. Serve hot with rice or roti.",
        [("chana_dal", "1 cup"), ("mustard_seeds", "1/2 tsp"), ("jeera", "1/2 tsp"),
         ("hing", "1/4 tsp"), ("dry_red_chilli", "2"), ("garlic", "4 cloves"),
         ("ghee", "2 tbsp"), ("haldi", "1/2 tsp"), ("salt", "to taste")],
    ),
    (
        "Phanu", "uttarakhandi", ["lunch", "dinner"], "vegetarian", 15, 35, 50,
        "medium", 4, 76, "balanced",
        "Uttarakhand lentil soup with gram-flour pakoras, the Kumaoni comfort food.",
        ["uttarakhandi", "soup", "healthy", "winter"],
        "1. Boil arhar dal with ginger and haldi.\n"
        "2. Make a stiff besan batter, shape into small pakoras.\n"
        "3. Drop pakoras into the boiling dal.\n"
        "4. Temper with jeera, hing, dry red chilli and green chilli in ghee.\n"
        "5. Simmer and serve hot.",
        [("toor_dal", "1 cup"), ("besan", "1/2 cup"), ("ginger", "1 inch"),
         ("haldi", "1/2 tsp"), ("jeera", "1/2 tsp"), ("hing", "1/4 tsp"),
         ("dry_red_chilli", "2"), ("green_chilli", "1"), ("ghee", "2 tbsp"),
         ("salt", "to taste")],
    ),
    # ---------------- MANIPURI ----------------
    (
        "Eromba", "manipuri", ["lunch", "dinner"], "vegetarian", 15, 25, 40,
        "medium", 4, 70, "balanced",
        "Manipuri mashed vegetables with fermented fish and chilli.",
        ["manipuri", "spicy", "healthy"],
        "1. Boil vegetables (beans, potato, pumpkin) until soft.\n"
        "2. Mash them roughly with salt.\n"
        "3. Roast and crush dry red chillies.\n"
        "4. Mix the crushed chillies into the mash.\n"
        "5. Serve with rice and fresh herbs.",
        [("beans", "150g"), ("potato", "1"), ("dry_red_chilli", "3"),
         ("dhaniya", "handful"), ("salt", "to taste")],
    ),
    (
        "Ooti", "manipuri", ["lunch", "dinner"], "vegetarian", 15, 35, 50,
        "medium", 4, 72, "balanced",
        "Manipuri pea-paneer curry, a festive wedding dish.",
        ["manipuri", "curry", "festive"],
        "1. Soak and pressure cook peas until soft.\n"
        "2. Mash half the peas, leave the rest whole.\n"
        "3. Add cubed paneer and simmer.\n"
        "4. Season with salt, green chilli and ginger.\n"
        "5. Finish with a tempering of mustard oil.",
        [("peas", "1.5 cups"), ("paneer", "200g"), ("ginger", "1 inch"),
         ("green_chilli", "2"), ("mustard_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    # ---------------- NAGA ----------------
    (
        "Naga Pork with Bamboo Shoot", "naga", ["lunch", "dinner"], "non_vegetarian", 20, 45, 65,
        "hard", 4, 60, "moderate",
        "Smoky Naga-style pork cooked with bamboo shoot and fiery bhoot jolokia.",
        ["naga", "pork", "spicy", "smoky"],
        "1. Cut pork into bite-size pieces.\n"
        "2. Cook pork in its own fat with ginger and garlic.\n"
        "3. Add bamboo shoot and cook until tender.\n"
        "4. Season with chilli and salt, no masala needed.\n"
        "5. Finish with spring onion and serve with steamed rice.",
        [("chicken", "500g"), ("ginger", "2 inch"), ("garlic", "6 cloves"),
         ("dry_red_chilli", "4"), ("onion", "1"), ("cooking_oil", "2 tbsp"),
         ("salt", "to taste")],
    ),
    (
        "Khar", "naga", ["lunch"], "vegetarian", 10, 25, 35,
        "easy", 4, 74, "balanced",
        "Alkaline Naga vegetable stew made with mustard-alkali water.",
        ["naga", "healthy", "stew", "simple"],
        "1. Boil mustard-alkali water (khar) until frothy.\n"
        "2. Add vegetables and simmer until soft.\n"
        "3. Season with salt only.\n"
        "4. Serve with steamed sticky rice.",
        [("pumpkin", "200g"), ("beans", "100g"), ("mustard_seeds", "1 tsp"),
         ("green_chilli", "2"), ("salt", "to taste")],
    ),
]


def main():
    db = SessionLocal()
    try:
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
