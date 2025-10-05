<# 
validate_vault_security.ps1
Audit de sécurité de la CyberArk Digital Vault (hors EAM)
NB: Script communautaire inspiré des bonnes pratiques CyberArk ; non-officiel.
#>

$Report = @()

function Add-Check {
    param($Name, $Result, $Details)
    $script:Report += [pscustomobject]@{
        Check = $Name
        Result = $Result
        Details = $Details
    }
}

# 1) Non appartenance au domaine
try {
    $cs = Get-CimInstance Win32_ComputerSystem
    if ($cs.PartOfDomain -eq $false) {
        Add-Check "Domain membership" "PASS" "Machine non jointe à un domaine AD"
    } else {
        Add-Check "Domain membership" "FAIL" "Machine jointe au domaine $($cs.Domain)"
    }
} catch {
    Add-Check "Domain membership" "WARN" "Impossible de déterminer l'appartenance au domaine: $($_.Exception.Message)"
}

# 2) Ports ouverts 1858/1859 uniquement (contrôle indicatif)
try {
    $ports = (Get-NetTCPConnection -State Listen | Select-Object -ExpandProperty LocalPort | Sort-Object -Unique)
    $required = @('1858','1859')
    $extra = $ports | Where-Object { $_ -notin $required }
    if (($required | Where-Object {$_ -in $ports}).Count -eq 2 -and $extra.Count -eq 0) {
        Add-Check "Listening ports" "PASS" "Ports 1858/1859 uniquement"
    } else {
        Add-Check "Listening ports" "FAIL" "Ports à l'écoute: $($ports -join ',')"
    }
} catch {
    Add-Check "Listening ports" "WARN" "Impossible de lister les ports: $($_.Exception.Message)"
}

# 3) FIPS mode
try {
    $fips = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\FipsAlgorithmPolicy" -Name Enabled -ErrorAction Stop
    if ($fips.Enabled -eq 1) {
        Add-Check "FIPS mode" "PASS" "FIPSAlgorithmPolicy Enabled=1"
    } else {
        Add-Check "FIPS mode" "FAIL" "FIPSAlgorithmPolicy Enabled=$($fips.Enabled)"
    }
} catch {
    Add-Check "FIPS mode" "WARN" "Registre introuvable: $($_.Exception.Message)"
}

# 4) Signature du binaire PrivateArk (chemin à adapter)
$binPath = "C:\Program Files (x86)\PrivateArk\Server\PADR.exe"
try {
    if (Test-Path $binPath) {
        $sig = Get-AuthenticodeSignature -FilePath $binPath
        if ($sig.SignerCertificate.Subject -like "*CyberArk*") {
            Add-Check "Binary signature" "PASS" "Signé par: $($sig.SignerCertificate.Subject)"
        } else {
            Add-Check "Binary signature" "FAIL" "Signature inattendue: $($sig.SignerCertificate.Subject)"
        }
    } else {
        Add-Check "Binary signature" "WARN" "Binaire non trouvé: $binPath"
    }
} catch {
    Add-Check "Binary signature" "WARN" "Erreur vérification signature: $($_.Exception.Message)"
}

# 5) Patching OS (dernier hotfix < 35 jours)
try {
    $last = (Get-HotFix | Sort-Object -Property InstalledOn -Descending | Select-Object -First 1).InstalledOn
    if ($last -and ((Get-Date) - $last).Days -le 35) {
        Add-Check "OS patching" "PASS" "Dernier hotfix: $last"
    } else {
        Add-Check "OS patching" "FAIL" "Dernier hotfix: $last (ancien)"
    }
} catch {
    Add-Check "OS patching" "WARN" "Impossible de lire les hotfix: $($_.Exception.Message)"
}

# 6) Comptes locaux (indicatif)
try {
    $localUsers = Get-LocalUser | Select-Object -ExpandProperty Name
    Add-Check "Local accounts (indicatif)" "INFO" ("Comptes locaux: " + ($localUsers -join ','))
} catch {
    Add-Check "Local accounts (indicatif)" "WARN" "Impossible de lister les comptes locaux: $($_.Exception.Message)"
}

