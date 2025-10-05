# Sample constrained cmdlet to run inside JEA-T0
Get-ADDomain | Select-Object Name, PDCEmulator, RIDMaster, InfrastructureMaster
