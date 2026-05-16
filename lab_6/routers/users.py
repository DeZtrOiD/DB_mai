from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from models import User
from schemas import UserCreate, UserUpdate, UserOut
from dependencies import get_db, PaginationParams, apply_sorting
from typing import Optional
from fastapi import Query

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/", response_model=list[UserOut])
def get_users(
    db: Session = Depends(get_db),
    pagination: PaginationParams = Depends(),
    sort: Optional[str] = None,
    order: Optional[str] = Query("asc", pattern="^(asc|desc)$"),
    username: Optional[str] = None,
    email: Optional[str] = None
):
    query = db.query(User)
    if username:
        query = query.filter(User.username.ilike(f"%{username}%"))
    if email:
        query = query.filter(User.email.ilike(f"%{email}%"))
    if order:
        query = apply_sorting(query, sort, order)
    return query.offset(pagination.offset).limit(pagination.limit).all()


@router.get("/{user_id}", response_model=UserOut)
def get_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(404, "User not found")
    return user


@router.post("/", response_model=UserOut, status_code=201)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    new_user = User(
        username=user.username, email=user.email,
        birth_date=user.birth_date, password_hash=user.password
    )
    try:
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        return new_user
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "Username or email already exists")


@router.put("/{user_id}", response_model=UserOut)
def update_user(user_id: int, user_data: UserUpdate,
                db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(404, "User not found")
    for k, v in user_data.model_dump(exclude_unset=True).items():
        setattr(user, k, v)
    try:
        db.commit()
        db.refresh(user)
        return user
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            409, "Update failed: duplicate constraint violation")


@router.delete("/{user_id}", status_code=204)
def delete_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(404, "User not found")
    db.delete(user)
    db.commit()
