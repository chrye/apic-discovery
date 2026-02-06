# Removing Azure Resources from APIM and API Center

## Why Commenting Out Bicep Doesn't Remove Resources

Azure Resource Manager uses **incremental deployment mode** by default:
- ✅ Creates new resources
- ✅ Updates existing resources
- ❌ Does **NOT** delete resources removed from the template

To auto-delete resources, you'd need to use `--mode Complete`, but this is **dangerous** as it deletes ALL resources in the resource group not in the template.

### Best Practice

When removing resources:
1. Manually delete them using Azure CLI or Azure Portal
2. Then comment out/remove from Bicep to prevent redeployment

---

## Commands to Remove Place Order API and MCP

### Prerequisites

Get your resource names:

```powershell
# Get APIM service name
az apim list --resource-group rg-lab-ai-gateway2 --query "[0].name" -o tsv

# Get API Center service name
az apic list --resource-group rg-lab-ai-gateway2 --query "[0].name" -o tsv

# List all APIs in APIM
az apim api list --resource-group rg-lab-ai-gateway2 --service-name <apim-name> --query "[].name" -o table

# List all APIs in API Center
az apic api list --resource-group rg-lab-ai-gateway2 --service-name <apic-name> --query "[].name" -o table
```

### Remove from APIM

```powershell
# Delete the Place Order API
az apim api delete --resource-group rg-lab-ai-gateway2 --service-name apim-mcps --api-id order-api --yes

# Delete the Place Order MCP (if exists)
az apim api delete --resource-group rg-lab-ai-gateway2 --service-name apim-mcps --api-id order-mcp --yes
```

### Remove from API Center

```powershell
# Delete the Place Order API
az apic api delete --resource-group rg-lab-ai-gateway2 --service-name apic6-pqcbuguzikzyq --api-id order-api --yes

# Delete the Place Order MCP
az apic api delete --resource-group rg-lab-ai-gateway2 --service-name apic6-pqcbuguzikzyq --api-id order-mcp --yes
```

---

## Verify Deletion

```powershell
# Verify APIs removed from APIM
az apim api list --resource-group rg-lab-ai-gateway2 --service-name apim-mcps --query "[].name" -o tsv

# Verify APIs removed from API Center
az apic api list --resource-group rg-lab-ai-gateway2 --service-name apic6-pqcbuguzikzyq --query "[].name" -o tsv
```

---

## Generic Commands Reference

### APIM API Management

```powershell
# List all APIs
az apim api list --resource-group <rg-name> --service-name <apim-name> -o table

# Delete an API
az apim api delete --resource-group <rg-name> --service-name <apim-name> --api-id <api-id> --yes

# Filter APIs by name pattern
az apim api list --resource-group <rg-name> --service-name <apim-name> --query "[?contains(name, 'pattern')].name" -o table
```

### API Center

```powershell
# List all API Center services
az apic list --resource-group <rg-name> -o table

# List all APIs in API Center
az apic api list --resource-group <rg-name> --service-name <apic-name> -o table

# Delete an API from API Center
az apic api delete --resource-group <rg-name> --service-name <apic-name> --api-id <api-id> --yes

# Filter APIs by name pattern
az apic api list --resource-group <rg-name> --service-name <apic-name> --query "[?contains(name, 'pattern')].name" -o table
```

---

## Notes

- Replace `<rg-name>`, `<apim-name>`, `<apic-name>`, and `<api-id>` with your actual values
- The `--yes` flag skips confirmation prompts
- API Center extension may need to be installed: `az extension add --name apic-extension`
