"""Gemini Vision meal analysis — isolated tool node."""
import json
from app.models.person import Person
from ..schemas import ImageAnalysisResult
from ..prompts import SYSTEM_MEDICAL_PERSONA, VLM_MEAL_ANALYSIS_PROMPT
from ..llm import call_llm


async def analyze_meal_image(image_b64: str, person: Person) -> ImageAnalysisResult:
    prompt = VLM_MEAL_ANALYSIS_PROMPT.format(patient_data=person.model_dump_json())
    raw = await call_llm(SYSTEM_MEDICAL_PERSONA, prompt, image_b64=image_b64)
    try:
        data = json.loads(raw.strip().strip("```json").strip("```").strip())
        return ImageAnalysisResult(**data)
    except Exception:
        return ImageAnalysisResult(is_compatible=False, reasoning="Failed to analyze image.", alternative_suggestion=None)
