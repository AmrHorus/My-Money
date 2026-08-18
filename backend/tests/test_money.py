"""Tests for Money domain model."""

import pytest

from app.core.money import Money, CURRENCY_MINOR_UNITS


class TestMoneyCreation:
    """Test Money object creation and validation."""
    
    def test_create_valid_money(self):
        """Test creating valid Money instances."""
        money = Money(2550, "USD")
        assert money.amount_minor_units == 2550
        assert money.currency_code == "USD"
    
    def test_create_zero_money(self):
        """Test creating zero-value Money."""
        money = Money.zero("SAR")
        assert money.amount_minor_units == 0
        assert money.currency_code == "SAR"
        assert money.is_zero()
    
    def test_all_supported_currencies(self):
        """Test creating Money for all supported currencies."""
        for currency in CURRENCY_MINOR_UNITS.keys():
            money = Money(100, currency)
            assert money.currency_code == currency
    
    def test_invalid_currency(self):
        """Test that invalid currency raises error."""
        with pytest.raises(ValueError, match="Invalid currency code"):
            Money(100, "INVALID")
    
    def test_amount_too_large(self):
        """Test that excessively large amounts raise error."""
        with pytest.raises(ValueError, match="Amount too large"):
            Money(10_000_000_000_001, "USD")
    
    def test_amount_too_negative(self):
        """Test that excessively negative amounts raise error."""
        with pytest.raises(ValueError, match="Amount too negative"):
            Money(-10_000_000_000_001, "USD")


class TestMoneyFromMajor:
    """Test conversion from major units."""
    
    def test_from_major_usd(self):
        """Test USD conversion."""
        money = Money.from_major(25.50, "USD")
        assert money.amount_minor_units == 2550
    
    def test_from_major_kwd(self):
        """Test KWD conversion (3 decimal places)."""
        money = Money.from_major(10.123, "KWD")
        assert money.amount_minor_units == 10123
    
    def test_from_major_string(self):
        """Test conversion from string to avoid float issues."""
        money = Money.from_major("25.50", "USD")
        assert money.amount_minor_units == 2550
    
    def test_from_major_rounding(self):
        """Test that small fractions are handled correctly."""
        money = Money.from_major(0.01, "USD")
        assert money.amount_minor_units == 1


class TestMoneyArithmetic:
    """Test Money arithmetic operations."""
    
    def test_addition(self):
        """Test adding two Money values."""
        m1 = Money(1000, "USD")
        m2 = Money(500, "USD")
        result = m1 + m2
        assert result.amount_minor_units == 1500
        assert result.currency_code == "USD"
    
    def test_subtraction(self):
        """Test subtracting two Money values."""
        m1 = Money(1000, "USD")
        m2 = Money(500, "USD")
        result = m1 - m2
        assert result.amount_minor_units == 500
    
    def test_negation(self):
        """Test negating Money."""
        money = Money(1000, "USD")
        result = -money
        assert result.amount_minor_units == -1000
    
    def test_multiplication_int(self):
        """Test multiplying by integer."""
        money = Money(1000, "USD")
        result = money * 3
        assert result.amount_minor_units == 3000
    
    def test_absolute_value(self):
        """Test absolute value."""
        money = Money(-500, "USD")
        result = abs(money)
        assert result.amount_minor_units == 500
        assert result.is_positive()
    
    def test_cannot_add_different_currencies(self):
        """Test that adding different currencies raises error."""
        usd = Money(1000, "USD")
        sar = Money(1000, "SAR")
        with pytest.raises(TypeError, match="Cannot add different currencies"):
            usd + sar
    
    def test_cannot_subtract_different_currencies(self):
        """Test that subtracting different currencies raises error."""
        usd = Money(1000, "USD")
        eur = Money(500, "EUR")
        with pytest.raises(TypeError, match="Cannot subtract different currencies"):
            usd - eur


class TestMoneyComparison:
    """Test Money comparison operations."""
    
    def test_less_than(self):
        """Test less than comparison."""
        m1 = Money(1000, "USD")
        m2 = Money(2000, "USD")
        assert m1 < m2
        assert not m2 < m1
    
    def test_greater_than(self):
        """Test greater than comparison."""
        m1 = Money(2000, "USD")
        m2 = Money(1000, "USD")
        assert m1 > m2
    
    def test_equal(self):
        """Test equality comparison."""
        m1 = Money(1000, "USD")
        m2 = Money(1000, "USD")
        assert m1 == m2
    
    def test_not_equal_different_amount(self):
        """Test inequality with different amounts."""
        m1 = Money(1000, "USD")
        m2 = Money(2000, "USD")
        assert m1 != m2
    
    def test_cannot_compare_different_currencies(self):
        """Test that comparing different currencies raises error."""
        usd = Money(1000, "USD")
        sar = Money(1000, "SAR")
        with pytest.raises(TypeError, match="Cannot compare different currencies"):
            usd < sar


class TestMoneyFormatting:
    """Test Money formatting for display."""
    
    def test_format_usd_english(self):
        """Test USD formatting in English."""
        money = Money(2550, "USD")
        formatted = money.format("en")
        assert "$25.50" in formatted
    
    def test_format_sar_arabic(self):
        """Test SAR formatting in Arabic."""
        money = Money(10000, "SAR")
        formatted = money.format("ar")
        assert "ر.س" in formatted
    
    def test_to_major(self):
        """Test conversion to major units."""
        money = Money(2550, "USD")
        major = money.to_major()
        assert major == 25.50
    
    def test_to_dict(self):
        """Test dictionary serialization."""
        money = Money(2550, "USD")
        data = money.to_dict()
        assert data["amount_minor_units"] == 2550
        assert data["currency_code"] == "USD"
    
    def test_from_dict(self):
        """Test dictionary deserialization."""
        data = {"amount_minor_units": 2550, "currency_code": "USD"}
        money = Money.from_dict(data)
        assert money.amount_minor_units == 2550
        assert money.currency_code == "USD"


class TestMoneyEdgeCases:
    """Test edge cases and boundary conditions."""
    
    def test_zero_comparisons(self):
        """Test zero value comparisons."""
        zero1 = Money.zero("USD")
        zero2 = Money.zero("USD")
        assert zero1 == zero2
        assert zero1.is_zero()
    
    def test_negative_money(self):
        """Test negative money values."""
        money = Money(-500, "USD")
        assert money.is_negative()
        assert not money.is_positive()
        assert not money.is_zero()
    
    def test_hash_consistency(self):
        """Test hash consistency for use in sets/dicts."""
        money = Money(1000, "USD")
        money_set = {money, money}
        assert len(money_set) == 1
        
        money_dict = {money: "value"}
        assert money_dict[money] == "value"
    
    def test_overflow_protection_addition(self):
        """Test overflow protection in addition."""
        max_money = Money(9_000_000_000_000, "USD")
        with pytest.raises(ValueError, match="overflow"):
            max_money + max_money
    
    def test_minor_unit_factor(self):
        """Test minor unit factor calculation."""
        usd = Money(100, "USD")
        assert usd.get_minor_unit_factor() == 100
        
        kwd = Money(100, "KWD")
        assert kwd.get_minor_unit_factor() == 1000
