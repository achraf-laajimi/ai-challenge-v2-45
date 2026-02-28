from fastapi import APIRouter, HTTPException
from app.config import settings
from app.database import get_database, get_persons_collection
from app.models.person import Person

from .schemas import AssistantRequest, AssistantResponse
from .services import (
    get_doctor_specialty, 
    get_nutrition_recommendation, 
    analyze_meal_image, 
    query_google_places
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

    # 2. Analyse VLM de l'image (si fournie)
    if req.image_base64:
        response.meal_analysis = await analyze_meal_image(req.image_base64, person)

    # 3. Recommandation Nutrition par LLM
    if req.include_nutrition and not req.image_base64: 
        # On évite de faire une nutrition générale si on analyse déjà une assiette
        response.nutrition = await get_nutrition_recommendation(person)

    # 4. Suggestion de Médecins intelligente par LLM + Google Maps
    if req.include_doctors:
        # Le LLM décide de la spécialité exacte en fonction du dossier !
        specialty_query = await get_doctor_specialty(person)
        response.note = f"Based on the profile, AI suggests looking for: {specialty_query}"
        
        if settings.google_maps_api_key and req.location:
            places = await query_google_places(settings.google_maps_api_key, req.location, specialty_query)
            response.doctors = places

    return response