import json
import httpx
from typing import List, Optional
from app.config import settings
from app.models.person import Person
from .schemas import Location, Place, NutritionSuggestion, ImageAnalysisResult
from .prompts import SYSTEM_MEDICAL_PERSONA, DOCTOR_SPECIALTY_PROMPT, NUTRITION_REASONING_PROMPT, VLM_MEAL_ANALYSIS_PROMPT

import base64
from typing import List, Optional
import google.generativeai as genai

# Assurez-vous d'avoir ajouté gemini_api_key dans votre fichier config.py
from app.config import settings 

# 1. Configuration initiale de Gemini avec votre clé API
genai.configure(api_key=settings.gemini_api_key)

async def _call_llm(system_prompt: str, user_prompt: str, image_b64: Optional[str] = None) -> str:
    """
    Appel asynchrone à l'API Google Gemini (1.5 Flash pour un bon ratio vitesse/vision).
    Gère les requêtes textuelles et multimodales (vision).
    """
    try:
        # 2. Initialisation du modèle. 
        # On utilise 'gemini-1.5-flash' car il est rapide et gère très bien la vision. 
        # Pour des raisonnements médicaux très complexes, on pourrait utiliser 'gemini-1.5-pro'.
        model = genai.GenerativeModel(
            model_name="gemini-1.5-flash",
            system_instruction=system_prompt, # Gemini gère le prompt système nativement ici
        )

        # 3. Préparation du contenu de la requête (User Prompt)
        contents = [user_prompt]

        # 4. Traitement de l'image si elle est présente (VLM)
        if image_b64:
            mime_type = "image/jpeg" # Valeur par défaut
            
            # Nettoyage si le front-end envoie le préfixe HTML (ex: "data:image/png;base64,iVBORw...")
            if image_b64.startswith("data:image"):
                header, image_b64 = image_b64.split(",", 1)
                mime_type = header.split(";")[0].split(":")[1]
            
            # Gemini attend un dictionnaire spécifique pour les données binaires
            image_part = {
                "mime_type": mime_type,
                "data": image_b64
            }
            contents.append(image_part)

        # 5. Appel asynchrone à l'API de Google
        # On utilise une température basse (0.2) pour que les conseils médicaux soient déterministes et factuels
        response = await model.generate_content_async(
            contents,
            generation_config=genai.types.GenerationConfig(
                temperature=0.2, 
            )
        )
        
        return response.text

    except Exception as e:
        print(f"Erreur API Gemini : {str(e)}")
        # En cas d'erreur, on renvoie une chaîne vide ou on lève une exception selon votre logique globale
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
        places.append(Place(
            name=p.get("name"),
            address=p.get("vicinity") or p.get("formatted_address"),
            place_id=p.get("place_id"),
            open_now=(p.get("opening_hours", {}).get("open_now") if p.get("opening_hours") else None),
        ))
    return places