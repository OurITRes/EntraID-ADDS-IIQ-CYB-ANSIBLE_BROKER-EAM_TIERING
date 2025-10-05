param(
    [Parameter(Mandatory=$true)][string]$Sam,
    [Parameter(Mandatory=$true)][string]$OU,
    [Parameter(Mandatory=$true)][string]$UPNSuffix
)
Import-Module ActiveDirectory
if (-not (Get-ADUser -Filter "sAMAccountName -eq '$Sam'")) {
    New-ADUser -Name $Sam -SamAccountName $Sam -UserPrincipalName "$Sam@$UPNSuffix" -Path $OU -Enabled $true
}
