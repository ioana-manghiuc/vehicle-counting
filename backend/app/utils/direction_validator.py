"""Validation for direction data."""


def validate_directions(directions: list[dict]) -> None:
    """
    Validate direction data structure and requirements.
    
    Args:
        directions: List of direction dictionaries
        
    Raises:
        ValueError: If validation fails
    """
    for d in directions:
        if "id" not in d:
            raise ValueError("Direction missing id")
            
        if "lines" not in d or len(d["lines"]) < 2:
            raise ValueError(
                f"Direction {d.get('id')} must have at least 2 lines (entry and exit)"
            )
            
        if "from" not in d or "to" not in d:
            raise ValueError(f"Direction {d.get('id')} missing from/to labels")
        
        entry_count = sum(1 for line in d["lines"] if line.get("isEntry", False))
        exit_count = sum(1 for line in d["lines"] if not line.get("isEntry", True))
        
        if entry_count < 1:
            raise ValueError(
                f"Direction {d.get('id')} missing entry line (isEntry=true)"
            )
            
        if exit_count < 1:
            raise ValueError(
                f"Direction {d.get('id')} missing exit line (isEntry=false)"
            )
