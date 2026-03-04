"""
AgentState — the shared memory that every node reads from and writes to.

Fields are intentionally typed with Any for Pydantic objects (Person, Location)
because Python's TypedDict is structurally typed; the LangGraph runtime treats
all values as opaque and only applies reducers where annotated.
"""

from __future__ import annotations

from operator import add
from typing import Annotated, Any, List, Optional

from typing_extensions import TypedDict


class AgentState(TypedDict):
    # ── Inputs ────────────────────────────────────────────────────────────────
    person: Any                      # app.models.person.Person instance
    user_message: str                # Raw text typed by the user
    image_base64: Optional[str]      # Base-64 encoded meal photo (if any)
    location: Optional[Any]          # schemas.Location | None (for Maps queries)

    # ── Supervisor decisions ──────────────────────────────────────────────────
    do_nutrition: bool               # True → run nutrition node
    do_doctors: bool                 # True → run doctors node
    direct_response: str             # Non-empty → LLM answered directly (skip tools)

    # ── Outputs (doctors uses add-reducer so parallel fan-out merges safely) ──
    nutrition: Optional[dict]        # NutritionSuggestion serialised to dict
    doctors: Annotated[List[dict], add]   # List of Place dicts
    meal_analysis: Optional[dict]    # ImageAnalysisResult serialised to dict
    note: Optional[str]              # Final text response for the user
