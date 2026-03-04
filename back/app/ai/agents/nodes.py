"""
Agent nodes - each function is a pure async transformation of AgentState.
"""

from __future__ import annotations

import logging

from app.utils.config import settings
from ..tools import call_llm, classify_intent, get_nutrition, find_nearby_doctor, analyze_meal_image
from ..prompts import SYSTEM_MEDICAL_PERSONA
from .state import AgentState

logger = logging.getLogger(__name__)


# Node 1 : Supervisor
async def supervisor_node(state: AgentState) -> dict:
    """
    Inspect the request and decide which specialist nodes to activate.

    Short-circuit rules (checked in priority order):
      1. Image present -> vision only.
      2. Hypertensive crisis (systolic_bp > 180) -> doctors only, no nutrition.
      3. Otherwise classify intent via LLM.
    """
    # 1. Vision short-circuit
    if state.get("image_base64"):
        return {"do_nutrition": False, "do_doctors": False, "direct_response": ""}

    # 2. Safety guard: hypertensive emergency
    person = state.get("person")
    if person and getattr(person, "systolic_bp", 0) > 180:
        emergency_msg = (
            f"URGENCE - Tension arterielle critique : {person.systolic_bp}/{person.diastolic_bp} mmHg. "
            "Consultez immediatement un service d'urgence ou appelez le 15."
        )
        return {"do_nutrition": False, "do_doctors": True, "direct_response": emergency_msg}

    user_message = state.get("user_message", "").strip()
    if not user_message:
        return {"do_nutrition": False, "do_doctors": False, "direct_response": ""}

    try:
        intent = await classify_intent(user_message, state["person"])
        return {
            "do_nutrition": bool(intent.get("suggest_nutrition", False)),
            "do_doctors": bool(intent.get("suggest_doctors", False)),
            "direct_response": intent.get("direct_response", "") or "",
        }
    except Exception as exc:
        logger.warning("Supervisor intent classification failed: %s", exc)
        return {"do_nutrition": False, "do_doctors": False, "direct_response": ""}


# Node 2 : Vision
async def vision_node(state: AgentState) -> dict:
    """Analyse the meal photo using Gemini Vision."""
    try:
        result = await analyze_meal_image(state["image_base64"], state["person"])
        return {"meal_analysis": result.model_dump()}
    except Exception as exc:
        logger.error("Vision node error: %s", exc)
        return {
            "meal_analysis": {
                "is_compatible": False,
                "reasoning": f"Image analysis failed: {exc}",
                "alternative_suggestion": None,
            }
        }


# Node 3 : Nutrition
async def nutrition_node(state: AgentState) -> dict:
    """Generate a personalised nutrition plan for the patient."""
    try:
        suggestion = await get_nutrition(state["person"])
        return {"nutrition": suggestion.model_dump()}
    except Exception as exc:
        logger.error("Nutrition node error: %s", exc)
        return {
            "nutrition": {
                "title": "Balanced Diet",
                "description": f"Could not generate plan: {exc}",
                "shopping_list": [],
            }
        }


# Node 4 : Doctors
async def doctors_node(state: AgentState) -> dict:
    """Resolve the best medical specialty and find nearby clinics in one step."""
    try:
        specialty, places = await find_nearby_doctor(
            person=state["person"],
            location=state.get("location"),
            api_key=settings.google_maps_api_key or "",
        )
        updates: dict = {"doctors": [p.model_dump() for p in places]}
        # Only overwrite note when the supervisor did not already set an emergency message
        if not state.get("direct_response"):
            updates["note"] = f"Je recommande de consulter : {specialty}"
        return updates
    except Exception as exc:
        logger.error("Doctors node error: %s", exc)
        return {"doctors": [], "note": f"Doctors lookup failed: {exc}"}


# Node 5 : Final Answer (merged fallback + direct-response)
async def final_answer_node(state: AgentState) -> dict:
    """
    Single exit point for text-only responses.
    - If the supervisor already composed a direct answer, promote it to note.
    - Otherwise call the LLM for a general health summary.
    """
    direct = state.get("direct_response", "")
    if direct:
        return {"note": direct}

    try:
        import json as _json
        person = state["person"]
        try:
            patient_data = person.model_dump_json()
        except AttributeError:
            patient_data = _json.dumps(person)

        msg = state.get("user_message") or "Decris l'etat de sante general de ce patient."
        raw = await call_llm(
            SYSTEM_MEDICAL_PERSONA,
            f"Patient data: {patient_data}\n\nUser question: {msg}\n\n"
            "Answer concisely in the same language as the question.",
        )
        return {"note": raw.strip()}
    except Exception as exc:
        logger.error("Final answer node error: %s", exc)
        return {"note": "Je suis desole, une erreur est survenue. Veuillez reessayer."}
