# Federated API Governance — MCP + A2A Discovery Demo

End-to-end demo showing how **Azure API Management** and **Azure API Center** enable federated governance across distributed API environments — covering **REST APIs**, **MCP servers**, and **A2A agents** in a single unified catalog.

## Architecture

| Resource Group | Role | Contents |
|---------------|------|----------|
| **RG 2** `rg-lab-mcp-demo-1-1` | Pre-deployed mixed APIs | 4 REST APIs converted to MCP servers + remote MCPs |
| **RG 3** `rg-lab-mcp-containers` | FastMCP containers | 4 FastMCP servers on Azure Container Apps + APIM + APIC |
| **RG 4** `rg-lab-a2a-demo` | A2A agents | 3 A2A agents + REST APIs + remote MCPs |
| **RG 1** `rg-lab-apic-central` | Central catalog | Federated API Center aggregating all APIs from RG 2, 3, 4 |

## Getting Started

### Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed and signed in
- [Python 3.12+](https://www.python.org/)
- An Azure subscription with **Contributor** access
- Install dependencies: `pip install -r requirements.txt`

### Run the Demo

Open **[demo.ipynb](demo.ipynb)** and run the cells top to bottom. The notebook is self-contained — it deploys infrastructure, builds containers, tests APIs, and demonstrates federated discovery.

## Demo Story (10 Parts)

| Part | Topic | Description |
|------|-------|-------------|
| 1–3 | **MCP Servers** | Explore existing APIs (RG 2), deploy FastMCP containers (RG 3), test |
| 4–5 | **Federation** | Deploy central APIC (RG 1), aggregate APIs from RG 2 + RG 3 |
| 6–7 | **MCP Discovery** | Unified catalog view, dynamic MCP invocation, agent workflow |
| 8–9 | **A2A Agents** | Explore A2A agents (RG 4), aggregate to central catalog |
| 10 | **Unified Governance** | Full REST + MCP + A2A catalog, agent card discovery, APIM analytics |

## Files

| File | Purpose |
|------|---------|
| `demo.ipynb` | Main demo notebook — single entry point |
| `demo-mcp-containers.bicep` | Bicep: deploys Container Apps + APIM + APIC for FastMCP servers |
| `demo-central-apic.bicep` | Bicep: deploys central API Center with REST/MCP/A2A environments |
| `requirements.txt` | Python dependencies |
| `src/*/container/` | FastMCP server source code (Dockerfiles + Python) |
