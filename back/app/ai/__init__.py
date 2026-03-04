"""
AI module — FastAPI router.

Responsibilities:
  1. Validate the request and load the patient profile from MongoDB.
  2. Build the initial AgentState.
  3. Invoke the compiled LangGraph medical agent.
  4. Map the final AgentState back to an AssistantResponse.
"""

from fastapi import APIRouter, HTTPException

from app.utils.database import get_database, get_persons_collection
from app.models.person import Person

from .agents.graph import medical_agent
from .schemas import (
    AssistantRequest,
    AssistantResponse,
    ImageAnalysisResult,
    NutritionSuggestion,
    Place,
)

router = APIRouter(prefix="/ai", tags=["ai"])


@router.post("/assistant", response_model=AssistantResponse)
async def assistant(req: AssistantRequest):
    # ── 1. Load patient profile ─────────────────────────────────────────────
    db = await get_database()
    persons_coll = get_persons_collection(db)

    if req.person_id:
        doc = await persons_coll.find_one({"_id": req.person_id})
        if not doc:
            raise HTTPException(status_code=404, detail="Person not found")
    elif req.family_id:
        doc = await persons_coll.find_one({"family_id": req.family_id})
        if not doc:
            raise HTTPException(status_code=404, detail="No persons for this family")
    else:
        raise HTTPException(status_code=400, detail="person_id or family_id required")

    person = Person.from_mongo_doc(doc)

    # ── 2. Build initial agent state ───────────────────────────────────────────
    initial_state = {
        "person": person,
        "user_message": req.user_message or "",
        "image_base64": req.image_base64,
        "location": req.location,
        "do_nutrition": False,
        "do_doctors": False,
        "direct_response": "",
        "nutrition": None,
        "doctors": [],
        "meal_analysis": None,
        "note": None,
    }

    # ── 3. Run the LangGraph agent ────────────────────────────────────────────
    final_state = await medical_agent.ainvoke(initial_state)

    # ── 4. Map agent state → API response ───────────────────────────────────────
    response = AssistantResponse(person_id=person.id)

    if final_state.get("meal_analysis"):
        response.meal_analysis = ImageAnalysisResult(**final_state["meal_analysis"])

    if final_state.get("nutrition"):
        response.nutrition = NutritionSuggestion(**final_state["nutrition"])

    if final_state.get("doctors"):
        response.doctors = [Place(**p) for p in final_state["doctors"]]

    if final_state.get("note"):
        response.note = final_state["note"]

    return response
