import base64
import json
import httpx
from typing import List, Optional
from google import genai
from google.genai import types as genai_types
from app.config import settings
from app.models.person import Person
from .schemas import Location, Place, NutritionSuggestion, ImageAnalysisResult
from .prompts import SYSTEM_MEDICAL_PERSONA, DOCTOR_SPECIALTY_PROMPT, NUTRITION_REASONING_PROMPT, VLM_MEAL_ANALYSIS_PROMPT

_gemini_client = genai.Client(api_key=settings.gemini_api_key)
_MODEL = "gemini-2.5-flash"

async def _call_llm(system_prompt: str, user_prompt: str, image_b64: Optional[str] = None) -> str:
    """
    Appel asynchrone à l'API Google Gemini via le nouveau SDK google-genai.
    Gère les requêtes textuelles et multimodales (vision).
    """
    try:
        parts: list = [user_prompt]

        if image_b64:
            mime_type = "image/jpeg"
            if image_b64.startswith("data:image"):
                header, image_b64 = image_b64.split(",", 1)
                mime_type = header.split(";")[0].split(":")[1]
            parts.append(genai_types.Part.from_bytes(
                data=base64.b64decode(image_b64),
                mime_type=mime_type,
            ))

        response = await _gemini_client.aio.models.generate_content(
            model=_MODEL,
            contents=parts,
            config=genai_types.GenerateContentConfig(
                system_instruction=system_prompt,
                temperature=0.2,
            ),
        )

        return response.text

    except Exception as e:
        print(f"Erreur API Gemini : {str(e)}")
        raise ValueError(f"Échec de la génération IA : {str(e)}")

async def get_doctor_specialty(person: Person) -> str:
    patient_data = person.model_dump_json()
    prompt = DOCTOR_SPECIALTY_PROMPT.format(patient_data=patient_data)
    
    # Appel LLM pour raisonner sur la spécialité
    specialty = await _call_llm(SYSTEM_MEDICAL_PERSONA, prompt)
    return specialty.strip() if specialty else "General Practitioner"

async def get_nutrition_recommendation(person: Person) -> NutritionSuggestion:
    patient_data = person.model_dump_json()
    prompt = NUTRITION_REASONING_PROMPT.format(patient_data=patient_data)
    
    raw_response = await _call_llm(SYSTEM_MEDICAL_PERSONA, prompt)
    try:
        # Nettoyage et parsing du JSON renvoyé par le LLM
        clean_json = raw_response.strip("```json").strip("```").strip()
        data = json.loads(clean_json)
        return NutritionSuggestion(**data)
    except Exception:
        # Fallback de sécurité
        return NutritionSuggestion(title="Balanced Diet", description="Please consult a human doctor.", shopping_list=["Water", "Vegetables"])

async def analyze_meal_image(image_b64: str, person: Person) -> ImageAnalysisResult:
    patient_data = person.model_dump_json()
    prompt = VLM_MEAL_ANALYSIS_PROMPT.format(patient_data=patient_data)
    
    raw_response = await _call_llm(SYSTEM_MEDICAL_PERSONA, prompt, image_b64=image_b64)
    try:
        clean_json = raw_response.strip("```json").strip("```").strip()
        data = json.loads(clean_json)
        return ImageAnalysisResult(**data)
    except Exception:
        return ImageAnalysisResult(is_compatible=False, reasoning="Failed to analyze image.", alternative_suggestion=None)

async def classify_intent(user_message: str, person: Person) -> dict:
    """Use LLM to decide which tools to invoke based on what the user actually asked."""
    from .prompts import INTENT_CLASSIFICATION_PROMPT
    from datetime import date
    age = (date.today() - person.dob.date()).days // 365 if person.dob else "?"
    patient_summary = f"age={age}, sugar={person.sugarLevel}, bp={person.systolicBP}/{person.diastolicBP}, diseases={person.chronicDiseases}"
    prompt = INTENT_CLASSIFICATION_PROMPT.format(
        user_message=user_message,
        patient_summary=patient_summary,
    )
    raw = await _call_llm(SYSTEM_MEDICAL_PERSONA, prompt)
    try:
        clean = raw.strip().strip("```json").strip("```").strip()
        return json.loads(clean)
    except Exception:
        # Fallback: infer from keywords
        msg = user_message.lower()
        return {
            "suggest_doctors": any(w in msg for w in ["médecin", "docteur", "spécialiste", "clinique", "doctor", "specialist"]),
            "suggest_nutrition": any(w in msg for w in ["nutrition", "repas", "alimentation", "régime", "manger", "diet", "food", "meal"]),
            "direct_response": "",
        }


async def query_google_places(api_key: str, location: Location, query: str) -> List[Place]:
    url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
    params = {
        "key": api_key,
        "location": f"{location.lat},{location.lng}",
        "rankby": "distance",
        "keyword": query,
    }
    async with httpx.AsyncClient(timeout=10.0) as client:
        r = await client.get(url, params=params)
        data = r.json()
        
    places = []
    for p in data.get("results", [])[:6]:
        geo = p.get("geometry", {}).get("location", {})
        places.append(Place(
            name=p.get("name"),
            address=p.get("vicinity") or p.get("formatted_address"),
            place_id=p.get("place_id"),
            open_now=(p.get("opening_hours", {}).get("open_now") if p.get("opening_hours") else None),
            lat=geo.get("lat"),
            lng=geo.get("lng"),
        ))
    return places