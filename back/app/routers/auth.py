"""Auth: register, login with JWT (name + password, no family_code)."""
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from bson import ObjectId

from app.database import get_database, get_users_collection, get_families_collection
from app.models.user import UserCreate, UserLogin
from app.utils.security import hash_password, verify_password, create_access_token
from app.utils.dependencies import get_current_user_id

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=dict)
async def register(data: UserCreate):
    """Register: create user and a new family."""
    db = await get_database()
    users = get_users_collection(db)
    families = get_families_collection(db)

    existing = await users.find_one({"name": data.name})
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Name already registered",
        )

    family_id = str(ObjectId())
    await families.insert_one({
        "_id": family_id,
        "family_history": [],
        "created_at": datetime.utcnow(),
    })

    user_id = str(ObjectId())
    await users.insert_one({
        "_id": user_id,
        "name": data.name,
        "hashed_password": hash_password(data.password),
        "family_id": family_id,
        "created_at": datetime.utcnow(),
    })

    token = create_access_token(subject=user_id)
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": user_id,
            "name": data.name,
            "family_id": family_id,
        },
    }


@router.post("/login", response_model=dict)
async def login(data: UserLogin):
    """Login: returns JWT access_token."""
    db = await get_database()
    users = get_users_collection(db)

    user = await users.find_one({"name": data.name})
    if not user or not verify_password(data.password, user["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid name or password",
        )

    user_id = str(user["_id"])
    token = create_access_token(subject=user_id)
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": user_id,
            "name": user["name"],
            "family_id": user["family_id"],
        },
    }


@router.get("/me", response_model=dict)
async def me(user_id: str = Depends(get_current_user_id)):
    """Current user info (requires Bearer token)."""
    db = await get_database()
    users = get_users_collection(db)
    user = await users.find_one({"_id": user_id})
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return {
        "id": str(user["_id"]),
        "name": user["name"],
        "family_id": user["family_id"],
    }
