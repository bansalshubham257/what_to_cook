import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.services.ai_service import _mock_parse_inventory


def test_remove_bhindi():
    """Bhindi khatam ho gayi -> REMOVE okra"""
    result = _mock_parse_inventory("Bhindi khatam ho gayi", "hi")
    assert "okra" in result["remove"], f"Expected okra in remove, got {result}"
    assert result["intent"] == "add" or result["intent"] is not None


def test_add_paneer():
    """Paneer bhi hai -> ADD paneer"""
    result = _mock_parse_inventory("Paneer bhi hai", "hi")
    assert "paneer" in result["add"], f"Expected paneer in add, got {result}"


def test_replace_vegetables():
    """Sabjiyon mein sirf aloo pyaz tamatar hain -> replace vegetables"""
    result = _mock_parse_inventory("Sabjiyon mein sirf aloo pyaz tamatar hain", "hi")
    assert result["intent"] == "replace_category", f"Expected replace_category, got {result['intent']}"
    assert result["requires_confirmation"] == True
    assert "potato" in result["add"]
    assert "onion" in result["add"]
    assert "tomato" in result["add"]


def test_remove_bread_keep_eggs():
    """Bread nahi hai lekin eggs hain -> remove bread, add eggs"""
    result = _mock_parse_inventory("Bread nahi hai lekin eggs hain", "hi")
    assert "bread" in result["remove"], f"Expected bread in remove, got {result}"
    assert "eggs" in result["add"], f"Expected eggs in add, got {result}"


def test_set_low_tomato():
    """Tomato thoda bacha hai -> set_low tomato"""
    result = _mock_parse_inventory("Tomato thoda bacha hai", "hi")
    assert "tomato" in result["set_low"], f"Expected tomato in set_low, got {result}"


def test_hindi_add():
    """Hindi: mere paas aloo pyaz tomato hai -> add potato, onion, tomato"""
    result = _mock_parse_inventory("mere paas aloo pyaz tomato hai", "hi")
    assert "potato" in result["add"]
    assert "onion" in result["add"]
    assert "tomato" in result["add"]


def test_hinglish_mixed():
    """Hinglish: Aloo pyaz tomato hai, thoda paneer bacha hai aur mushroom khatam"""
    result = _mock_parse_inventory("Aloo pyaz tomato hai, thoda paneer bacha hai aur mushroom khatam", "hi")
    assert "potato" in result["add"]
    assert "paneer" in result["set_low"], f"Expected paneer in set_low, got {result}"
    assert "mushroom" in result["remove"], f"Expected mushroom in remove, got {result}"


def test_low_confidence_empty():
    """Unrecognized text -> low confidence"""
    result = _mock_parse_inventory("xyz abc def ghi", "hi")
    assert result["confidence"] < 0.7
    assert result["requires_confirmation"] == True


def test_add_mushroom_paneer():
    """Test: Paneer aur mushroom bhi hain"""
    result = _mock_parse_inventory("Paneer aur mushroom bhi hain", "hi")
    assert "paneer" in result["add"]
    assert "mushroom" in result["add"]


def test_english_inventory():
    """Test: I have potatoes, onions, and tomatoes"""
    result = _mock_parse_inventory("I have potatoes, onions and tomatoes", "en")
    assert "potato" in result["add"]
    assert "onion" in result["add"]
    assert "tomato" in result["add"]
