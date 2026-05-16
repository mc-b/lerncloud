import os
from openai import OpenAI
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

    model = os.getenv("AI_MODEL", "gpt-5.2")
    base_url = os.getenv("AI_BASE_URL", "https://api.openai.com/v1")

    client = OpenAI(
        api_key=api_key,
        base_url=base_url,
        timeout=300,
    )

    system_prompt = line.strip()
    user_prompt = cell.strip()

    try:
        response = client.responses.create(
            model=model,
            instructions=system_prompt or None,
            input=user_prompt,
        )

        display(Markdown(response.output_text or ""))

    except Exception as e:
        display(Markdown(f"**Fehler bei der Anfrage:** `{e}`"))