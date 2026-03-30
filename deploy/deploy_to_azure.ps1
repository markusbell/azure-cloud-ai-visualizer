
<# Original script with hardcoded values, refactored to use parameters for better reusability and flexibility. The script creates an Azure Resource Group, an App Service Plan, and two Web Apps for frontend and backend, configuring them to use container images from a specified Azure Container Registry (ACR). 
Param(
  
  [string]$ResourceGroup = "VSE-AzureArchitectVisualizer-RG",
  [string]$AcrName = "VSEAtAzViusualizerContReg",
  [string]$FrontendImage = "$($AcrName).azurecr.io/myrepo-frontend:latest",
  [string]$BackendImage = "$($AcrName).azurecr.io/myrepo-backend:latest"
)

Write-Host "Deploying to Azure using ACR=$AcrName, RG=$ResourceGroup"

az group create -n $ResourceGroup -l westeurope | Out-Null

az appservice plan create -g $ResourceGroup -n webplan --is-linux --sku B1 -o none

az webapp create -g $ResourceGroup -p webplan -n cloud-visualizer-backend --deployment-container-image-name $BackendImage -o none

try {
  $acrId = az acr show -n $AcrName --query id -o tsv
  if ($acrId) {
    az webapp config container set -g $ResourceGroup -n cloud-visualizer-backend --docker-custom-image-name $BackendImage --docker-registry-server-url "https://$AcrName.azurecr.io" | Out-Null
    Write-Host "Configured backend webapp to use image $BackendImage"
  }
} catch {
  Write-Host "ACR $AcrName not found or accessible; ensure image is in a public registry or provide credentials."
}

az webapp create -g $ResourceGroup -p webplan -n cloud-visualizer-frontend --deployment-container-image-name $FrontendImage -o none
az webapp config container set -g $ResourceGroup -n cloud-visualizer-frontend --docker-custom-image-name $FrontendImage --docker-registry-server-url "https://$AcrName.azurecr.io" -o none

Write-Host "Deployment initiated. Check Azure Portal or use 'az webapp show' to inspect apps."
#>

Param(
  [Parameter(Mandatory = $true)]
  [string]$SubscriptionId,

  [Parameter(Mandatory = $true)]
  [string]$ResourceGroupName,

  [Parameter(Mandatory = $true)]
  [string]$Location,

  [Parameter(Mandatory = $true)]
  [string]$FrontendImage,

  [Parameter(Mandatory = $true)]
  [string]$BackendImage,

  [Parameter(Mandatory = $true)]
  [string]$AcrName    # z.B. "VSEAtAzViusualizerContReg"
)

Write-Host "Deploying to Azure using ACR=$AcrName, RG=$ResourceGroupName, Location=$Location" -ForegroundColor Cyan

# Resource Group idempotent anlegen
az group create -n $ResourceGroupName -l $Location -o none

# App Service Plan (Linux)
az appservice plan create `
  -g $ResourceGroupName `
  -n webplan `
  --is-linux `
  --sku B1 `
  -o none

# Backend Web App erstellen
az webapp create `
  -g $ResourceGroupName `
  -p webplan `
  -n cloud-visualizer-backend `
  --deployment-container-image-name $BackendImage `
  -o none

try {
  $acrId = az acr show -n $AcrName --query id -o tsv
  if ($acrId) {
    az webapp config container set `
      -g $ResourceGroupName `
      -n cloud-visualizer-backend `
      --docker-custom-image-name $BackendImage `
      --docker-registry-server-url "https://$AcrName.azurecr.io" `
      -o none

    Write-Host "Configured backend webapp to use image $BackendImage" -ForegroundColor Green
  }
  else {
    Write-Host "ACR $AcrName not found; make sure it exists and the UAMI has access." -ForegroundColor Yellow
  }
}
catch {
  Write-Host ("Error retrieving ACR info for {0}: {1}" -f $AcrName, $_) -ForegroundColor Red
}

# Frontend Web App erstellen / konfigurieren
az webapp create `
  -g $ResourceGroupName `
  -p webplan `
  -n cloud-visualizer-frontend `
  --deployment-container-image-name $FrontendImage `
  -o none

az webapp config container set `
  -g $ResourceGroupName `
  -n cloud-visualizer-frontend `
  --docker-custom-image-name $FrontendImage `
  --docker-registry-server-url "https://$AcrName.azurecr.io" `
  -o none

Write-Host "Deployment initiated. Check Azure Portal or use 'az webapp show' to inspect apps." -ForegroundColor Green
    