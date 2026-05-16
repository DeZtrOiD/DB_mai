
from database import SessionLocal
from typing import Optional
from fastapi import Query


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


class PaginationParams:
    def __init__(
            self, page: int = Query(1, ge=1),
            limit: int = Query(10, ge=1, le=100)
            ):
        self.page = page
        self.limit = limit
        self.offset = (page - 1) * limit


def apply_sorting(
        query, sort_field: Optional[str] = None,
        order: str = Query("asc", pattern="^(asc|desc)$")
        ):
    if not sort_field:
        return query
    col = getattr(query.column_descriptions[0]["entity"], sort_field, None)
    if not col:
        return query
    return query.order_by(col.desc() if order == "desc" else col.asc())
