"""Persons CRUD (family members)."""
from datetime import datetime

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, status

from app.database import get_database, get_persons_collection
from app.models.person import Person, PersonCreate, PersonUpdate, PersonRole
from app.utils.dependencies import get_current_user_family_id

router = APIRouter(prefix="/persons", tags=["persons"])


def _person_doc_to_response(doc: dict) -> Person:
    return Person.from_mongo_doc(doc)


def _create_doc_to_db(data: PersonCreate) -> dict:
    """Convert PersonCreate to MongoDB document (snake_case)."""
    return {
        "name": data.name,
        "phone": data.phone,
        "dob": data.dob,
        "gender": data.gender,
        "blood_type": data.blood_type,
        "rh_factor": data.rh_factor,
        "height": data.height,
        "weight": data.weight,
        "sugar_level": data.sugar_level,
        "systolic_bp": data.systolic_bp,
        "diastolic_bp": data.diastolic_bp,
        "heart_rate": data.heart_rate,
        "allergies": data.allergies,
        "chronic_diseases": data.chronic_diseases,
        "vaccines_up_to_date": data.vaccines_up_to_date,
        "family_id": data.family_id,
        "role": data.role.value,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow(),
    }


@router.post("", response_model=Person, status_code=status.HTTP_201_CREATED)
async def create_person(
    data: PersonCreate,
    family_id: str = Depends(get_current_user_family_id),
):
    """Create a family member. family_id in body must match current user's family."""
    if data.family_id != family_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot add person to another family",
        )
    db = await get_database()
    persons = get_persons_collection(db)

    # Enforce single father/mother per family
    if data.role in (PersonRole.FATHER, PersonRole.MOTHER):
        existing = await persons.find_one({
            "family_id": family_id,
            "role": data.role.value,
        })
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Family already has a {data.role.value}",
            )

    doc = _create_doc_to_db(data)
    doc["_id"] = str(ObjectId())
    await persons.insert_one(doc)
    return _person_doc_to_response(doc)


@router.get("", response_model=list[Person])
async def list_persons(
    family_id: str = Depends(get_current_user_family_id),
):
    """List all members of current user's family."""
    db = await get_database()
    persons = get_persons_collection(db)
    cursor = persons.find({"family_id": family_id}).sort("role", 1)
    docs = await cursor.to_list(length=100)
    return [_person_doc_to_response(d) for d in docs]


@router.get("/{person_id}", response_model=Person)
async def get_person(
    person_id: str,
    family_id: str = Depends(get_current_user_family_id),
):
    """Get one person by id (must belong to user's family)."""
    db = await get_database()
    persons = get_persons_collection(db)
    doc = await persons.find_one({"_id": person_id, "family_id": family_id})
    if not doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Person not found",
        )
    return _person_doc_to_response(doc)


@router.patch("/{person_id}", response_model=Person)
async def update_person(
    person_id: str,
    data: PersonUpdate,
    family_id: str = Depends(get_current_user_family_id),
):
    """Update a family member."""
    db = await get_database()
    persons = get_persons_collection(db)
    doc = await persons.find_one({"_id": person_id, "family_id": family_id})
    if not doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Person not found",
        )

    update_fields = data.model_dump(exclude_unset=True, by_alias=False)
    set_dict = {**update_fields, "updated_at": datetime.utcnow()}

    await persons.update_one(
        {"_id": person_id, "family_id": family_id},
        {"$set": set_dict},
    )
    updated = await persons.find_one({"_id": person_id})
    return _person_doc_to_response(updated)


@router.delete("/{person_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_person(
    person_id: str,
    family_id: str = Depends(get_current_user_family_id),
):
    """Delete a family member."""
    db = await get_database()
    persons = get_persons_collection(db)
    result = await persons.delete_one({"_id": person_id, "family_id": family_id})
    if result.deleted_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Person not found",
        )
