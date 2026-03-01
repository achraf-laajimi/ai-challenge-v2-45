from fastapi import APIRouter, HTTPException
from app.config import settings
from app.database import get_database, get_persons_collection
from app.models.person import Person

from .schemas import AssistantRequest, AssistantResponse
from .services import (
    get_doctor_specialty,
    get_nutrition_recommendation,
    analyze_meal_image,
    query_google_places,
    classify_intent,
)

router = APIRouter(prefix="/ai", tags=["ai"])

@router.post("/assistant", response_model=AssistantResponse)
async def assistant(req: AssistantRequest):
    db = await get_database()
    persons_coll = get_persons_collection(db)

    # 1. Récupération du profil patient
    if req.person_id:
        person_doc = await persons_coll.find_one({"_id": req.person_id})
        if not person_doc:
            raise HTTPException(status_code=404, detail="Person not found")
        person = Person.from_mongo_doc(person_doc)
    elif req.family_id:
        person_doc = await persons_coll.find_one({"family_id": req.family_id})
        if not person_doc:
            raise HTTPException(status_code=404, detail="No persons for this family")
        person = Person.from_mongo_doc(person_doc)
    else:
        raise HTTPException(status_code=400, detail="person_id or family_id required")

    response = AssistantResponse(person_id=person.id)

    # 2. Si une image est fournie → analyse VLM prioritaire
    if req.image_base64:
        response.meal_analysis = await analyze_meal_image(req.image_base64, person)
        return response

    # 3. Routing intelligent basé sur le message utilisateur
    do_doctors = req.include_doctors
    do_nutrition = req.include_nutrition
    direct_response = ""

    if req.user_message:
        intent = await classify_intent(req.user_message, person)
        do_doctors = intent.get("suggest_doctors", False)
        do_nutrition = intent.get("suggest_nutrition", False)
        direct_response = intent.get("direct_response", "")

    # 4. Réponse directe du LLM (questions simples : décrire la santé, expliquer une valeur...)
    if direct_response:
        response.note = direct_response

    # 5. Recommandation nutritionnelle
    if do_nutrition:
        response.nutrition = await get_nutrition_recommendation(person)

    # 6. Suggestion de médecins via LLM + Google Maps
    if do_doctors:
        specialty_query = await get_doctor_specialty(person)
        if not direct_response:
            response.note = f"Je recommande de consulter : {specialty_query}"
        if settings.google_maps_api_key and req.location:
            places = await query_google_places(settings.google_maps_api_key, req.location, specialty_query)
            response.doctors = places

    # 7. Fallback : si rien n'a été déclenché, faire un bilan textuel
    if not do_doctors and not do_nutrition and not direct_response:
        from .prompts import SYSTEM_MEDICAL_PERSONA
        from .services import _call_llm
        msg = req.user_message or "Décris l'état de santé général de ce patient."
        patient_data = person.model_dump_json()
        raw = await _call_llm(
            SYSTEM_MEDICAL_PERSONA,
            f"Patient data: {patient_data}\n\nUser question: {msg}\n\nAnswer concisely in the same language as the question.",
        )
        response.note = raw.strip()

    return response