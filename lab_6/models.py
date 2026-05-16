from sqlalchemy import Column, Integer, String, Date, Boolean, ForeignKey
from sqlalchemy import SmallInteger, Text, func, DateTime
from database import Base


class User(Base):
    __tablename__ = "users"
    __table_args__ = {"schema": "lab_4"}
    user_id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(50), unique=True, nullable=False)
    birth_date = Column(Date)
    email = Column(String(255), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)


class Playlist(Base):
    __tablename__ = "playlists"
    __table_args__ = {"schema": "lab_4"}
    playlist_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(
        Integer, ForeignKey("lab_4.users.user_id"),
        nullable=False
    )
    name = Column(String(100), nullable=False)
    description = Column(Text)
    is_public = Column(Boolean, default=False)


class Rating(Base):
    __tablename__ = "ratings"
    __table_args__ = {"schema": "lab_4"}
    user_id = Column(
        Integer, ForeignKey("lab_4.users.user_id"),
        primary_key=True
    )
    item_id = Column(Integer, ForeignKey(
        "lab_4.content_items.item_id"), primary_key=True
    )
    rating_value = Column(SmallInteger, nullable=False)
    review_text = Column(Text)
    rated_at = Column(DateTime(timezone=True), server_default=func.now())


# === Представления ===
class VContentRatings(Base):
    __tablename__ = "v_content_ratings"
    __table_args__ = {"schema": "lab_4"}
    item_id = Column(Integer, primary_key=True)
    title = Column(String(255))
    ratings_count = Column(Integer)
    avg_rating = Column(String)


class VUserActivity(Base):
    __tablename__ = "v_user_activity"
    __table_args__ = {"schema": "lab_4"}
    user_id = Column(Integer, primary_key=True)
    username = Column(String(50))
    items_in_collection = Column(Integer)
    rated_items = Column(Integer)
    playlists_count = Column(Integer)


class VTopContent(Base):
    __tablename__ = "v_top_content"
    __table_args__ = {"schema": "lab_4"}
    item_id = Column(Integer, primary_key=True)
    title = Column(String(255))
    avg_rating = Column(String)
    ratings_count = Column(Integer)
