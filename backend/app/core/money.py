"""Money domain model for financial calculations.

This module implements a robust Money value object that:
- Uses integer minor units to avoid floating-point precision issues
- Enforces currency code validation
- Provides deterministic arithmetic operations
- Prevents overflow and underflow
- Supports serialization/deserialization

CRITICAL: Never use floating-point values for canonical money representation.
All financial calculations MUST be performed using minor units.
"""

from dataclasses import dataclass
from typing import Self


# Supported currencies with their minor unit factors
CURRENCY_MINOR_UNITS = {
    "SAR": 2,  # Saudi Riyal - 2 decimal places (halalas)
    "EGP": 2,  # Egyptian Pound - 2 decimal places (piastres)
    "USD": 2,  # US Dollar - 2 decimal places (cents)
    "EUR": 2,  # Euro - 2 decimal places (cents)
    "GBP": 2,  # British Pound - 2 decimal places (pence)
    "AED": 2,  # UAE Dirham - 2 decimal places (fils)
    "KWD": 3,  # Kuwaiti Dinar - 3 decimal places (fils)
}

# Reasonable limits to prevent overflow
MAX_AMOUNT_MINOR_UNITS = 10_000_000_000_000  # 10 trillion in smallest minor units
MIN_AMOUNT_MINOR_UNITS = -MAX_AMOUNT_MINOR_UNITS