# 7) TLS – Vérification des suites supportées (si cmdlet disponible)
try {
    if (Get-Command Get-TlsCipherSuite -ErrorAction SilentlyContinue) {
        $weak = @('RC4','3DES','NULL','MD5','DES','EXPORT','PSK','DHE_DSS')
        $suites = Get-TlsCipherSuite | Select-Object Name
        $bad = @()
        foreach ($s in $suites) {
            foreach ($w in $weak) {
                if ($s.Name -match $w) { $bad += $s.Name }
            }
        }
        if ($bad.Count -eq 0) {
            Add-Check "TLS cipher suites" "PASS" "Aucune suite faible détectée (RC4/3DES/DES/NULL/MD5/EXPORT/PSK/DSS)"
        } else {
            Add-Check "TLS cipher suites" "FAIL" ("Suites faibles détectées: " + ($bad | Sort-Object -Unique -join ','))
        }
    } else {
        Add-Check "TLS cipher suites" "WARN" "Get-TlsCipherSuite indisponible (version Windows/PowerShell). Vérifier manuellement la configuration TLS."
    }
} catch {
    Add-Check "TLS cipher suites" "WARN" "Erreur lors de la vérification des suites TLS: $($_.Exception.Message)"
}

# 8) Services attendus – Vérification minimale
# Sur la Digital Vault, le service critique est "PrivateArk Server". D'autres services CyberArk (CPM/PSM/PVWA) ne doivent PAS tourner sur ce serveur.
try {
    $expectedRunning = @('PrivateArk Server')
    $forbiddenPrefixes = @('CyberArk Central Policy Manager','CyberArk Privileged Session Manager','IIS','MSSQL','SQL Server','W3SVC')

    $svc = Get-Service | Select-Object DisplayName, Status

    $missing = @()
    foreach ($e in $expectedRunning) {
        $match = $svc | Where-Object { $_.DisplayName -like "$e*" -and $_.Status -eq 'Running' }
        if (-not $match) { $missing += $e }
    }

    $forbidden = @()
    foreach ($f in $forbiddenPrefixes) {
        $hit = $svc | Where-Object { $_.DisplayName -like "$f*" -and $_.Status -eq 'Running' }
        if ($hit) { $forbidden += ($hit | ForEach-Object { $_.DisplayName }) }
    }

    if ($missing.Count -eq 0 -and $forbidden.Count -eq 0) {
        Add-Check "Services (Vault host)" "PASS" "Service 'PrivateArk Server' actif, aucun service interdit (CPM/PSM/PVWA/IIS/SQL)"
    } else {
        $detail = @()
        if ($missing.Count -gt 0) { $detail += "Manquants: " + ($missing -join ',') }
        if ($forbidden.Count -gt 0) { $detail += "Interdits actifs: " + ($forbidden -join ',') }
        Add-Check "Services (Vault host)" "FAIL" ($detail -join ' | ')
    }
} catch {
    Add-Check "Services (Vault host)" "WARN" "Erreur lors de la vérification des services: $($_.Exception.Message)"
}

# Export
$csv = Join-Path $PSScriptRoot "vault_security_report.csv"
$md  = Join-Path $PSScriptRoot "vault_security_report.md"

$Report | Export-Csv -NoTypeInformation -Delimiter ';' -Path $csv

# Markdown simple
$mdContent = @("# Vault Security Report", "", "| Check | Result | Details |", "|------|--------|---------|")
foreach ($r in $Report) {
    $mdContent += "| {0} | {1} | {2} |" -f $r.Check, $r.Result, ($r.Details -replace '\|','/')
}
$mdContent -join "`n" | Out-File -FilePath $md -Encoding UTF8

Write-Host "Report written:"
Write-Host $csv
Write-Host $md
