import os
from openai import OpenAI
from IPython.core.magic import register_cell_magic
from IPython.display import display, Markdown
from dotenv import load_dotenv

@register_cell_magic
def askvs(line, cell):
    load_dotenv("/home/ubuntu/data/env.py", override=True)

    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        display(Markdown("**Fehler:** `OPENAI_API_KEY` ist nicht gesetzt."))
        return

    vector_store_name = line.strip()
    query = cell.strip()

    if not vector_store_name:
        display(Markdown("**Fehler:** Vector-Store-Name fehlt. Beispiel: `%%askvs kursunterlagen`"))
        return

    if not query:
        display(Markdown("**Fehler:** Query fehlt."))
        return

    client = OpenAI(
        api_key=api_key,
        base_url=os.getenv("AI_BASE_URL", "https://api.openai.com/v1"),
        timeout=300,
    )

    model = os.getenv("AI_MODEL", "gpt-4o-mini")

    try:
        stores = client.vector_stores.list(limit=100)

        store = next(
            (vs for vs in stores.data if vs.name.lower() == vector_store_name.lower()),
            None,
        )

        if not store:
            names = "\n".join(f"- `{vs.name}`" for vs in stores.data)
            display(Markdown(
                f"**Fehler:** Vector Store `{vector_store_name}` nicht gefunden.\n\n"
                f"Gefundene Vector Stores:\n\n{names}"
            ))
            return

        response = client.responses.create(
            model=model,
            instructions=(
                "Beantworte die Frage ausschliesslich mit Informationen aus dem File-Search-Tool. "
                "Wenn im Vector Store keine passende Information gefunden wird, antworte exakt: "
                "`Keine passende Information im Vector Store gefunden.` "
                "Nutze kein Allgemeinwissen."
            ),
            input=query,
            tools=[
                {
                    "type": "file_search",
                    "vector_store_ids": [store.id],
                    "max_num_results": 10,
                }
            ],
            tool_choice={
                "type": "file_search"
            },
        )

        used_file_search = any(
            item.type == "file_search_call"
            for item in response.output
        )

        if not used_file_search:
            display(Markdown("**Fehler:** File Search wurde nicht ausgeführt."))
            return

        answer = response.output_text or "Keine Antwort erhalten."
        display(Markdown(answer))

    except Exception as e:
        display(Markdown(f"**Fehler beim OpenAI-Zugriff:** `{e}`"))