param(
    [Parameter(Mandatory=$true)][string]$Sam
)
# Sample constrained cmdlet to run inside JEA-T1
Get-ADUser -Identity $Sam | Select-Object SamAccountName, Enabled
