"""Family model."""
from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field

from app.models.person import Person


class FamilyBase(BaseModel):
    family_history: List[str] = Field(default_factory=list, alias="familyHistory")

    class Config:
        populate_by_name = True


class FamilyCreate(FamilyBase):
    pass


class FamilyUpdate(BaseModel):
    family_history: Optional[List[str]] = None

    class Config:
        populate_by_name = True


class FamilyResponse(BaseModel):
    """Family with members (father, mother, children) for API response."""
    model_config = ConfigDict(populate_by_name=True, serialize_by_alias=True)

    id: str
    family_code: str = Field(alias="familyCode")
    family_history: List[str] = Field(default_factory=list, alias="familyHistory")
    father: Optional[Person] = None
    mother: Optional[Person] = None
    children: List[Person] = Field(default_factory=list)
    created_at: datetime = Field(alias="createdAt")
