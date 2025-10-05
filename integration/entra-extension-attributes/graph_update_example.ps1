# Requires Microsoft.Graph PowerShell
# Connect-MgGraph -Scopes "User.ReadWrite.All"
param(
    [Parameter(Mandatory=$true)][string]$UserPrincipalName,
    [ValidateSet("T0","T1","T2")][string]$Tier = "T2",
    [ValidateSet("PRD","DEV","TST","SBX")][string]$Environment = "PRD",
    [ValidateSet("Standard","Admin","Service")][string]$AccountType = "Standard"
)
$body = @{
    extensionAttribute10 = $Tier
    extensionAttribute11 = $Environment
    extensionAttribute12 = $AccountType
}
$user = Get-MgUser -UserId $UserPrincipalName
Update-MgUser -UserId $user.Id -BodyParameter $body
