"""User model for authentication."""
from datetime import datetime

from pydantic import BaseModel


class UserBase(BaseModel):
    name: str


class UserCreate(UserBase):
    password: str


class UserLogin(BaseModel):
    name: str
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
