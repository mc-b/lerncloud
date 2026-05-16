import os
import requests
from IPython.core.magic import register_cell_magic
from IPython.display import display, Markdown
from dotenv import load_dotenv

@register_cell_magic
def ai(line, cell):
    load_dotenv("/home/ubuntu/data/env.py", override=True)
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        display(Markdown("**Fehler:** `OPENAI_API_KEY` ist nicht gesetzt."))
        return

    model = os.getenv("AI_MODEL", "gpt-5.4")
    base_url = os.getenv("AI_BASE_URL", "https://api.openai.com/v1").rstrip("/")

    system_prompt = line.strip()
    user_prompt = cell.strip()

    if system_prompt:
        input_text = f"{system_prompt}\n\n{user_prompt}"
    else:
        input_text = user_prompt

    payload = {
        "model": model,
        "input": input_text,
    }

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }

    try:
        response = requests.post(
            f"{base_url}/responses",
            json=payload,
            headers=headers,
            timeout=300,
        )
        response.raise_for_status()
        data = response.json()

        result = data.get("output_text", "")

        if not result:
            result = ""
            for item in data.get("output", []):
                for content in item.get("content", []):
                    if content.get("type") == "output_text":
                        result += content.get("text", "")

        display(Markdown(result))
        #return result

    except Exception as e:
        display(Markdown(f"**Fehler bei der Anfrage:** `{e}`"))
        
