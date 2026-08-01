# What to Cook? - AI Smart Kitchen App

**Tell us what you have. We'll tell you what to cook.**

A production-ready mobile application that answers the daily question: **"What should I cook/eat today?"**

---

## Features

### Core Loop
1. **Onboarding** - Quick setup with household info, diet preference, cuisine choices, and automatic kitchen profile
2. **Default Kitchen** - Pre-populated inventory based on your kitchen type (no manual entry required)
3. **Voice/Text Inventory** - Tell us what's in your kitchen naturally in Hindi, English, or Hinglish
4. **Smart Recommendations** - What to cook based on what you have, use-soon items, recent meals, and preferences
5. **Recipe Details** - Step-by-step instructions with distraction-free cooking mode
6. **I Made This** - Log meals to improve future recommendations and update inventory
7. **Use-Soon Alerts** - Know which ingredients should be used soon
8. **Weekly/Monthly Insights** - Track your eating patterns

### Inventory Management
- **Kitchen Profiles**: Basic North Indian Veg, North Indian Non-Veg, South Indian, Mixed Indian
- **Default Inventory**: Grains, pulses, spices, and common vegetables pre-populated
- **Voice-First Input**: Speak in Hindi/English/Hinglish to update your kitchen
- **Smart Parsing**: Understands ADD, REMOVE, SET LOW, REPLACE CATEGORY, REPLACE ALL intents
- **Ingredient Normalization**: Canonical IDs with aliases for Hindi, English, Hinglish

### Recommendation Engine
- Deterministic scoring based on ingredient match, freshness, meal type, cuisine, recent meals
- Missing ingredient opportunities with "Buy X → Unlock Y meals"
- Surprise Me mode for when you can't decide
- Time-of-day awareness (breakfast/lunch/snacks/dinner)

### Health & Insights
- Meal health classification (Balanced/Moderate/Indulgent)
- Weekly and monthly food reports
- Cuisine distribution tracking
- Balance My Week feature
- No medical claims - just food balance indicators

---

## Tech Stack

### Frontend
- **Flutter** 3.x with Dart
- **Material 3** Design
- **Riverpod** for state management
- **GoRouter** for navigation
- Clean Architecture with domain/data/presentation layers

### Backend
- **FastAPI** (Python)
- **PostgreSQL** with SQLAlchemy ORM
- **Alembic** for migrations
- **Pydantic** for validation
- RESTful API design
- JWT authentication

### AI
- Abstraction layer for LLM provider (OpenAI by default, swappable)
- Used for: inventory parsing, natural-language search, recipe adaptation
- Deterministic recommendation engine (no LLM for core matching)

---

## Project Structure

```
what-to-cook/
├── frontend/                 # Flutter mobile app
│   └── lib/
│       ├── core/             # Constants, theme, network, utils
│       ├── data/             # Models, repositories, datasources
│       │   ├── datasources/remote/   # API client
│       │   └── models/               # Data models
│       ├── domain/           # Entities, use cases (future)
│       └── presentation/     # Screens, providers, widgets
│           ├── screens/
│           │   ├── auth/
│           │   ├── splash/
│           │   ├── onboarding/
│           │   ├── home/
│           │   ├── kitchen/
│           │   ├── discover/
│           │   ├── insights/
│           │   ├── profile/
│           │   ├── recipe/
│           │   └── shopping_list/
│           └── providers/
├── backend/                  # FastAPI server
│   ├── app/
│   │   ├── api/v1/           # Route handlers
│   │   ├── core/             # Config, security, database
│   │   ├── models/           # SQLAlchemy models
│   │   ├── schemas/          # Pydantic schemas
│   │   ├── services/         # Business logic
│   │   │   ├── ai_service.py           # Inventory parser
│   │   │   ├── recommendation_engine.py # Scoring engine
│   │   │   ├── freshness_engine.py     # Use-soon detection
│   │   │   └── health_scoring.py       # Meal quality scoring
│   │   ├── crud/             # Database CRUD operations
│   │   └── seed_data/        # Initial data seeding
│   ├── alembic/              # Database migrations
│   └── tests/                # Pytest tests
└── docs/
```

## Database Models

- `users` - User accounts with diet type and preferences
- `households` / `household_members` - Household grouping
- `ingredients` / `ingredient_aliases` - Canonical ingredient database with Hindi/English/Hinglish aliases
- `ingredient_categories` - Vegetable, grain, spice, etc.
- `kitchen_profiles` / `kitchen_profile_items` - Default kitchen templates
- `inventory_items` - Current household inventory with status (available/low/use_soon/not_available)
- `recipes` / `recipe_ingredients` / `recipe_tags` - Recipe database
- `cuisines` - Cuisine metadata
- `meal_history` / `meal_feedback` - Meal tracking
- `freshness_rules` - Expected freshness windows per ingredient
- `shopping_lists` / `shopping_list_items` - Shopping list
- `notification_preferences` / `device_tokens` - Push notification config
- `recommendation_events` / `ai_parsing_logs` - Analytics

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Register new user |
| POST | `/api/v1/auth/login` | Login |
| POST | `/api/v1/onboarding/complete` | Complete onboarding with preferences |
| GET | `/api/v1/kitchen/inventory` | Get household inventory |
| POST | `/api/v1/kitchen/inventory/update` | Update single inventory item |
| POST | `/api/v1/kitchen/voice` | Voice/text inventory update |
| POST | `/api/v1/kitchen/voice/confirm` | Confirm parsed voice update |
| GET | `/api/v1/kitchen/use-soon` | Get use-soon ingredients |
| GET | `/api/v1/kitchen/ingredients` | List all ingredients |
| GET | `/api/v1/recommendations/` | Get meal recommendations |
| GET | `/api/v1/recommendations/surprise-me` | Surprise me recommendation |
| GET | `/api/v1/recommendations/missing-ingredients` | Missing ingredient opportunities |
| GET | `/api/v1/recipes/:id` | Recipe detail |
| GET | `/api/v1/recipes/search` | Search recipes |
| POST | `/api/v1/meals/log` | Log a cooked meal |
| GET | `/api/v1/meals/history` | Get meal history |
| GET | `/api/v1/insights/weekly` | Weekly eating insights |
| GET | `/api/v1/insights/monthly` | Monthly eating report |
| GET | `/api/v1/insights/balance` | Balance My Week suggestion |
| GET | `/api/v1/shopping/` | Get shopping list |
| POST | `/api/v1/shopping/add` | Add item to shopping list |
| POST | `/api/v1/shopping/add-from-recipe/:id` | Add recipe missing items |

