from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from models import VContentRatings, VUserActivity, VTopContent, Rating
from models import Playlist
from dependencies import get_db

router = APIRouter(prefix="/reports", tags=["Reports & Views"])


@router.get("/content-ratings")
def get_content_ratings(db: Session = Depends(get_db)):
    return db.query(VContentRatings).all()


@router.get("/user-activity")
def get_user_activity(db: Session = Depends(get_db)):
    return db.query(VUserActivity).all()


@router.get("/top-content")
def get_top_content(db: Session = Depends(get_db)):
    return db.query(VTopContent).all()


@router.get("/platform-stats")
def get_platform_stats(db: Session = Depends(get_db)):
    total_users = db.query(func.count(Rating.user_id)).scalar()
    avg_rating = db.query(func.avg(Rating.rating_value)).scalar()
    total_playlists = db.query(func.count(Playlist.playlist_id)).scalar()
    return {
        "total_ratings": total_users,
        "average_rating": float(avg_rating) if avg_rating else 0,
        "total_playlists": total_playlists
        }