@dataclass(frozen=True)
class Money:
    """Immutable Money value object.
    
    Attributes:
        amount_minor_units: Amount in minor units (e.g., cents for USD)
        currency_code: ISO 4217 currency code (e.g., "USD", "SAR")
    
    Examples:
        >>> usd_25_50 = Money(2550, "USD")  # $25.50
        >>> sar_100 = Money(10000, "SAR")   # SAR 100.00
    """
    
    amount_minor_units: int
    currency_code: str
    
    def __post_init__(self):
        """Validate money attributes after initialization."""
        # Validate currency code
        if self.currency_code not in CURRENCY_MINOR_UNITS:
            raise ValueError(
                f"Invalid currency code: {self.currency_code}. "
                f"Must be one of: {', '.join(CURRENCY_MINOR_UNITS.keys())}"
            )
        
        # Validate amount range
        if self.amount_minor_units < MIN_AMOUNT_MINOR_UNITS:
            raise ValueError(
                f"Amount too negative: {self.amount_minor_units}. "
                f"Minimum: {MIN_AMOUNT_MINOR_UNITS}"
            )
        
        if self.amount_minor_units > MAX_AMOUNT_MINOR_UNITS:
            raise ValueError(
                f"Amount too large: {self.amount_minor_units}. "
                f"Maximum: {MAX_AMOUNT_MINOR_UNITS}"
            )
    
    @classmethod
    def from_major(cls, amount: float | str, currency_code: str) -> Self:
        """Create Money from major unit representation.
        
        WARNING: Float conversion can introduce precision errors.
        Prefer using from_minor_units() when possible.
        
        Args:
            amount: Amount in major units (e.g., 25.50 for $25.50)
            currency_code: ISO 4217 currency code
            
        Returns:
            Money instance
            
        Raises:
            ValueError: If conversion would lose precision
        """
        if isinstance(amount, float):
            # Convert float to string first to preserve precision
            amount_str = f"{amount:.10f}".rstrip('0').rstrip('.')
        else:
            amount_str = str(amount)
        
        # Parse as decimal to avoid float issues
        from decimal import Decimal, InvalidOperation
        
        try:
            decimal_amount = Decimal(amount_str)
        except InvalidOperation:
            raise ValueError(f"Invalid amount format: {amount}")
        
        minor_unit_factor = 10 ** CURRENCY_MINOR_UNITS[currency_code]
        minor_units = int(decimal_amount * minor_unit_factor)
        
        return cls(minor_units, currency_code)
    
    @classmethod
    def zero(cls, currency_code: str) -> Self:
        """Create a zero-value Money instance.
        
        Args:
            currency_code: ISO 4217 currency code
            
        Returns:
            Money instance with zero value
        """
        return cls(0, currency_code)
    
    def is_zero(self) -> bool:
        """Check if this Money represents zero value."""
        return self.amount_minor_units == 0
    
    def is_positive(self) -> bool:
        """Check if this Money represents a positive value."""
        return self.amount_minor_units > 0
    
    def is_negative(self) -> bool:
        """Check if this Money represents a negative value."""
        return self.amount_minor_units < 0
    
    def __add__(self, other: Self) -> Self:
        """Add two Money values.
        
        Args:
            other: Money value to add
            
        Returns:
            New Money instance with sum
            
        Raises:
            TypeError: If currencies don't match
            ValueError: If result overflows
        """
        if not isinstance(other, Money):
            return NotImplemented
        
        if self.currency_code != other.currency_code:
            raise TypeError(
                f"Cannot add different currencies: {self.currency_code} + {other.currency_code}"
            )
        
        result = self.amount_minor_units + other.amount_minor_units
        
        if result > MAX_AMOUNT_MINOR_UNITS or result < MIN_AMOUNT_MINOR_UNITS:
            raise ValueError("Addition result would overflow")
        
        return self.__class__(result, self.currency_code)
    
    def __sub__(self, other: Self) -> Self:
        """Subtract two Money values.
        
        Args:
            other: Money value to subtract
            
        Returns:
            New Money instance with difference
            
        Raises:
            TypeError: If currencies don't match
            ValueError: If result overflows
        """
        if not isinstance(other, Money):
            return NotImplemented
        
        if self.currency_code != other.currency_code:
            raise TypeError(
                f"Cannot subtract different currencies: {self.currency_code} - {other.currency_code}"
            )
        
        result = self.amount_minor_units - other.amount_minor_units
        
        if result > MAX_AMOUNT_MINOR_UNITS or result < MIN_AMOUNT_MINOR_UNITS:
            raise ValueError("Subtraction result would overflow")
        
        return self.__class__(result, self.currency_code)
    
    def __neg__(self) -> Self:
        """Negate this Money value.
        
        Returns:
            New Money instance with negated value
            
        Raises:
            ValueError: If negation would overflow
        """
        result = -self.amount_minor_units
        
        if result > MAX_AMOUNT_MINOR_UNITS or result < MIN_AMOUNT_MINOR_UNITS:
            raise ValueError("Negation result would overflow")
        
        return self.__class__(result, self.currency_code)
    
    def __mul__(self, multiplier: int | float) -> Self:
        """Multiply Money by a scalar.
        
        Args:
            multiplier: Scalar to multiply by (should be integer for exact results)
            
        Returns:
            New Money instance with product
            
        Raises:
            ValueError: If result overflows
        """
        if isinstance(multiplier, float):
            # For float multipliers, round to nearest minor unit
            from decimal import Decimal
            result = int(Decimal(str(self.amount_minor_units)) * Decimal(str(multiplier)))
        else:
            result = self.amount_minor_units * multiplier
        
        if result > MAX_AMOUNT_MINOR_UNITS or result < MIN_AMOUNT_MINOR_UNITS:
            raise ValueError("Multiplication result would overflow")
        
        return self.__class__(result, self.currency_code)
    
    def __abs__(self) -> Self:
        """Get absolute value of this Money.
        
        Returns:
            New Money instance with absolute value
        """
        return self.__class__(abs(self.amount_minor_units), self.currency_code)
    
    def __lt__(self, other: Self) -> bool:
        """Compare if this Money is less than another."""
        if not isinstance(other, Money):
            return NotImplemented
        
        if self.currency_code != other.currency_code:
            raise TypeError(
                f"Cannot compare different currencies: {self.currency_code} vs {other.currency_code}"
            )
        
        return self.amount_minor_units < other.amount_minor_units
    
    def __le__(self, other: Self) -> bool:
        """Compare if this Money is less than or equal to another."""
        if not isinstance(other, Money):
            return NotImplemented
        
        if self.currency_code != other.currency_code:
            raise TypeError(
                f"Cannot compare different currencies: {self.currency_code} vs {other.currency_code}"
            )
        
        return self.amount_minor_units <= other.amount_minor_units
    
    def __gt__(self, other: Self) -> bool:
        """Compare if this Money is greater than another."""
        if not isinstance(other, Money):
            return NotImplemented
        
        if self.currency_code != other.currency_code:
            raise TypeError(
                f"Cannot compare different currencies: {self.currency_code} vs {other.currency_code}"
            )
        
        return self.amount_minor_units > other.amount_minor_units
    
    def __ge__(self, other: Self) -> bool:
        """Compare if this Money is greater than or equal to another."""
        if not isinstance(other, Money):
            return NotImplemented
        
        if self.currency_code != other.currency_code:
            raise TypeError(
                f"Cannot compare different currencies: {self.currency_code} vs {other.currency_code}"
            )
        
        return self.amount_minor_units >= other.amount_minor_units
    
    def __eq__(self, other: object) -> bool:
        """Check equality with another Money."""
        if not isinstance(other, Money):
            return False
        
        return (
            self.amount_minor_units == other.amount_minor_units
            and self.currency_code == other.currency_code
        )
    
    def __hash__(self) -> int:
        """Generate hash for use in sets and dicts."""
        return hash((self.amount_minor_units, self.currency_code))
    
    def to_major(self) -> float:
        """Convert to major unit representation.
        
        WARNING: This conversion may lose precision for display purposes only.
        Never use the result for further calculations.
        
        Returns:
            Amount in major units (e.g., 25.50 for $25.50)
        """
        minor_unit_factor = 10 ** CURRENCY_MINOR_UNITS[self.currency_code]
        return self.amount_minor_units / minor_unit_factor
    
    def format(self, locale: str = "en") -> str:
        """Format Money for display.
        
        Args:
            locale: Locale code ("en" or "ar")
            
        Returns:
            Formatted string (e.g., "$25.50" or "٢٥٫٥٠ ر.س")
        """
        from decimal import Decimal
        
        major_amount = Decimal(self.amount_minor_units) / (
            10 ** CURRENCY_MINOR_UNITS[self.currency_code]
        )
        
        # Currency symbols and formats
        currency_formats = {
            "SAR": {"en": "SAR", "ar": "ر.س"},
            "EGP": {"en": "EGP", "ar": "ج.م"},
            "USD": {"en": "$", "ar": "$"},
            "EUR": {"en": "€", "ar": "€"},
            "GBP": {"en": "£", "ar": "£"},
            "AED": {"en": "AED", "ar": "د.إ"},
            "KWD": {"en": "KWD", "ar": "د.ك"},
        }
        
        symbol = currency_formats.get(self.currency_code, {}).get(locale, self.currency_code)
        
        # Format number with appropriate decimal places
        decimal_places = CURRENCY_MINOR_UNITS[self.currency_code]
        format_str = f"{{:.{decimal_places}f}}"
        
        if locale == "ar":
            # Arabic numeral formatting
            formatted = format_str.format(float(major_amount))
            # Convert to Arabic-Indic digits
            arabic_digits = "٠١٢٣٤٥٦٧٨٩"
            formatted_arabic = "".join(
                arabic_digits[int(c)] if c.isdigit() else c 
                for c in formatted
            )
            # Replace decimal point with Arabic decimal separator
            formatted_arabic = formatted_arabic.replace(".", "٫")
            return f"{formatted_arabic} {symbol}"
        else:
            return f"{symbol}{format_str.format(float(major_amount))}"
    
    def to_dict(self) -> dict:
        """Convert to dictionary for serialization."""
        return {
            "amount_minor_units": self.amount_minor_units,
            "currency_code": self.currency_code,
        }
    
    @classmethod
    def from_dict(cls, data: dict) -> Self:
        """Create from dictionary.
        
        Args:
            data: Dictionary with amount_minor_units and currency_code
            
        Returns:
            Money instance
        """
        return cls(
            amount_minor_units=data["amount_minor_units"],
            currency_code=data["currency_code"],
        )
    
    def get_minor_unit_factor(self) -> int:
        """Get the factor for converting between major and minor units.
        
        Returns:
            Factor (e.g., 100 for USD, 1000 for KWD)
        """
        return 10 ** CURRENCY_MINOR_UNITS[self.currency_code]
