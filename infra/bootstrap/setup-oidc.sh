#!/usr/bin/env bash
# One-time bootstrap: create GitHub OIDC app registrations, federated credentials,
# and subscription role assignments for the Notes sample app.
#
# Prerequisites: az CLI, logged in as a user with:
#   - Owner or User Access Administrator on the subscription
#   - Application Developer (or better) in Entra ID
#
# Usage:
#   ./setup-oidc.sh <github-owner> <github-repo> <env-name> [subscription-id]
# Example:
#   ./setup-oidc.sh amis-4630 sample-app dev
set -euo pipefail

GH_OWNER="${1:?github owner required}"
GH_REPO="${2:?github repo required}"
ENV_NAME="${3:?environment name required (dev|prod)}"
SUB_ID="${4:-$(az account show --query id -o tsv)}"
TENANT_ID="$(az account show --query tenantId -o tsv)"

APP_NAME="gh-oidc-${GH_OWNER}-${GH_REPO}-${ENV_NAME}"

echo "==> Subscription: $SUB_ID"
echo "==> Tenant:       $TENANT_ID"
echo "==> App name:     $APP_NAME"

# 1. App registration + service principal (idempotent).
APP_ID="$(az ad app list --display-name "$APP_NAME" --query '[0].appId' -o tsv)"
if [[ -z "$APP_ID" ]]; then
  echo "==> Creating app registration"
  APP_ID="$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)"
fi

SP_ID="$(az ad sp list --filter "appId eq '$APP_ID'" --query '[0].id' -o tsv)"
if [[ -z "$SP_ID" ]]; then
  echo "==> Creating service principal"
  SP_ID="$(az ad sp create --id "$APP_ID" --query id -o tsv)"
fi

# 2. Federated credential for GitHub Environment.
FIC_NAME="gh-env-${ENV_NAME}"
SUBJECT="repo:${GH_OWNER}/${GH_REPO}:environment:${ENV_NAME}"
EXISTING_FIC="$(az ad app federated-credential list --id "$APP_ID" --query "[?name=='$FIC_NAME'].name" -o tsv)"
if [[ -z "$EXISTING_FIC" ]]; then
  echo "==> Adding federated credential for $SUBJECT"
  az ad app federated-credential create --id "$APP_ID" --parameters "$(cat <<JSON
{
  "name": "$FIC_NAME",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "$SUBJECT",
  "audiences": ["api://AzureADTokenExchange"]
}
JSON
)"
fi

# 3. Also add a pull_request federated credential for what-if on PRs.
FIC_PR_NAME="gh-pr"
PR_SUBJECT="repo:${GH_OWNER}/${GH_REPO}:pull_request"
EXISTING_PR_FIC="$(az ad app federated-credential list --id "$APP_ID" --query "[?name=='$FIC_PR_NAME'].name" -o tsv)"
if [[ -z "$EXISTING_PR_FIC" && "$ENV_NAME" == "dev" ]]; then
  echo "==> Adding federated credential for pull_request"
  az ad app federated-credential create --id "$APP_ID" --parameters "$(cat <<JSON
{
  "name": "$FIC_PR_NAME",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "$PR_SUBJECT",
  "audiences": ["api://AzureADTokenExchange"]
}
JSON
)"
fi

# 4. Subscription-scope role assignments.
#    - Contributor:            create/manage resources
#    - User Access Administrator: assign data-plane roles in Bicep (KV RBAC, etc.)
for ROLE in "Contributor" "User Access Administrator"; do
  echo "==> Assigning '$ROLE' to SP at subscription scope"
  az role assignment create \
    --assignee-object-id "$SP_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "$ROLE" \
    --scope "/subscriptions/$SUB_ID" \
    --only-show-errors >/dev/null || true
done

cat <<EOF

==> DONE.

Add the following to GitHub Environment '$ENV_NAME' in
https://github.com/$GH_OWNER/$GH_REPO/settings/environments :

  Variables:
    AZURE_CLIENT_ID            = $APP_ID
    AZURE_TENANT_ID            = $TENANT_ID
    AZURE_SUBSCRIPTION_ID      = $SUB_ID
    AZURE_RESOURCE_GROUP       = rg-notes-$ENV_NAME
    AZURE_LOCATION             = eastus2
    AZURE_DEPLOYER_OBJECT_ID   = $SP_ID
    SQL_ADMIN_OBJECT_ID        = <your user object ID: az ad signed-in-user show --query id -o tsv>
    SQL_ADMIN_PRINCIPAL_NAME   = <your UPN: az ad signed-in-user show --query userPrincipalName -o tsv>

For the 'prod' environment, also enable "Required reviewers".
EOF
