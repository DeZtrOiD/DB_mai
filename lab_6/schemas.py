
from pydantic import BaseModel, Field, field_validator
from typing import Optional
from datetime import date, datetime


class UserBase(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: str
    birth_date: Optional[date] = None

    @field_validator("email")
    def validate_email(cls, v):
        if "@" not in v or "." not in v.split("@")[-1]:
            raise ValueError("Invalid email format")
        return v


class UserCreate(UserBase):
    password: str = Field(..., min_length=6)


class UserUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None
    birth_date: Optional[date] = None


class UserOut(UserBase):
    user_id: int

    class Config:
        from_attributes = True


class PlaylistBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = None
    is_public: bool = False


class PlaylistCreate(PlaylistBase):
    user_id: int


class PlaylistOut(PlaylistBase):
    playlist_id: int
    user_id: int

    class Config:
        from_attributes = True


class RatingCreate(BaseModel):
    user_id: int
    item_id: int
    rating_value: int = Field(..., ge=1, le=10)
    review_text: Optional[str] = None


class RatingOut(BaseModel):
    user_id: int
    item_id: int
    rating_value: int
    review_text: Optional[str]
    rated_at: datetime

    class Config:
        from_attributes = True
