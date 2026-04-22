<#
.SYNOPSIS
  One-time bootstrap: create GitHub OIDC app registration, federated
  credentials, and subscription role assignments for the Notes sample app.

.DESCRIPTION
  PowerShell port of setup-oidc.sh. Idempotent.

  Prerequisites: Azure CLI (`az`), logged in as a user with:
    - Owner or User Access Administrator on the subscription
    - Application Developer (or better) in Entra ID

.EXAMPLE
  ./setup-oidc.ps1 -GitHubOwner amis-4630 -GitHubRepo sample-app -EnvName dev

.EXAMPLE
  ./setup-oidc.ps1 amis-4630 sample-app prod 00000000-0000-0000-0000-000000000000
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$GitHubOwner,

    [Parameter(Mandatory, Position = 1)]
    [string]$GitHubRepo,

    [Parameter(Mandatory, Position = 2)]
    [ValidateSet('dev', 'prod')]
    [string]$EnvName,

    [Parameter(Position = 3)]
    [string]$SubscriptionId
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw "Azure CLI (az) is required. Install: winget install -e --id Microsoft.AzureCLI"
}

if (-not $SubscriptionId) {
    $SubscriptionId = az account show --query id -o tsv
}
$TenantId = az account show --query tenantId -o tsv

$AppName = "gh-oidc-$GitHubOwner-$GitHubRepo-$EnvName"

Write-Host "==> Subscription: $SubscriptionId"
Write-Host "==> Tenant:       $TenantId"
Write-Host "==> App name:     $AppName"

# 1. App registration + service principal (idempotent).
$AppId = az ad app list --display-name $AppName --query '[0].appId' -o tsv
if (-not $AppId) {
    Write-Host "==> Creating app registration"
    $AppId = az ad app create --display-name $AppName --query appId -o tsv
}

$SpId = az ad sp list --filter "appId eq '$AppId'" --query '[0].id' -o tsv
if (-not $SpId) {
    Write-Host "==> Creating service principal"
    $SpId = az ad sp create --id $AppId --query id -o tsv
}

function New-FederatedCredential {
    param(
        [string]$AppId,
        [string]$Name,
        [string]$Subject
    )

    $existing = az ad app federated-credential list --id $AppId --query "[?name=='$Name'].name" -o tsv
    if ($existing) {
        Write-Host "==> Federated credential '$Name' already exists"
        return
    }

    Write-Host "==> Adding federated credential '$Name' for $Subject"
    $payload = @{
        name      = $Name
        issuer    = 'https://token.actions.githubusercontent.com'
        subject   = $Subject
        audiences = @('api://AzureADTokenExchange')
    } | ConvertTo-Json -Compress

    # Write to a temp file to avoid cross-shell quoting headaches.
    $tmp = New-TemporaryFile
    try {
        Set-Content -Path $tmp -Value $payload -Encoding utf8
        az ad app federated-credential create --id $AppId --parameters "@$tmp" | Out-Null
    }
    finally {
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    }
}

# 2. Federated credential scoped to the GitHub Environment.
New-FederatedCredential `
    -AppId $AppId `
    -Name "gh-env-$EnvName" `
    -Subject "repo:$GitHubOwner/$GitHubRepo`:environment:$EnvName"

# 3. pull_request federated credential (dev only) for what-if on PRs.
if ($EnvName -eq 'dev') {
    New-FederatedCredential `
        -AppId $AppId `
        -Name 'gh-pr' `
        -Subject "repo:$GitHubOwner/$GitHubRepo`:pull_request"
}

# 4. Subscription-scope role assignments.
$scope = "/subscriptions/$SubscriptionId"
foreach ($role in 'Contributor', 'User Access Administrator') {
    Write-Host "==> Assigning '$role' to SP at subscription scope"
    az role assignment create `
        --assignee-object-id $SpId `
        --assignee-principal-type ServicePrincipal `
        --role $role `
        --scope $scope `
        --only-show-errors 2>$null | Out-Null
}

@"

==> DONE.

Add the following to GitHub Environment '$EnvName' in
https://github.com/$GitHubOwner/$GitHubRepo/settings/environments :

  Variables:
    AZURE_CLIENT_ID            = $AppId
    AZURE_TENANT_ID            = $TenantId
    AZURE_SUBSCRIPTION_ID      = $SubscriptionId
    AZURE_RESOURCE_GROUP       = rg-notes-$EnvName
    AZURE_LOCATION             = eastus2
    AZURE_DEPLOYER_OBJECT_ID   = $SpId
    SQL_ADMIN_OBJECT_ID        = <your user object ID: az ad signed-in-user show --query id -o tsv>
    SQL_ADMIN_PRINCIPAL_NAME   = <your UPN: az ad signed-in-user show --query userPrincipalName -o tsv>

For the 'prod' environment, also enable "Required reviewers".
"@
