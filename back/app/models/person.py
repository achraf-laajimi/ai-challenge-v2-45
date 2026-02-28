"""Person model (family member with health data)."""
from datetime import datetime
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, Field


class PersonRole(str, Enum):
    FATHER = "father"
    MOTHER = "mother"
    CHILD = "child"


class PersonBase(BaseModel):
    name: str
    phone: str = ""
    dob: datetime
    gender: str
    blood_type: str = Field(alias="bloodType")
    rh_factor: str = Field(alias="rhFactor")
    height: float  # meters
    weight: float  # kg
    sugar_level: float = Field(alias="sugarLevel")  # g/L
    systolic_bp: int = Field(alias="systolicBP")
    diastolic_bp: int = Field(alias="diastolicBP")
    heart_rate: int = Field(alias="heartRate")
    allergies: List[str] = Field(default_factory=list)
    chronic_diseases: List[str] = Field(default_factory=list, alias="chronicDiseases")
    vaccines_up_to_date: bool = Field(True, alias="vaccinesUpToDate")

    class Config:
        populate_by_name = True


class PersonCreate(PersonBase):
    family_id: str
    role: PersonRole


class PersonUpdate(BaseModel):
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

    class Config:
        populate_by_name = True


class PersonInDB(PersonBase):
    id: str
    family_id: str
    role: PersonRole
    created_at: datetime
    updated_at: datetime

    class Config:
        populate_by_name = True


class Person(BaseModel):
    """Response model (camelCase for Flutter)."""
    id: str
    name: str
    phone: str = ""
    dob: datetime
    gender: str
    bloodType: str
    rhFactor: str
    height: float
    weight: float
    sugarLevel: float
    systolicBP: int
    diastolicBP: int
    heartRate: int
    allergies: List[str] = Field(default_factory=list)
    chronicDiseases: List[str] = Field(default_factory=list)
    vaccinesUpToDate: bool = True
    role: str  # father | mother | child

    @classmethod
    def from_mongo_doc(cls, doc: dict) -> "Person":
        """Build Person from MongoDB document (snake_case keys)."""
        return cls(
            id=doc["_id"],
            name=doc["name"],
            phone=doc.get("phone", ""),
            dob=doc["dob"],
            gender=doc["gender"],
            bloodType=doc.get("blood_type", ""),
            rhFactor=doc.get("rh_factor", ""),
            height=doc["height"],
            weight=doc["weight"],
            sugarLevel=doc.get("sugar_level", 0.0),
            systolicBP=doc.get("systolic_bp", 0),
            diastolicBP=doc.get("diastolic_bp", 0),
            heartRate=doc.get("heart_rate", 0),
            allergies=doc.get("allergies", []),
            chronicDiseases=doc.get("chronic_diseases", []),
            vaccinesUpToDate=doc.get("vaccines_up_to_date", True),
            role=doc.get("role", "child"),
        )
