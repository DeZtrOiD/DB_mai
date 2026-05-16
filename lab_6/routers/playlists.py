from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from models import Playlist
from schemas import PlaylistCreate, PlaylistOut
from dependencies import get_db, PaginationParams


router = APIRouter(prefix="/playlists", tags=["Playlists"])


@router.get("/", response_model=list[PlaylistOut])
def get_playlists(
        db: Session = Depends(get_db), pagination: PaginationParams = Depends()
        ):
    return (
        db.query(Playlist).offset(pagination.offset)
        .limit(pagination.limit)
        .all())


@router.get("/{playlist_id}", response_model=PlaylistOut)
def get_playlist(playlist_id: int, db: Session = Depends(get_db)):
    pl = db.query(Playlist).filter(Playlist.playlist_id == playlist_id).first()
    if not pl:
        raise HTTPException(404, "Playlist not found")
    return pl


@router.post("/", response_model=PlaylistOut, status_code=201)
def create_playlist(pl: PlaylistCreate, db: Session = Depends(get_db)):
    new_pl = Playlist(**pl.model_dump())
    db.add(new_pl)
    db.commit()
    db.refresh(new_pl)
    return new_pl


@router.delete("/{playlist_id}", status_code=204)
def delete_playlist(playlist_id: int, db: Session = Depends(get_db)):
    pl = db.query(Playlist).filter(Playlist.playlist_id == playlist_id).first()
    if not pl:
        raise HTTPException(404, "Playlist not found")
    db.delete(pl)
    db.commit()
