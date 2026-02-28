"""Auth: register, login with JWT."""
import secrets
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from bson import ObjectId

from app.config import settings
from app.database import get_database, get_users_collection, get_families_collection
from app.models.user import UserCreate, UserLogin
from app.utils.security import hash_password, verify_password, create_access_token
from app.utils.dependencies import get_current_user_id

router = APIRouter(prefix="/auth", tags=["auth"])


def _generate_family_code() -> str:
    return "FAM-" + secrets.token_hex(4).upper()


@router.post("/register", response_model=dict)
async def register(data: UserCreate):
    """Register: create user. If family_code provided, join family; else create new family."""
    db = await get_database()
    users = get_users_collection(db)
    families = get_families_collection(db)

    existing = await users.find_one({"email": data.email})
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    family_id: str
    if data.family_code:
        fam = await families.find_one({"family_code": data.family_code})
        if not fam:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid family code",
            )
        family_id = str(fam["_id"])
    else:
        family_id = str(ObjectId())
        family_code = _generate_family_code()
        await families.insert_one({
            "_id": family_id,
            "family_code": family_code,
            "family_history": [],
            "created_at": datetime.utcnow(),
        })

    user_id = str(ObjectId())
    await users.insert_one({
        "_id": user_id,
        "email": data.email,
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
            "email": data.email,
            "family_id": family_id,
        },
    }


@router.post("/login", response_model=dict)
async def login(data: UserLogin):
    """Login: returns JWT access_token."""
    db = await get_database()
    users = get_users_collection(db)

    user = await users.find_one({"email": data.email})
    if not user or not verify_password(data.password, user["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    user_id = str(user["_id"])
    token = create_access_token(subject=user_id)
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": user_id,
            "email": user["email"],
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
        "email": user["email"],
        "family_id": user["family_id"],
    }
