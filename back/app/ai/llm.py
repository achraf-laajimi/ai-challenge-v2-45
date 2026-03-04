"""Gemini LLM client — single entry point for all AI calls."""
import base64
from typing import Optional

from google import genai
from google.genai import types as genai_types

from app.utils.config import settings

_client = genai.Client(api_key=settings.gemini_api_key)
_MODEL = "gemini-2.5-flash"


async def call_llm(system: str, prompt: str, image_b64: Optional[str] = None) -> str:
    parts: list = [prompt]
    if image_b64:
        mime = "image/jpeg"
        if image_b64.startswith("data:image"):
            header, image_b64 = image_b64.split(",", 1)
            mime = header.split(";")[0].split(":")[1]
        parts.append(genai_types.Part.from_bytes(data=base64.b64decode(image_b64), mime_type=mime))
    resp = await _client.aio.models.generate_content(
        model=_MODEL,
        contents=parts,
        config=genai_types.GenerateContentConfig(system_instruction=system, temperature=0.2),
    )
    return resp.text
