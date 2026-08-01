"""Seed international cuisines (Italian, French, Thai, Chinese, Mexican, Japanese,
Mediterranean, Korean, Vietnamese) with at least 5 dishes each so every category
has a solid database set to pair with the app's hardcoded dishes. Also tops up the
Goan breakfast category to 5 database dishes.

Idempotent: skips recipes/ingredients that already exist.
"""
from app.core.database import SessionLocal
from app.models.recipe import Cuisine, Recipe, RecipeIngredient
from app.models.ingredient import Ingredient, IngredientCategoryType, IngredientStorageType

# (name, cuisine, meal_types, diet, prep, cook, total, difficulty, servings, health_score,
#  health_category, desc, tags, instructions, [(ingredient_name, quantity)])
RECIPES = [
    # ---------------- GOAN (breakfast top-up) ----------------
    (
        "Poee", "goan", ["breakfast"], "vegetarian", 30, 25, 55,
        "medium", 4, 60, "moderate",
        "Goa's signature soft, leavened bread, served with butter or curry.",
        ["goan", "breakfast", "bread"],
        "1. Make a dough from maida, toddy/yeast, and water.\n"
        "2. Rest until doubled in volume.\n"
        "3. Shape into round loaves and rest again.\n"
        "4. Bake in a hot oven or clay oven until puffed and golden.\n"
        "5. Serve warm with butter or with chutney.",
        [("maida", "3 cups"), ("yeast", "1 tsp"), ("sugar", "1 tbsp"),
         ("salt", "1 tsp"), ("ghee", "1 tbsp")],
    ),
    (
        "Patal Bhaji", "goan", ["breakfast"], "vegetarian", 15, 25, 40,
        "easy", 4, 72, "balanced",
        "Spicy, watery Goan vegetable curry, the classic partner for sanna and poi.",
        ["goan", "breakfast", "vegetable", "curry"],
        "1. Grind coconut, garlic, and red chilli into a masala paste.\n"
        "2. Boil mixed vegetables (potato, pumpkin, beans).\n"
        "3. Stir in the masala and simmer for 10 minutes.\n"
        "4. Add tamarind water and season with salt.\n"
        "5. Serve hot with sanna or poi.",
        [("potato", "2"), ("pumpkin", "200g"), ("beans", "100g"), ("coconut", "1 cup"),
         ("garlic", "4 cloves"), ("red_chilli_powder", "1 tsp"), ("tamarind", "small piece"),
         ("salt", "to taste")],
    ),
    (
        "Goan Sheera", "goan", ["breakfast"], "vegetarian", 10, 20, 30,
        "easy", 4, 58, "moderate",
        "Goan semolina pudding with ghee, cardamom and cashews.",
        ["goan", "breakfast", "sweet", "semolina"],
        "1. Roast semolina in ghee until fragrant.\n"
        "2. Boil water with sugar and cardamom.\n"
        "3. Pour the syrup into the semolina and stir.\n"
        "4. Add ghee-soaked cashews and mix well.\n"
        "5. Serve warm, optionally with a little coconut milk.",
        [("suji", "1 cup"), ("ghee", "4 tbsp"), ("sugar", "3/4 cup"),
         ("cardamom", "3"), ("cashews", "2 tbsp"), ("coconut_milk", "1/4 cup")],
    ),
    (
        "Goan Bread Omelette", "goan", ["breakfast"], "vegetarian_egg", 5, 10, 15,
        "easy", 2, 62, "moderate",
        "A street-style Goan breakfast of soft poee tucked inside a spicy omelette.",
        ["goan", "breakfast", "eggs", "street_food"],
        "1. Beat eggs with onion, green chilli and salt.\n"
        "2. Pour into a hot buttered pan and cook until just set.\n"
        "3. Slide the omelette onto a slice of poee or bread.\n"
        "4. Fold the bread over the omelette.\n"
        "5. Serve hot with a cup of chai.",
        [("egg", "2"), ("onion", "1/4"), ("green_chilli", "1"), ("bread", "2 slices"),
         ("butter", "1 tbsp"), ("dhaniya", "1 tbsp"), ("salt", "to taste")],
    ),
    # ---------------- ITALIAN ----------------
    (
        "Margherita Pizza", "italian", ["lunch", "dinner"], "vegetarian", 20, 25, 45,
        "medium", 2, 64, "moderate",
        "The classic Neapolitan pizza with tomato, mozzarella and fresh basil.",
        ["italian", "pizza", "cheese", "classic"],
        "1. Make the dough from maida, yeast, water and olive oil and rest for 1 hour.\n"
        "2. Roll out the dough into a thin round.\n"
        "3. Spread crushed tomato and torn mozzarella on top.\n"
        "4. Bake at 230C until the crust is blistered and golden.\n"
        "5. Finish with fresh basil leaves and a drizzle of olive oil.",
        [("maida", "2 cups"), ("yeast", "1 tsp"), ("tomato", "2"), ("mozzarella", "150g"),
         ("basil_leaf", "handful"), ("olive_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    (
        "Spaghetti Aglio e Olio", "italian", ["dinner"], "vegetarian", 10, 15, 25,
        "easy", 2, 72, "balanced",
        "Garlic, olive oil and chilli tossed through al dente spaghetti.",
        ["italian", "pasta", "quick", "simple"],
        "1. Boil spaghetti in salted water until al dente.\n"
        "2. Gently warm olive oil with sliced garlic and chilli flakes.\n"
        "3. Toss the drained pasta through the garlic oil.\n"
        "4. Finish with parsley and black pepper.\n"
        "5. Serve hot.",
        [("pasta", "200g"), ("garlic", "6 cloves"), ("olive_oil", "4 tbsp"),
         ("chili_flakes", "1 tsp"), ("parsley", "1 tbsp"), ("black_pepper", "1/2 tsp"),
         ("salt", "to taste")],
    ),
    (
        "Risotto alla Milanese", "italian", ["dinner"], "vegetarian", 15, 35, 50,
        "medium", 2, 60, "moderate",
        "Creamy saffron risotto, the golden heart of Milanese cuisine.",
        ["italian", "rice", "saffron", "creamy"],
        "1. Soften onion in butter until translucent.\n"
        "2. Add rice and toast for 2 minutes.\n"
        "3. Add warm broth ladle by ladle, stirring until absorbed.\n"
        "4. Dissolve saffron in a little broth and stir in.\n"
        "5. Finish with parmesan and butter, serve warm.",
        [("rice", "1 cup"), ("onion", "1"), ("butter", "3 tbsp"), ("saffron", "a pinch"),
         ("parmesan", "1/2 cup"), ("milk", "1 cup"), ("salt", "to taste")],
    ),
    (
        "Bruschetta", "italian", ["snacks"], "vegetarian", 15, 5, 20,
        "easy", 2, 70, "balanced",
        "Toasted bread topped with fresh tomato, basil and garlic.",
        ["italian", "snack", "quick", "fresh"],
        "1. Toast slices of bread until golden and rub with garlic.\n"
        "2. Chop tomato and toss with olive oil and basil.\n"
        "3. Season with salt and black pepper.\n"
        "4. Pile the tomato mixture onto the toast.\n"
        "5. Serve immediately.",
        [("bread", "4 slices"), ("tomato", "2"), ("garlic", "1 clove"), ("basil_leaf", "handful"),
         ("olive_oil", "2 tbsp"), ("black_pepper", "1/2 tsp"), ("salt", "to taste")],
    ),
    (
        "Tiramisu", "italian", ["dessert"], "vegetarian", 20, 0, 20,
        "easy", 4, 48, "indulgent",
        "Espresso-soaked layers of mascarpone cream dusted with cocoa.",
        ["italian", "dessert", "coffee", "no_bake"],
        "1. Whisk mascarpone with egg yolks and sugar until smooth.\n"
        "2. Whip egg whites and fold into the mascarpone.\n"
        "3. Dip bread slices quickly in brewed coffee.\n"
        "4. Layer coffee bread and mascarpone cream in a dish.\n"
        "5. Dust generously with cocoa and chill for 3 hours.",
        [("mascarpone", "250g"), ("coffee", "1 cup"), ("egg", "2"), ("sugar", "1/2 cup"),
         ("cocoa_powder", "2 tbsp"), ("bread", "6 slices")],
    ),
    # ---------------- FRENCH ----------------
    (
        "Butter Croissant", "french", ["breakfast"], "vegetarian", 30, 30, 60,
        "hard", 4, 52, "indulgent",
        "Flaky, buttery laminated pastry, a French breakfast icon.",
        ["french", "breakfast", "pastry", "butter"],
        "1. Make a yeasted dough and chill.\n"
        "2. Roll the dough around a block of cold butter, folding repeatedly.\n"
        "3. Chill between folds for flaky layers.\n"
        "4. Roll out, cut triangles and roll into crescents.\n"
        "5. Proof, brush with milk and bake until golden.",
        [("maida", "2 cups"), ("butter", "200g"), ("milk", "1/2 cup"), ("sugar", "1 tbsp"),
         ("yeast", "1 tsp"), ("salt", "1/2 tsp")],
    ),
    (
        "Ratatouille", "french", ["dinner"], "vegetarian", 20, 35, 55,
        "medium", 4, 74, "balanced",
        "Provençal stewed vegetables in olive oil and herbs.",
        ["french", "vegetable", "healthy", "stew"],
        "1. Slice eggplant, zucchini and bell pepper.\n"
        "2. Soften onion and garlic in olive oil.\n"
        "3. Add the vegetables and tomato.\n"
        "4. Season with thyme and simmer slowly.\n"
        "5. Serve warm with crusty bread.",
        [("eggplant", "1"), ("zucchini", "1"), ("bell_pepper", "1"), ("tomato", "3"),
         ("onion", "1"), ("garlic", "3 cloves"), ("olive_oil", "3 tbsp"), ("thyme", "1 tsp"),
         ("salt", "to taste")],
    ),
    (
        "French Onion Soup", "french", ["dinner"], "vegetarian", 15, 40, 55,
        "medium", 2, 62, "moderate",
        "Deeply caramelised onions in a rich broth, topped with melted cheese.",
        ["french", "soup", "winter", "comfort"],
        "1. Slowly caramelise onions in butter for 20 minutes.\n"
        "2. Add a splash of water and season with thyme.\n"
        "3. Simmer for 15 minutes to build the broth.\n"
        "4. Ladle into bowls and top with bread and mozzarella.\n"
        "5. Grill until the cheese is bubbly and golden.",
        [("onion", "4"), ("butter", "2 tbsp"), ("bread", "2 slices"), ("mozzarella", "1/2 cup"),
         ("thyme", "1/2 tsp"), ("black_pepper", "1/2 tsp"), ("salt", "to taste")],
    ),
    (
        "Crêpes Suzette", "french", ["breakfast", "snacks"], "vegetarian", 10, 15, 25,
        "easy", 4, 54, "indulgent",
        "Thin French pancakes in a buttery orange sauce.",
        ["french", "pancake", "sweet", "breakfast"],
        "1. Whisk maida, milk, egg and sugar into a thin batter.\n"
        "2. Rest the batter for 10 minutes.\n"
        "3. Cook thin crêpes in a buttered pan.\n"
        "4. Fold each crêpe into quarters.\n"
        "5. Serve with sugar and a squeeze of lemon.",
        [("maida", "1 cup"), ("milk", "1 cup"), ("egg", "2"), ("sugar", "2 tbsp"),
         ("butter", "2 tbsp"), ("lemon", "1")],
    ),
    (
        "Crème Brûlée", "french", ["dessert"], "vegetarian", 15, 35, 50,
        "medium", 4, 45, "indulgent",
        "Silky vanilla custard under a crackling caramel crust.",
        ["french", "dessert", "vanilla", "classic"],
        "1. Warm cream with vanilla.\n"
        "2. Whisk egg yolks with sugar and pour in the cream.\n"
        "3. Strain and bake in ramekins in a water bath.\n"
        "4. Chill for 3 hours.\n"
        "5. Sprinkle sugar and caramelise with a torch.",
        [("heavy_cream", "2 cups"), ("egg", "4"), ("sugar", "1/2 cup"), ("vanilla", "1 tsp")],
    ),
    # ---------------- THAI ----------------
    (
        "Pad Thai", "thai", ["lunch", "dinner"], "vegetarian", 20, 15, 35,
        "medium", 2, 66, "moderate",
        "Stir-fried rice noodles with tofu, beansprouts and peanuts.",
        ["thai", "noodles", "street_food", "tamarind"],
        "1. Soak rice noodles until soft.\n"
        "2. Stir-fry garlic and tofu in a hot pan.\n"
        "3. Add noodles and a sauce of soy, fish sauce and lime.\n"
        "4. Toss with beansprouts and spring onion.\n"
        "5. Top with crushed peanuts and serve.",
        [("noodles", "200g"), ("tofu", "150g"), ("peanuts", "3 tbsp"), ("beans", "1 cup"),
         ("soy_sauce", "2 tbsp"), ("fish_sauce", "1 tbsp"), ("lime", "1"), ("egg", "1")],
    ),
    (
        "Thai Green Curry", "thai", ["dinner"], "vegetarian", 20, 25, 45,
        "medium", 2, 68, "balanced",
        "Fragrant coconut curry with vegetables and green chilli.",
        ["thai", "curry", "coconut", "spicy"],
        "1. Fry green curry paste in coconut milk.\n"
        "2. Add tofu and vegetables.\n"
        "3. Pour in the remaining coconut milk and simmer.\n"
        "4. Season with fish sauce and palm sugar.\n"
        "5. Finish with basil and serve with rice.",
        [("coconut_milk", "400ml"), ("tofu", "200g"), ("beans", "100g"), ("capsicum", "1"),
         ("lemongrass", "1 stalk"), ("green_chilli", "2"), ("basil_leaf", "handful"),
         ("fish_sauce", "1 tbsp"), ("soy_sauce", "1 tbsp")],
    ),
    (
        "Tom Yum Soup", "thai", ["lunch", "dinner"], "vegetarian", 15, 20, 35,
        "medium", 2, 70, "balanced",
        "Hot and sour Thai soup with mushroom and lemongrass.",
        ["thai", "soup", "spicy", "sour"],
        "1. Simmer lemongrass and ginger in water.\n"
        "2. Add mushrooms and simmer until tender.\n"
        "3. Stir in coconut milk and chilli flakes.\n"
        "4. Season with lime juice and soy sauce.\n"
        "5. Garnish with coriander and serve hot.",
        [("mushroom", "200g"), ("lemongrass", "1 stalk"), ("ginger", "1 inch"),
         ("lime", "1"), ("coconut_milk", "1/2 cup"), ("chili_flakes", "1 tsp"),
         ("soy_sauce", "1 tbsp"), ("dhaniya", "handful")],
    ),
    (
        "Thai Mango Sticky Rice", "thai", ["dessert"], "vegetarian", 20, 20, 40,
        "easy", 4, 50, "indulgent",
        "Sweet coconut rice with ripe mango, a Thai dessert classic.",
        ["thai", "dessert", "mango", "rice"],
        "1. Steam glutinous rice until tender.\n"
        "2. Warm coconut milk with sugar and fold into the rice.\n"
        "3. Let the rice absorb the coconut milk.\n"
        "4. Slice ripe mango.\n"
        "5. Serve the rice with mango and extra coconut milk.",
        [("rice", "1 cup"), ("coconut_milk", "1 cup"), ("mango", "1"), ("sugar", "3 tbsp"),
         ("sesame_seeds", "1 tsp")],
    ),
    (
        "Thai Basil Tofu", "thai", ["dinner"], "vegetarian", 15, 15, 30,
        "easy", 2, 68, "balanced",
        "Stir-fried tofu with holy basil, garlic and chilli over rice.",
        ["thai", "stir_fry", "spicy", "quick"],
        "1. Pan-fry tofu cubes until golden.\n"
        "2. Stir-fry garlic, onion and chilli.\n"
        "3. Add tofu and soy sauce, toss well.\n"
        "4. Throw in fresh basil and wilt.\n"
        "5. Serve over steamed rice.",
        [("tofu", "250g"), ("basil_leaf", "handful"), ("garlic", "4 cloves"),
         ("chili_flakes", "1 tsp"), ("onion", "1"), ("soy_sauce", "2 tbsp"), ("rice", "1 cup")],
    ),
    # ---------------- CHINESE ----------------
    (
        "Vegetable Fried Rice", "chinese", ["lunch"], "vegetarian", 15, 10, 25,
        "easy", 2, 68, "moderate",
        "Wok-tossed rice with crunchy vegetables and soy.",
        ["chinese", "rice", "wok", "quick"],
        "1. Cook rice and let it cool completely.\n"
        "2. Stir-fry garlic, carrot, peas and capsicum.\n"
        "3. Push vegetables aside and scramble the egg.\n"
        "4. Add rice and soy sauce, toss over high heat.\n"
        "5. Finish with spring onion.",
        [("rice", "2 cups"), ("carrot", "1"), ("peas", "1/2 cup"), ("capsicum", "1"),
         ("egg", "1"), ("soy_sauce", "2 tbsp"), ("garlic", "2 cloves"),
         ("spring_onion", "2 tbsp")],
    ),
    (
        "Veg Chow Mein", "chinese", ["lunch", "dinner"], "vegetarian", 15, 10, 25,
        "easy", 2, 64, "moderate",
        "Noodles stir-fried with cabbage, carrot and capsicum in soy.",
        ["chinese", "noodles", "street_food", "wok"],
        "1. Boil noodles and rinse with cold water.\n"
        "2. Stir-fry garlic, cabbage, carrot and capsicum.\n"
        "3. Add the noodles and soy sauce.\n"
        "4. Toss over high heat for 2 minutes.\n"
        "5. Garnish with spring onion.",
        [("noodles", "200g"), ("cabbage", "1/2 cup"), ("carrot", "1"), ("capsicum", "1"),
         ("soy_sauce", "2 tbsp"), ("garlic", "2 cloves"), ("spring_onion", "2 tbsp")],
    ),
    (
        "Vegetable Spring Rolls", "chinese", ["snacks"], "vegetarian", 20, 15, 35,
        "medium", 4, 60, "moderate",
        "Crispy golden rolls stuffed with glass noodles and vegetables.",
        ["chinese", "snack", "crispy", "street_food"],
        "1. Soak vermicelli and chop vegetables finely.\n"
        "2. Stir-fry the filling with soy sauce and garlic.\n"
        "3. Wrap spoonfuls in a dough wrapper.\n"
        "4. Deep-fry until golden and crisp.\n"
        "5. Serve with sweet chilli or soy.",
        [("vermicelli", "50g"), ("cabbage", "1/2 cup"), ("carrot", "1"), ("maida", "1 cup"),
         ("soy_sauce", "1 tbsp"), ("garlic", "2 cloves"), ("cooking_oil", "for frying")],
    ),
    (
        "Kung Pao Tofu", "chinese", ["dinner"], "vegetarian", 15, 15, 30,
        "medium", 2, 66, "moderate",
        "Crispy tofu and peanuts in a fiery sweet-sour kung pao sauce.",
        ["chinese", "tofu", "spicy", "peanuts"],
        "1. Cube and pan-fry tofu until golden.\n"
        "2. Roast peanuts lightly.\n"
        "3. Stir-fry garlic, capsicum and red chilli.\n"
        "4. Add tofu, peanuts and soy-based sauce.\n"
        "5. Toss and serve with rice.",
        [("tofu", "250g"), ("peanuts", "1/2 cup"), ("capsicum", "1"), ("garlic", "3 cloves"),
         ("red_chilli_powder", "1 tsp"), ("soy_sauce", "2 tbsp"), ("rice", "1 cup")],
    ),
    (
        "Egg Drop Soup", "chinese", ["dinner"], "vegetarian_egg", 10, 10, 20,
        "easy", 2, 72, "balanced",
        "Silky egg ribbons in a light, gingery broth.",
        ["chinese", "soup", "light", "comfort"],
        "1. Simmer water with ginger and mushroom.\n"
        "2. Season with soy sauce and a little cornflour slurry.\n"
        "3. Slowly drizzle in beaten egg while stirring.\n"
        "4. Garnish with spring onion.\n"
        "5. Serve hot.",
        [("egg", "2"), ("mushroom", "100g"), ("ginger", "1 inch"), ("soy_sauce", "1 tbsp"),
         ("cornflour", "1 tbsp"), ("spring_onion", "1 tbsp")],
    ),
    # ---------------- MEXICAN ----------------
    (
        "Vegetable Tacos", "mexican", ["dinner"], "vegetarian", 15, 15, 30,
        "easy", 2, 66, "moderate",
        "Soft tortillas filled with beans, veggies, avocado and lime.",
        ["mexican", "taco", "street_food", "beans"],
        "1. Warm tortillas on a dry pan.\n"
        "2. Cook beans with onion, tomato and capsicum.\n"
        "3. Mash avocado with lime for a quick topping.\n"
        "4. Fill tortillas with the bean mix.\n"
        "5. Top with coriander and a squeeze of lime.",
        [("tortilla", "4"), ("beans", "1 cup"), ("onion", "1"), ("tomato", "2"),
         ("capsicum", "1"), ("avocado", "1"), ("lime", "1"), ("dhaniya", "handful")],
    ),
    (
        "Guacamole", "mexican", ["snacks"], "vegetarian", 10, 0, 10,
        "easy", 4, 72, "balanced",
        "Creamy mashed avocado with lime, onion and chilli.",
        ["mexican", "dip", "healthy", "quick"],
        "1. Halve and mash the avocados.\n"
        "2. Stir in finely chopped onion and tomato.\n"
        "3. Add lime juice and salt.\n"
        "4. Season with chilli flakes.\n"
        "5. Serve with tortilla chips or bread.",
        [("avocado", "2"), ("lime", "1"), ("onion", "1/4"), ("tomato", "1"),
         ("dhaniya", "handful"), ("chili_flakes", "1/2 tsp"), ("salt", "to taste")],
    ),
    (
        "Cheesy Enchiladas", "mexican", ["dinner"], "vegetarian", 20, 25, 45,
        "medium", 2, 58, "moderate",
        "Rolled tortillas baked in a tangy tomato sauce with melted cheese.",
        ["mexican", "baked", "cheese", "tomato"],
        "1. Blend tomato with onion and chilli into a sauce.\n"
        "2. Fill tortillas with seasoned beans and roll up.\n"
        "3. Lay in a baking dish and cover with the sauce.\n"
        "4. Top with mozzarella and bake at 200C for 20 minutes.\n"
        "5. Serve hot with a dollop of curd.",
        [("tortilla", "4"), ("beans", "1 cup"), ("tomato", "4"), ("onion", "1"),
         ("capsicum", "1"), ("mozzarella", "1 cup"), ("chili_flakes", "1 tsp")],
    ),
    (
        "Huevos Rancheros", "mexican", ["breakfast"], "vegetarian_egg", 10, 15, 25,
        "easy", 2, 64, "moderate",
        "Fried eggs on tortillas with a spicy tomato-bean sauce.",
        ["mexican", "breakfast", "eggs", "spicy"],
        "1. Simmer tomato, onion and beans into a chunky sauce.\n"
        "2. Warm the tortillas.\n"
        "3. Fry the eggs to your liking.\n"
        "4. Layer tortilla, sauce and fried egg.\n"
        "5. Garnish with coriander and chilli.",
        [("egg", "2"), ("tortilla", "2"), ("tomato", "2"), ("onion", "1"), ("beans", "1/2 cup"),
         ("chili_flakes", "1 tsp"), ("dhaniya", "handful")],
    ),
    (
        "Churros with Chocolate", "mexican", ["dessert"], "vegetarian", 20, 15, 35,
        "medium", 4, 42, "indulgent",
        "Cinnamon-sugar fried dough sticks with warm chocolate dip.",
        ["mexican", "dessert", "fried", "sweet"],
        "1. Boil water, butter and a pinch of salt.\n"
        "2. Beat in maida to form a dough.\n"
        "3. Pipe into strips and deep-fry until golden.\n"
        "4. Roll in cinnamon sugar.\n"
        "5. Serve with melted chocolate (cocoa, milk, sugar).",
        [("maida", "1 cup"), ("butter", "2 tbsp"), ("sugar", "1/2 cup"), ("cinnamon", "1 tsp"),
         ("cocoa_powder", "3 tbsp"), ("milk", "1/2 cup"), ("cooking_oil", "for frying")],
    ),
    # ---------------- JAPANESE ----------------
    (
        "Veg Sushi Rolls", "japanese", ["dinner"], "vegetarian", 30, 20, 50,
        "hard", 2, 66, "moderate",
        "Hand-rolled nori sushi with seasoned rice, cucumber and avocado.",
        ["japanese", "sushi", "rice", "fresh"],
        "1. Cook sushi rice and season with rice vinegar and sugar.\n"
        "2. Slice cucumber, carrot and avocado into thin sticks.\n"
        "3. Lay nori on a bamboo mat, spread with rice.\n"
        "4. Add the vegetable sticks and roll tightly.\n"
        "5. Slice and serve with soy sauce.",
        [("sushi_rice", "1.5 cups"), ("nori", "4 sheets"), ("cucumber", "1"),
         ("carrot", "1"), ("avocado", "1"), ("rice_vinegar", "2 tbsp"), ("sugar", "1 tsp"),
         ("soy_sauce", "2 tbsp")],
    ),
    (
        "Miso Soup", "japanese", ["dinner"], "vegetarian", 10, 10, 20,
        "easy", 2, 74, "balanced",
        "Warming umami broth with tofu, wakame and spring onion.",
        ["japanese", "soup", "light", "healthy"],
        "1. Simmer water with mushroom for 5 minutes.\n"
        "2. Whisk in miso paste off the heat.\n"
        "3. Add cubed tofu and crumbled nori.\n"
        "4. Garnish with spring onion.\n"
        "5. Serve piping hot.",
        [("miso", "2 tbsp"), ("tofu", "100g"), ("mushroom", "50g"), ("nori", "1 sheet"),
         ("spring_onion", "1 tbsp")],
    ),
    (
        "Veg Tempura", "japanese", ["snacks"], "vegetarian", 15, 15, 30,
        "medium", 2, 62, "moderate",
        "Feather-light battered and fried vegetables with a soy dip.",
        ["japanese", "fried", "crispy", "snack"],
        "1. Make a very cold, lumpy batter from maida and ice water.\n"
        "2. Slice zucchini, bell pepper and mushroom.\n"
        "3. Dip in batter and deep-fry until pale golden.\n"
        "4. Drain on paper towel.\n"
        "5. Serve with soy sauce and ginger.",
        [("maida", "1 cup"), ("zucchini", "1"), ("bell_pepper", "1"), ("mushroom", "100g"),
         ("egg", "1"), ("cooking_oil", "for frying"), ("soy_sauce", "2 tbsp")],
    ),
    (
        "Japanese Omurice", "japanese", ["breakfast", "lunch"], "vegetarian_egg", 10, 15, 25,
        "easy", 2, 62, "moderate",
        "Tomato fried rice wrapped in a soft omelette, topped with ketchup.",
        ["japanese", "rice", "eggs", "comfort"],
        "1. Stir-fry onion, peas and rice with tomato and soy.\n"
        "2. Beat eggs and cook into a soft omelette.\n"
        "3. Shape the rice into an oval on a plate.\n"
        "4. Cover with the omelette.\n"
        "5. Squeeze ketchup or tomato sauce on top.",
        [("rice", "2 cups"), ("egg", "3"), ("onion", "1"), ("peas", "1/2 cup"),
         ("tomato", "1"), ("soy_sauce", "1 tbsp"), ("butter", "1 tbsp")],
    ),
    (
        "Matcha Mochi", "japanese", ["dessert"], "vegetarian", 15, 15, 30,
        "easy", 4, 50, "moderate",
        "Chewy glutinous rice cake lightly sweetened with green tea.",
        ["japanese", "dessert", "matcha", "chewy"],
        "1. Mix rice flour, sugar and matcha with coconut milk.\n"
        "2. Steam until the batter turns translucent.\n"
        "3. Cool slightly and knead until smooth.\n"
        "4. Cut into squares and dust with rice flour.\n"
        "5. Serve at room temperature.",
        [("maida", "1 cup"), ("sugar", "1/2 cup"), ("coconut_milk", "3/4 cup"),
         ("green_tea", "1 tbsp"), ("cornflour", "for dusting")],
    ),
    # ---------------- MEDITERRANEAN ----------------
    (
        "Falafel Wrap", "mediterranean", ["lunch", "snacks"], "vegetarian", 25, 20, 45,
        "medium", 2, 66, "moderate",
        "Crisp chickpea falafel in a wrap with fresh veg and tahini.",
        ["mediterranean", "chickpea", "wrap", "street_food"],
        "1. Blend soaked chickpeas with garlic, onion and spices.\n"
        "2. Shape into balls and deep-fry until golden.\n"
        "3. Warm a wrap or tortilla.\n"
        "4. Add falafel, sliced veg and cucumber.\n"
        "5. Drizzle with tahini and roll up.",
        [("chickpeas", "1 cup"), ("garlic", "3 cloves"), ("onion", "1"), ("cumin", "1 tsp"),
         ("tortilla", "2"), ("cucumber", "1"), ("tahini", "2 tbsp"), ("cooking_oil", "for frying")],
    ),
    (
        "Greek Salad", "mediterranean", ["snacks", "lunch"], "vegetarian", 15, 0, 15,
        "easy", 2, 74, "balanced",
        "Fresh tomato, cucumber and onion with olives and feta-style cheese.",
        ["mediterranean", "salad", "fresh", "healthy"],
        "1. Chop tomato, cucumber and onion.\n"
        "2. Add olives and cubed paneer.\n"
        "3. Dress with olive oil and lemon.\n"
        "4. Season with oregano and black pepper.\n"
        "5. Toss and serve chilled.",
        [("tomato", "2"), ("cucumber", "1"), ("onion", "1/2"), ("paneer", "100g"),
         ("olive_oil", "2 tbsp"), ("lemon", "1"), ("oregano", "1/2 tsp"),
         ("black_pepper", "1/2 tsp")],
    ),
    (
        "Hummus", "mediterranean", ["snacks"], "vegetarian", 15, 20, 35,
        "easy", 4, 72, "balanced",
        "Silky chickpea and tahini dip with garlic and lemon.",
        ["mediterranean", "dip", "healthy", "chickpea"],
        "1. Pressure cook chickpeas until very soft.\n"
        "2. Blend with tahini, garlic and lemon juice.\n"
        "3. Drizzle in olive oil and a little water.\n"
        "4. Blend until silky smooth.\n"
        "5. Serve with bread or veggie sticks.",
        [("chickpeas", "1.5 cups"), ("tahini", "3 tbsp"), ("garlic", "2 cloves"),
         ("lemon", "1"), ("olive_oil", "2 tbsp"), ("salt", "to taste")],
    ),
    (
        "Shakshuka", "mediterranean", ["breakfast"], "vegetarian_egg", 15, 20, 35,
        "easy", 2, 66, "moderate",
        "Eggs poached in a spiced tomato-pepper sauce.",
        ["mediterranean", "breakfast", "eggs", "tomato"],
        "1. Cook onion, capsicum and garlic in olive oil.\n"
        "2. Add tomato, cumin and chilli, simmer into a sauce.\n"
        "3. Make wells and crack in the eggs.\n"
        "4. Cover and cook until the whites set.\n"
        "5. Garnish with coriander and serve with bread.",
        [("egg", "2"), ("tomato", "4"), ("onion", "1"), ("capsicum", "1"), ("garlic", "2 cloves"),
         ("cumin", "1 tsp"), ("olive_oil", "2 tbsp"), ("dhaniya", "handful")],
    ),
    (
        "Baklava", "mediterranean", ["dessert"], "vegetarian", 30, 30, 60,
        "hard", 8, 44, "indulgent",
        "Layers of crisp pastry with nuts and honey syrup.",
        ["mediterranean", "dessert", "honey", "nuts"],
        "1. Chop pistachios and walnuts, mix with sugar and cinnamon.\n"
        "2. Layer pastry sheets with melted butter and the nut mix.\n"
        "3. Cut into diamonds before baking.\n"
        "4. Bake until golden and crisp.\n"
        "5. Pour over warm honey syrup and cool.",
        [("maida", "2 cups"), ("butter", "150g"), ("pistachios", "1/2 cup"),
         ("walnuts", "1/2 cup"), ("honey", "1/2 cup"), ("sugar", "1/4 cup"),
         ("cinnamon", "1/2 tsp")],
    ),
    # ---------------- KOREAN ----------------
    (
        "Kimchi Fried Rice", "korean", ["lunch"], "vegetarian", 10, 15, 25,
        "easy", 2, 64, "moderate",
        "Spicy, tangy rice stir-fried with kimchi and gochujang.",
        ["korean", "rice", "spicy", "street_food"],
        "1. Stir-fry chopped kimchi with garlic.\n"
        "2. Add cooked rice and gochujang, toss well.\n"
        "3. Season with soy sauce and sesame oil.\n"
        "4. Top with a fried egg.\n"
        "5. Garnish with spring onion and sesame seeds.",
        [("rice", "2 cups"), ("kimchi", "1 cup"), ("gochujang", "1 tbsp"), ("egg", "1"),
         ("soy_sauce", "1 tbsp"), ("sesame_oil", "1 tsp"), ("spring_onion", "1 tbsp"),
         ("sesame_seeds", "1 tsp")],
    ),
    (
        "Bibimbap", "korean", ["lunch", "dinner"], "vegetarian", 20, 15, 35,
        "medium", 2, 72, "balanced",
        "Rice bowl with seasoned vegetables, a fried egg and gochujang.",
        ["korean", "rice", "healthy", "bowl"],
        "1. Cook rice and keep warm.\n"
        "2. Separately saute carrot, spinach and beans.\n"
        "3. Season each with salt and sesame oil.\n"
        "4. Assemble vegetables over the rice.\n"
        "5. Top with a fried egg and gochujang.",
        [("rice", "2 cups"), ("carrot", "1"), ("spinach", "1 cup"), ("beans", "1/2 cup"),
         ("egg", "1"), ("gochujang", "1 tbsp"), ("sesame_oil", "1 tsp"),
         ("sesame_seeds", "1 tsp")],
    ),
    (
        "Korean Veg Pancake", "korean", ["snacks"], "vegetarian", 15, 15, 30,
        "easy", 2, 62, "moderate",
        "Crisp scallion and vegetable pancake served with soy dip.",
        ["korean", "pancake", "crispy", "snack"],
        "1. Make a thin batter from maida, water and egg.\n"
        "2. Stir in spring onion, carrot and capsicum.\n"
        "3. Pan-fry until golden on both sides.\n"
        "4. Cut into wedges.\n"
        "5. Serve with a soy-vinegar dip.",
        [("maida", "1 cup"), ("egg", "1"), ("spring_onion", "1/2 cup"), ("carrot", "1/2"),
         ("capsicum", "1/2"), ("soy_sauce", "2 tbsp"), ("cooking_oil", "2 tbsp")],
    ),
    (
        "Tteokbokki", "korean", ["snacks"], "vegetarian", 10, 20, 30,
        "easy", 2, 58, "moderate",
        "Chewy rice cakes in a glossy, spicy-sweet gochujang sauce.",
        ["korean", "rice", "spicy", "street_food"],
        "1. Soak rice cakes (soft rice dough strips) in water.\n"
        "2. Simmer gochujang, sugar and water into a sauce.\n"
        "3. Add the rice cakes and cook until glossy.\n"
        "4. Stir in spring onion and sesame oil.\n"
        "5. Serve hot.",
        [("rice", "2 cups"), ("gochujang", "2 tbsp"), ("sugar", "1 tbsp"), ("spring_onion", "1 tbsp"),
         ("sesame_oil", "1 tsp"), ("sesame_seeds", "1 tsp")],
    ),
    (
        "Korean BBQ Tofu", "korean", ["dinner"], "vegetarian", 15, 20, 35,
        "medium", 2, 68, "balanced",
        "Glazed tofu steaks in a smoky-sweet gochujang marinade.",
        ["korean", "tofu", "bbq", "glazed"],
        "1. Slice tofu thickly and press out excess water.\n"
        "2. Mix gochujang, soy, garlic and sesame oil into a glaze.\n"
        "3. Pan-fry tofu until golden on both sides.\n"
        "4. Brush with the glaze and caramelise.\n"
        "5. Serve with rice and spring onion.",
        [("tofu", "250g"), ("gochujang", "2 tbsp"), ("soy_sauce", "1 tbsp"),
         ("garlic", "2 cloves"), ("sesame_oil", "1 tsp"), ("rice", "1 cup"),
         ("spring_onion", "1 tbsp")],
    ),
    # ---------------- VIETNAMESE ----------------
    (
        "Veg Pho", "vietnamese", ["lunch", "dinner"], "vegetarian", 20, 30, 50,
        "medium", 2, 74, "balanced",
        "Fragrant noodle soup with herbs, tofu and lime.",
        ["vietnamese", "soup", "noodles", "herbs"],
        "1. Simmer onion, ginger and cinnamon for a fragrant broth.\n"
        "2. Cook rice noodles separately.\n"
        "3. Add tofu and mushrooms to the broth.\n"
        "4. Ladle over noodles in a bowl.\n"
        "5. Top with coriander, spring onion, lime and chilli.",
        [("noodles", "200g"), ("tofu", "150g"), ("mushroom", "100g"), ("onion", "1"),
         ("ginger", "1 inch"), ("cinnamon", "1 stick"), ("lime", "1"), ("spring_onion", "1 tbsp"),
         ("dhaniya", "handful"), ("soy_sauce", "2 tbsp")],
    ),
    (
        "Vietnamese Spring Rolls", "vietnamese", ["snacks"], "vegetarian", 20, 0, 20,
        "easy", 4, 72, "balanced",
        "Fresh rice-paper rolls packed with noodles and crunchy vegetables.",
        ["vietnamese", "fresh", "healthy", "no_cook"],
        "1. Soften rice paper in warm water.\n"
        "2. Layer vermicelli, carrot, cucumber and mint.\n"
        "3. Roll tightly and seal.\n"
        "4. Repeat for the remaining rolls.\n"
        "5. Serve with a peanut-soy dipping sauce.",
        [("rice_paper", "8 sheets"), ("vermicelli", "50g"), ("carrot", "1"), ("cucumber", "1"),
         ("mint", "handful"), ("peanuts", "2 tbsp"), ("soy_sauce", "2 tbsp")],
    ),
    (
        "Veg Banh Mi", "vietnamese", ["lunch"], "vegetarian", 15, 10, 25,
        "easy", 2, 62, "moderate",
        "Crisp baguette sandwich with pickled veg, tofu and fresh herbs.",
        ["vietnamese", "sandwich", "fresh", "street_food"],
        "1. Pan-fry tofu slices in soy sauce.\n"
        "2. Pickle carrot and cucumber in vinegar and sugar.\n"
        "3. Split and toast a baguette.\n"
        "4. Layer with tofu, pickled veg and coriander.\n"
        "5. Drizzle with soy sauce and serve.",
        [("bread", "1 baguette"), ("tofu", "150g"), ("carrot", "1"), ("cucumber", "1"),
         ("dhaniya", "handful"), ("soy_sauce", "2 tbsp"), ("rice_vinegar", "2 tbsp"),
         ("sugar", "1 tsp")],
    ),
    (
        "Vietnamese Noodle Salad", "vietnamese", ["lunch"], "vegetarian", 15, 15, 30,
        "easy", 2, 70, "balanced",
        "Cool vermicelli salad with herbs, peanuts and lime dressing.",
        ["vietnamese", "salad", "fresh", "healthy"],
        "1. Boil vermicelli and cool under running water.\n"
        "2. Shred carrot and cucumber.\n"
        "3. Whisk soy sauce, lime and sugar into a dressing.\n"
        "4. Toss noodles with vegetables and mint.\n"
        "5. Top with crushed peanuts and coriander.",
        [("vermicelli", "150g"), ("carrot", "1"), ("cucumber", "1"), ("mint", "handful"),
         ("peanuts", "2 tbsp"), ("soy_sauce", "2 tbsp"), ("lime", "1"), ("sugar", "1 tsp"),
         ("dhaniya", "handful")],
    ),
    (
        "Coconut Sticky Rice", "vietnamese", ["dessert"], "vegetarian", 20, 20, 40,
        "easy", 4, 52, "indulgent",
        "Sweet coconut-glazed sticky rice with sesame.",
        ["vietnamese", "dessert", "coconut", "rice"],
        "1. Steam glutinous rice until tender.\n"
        "2. Warm coconut milk with sugar and a pinch of salt.\n"
        "3. Fold the coconut milk into the rice.\n"
        "4. Let it absorb and thicken.\n"
        "5. Serve with toasted sesame seeds.",
        [("rice", "1 cup"), ("coconut_milk", "1 cup"), ("sugar", "3 tbsp"),
         ("sesame_seeds", "1 tsp"), ("salt", "a pinch")],
    ),
]


# (name, display_name_en, category, storage_type)
NEW_INGREDIENTS = {
    "basil_leaf": ("Fresh Basil", IngredientCategoryType.HERB, IngredientStorageType.FRESH),
    "bell_pepper": ("Bell Pepper", IngredientCategoryType.VEGETABLE, IngredientStorageType.FRESH),
    "black_pepper": ("Black Pepper", IngredientCategoryType.SPICE, IngredientStorageType.PANTRY),
    "chili_flakes": ("Chilli Flakes", IngredientCategoryType.SPICE, IngredientStorageType.PANTRY),
    "cocoa_powder": ("Cocoa Powder", IngredientCategoryType.OTHER, IngredientStorageType.PANTRY),
    "coconut_milk": ("Coconut Milk", IngredientCategoryType.OTHER, IngredientStorageType.PANTRY),
    "fish_sauce": ("Fish Sauce", IngredientCategoryType.CONDIMENT, IngredientStorageType.PANTRY),
    "gochujang": ("Gochujang", IngredientCategoryType.CONDIMENT, IngredientStorageType.PANTRY),
    "green_tea": ("Green Tea Powder", IngredientCategoryType.OTHER, IngredientStorageType.PANTRY),
    "heavy_cream": ("Heavy Cream", IngredientCategoryType.DAIRY, IngredientStorageType.FRESH),
    "kimchi": ("Kimchi", IngredientCategoryType.VEGETABLE, IngredientStorageType.FRESH),
    "lemongrass": ("Lemongrass", IngredientCategoryType.HERB, IngredientStorageType.FRESH),
    "mango": ("Mango", IngredientCategoryType.FRUIT, IngredientStorageType.FRESH),
    "mascarpone": ("Mascarpone", IngredientCategoryType.DAIRY, IngredientStorageType.FRESH),
    "mint": ("Mint", IngredientCategoryType.HERB, IngredientStorageType.FRESH),
    "miso": ("Miso Paste", IngredientCategoryType.CONDIMENT, IngredientStorageType.PANTRY),
    "mozzarella": ("Mozzarella", IngredientCategoryType.DAIRY, IngredientStorageType.FRESH),
    "nori": ("Nori Seaweed", IngredientCategoryType.OTHER, IngredientStorageType.PANTRY),
    "olive_oil": ("Olive Oil", IngredientCategoryType.OIL, IngredientStorageType.PANTRY),
    "oregano": ("Oregano", IngredientCategoryType.HERB, IngredientStorageType.PANTRY),
    "parmesan": ("Parmesan", IngredientCategoryType.DAIRY, IngredientStorageType.FRESH),
    "parsley": ("Parsley", IngredientCategoryType.HERB, IngredientStorageType.FRESH),
    "rice_paper": ("Rice Paper", IngredientCategoryType.GRAIN, IngredientStorageType.PANTRY),
    "rice_vinegar": ("Rice Vinegar", IngredientCategoryType.CONDIMENT, IngredientStorageType.PANTRY),
    "sushi_rice": ("Sushi Rice", IngredientCategoryType.GRAIN, IngredientStorageType.PANTRY),
    "tahini": ("Tahini", IngredientCategoryType.CONDIMENT, IngredientStorageType.PANTRY),
    "thyme": ("Thyme", IngredientCategoryType.HERB, IngredientStorageType.FRESH),
    "tofu": ("Tofu", IngredientCategoryType.OTHER, IngredientStorageType.FRESH),
    "tortilla": ("Tortilla", IngredientCategoryType.GRAIN, IngredientStorageType.PANTRY),
    "vanilla": ("Vanilla", IngredientCategoryType.OTHER, IngredientStorageType.PANTRY),
    "zucchini": ("Zucchini", IngredientCategoryType.VEGETABLE, IngredientStorageType.FRESH),
    "spring_onion": ("Spring Onion", IngredientCategoryType.VEGETABLE, IngredientStorageType.FRESH),
    "avocado": ("Avocado", IngredientCategoryType.FRUIT, IngredientStorageType.FRESH),
    "lime": ("Lime", IngredientCategoryType.FRUIT, IngredientStorageType.FRESH),
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
        print(f"\nDone. {added} new international recipes added.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
