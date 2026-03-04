"""
Medical Supervisor graph - built with LangGraph StateGraph.

Parallel fan-out (nutrition + doctors) uses a plain list of node names returned
by the routing function - no Send() needed for fixed node sets.
"""

from __future__ import annotations

from typing import Union

from langgraph.graph import END, START, StateGraph

from .nodes import (
    doctors_node,
    final_answer_node,
    nutrition_node,
    supervisor_node,
    vision_node,
)
from .state import AgentState


def route_from_supervisor(state: AgentState) -> Union[str, list]:
    """
    Return a node name or a list of names for parallel execution.
    LangGraph dispatches all listed nodes in the same super-step.
    """
    if state.get("image_base64"):
        return "vision"

    do_nutrition = state.get("do_nutrition", False)
    do_doctors = state.get("do_doctors", False)
    direct = state.get("direct_response", "")

    targets = []
    if do_nutrition:
        targets.append("nutrition")
    if do_doctors:
        targets.append("doctors")

    if targets:
        if direct:
            targets.append("final_answer")
        return targets

    return "final_answer"


def build_medical_graph():
    builder = StateGraph(AgentState)

    builder.add_node("supervisor", supervisor_node)
    builder.add_node("vision", vision_node)
    builder.add_node("nutrition", nutrition_node)
    builder.add_node("doctors", doctors_node)
    builder.add_node("final_answer", final_answer_node)

    builder.add_edge(START, "supervisor")
    builder.add_conditional_edges("supervisor", route_from_supervisor)

    builder.add_edge("vision", END)
    builder.add_edge("nutrition", END)
    builder.add_edge("doctors", END)
    builder.add_edge("final_answer", END)

    return builder.compile()


medical_agent = build_medical_graph()