---

## Getting Started

### Prerequisites
- Python 3.11+
- PostgreSQL
- Flutter 3.x
- Firebase project (optional for auth)

### Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set up environment
cp ../.env.example .env
# Edit .env with your DATABASE_URL and AI_API_KEY

# Run database migrations
alembic upgrade head

# Seed initial data
python seed_all.py

# Start server
python run.py
```

### Frontend Setup

```bash
cd frontend

# Install Flutter dependencies
flutter pub get

# Run the app
flutter run
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://postgres:password@localhost:5432/what_to_cook` |
| `AI_API_KEY` | OpenAI API key | (required for AI features) |
| `JWT_SECRET_KEY` | JWT signing key | (change in production) |
| `FIREBASE_CREDENTIALS_PATH` | Firebase service account | `./firebase-credentials.json` |

---

## AI Inventory Parser

The parser understands natural language inventory updates in Hindi, English, and Hinglish.

### Supported Intents
| Intent | Example | Result |
|--------|---------|--------|
| ADD | "Paneer aur mushroom bhi hain" | Add paneer, mushroom |
| REMOVE | "Bhindi khatam ho gayi" | Remove okra |
| SET LOW | "Tomato thoda bacha hai" | Tomato = low |
| REPLACE CATEGORY | "Sabjiyon mein sirf aloo pyaz tamatar" | Only these vegetables, remove others |
| NEGATION | "Bread nahi hai lekin eggs hain" | Remove bread, add eggs |

### Test Cases (all pass)
- ✅ `test_remove_bhindi` - "Bhindi khatam ho gayi" → REMOVE okra
- ✅ `test_add_paneer` - "Paneer bhi hai" → ADD paneer
- ✅ `test_replace_vegetables` - "Sabjiyon mein sirf aloo pyaz tamatar hain" → replace vegetables
- ✅ `test_remove_bread_keep_eggs` - "Bread nahi hai lekin eggs hain" → remove bread, add eggs
- ✅ `test_set_low_tomato` - "Tomato thoda bacha hai" → set_low tomato
- ✅ `test_hindi_add` - "mere paas aloo pyaz tomato hai" → add potato, onion, tomato
- ✅ `test_hinglish_mixed` - Mixed Hinglish with low and remove
- ✅ `test_english_inventory` - "I have potatoes, onions and tomatoes"

---

## Recipe Seed Data

18 curated Indian recipes included:

| Recipe | Cuisine | Meal Type | Time |
|--------|---------|-----------|------|
| Aloo Gobhi | North Indian | Lunch/Dinner | 30 min |
| Dal Tadka | North Indian | Lunch/Dinner | 30 min |
| Paneer Butter Masala | Punjabi | Lunch/Dinner | 40 min |
| Veg Pulao | North Indian | Lunch/Dinner | 35 min |
| Mushroom Masala | North Indian | Lunch/Dinner | 30 min |
| Bhindi Masala | North Indian | Lunch/Dinner | 30 min |
| Aloo Matar | North Indian | Lunch/Dinner | 30 min |
| Palak Paneer | Punjabi | Lunch/Dinner | 35 min |
| Moong Dal Khichdi | North Indian | Lunch/Dinner | 25 min |
| Poha | Maharashtrian | Breakfast | 20 min |
| Veg Sandwich | Continental | Breakfast/Snack | 15 min |
| Paneer Bhurji | North Indian | Breakfast/Lunch/Dinner | 15 min |
| Aloo Paratha | Punjabi | Breakfast/Lunch | 40 min |
| Chana Masala | North Indian | Lunch/Dinner | 35 min |
| Dosa with Chutney | South Indian | Breakfast/Dinner | 135 min |
| Veg Biryani | North Indian | Lunch/Dinner | 50 min |
| Egg Curry | North Indian (Egg) | Lunch/Dinner | 25 min |
| Raita | North Indian | Side Dish | 5 min |

---

## Design Philosophy

- **Minimum effort**: Default inventory, voice updates, approximate quantities
- **Not a search app**: Small set of useful recommendations, not hundreds of recipes
- **No medical advice**: Food balance indicators, not diagnoses
- **Hindi/English/Hinglish**: Natural language understanding
- **Privacy**: Minimal data collection, voice recordings not stored

---

## License

MIT
