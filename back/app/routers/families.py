"""Families CRUD. Returns family with members (father, mother, children)."""
from datetime import datetime
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status

from app.database import get_database, get_families_collection, get_persons_collection
from app.models.family import FamilyResponse, FamilyUpdate
from app.models.person import Person, PersonRole
from app.utils.dependencies import get_current_user_id, get_current_user_family_id

router = APIRouter(prefix="/families", tags=["families"])


def _person_doc_to_response(doc: dict) -> Person:
    return Person.from_mongo_doc(doc)


@router.get("/me", response_model=FamilyResponse)
async def get_my_family(
    family_id: str = Depends(get_current_user_family_id),
):
    """Get current user's family with all members (father, mother, children)."""
    db = await get_database()
    families = get_families_collection(db)
    persons_coll = get_persons_collection(db)

    fam = await families.find_one({"_id": family_id})
    if not fam:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Family not found",
        )

    cursor = persons_coll.find({"family_id": family_id})
    members = await cursor.to_list(length=100)
    father = mother = None
    children: List[Person] = []
    for m in members:
        p = _person_doc_to_response(m)
        if m.get("role") == PersonRole.FATHER.value:
            father = p
        elif m.get("role") == PersonRole.MOTHER.value:
            mother = p
        else:
            children.append(p)

    return FamilyResponse(
        id=str(fam["_id"]),
        familyHistory=fam.get("family_history", []),
        father=father,
        mother=mother,
        children=children,
        createdAt=fam.get("created_at", datetime.utcnow()),
    )


@router.patch("/me", response_model=FamilyResponse)
async def update_my_family(
    data: FamilyUpdate,
    family_id: str = Depends(get_current_user_family_id),
):
    """Update family (e.g. family_history)."""
    db = await get_database()
    families = get_families_collection(db)
    persons_coll = get_persons_collection(db)

    if data.family_history is not None:
        await families.update_one(
            {"_id": family_id},
            {"$set": {"family_history": data.family_history}},
        )

    fam = await families.find_one({"_id": family_id})
    if not fam:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Family not found")

    cursor = persons_coll.find({"family_id": family_id})
    members = await cursor.to_list(length=100)
    father = mother = None
    children = []
    for m in members:
        p = _person_doc_to_response(m)
        if m.get("role") == PersonRole.FATHER.value:
            father = p
        elif m.get("role") == PersonRole.MOTHER.value:
            mother = p
        else:
            children.append(p)

    return FamilyResponse(
        id=str(fam["_id"]),
        familyHistory=fam.get("family_history", []),
        father=father,
        mother=mother,
        children=children,
        createdAt=fam.get("created_at", datetime.utcnow()),
    )
