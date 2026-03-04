"""Generate a personalised nutrition plan for a patient."""
import json

from app.models.person import Person
from ..schemas import NutritionSuggestion
from ..prompts import SYSTEM_MEDICAL_PERSONA, NUTRITION_REASONING_PROMPT
from ..llm import call_llm


async def get_nutrition(person: Person) -> NutritionSuggestion:
    raw = await call_llm(
        SYSTEM_MEDICAL_PERSONA,
        NUTRITION_REASONING_PROMPT.format(patient_data=person.model_dump_json()),
    )
    try:
        return NutritionSuggestion(**json.loads(raw.strip().strip("```json").strip("```").strip()))
    except Exception:
        return NutritionSuggestion(title="Balanced Diet", description="Please consult a doctor.", shopping_list=["Water", "Vegetables"])
