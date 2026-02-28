"""User model for authentication."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr


class UserBase(BaseModel):
    email: EmailStr


class UserCreate(UserBase):
    password: str
    family_code: Optional[str] = None  # None = create new family; set = join existing


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class User(UserBase):
    id: str
    family_id: str
    created_at: datetime

    class Config:
        from_attributes = True


class UserInDB(UserBase):
    hashed_password: str
    family_id: str
    created_at: datetime
