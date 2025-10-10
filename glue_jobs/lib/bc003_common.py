"""
Shared helpers for Glue jobs (BC003).
Implementations will be filled during Silver/Gold phases.
"""

def parse_date_ddMMyy(s: str):
    """
    Convert dd-MM-yy -> yyyy-MM-dd (ISO).
    Return None if invalid; Silver will handle nulls per business rules.
    """
    return None  # Placeholder

def dedupe_by_key(df, key_cols, order_cols):
    """
    PySpark: keep latest row per key using window + row_number().
    We'll implement in Silver when we have the final schemas.
    """
    return df  # Placeholder