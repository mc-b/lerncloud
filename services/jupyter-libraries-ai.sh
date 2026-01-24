#!/bin/bash
#

# Jupyter Libraries fuer AI

# OpenAI API als separater Kernel (Chat)
python3 -m venv .ai
source ~/.ai/bin/activate
pip install openai
pip install ipykernel
pip install nbconvert
python3 -m ipykernel install --user --name=ai --display-name "Python (ai)"

# RAG
python3 -m venv .rag
source ~/.rag/bin/activate
pip install ipykernel chromadb pypdf requests tqdm
python3 -m ipykernel install --user --name=rag --display-name "Python (rag)"

# MCP
python3 -m venv .mcp
source ~/.mcp/bin/activate
pip install ipykernel mcp requests
python3 -m ipykernel install --user --name=mcp --display-name "Python (mcp)"

