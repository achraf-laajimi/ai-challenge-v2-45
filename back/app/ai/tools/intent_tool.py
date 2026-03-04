"""Classify user intent → decide which agent nodes to activate."""
import json
from datetime import date

from app.models.person import Person
from ..prompts import SYSTEM_MEDICAL_PERSONA, INTENT_CLASSIFICATION_PROMPT
from ..llm import call_llm


async def classify_intent(user_message: str, person: Person) -> dict:
    age = (date.today() - person.dob.date()).days // 365 if person.dob else "?"
    summary = (
        f"age={age}, sugar={person.sugar_level} g/L, "
        f"bp={person.systolic_bp}/{person.diastolic_bp} mmHg, "
        f"hr={person.heart_rate} bpm, diseases={person.chronic_diseases}"
    )
    raw = await call_llm(
        SYSTEM_MEDICAL_PERSONA,
        INTENT_CLASSIFICATION_PROMPT.format(user_message=user_message, patient_summary=summary),
    )
    try:
        return json.loads(raw.strip().strip("```json").strip("```").strip())
    except Exception:
        msg = user_message.lower()
        return {
            "suggest_doctors": any(w in msg for w in ["médecin", "docteur", "spécialiste", "clinique", "doctor", "specialist"]),
            "suggest_nutrition": any(w in msg for w in ["nutrition", "repas", "alimentation", "régime", "manger", "diet", "food", "meal"]),
            "direct_response": "",
        }
