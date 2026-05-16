from fastapi import FastAPI
from config import settings
from routers import users, playlists, ratings, reports

app = FastAPI(
    title="Lab 6: RESTful API for PostgreSQL",
    description="API developed according to Lab 6 requirements",
    version="1.0.0"
)


app.include_router(users.router, prefix=settings.API_PREFIX)
app.include_router(playlists.router, prefix=settings.API_PREFIX)
app.include_router(ratings.router, prefix=settings.API_PREFIX)
app.include_router(reports.router, prefix=settings.API_PREFIX)


@app.get("/health")
def health_check():
    return {"status": "ok"}
