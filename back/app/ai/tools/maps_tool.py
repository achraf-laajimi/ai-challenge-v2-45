"""Google Maps Places lookup + doctor specialty resolver."""
import httpx
from typing import List, Tuple

from app.models.person import Person
from ..schemas import Location, Place
from ..prompts import SYSTEM_MEDICAL_PERSONA, DOCTOR_SPECIALTY_PROMPT
from ..llm import call_llm


async def query_google_places(api_key: str, location: Location, query: str) -> List[Place]:
    params = {
        "key": api_key,
        "location": f"{location.lat},{location.lng}",
        "rankby": "distance",
        "keyword": query,
    }
    async with httpx.AsyncClient(timeout=10.0) as client:
        data = (await client.get(
            "https://maps.googleapis.com/maps/api/place/nearbysearch/json",
            params=params,
        )).json()

    places = []
    for p in data.get("results", [])[:6]:
        geo = p.get("geometry", {}).get("location", {})
        places.append(Place(
            name=p.get("name"),
            address=p.get("vicinity") or p.get("formatted_address"),
            place_id=p.get("place_id"),
            open_now=p.get("opening_hours", {}).get("open_now") if p.get("opening_hours") else None,
            lat=geo.get("lat"),
            lng=geo.get("lng"),
        ))
    return places


async def find_nearby_doctor(
    person: Person,
    location: Location,
    api_key: str,
) -> Tuple[str, List[Place]]:
    """Resolve the right medical specialty for *person*, then search nearby clinics.

    Returns:
        (specialty_label, list_of_places)  — places is empty when api_key is falsy
        or location is None.
    """
    specialty = await call_llm(
        SYSTEM_MEDICAL_PERSONA,
        DOCTOR_SPECIALTY_PROMPT.format(patient_data=person.model_dump_json()),
    )
    specialty = specialty.strip() or "General Practitioner"

    places: List[Place] = []
    if api_key and location:
        places = await query_google_places(api_key, location, specialty)

    return specialty, places
