"""Person model (family member with health data)."""
from datetime import datetime
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field


class PersonRole(str, Enum):
    FATHER = "father"
    MOTHER = "mother"
    CHILD = "child"


# Shared config: Python uses snake_case, JSON/Flutter receives camelCase aliases
_SHARED = ConfigDict(populate_by_name=True, serialize_by_alias=True)


class PersonBase(BaseModel):
    model_config = _SHARED

    name: str
    phone: str = ""
    dob: datetime
    gender: str
    blood_type: str = Field(alias="bloodType")
    rh_factor: str = Field(alias="rhFactor")
    height: float = Field(gt=0, le=3.0)                            # metres
    weight: float = Field(gt=0, le=500.0)                          # kg
    sugar_level: float = Field(alias="sugarLevel", ge=0.0, le=30.0)   # g/L
    systolic_bp: int = Field(alias="systolicBP", ge=50, le=300)       # mmHg
    diastolic_bp: int = Field(alias="diastolicBP", ge=30, le=200)     # mmHg
    heart_rate: int = Field(alias="heartRate", ge=20, le=300)         # bpm
    allergies: List[str] = Field(default_factory=list)
    chronic_diseases: List[str] = Field(default_factory=list, alias="chronicDiseases")
    vaccines_up_to_date: bool = Field(True, alias="vaccinesUpToDate")


class PersonCreate(PersonBase):
    family_id: str
    role: PersonRole


class PersonUpdate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    name: Optional[str] = None
    phone: Optional[str] = None
    dob: Optional[datetime] = None
    gender: Optional[str] = None
    blood_type: Optional[str] = None
    rh_factor: Optional[str] = None
    height: Optional[float] = None
    weight: Optional[float] = None
    sugar_level: Optional[float] = None
    systolic_bp: Optional[int] = None
    diastolic_bp: Optional[int] = None
    heart_rate: Optional[int] = None
    allergies: Optional[List[str]] = None
    chronic_diseases: Optional[List[str]] = None
    vaccines_up_to_date: Optional[bool] = None


class PersonInDB(PersonBase):
    id: str
    family_id: str
    role: PersonRole
    created_at: datetime
    updated_at: datetime


class Person(PersonBase):
    """Complete patient model — inherits all vitals from PersonBase.

    Python code uses snake_case (e.g. person.sugar_level).
    JSON serialization produces camelCase for Flutter (e.g. sugarLevel).
    """

    id: str
    family_id: str = ""
    role: str  # father | mother | child

    @classmethod
    def from_mongo_doc(cls, doc: dict) -> "Person":
        """Build Person from a MongoDB document (snake_case keys)."""
        return cls(
            id=str(doc["_id"]),
            name=doc["name"],
            phone=doc.get("phone", ""),
            dob=doc["dob"],
            gender=doc["gender"],
            blood_type=doc.get("blood_type", ""),
            rh_factor=doc.get("rh_factor", ""),
            height=doc.get("height", 1.7),
            weight=doc.get("weight", 70.0),
            sugar_level=doc.get("sugar_level", 1.0),
            systolic_bp=doc.get("systolic_bp", 120),
            diastolic_bp=doc.get("diastolic_bp", 80),
            heart_rate=doc.get("heart_rate", 70),
            allergies=doc.get("allergies", []),
            chronic_diseases=doc.get("chronic_diseases", []),
            vaccines_up_to_date=doc.get("vaccines_up_to_date", True),
            role=doc.get("role", "child"),
            family_id=str(doc.get("family_id", "")),
        )
