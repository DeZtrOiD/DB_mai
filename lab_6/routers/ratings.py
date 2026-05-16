from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import DBAPIError
from pydantic import BaseModel, Field
from dependencies import get_db

router = APIRouter(prefix="/procedures", tags=["Stored Procedures"])


class AddRatingInput(BaseModel):
    user_id: int
    item_id: int
    rating: int = Field(..., ge=1, le=10)
    review: str | None = None


class AddToCollectionInput(BaseModel):
    user_id: int
    item_id: int


@router.post("/add-rating", status_code=status.HTTP_201_CREATED)
def call_add_rating(data: AddRatingInput, db: Session = Depends(get_db)):
    """Вызов lab_4.add_rating"""
    try:
        db.execute(
            text("""
                SELECT lab_4.add_rating(
                    :p_user_id::BIGINT, 
                    :p_item_id::BIGINT, 
                    :p_rating::SMALLINT, 
                    :p_review::TEXT
                )
            """),
            {
                "p_user_id": data.user_id,
                "p_item_id": data.item_id,
                "p_rating": data.rating,
                "p_review": data.review
            }
        )
        db.commit()
        return {"status": "success",
                "message": "Rating added via stored function"}
    except DBAPIError as e:
        db.rollback()
        err_msg = str(e.orig) if hasattr(e, 'orig') else str(e)

        if "User not found" in err_msg or "Content item not found" in err_msg:
            raise HTTPException(status_code=404, detail=err_msg)
        elif "already rated" in err_msg.lower():
            raise HTTPException(
                status_code=409,
                detail="User already rated this item")
        elif "Rating must be" in err_msg:
            raise HTTPException(status_code=400, detail=err_msg)
        raise HTTPException(
            status_code=500,
            detail=f"Database error: {err_msg}")


@router.post("/add-to-collection", status_code=status.HTTP_201_CREATED)
def call_add_to_collection(
        data: AddToCollectionInput,
        db: Session = Depends(get_db)
        ):
    """Вызов lab_4.add_to_collection"""
    try:
        db.execute(
            text("SELECT lab_4.add_to_collection(:p_user_id, :p_item_id)"),
            {"p_user_id": data.user_id, "p_item_id": data.item_id}
        )
        db.commit()
        return {
            "status": "success",
            "message": "Item added to collection via stored function"
        }
    except DBAPIError as e:
        db.rollback()
        err_msg = str(e.orig) if hasattr(e, 'orig') else str(e)

        if "already in collection" in err_msg.lower():
            raise HTTPException(
                status_code=409,
                detail="Item already in collection"
            )
        elif "Invalid user or item" in err_msg:
            raise HTTPException(status_code=400, detail=err_msg)
        raise HTTPException(
            status_code=500,
            detail=f"Database error: {err_msg}"
        )


@router.get("/items/{item_id}/avg-rating")
def call_get_avg_rating(item_id: int, db: Session = Depends(get_db)):
    """Вызов lab_4.get_avg_rating"""
    try:
        result = db.execute(
            text("SELECT lab_4.get_avg_rating(:p_item_id)"),
            {"p_item_id": item_id}
        ).scalar()

        return {
            "item_id": item_id,
            "average_rating": float(result) if result is not None else 0.0
            }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to calculate average rating: {str(e)}"
        )
