"""Family Health API - FastAPI app."""
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import get_database, close_database
from app.routers import auth, families, persons


@asynccontextmanager
async def lifespan(app: FastAPI):
    await get_database()
    yield
    await close_database()


app = FastAPI(
    title=settings.app_name,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api")
app.include_router(families.router, prefix="/api")
app.include_router(persons.router, prefix="/api")


@app.get("/health")
def health():
    return {"status": "ok"}
