from typing import List, Optional
from pydantic import BaseModel, Field

class Location(BaseModel):
    lat: float
    lng: float

class AssistantRequest(BaseModel):
    person_id: Optional[str] = None
    family_id: Optional[str] = None
    location: Optional[Location] = None
    image_base64: Optional[str] = None
    user_message: Optional[str] = None

class Place(BaseModel):
    name: str
    address: Optional[str] = None
    place_id: Optional[str] = None
    open_now: Optional[bool] = None
    lat: Optional[float] = None
    lng: Optional[float] = None

class NutritionSuggestion(BaseModel):
    title: str
    description: str
    shopping_list: List[str] = Field(default_factory=list)

class ImageAnalysisResult(BaseModel):
    is_compatible: bool
    reasoning: str
    alternative_suggestion: Optional[str] = None

class AssistantResponse(BaseModel):
    person_id: Optional[str] = None
    doctors: List[Place] = Field(default_factory=list)
    nutrition: Optional[NutritionSuggestion] = None
    meal_analysis: Optional[ImageAnalysisResult] = None
    note: Optional[str] = None