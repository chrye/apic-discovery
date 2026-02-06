python -m venv .venv
.venv\Scripts\Activate.ps1

# Install all required packages for the MCP lab
pip install -r requirements.txt

.\runAzLogin.ps1

# Run all cells in mcp-from-api.ipynb
jupyter nbconvert --to notebook --execute mcp-from-api.ipynb --inplace
