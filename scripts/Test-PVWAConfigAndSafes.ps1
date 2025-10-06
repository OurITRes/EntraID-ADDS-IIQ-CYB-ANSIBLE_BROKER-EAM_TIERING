<#
.SYNOPSIS
  Valide la configuration PVWA & la segmentation des Safes par tiers (EAM).
  Contrôle aussi les plateformes, les rôles membres et exporte CSV + Markdown + JSON.

.DESCRIPTION
  - Authentifie sur PVWA (AuthType: CyberArk ou LDAP), récupère un token.
  - Inventorie Safes, Détails, Membres (rôles et permissions), Plateformes.
  - Détermine le Tier (T0/T1/T2) d’un Safe et des identités via Regex paramétrables.
  - Détecte et signale :
      * Fuite inter-tier (membre T1 dans Safe T0, etc.)
      * Présence de 'Vault Admins' sur Safe non-T0
      * Safes sans ManagingCPM (si -ExpectManagingCPM)
      * Plateformes non conformes (rotation/dual-control/complexité), *best-effort*
      * Violations “EAM strict” (si -EnableEAMStrictProfile)
  - Génère :
      * CSV : pvwa_violations_*.csv, pvwa_safes_*.csv
      * Markdown : pvwa_report_*.md
      * JSON : pvwa_inventory_*.json (safes + members + plateformes), pvwa_violations_*.json

.PARAMETER PVWAUrl
  URL de PVWA, ex: https://pvwa.internal.contoso

.PARAMETER AuthType
  'CyberArk' | 'LDAP' (type d’authentification REST)

.PARAMETER Username
  Compte API/lecteur PVWA (autorisations lecture sur Safes/Members/Platforms)

.PARAMETER Password
  Optionnel (sinon demandé de manière interactive)

.PARAMETER PageSize
  Pagination API (défaut 50)

.PARAMETER SafeTierRegexMap
  Dictionnaire Tier -> tableau de Regex pour déduire le Tier d’un Safe (name/description)

.PARAMETER IdentityTierRegexMap
  Dictionnaire Tier -> tableau de Regex pour déduire le Tier d’un membre (user/groupe)

.PARAMETER GlobalAllowedPrincipals
  Identités autorisées globalement (opérateurs T0 PAM) qui ne déclenchent pas de “TierLeak”

.PARAMETER ExpectManagingCPM
  Si $true, chaque Safe (hors exemptions) doit avoir un ManagingCPM

.PARAMETER ManagingCPM_ExemptSafePatterns
  Regex des Safes exemptés du ManagingCPM attendu (ex: ^BreakGlass, ^DISCOVERY, ^PSM$)

.PARAMETER EnableEAMStrictProfile
  Active des règles strictes :
    - Safes T0 : membres *uniquement* T0 (sauf GlobalAllowedPrincipals)
    - Safes T1 : interdiction membres T0/T2
    - Safes T2 : interdiction membres T0/T1
    - Interdiction 'Owner' inter-tier
    - Interdiction 'Vault Admins' hors T0

.PARAMETER OutDir
  Répertoire de sortie des rapports

# ----------------------------
# HOW-TO (exemples d’utilisation)
# ----------------------------

# 1) Auth CyberArk interne (lecture inventaire, contrôles par défaut)
.\Test-PVWAConfigAndSafes.ps1 `
  -PVWAUrl "https://pvwa.internal.contoso" `
  -AuthType CyberArk `
  -Username "pam_api_reader"

# 2) Auth LDAP + exigence ManagingCPM + profil EAM strict
.\Test-PVWAConfigAndSafes.ps1 `
  -PVWAUrl "https://pvwa.internal.contoso" `
  -AuthType LDAP `
  -Username "contoso\svc_pvwa_reader" `
  -ExpectManagingCPM:$true `
  -EnableEAMStrictProfile:$true `
  -ManagingCPM_ExemptSafePatterns '^BreakGlass','^DISCOVERY','^PSM$'

# 3) Adapter les Regex Tiers (aligner avec votre nomenclature)
.\Test-PVWAConfigAndSafes.ps1 `
  -PVWAUrl "https://pvwa.internal.contoso" `
  -AuthType CyberArk `
  -Username "pam_api_reader" `
  -SafeTierRegexMap @{ 'T0'=@('^T0_','-T0-'); 'T1'=@('^T1_'); 'T2'=@('^T2_') } `
  -IdentityTierRegexMap @{ 'T0'=@('^GRP_T0_'); 'T1'=@('^GRP_T1_'); 'T2'=@('^GRP_T2_') }

# 4) Sortie dans un répertoire dédié (pour CI/CD)
.\Test-PVWAConfigAndSafes.ps1 `
  -PVWAUrl "https://pvwa.internal.contoso" `
  -AuthType CyberArk `
  -Username "pam_api_reader" `
  -OutDir "C:\Reports\PVWA"

# Notes :
# - Le compte utilisé doit pouvoir lister Safes/Members/Platforms via l’API PVWA.
# - Les contrôles de plateformes sont “best-effort” (les noms/propriétés exposées peuvent varier selon versions/paramétrages).
# - Ajustez les Regex Tiers pour refléter votre naming convention (AGDLP/EAM).
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$PVWAUrl,

  [Parameter(Mandatory=$true)]
  [ValidateSet('CyberArk','LDAP')]
  [string]$AuthType,

  [Parameter(Mandatory=$true)]
  [string]$Username,

  [Parameter(Mandatory=$false)]
  [SecureString]$Password,

  [int]$PageSize = 50,

  [hashtable]$SafeTierRegexMap = @{
    'T0' = @('(^|[^A-Z0-9])T0([^A-Z0-9]|$)','-T0-','\[Tier\s*:\s*T0\]');
    'T1' = @('(^|[^A-Z0-9])T1([^A-Z0-9]|$)','-T1-','\[Tier\s*:\s*T1\]');
    'T2' = @('(^|[^A-Z0-9])T2([^A-Z0-9]|$)','-T2-','\[Tier\s*:\s*T2\]');
  },

  [hashtable]$IdentityTierRegexMap = @{
    'T0' = @('(^|[^A-Z0-9])T0([^A-Z0-9]|$)','-T0-','\bTier0\b');
    'T1' = @('(^|[^A-Z0-9])T1([^A-Z0-9]|$)','-T1-','\bTier1\b');
    'T2' = @('(^|[^A-Z0-9])T2([^A-Z0-9]|$)','-T2-','\bTier2\b');
  },

  [string[]]$GlobalAllowedPrincipals = @('Vault Admins','PVWAAppUsers-T0','PAM-Admins-T0'),

  [bool]$ExpectManagingCPM = $false,

  [string[]]$ManagingCPM_ExemptSafePatterns = @('^BreakGlass','^DISCOVERY','^PSM$'),

  [bool]$EnableEAMStrictProfile = $false,

  [string]$OutDir = "$(Get-Location)"
)

#region Helpers ---------------------------------------------------------------

function Write-Info($msg){ Write-Host "[*] $msg" -ForegroundColor Cyan }
function Write-Warn($msg){ Write-Warning "$msg" }
function Write-Err ($msg){ Write-Error "$msg" }

function Resolve-Tier {
  param(
    [Parameter(Mandatory=$true)][string]$Text,
    [Parameter(Mandatory=$true)][hashtable]$RegexMap
  )
  foreach($tier in $RegexMap.Keys){
    foreach($rx in $RegexMap[$tier]){
      if($Text -match $rx){ return $tier }
    }
  }
  return $null
}

function Invoke-PVWARequest {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$Method,
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter()][hashtable]$Headers,
    [Parameter()][object]$Body,
    [switch]$ExpectJson
  )
  $uri = ($PVWAUrl.TrimEnd('/')) + $Path
  $params = @{
    Method  = $Method
    Uri     = $uri
    Headers = $Headers
    TimeoutSec = 120
  }
  if($Body){
    $params['ContentType'] = 'application/json'
    $params['Body'] = ($Body | ConvertTo-Json -Depth 10)
  }
  try{
    $resp = Invoke-RestMethod @params
    if($ExpectJson){ return $resp } else { return $resp }
  } catch {
    throw "PVWA request failed: $Method $Path `n$($_.Exception.Message)"
  }
}

#endregion Helpers ------------------------------------------------------------

#region Auth ------------------------------------------------------------------

function New-AuthHeader {
  param([Parameter(Mandatory=$true)][string]$Token)
  return @{ 'Authorization' = $Token }
}

function Connect-PVWA {
  if(-not $Password){ $Password = Read-Host "Password for $Username" -AsSecureString }
  $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
  $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)

  $authPath = "/PasswordVault/API/Auth/$AuthType/Logon"
  $body = @{ username = $Username; password = $plain }

  $token = Invoke-PVWARequest -Method 'POST' -Path $authPath -Body $body -ExpectJson
  if([string]::IsNullOrWhiteSpace($token)){ throw "Empty token returned by PVWA." }
  Write-Info "Authenticated to PVWA as '$Username' using '$AuthType'."
  return $token
}

function Disconnect-PVWA {
  param([Parameter(Mandatory=$true)][hashtable]$Headers)
  try{
    Invoke-PVWARequest -Method 'POST' -Path '/PasswordVault/API/Auth/Logoff' -Headers $Headers | Out-Null
    Write-Info "Logged off PVWA."
  } catch { Write-Warn "Logoff PVWA failed: $($_.Exception.Message)" }
}

#endregion Auth ---------------------------------------------------------------

#region Inventory -------------------------------------------------------------

function Get-PVWA-Safes {
  param([Parameter(Mandatory=$true)][hashtable]$Headers)
  $offset = 0; $acc = @()
  do{
    $path = "/PasswordVault/api/Safes?limit=$PageSize&offset=$offset"
    $resp = Invoke-PVWARequest -Method 'GET' -Path $path -Headers $Headers -ExpectJson
    if($resp -and $resp.value){ $acc += $resp.value }
    $total = $resp.total -as [int]
    $offset += $PageSize
  } while ($total -and $offset -lt $total)
  return $acc
}

function Get-PVWA-SafeDetails {
  param([Parameter(Mandatory=$true)][hashtable]$Headers,[Parameter(Mandatory=$true)][string]$SafeName)
  $path = "/PasswordVault/api/Safes/$([uri]::EscapeDataString($SafeName))"
  return Invoke-PVWARequest -Method 'GET' -Path $path -Headers $Headers -ExpectJson
}

function Get-PVWA-SafeMembers {
  param([Parameter(Mandatory=$true)][hashtable]$Headers,[Parameter(Mandatory=$true)][string]$SafeName)
  $offset = 0; $acc = @()
  do{
    $path = "/PasswordVault/api/Safes/$([uri]::EscapeDataString($SafeName))/Members?limit=$PageSize&offset=$offset"
    $resp = Invoke-PVWARequest -Method 'GET' -Path $path -Headers $Headers -ExpectJson
    if($resp -and $resp.value){ $acc += $resp.value }
    $total = $resp.total -as [int]
    $offset += $PageSize
  } while ($total -and $offset -lt $total)
  return $acc
}

function Get-PVWA-Platforms {
  param([Parameter(Mandatory=$true)][hashtable]$Headers)
  $offset = 0; $acc = @()
  do{
    $path = "/PasswordVault/api/Platforms?limit=$PageSize&offset=$offset"
    $resp = Invoke-PVWARequest -Method 'GET' -Path $path -Headers $Headers -ExpectJson
    if($resp -and $resp.value){ $acc += $resp.value }
    $total = $resp.total -as [int]
    $offset += $PageSize
  } while ($total -and $offset -lt $total)
  return $acc
}

#endregion Inventory ----------------------------------------------------------

#region Policy & Platform Checks ---------------------------------------------

function Test-IsExempt ($name, [string[]]$patterns){
  foreach($p in $patterns){ if($name -match $p){ return $true } }
  return $false
}

function Test-PlatformCompliance {
  <#
    Best-effort : selon versions, les propriétés exposées par /Platforms varient.
    On cherche des indicateurs clés (noms, flags connus) dans l’objet renvoyé.
    Output: liste d’objets { PlatformID, Issue, Expected, Actual }
  #>
  param(
    [Parameter(Mandatory=$true)][object[]]$Platforms
  )
  $issues = New-Object System.Collections.Generic.List[object]
  foreach($p in $Platforms){
    $pid = $p.platformID
    $pname = $p.platformDisplayName
    $json = ($p | ConvertTo-Json -Depth 10)

    # Rotation (look for "changePassword"/"automatic/*" like flags in JSON)
    if($json -notmatch 'changePassword|rotate|automatic'){
      $issues.Add([pscustomobject]@{
        PlatformID = $pid; Platform = $pname; Issue='RotationUnknownOrDisabled'
        Expected='Rotation/ChangePassword enabled'; Actual='No obvious rotation flag found'
      })
    }

    # Dual control (keywords)
    if($json -notmatch 'dual.?control|approval|concurrent'){
      $issues.Add([pscustomobject]@{
        PlatformID = $pid; Platform = $pname; Issue='DualControlNotDetected'
        Expected='Dual-control/approval policy enforced for sensitive platforms'; Actual='No dual-control keyword found'
      })
    }

    # Password policy / complexity (keywords)
    if($json -notmatch 'complexity|minLength|min.*length'){
      $issues.Add([pscustomobject]@{
        PlatformID = $pid; Platform = $pname; Issue='ComplexityPolicyUnknown'
        Expected='Minimum complexity/length defined'; Actual='No complexity keyword found'
      })
    }
  }
  return $issues
}

function Analyze-Safes {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][hashtable]$Headers,
    [Parameter(Mandatory=$true)][object[]]$Safes,
    [Parameter(Mandatory=$true)][hashtable]$SafeTierRegexMap,
    [Parameter(Mandatory=$true)][hashtable]$IdentityTierRegexMap
  )

  $violations = New-Object System.Collections.Generic.List[object]
  $safeSummaries = New-Object System.Collections.Generic.List[object]
  $inventory = New-Object System.Collections.Generic.List[object]

  foreach($s in $Safes){
    $safeName = $s.safeName
    $detail = Get-PVWA-SafeDetails -Headers $Headers -SafeName $safeName
    $desc = $detail.safeDescription
    $managingCPM = $detail.managingCPM
    $olac = $detail.isOLACEnabled

    $safeText = "$safeName `n$desc"
    $safeTier = Resolve-Tier -Text $safeText -RegexMap $SafeTierRegexMap
    if(-not $safeTier){ $safeTier = 'Unknown' }

    if($ExpectManagingCPM -and -not (Test-IsExempt $safeName $ManagingCPM_ExemptSafePatterns)){
      if([string]::IsNullOrWhiteSpace($managingCPM)){
        $violations.Add([pscustomobject]@{
          Type='SafePolicy'; Safe=$safeName; Issue='ManagingCPMMissing'
          Expected='ManagingCPM configured'; Actual='null/empty'
          SafeTier=$safeTier; Member=''; MemberTier=''; Role=''
          Details='Platform rotation expected but ManagingCPM is empty'
        })
      }
    }

    $members = Get-PVWA-SafeMembers -Headers $Headers -SafeName $safeName
    foreach($m in $members){
      $memberName = $m.memberName
      $memberType = $m.memberType
      $role = $m.memberRole # ex: Owner/Manager/Auditor/User — selon version API
      $permissionsJson = ($m.permissions | ConvertTo-Json -Depth 5)

      if($GlobalAllowedPrincipals -contains $memberName){ continue }

      $memberTier = Resolve-Tier -Text $memberName -RegexMap $IdentityTierRegexMap
      if(-not $memberTier){ $memberTier = 'Unknown' }

      # Base: fuite inter-tier
      if($safeTier -ne 'Unknown' -and $memberTier -ne 'Unknown' -and $safeTier -ne $memberTier){
        $violations.Add([pscustomobject]@{
          Type='TierLeak'; Safe=$safeName; Issue='MemberTierMismatch'
          Expected=$safeTier; Actual=$memberTier; SafeTier=$safeTier
          Member=$memberName; MemberTier=$memberTier; Role=$role
          Details="Member '$memberName' ($memberType/$role) has permissions on '$safeName' ($safeTier)"
        })
      }

      # Profil EAM strict : règles supplémentaires
      if($EnableEAMStrictProfile -and $safeTier -ne 'Unknown' -and $memberTier -ne 'Unknown'){
        # Interdiction Owner inter-tier
        if($role -match 'Owner' -and $safeTier -ne $memberTier){
          $violations.Add([pscustomobject]@{
            Type='EAMStrict'; Safe=$safeName; Issue='OwnerCrossTierForbidden'
            Expected=$safeTier; Actual=$memberTier; SafeTier=$safeTier
            Member=$memberName; MemberTier=$memberTier; Role=$role
            Details='Owner role must match Safe tier under EAM strict profile'
          })
        }
        # Interdiction Vault Admins hors T0
        if($memberName -eq 'Vault Admins' -and $safeTier -ne 'T0'){
          $violations.Add([pscustomobject]@{
            Type='EAMStrict'; Safe=$safeName; Issue='VaultAdminsOnNonT0'
            Expected='No Vault Admins on non-T0 Safes'; Actual='Vault Admins present'
            SafeTier=$safeTier; Member=$memberName; MemberTier='T0'; Role=$role
            Details='Restrict Vault Admins to Tier0 control plane only'
          })
        }
        # Interdiction T0 sur Safe T1/T2 (sauf GlobalAllowedPrincipals déjà exclus)
        if($safeTier -ne 'T0' -and $memberTier -eq 'T0'){
          $violations.Add([pscustomobject]@{
            Type='EAMStrict'; Safe=$safeName; Issue='Tier0MemberOnLowerTierSafe'
            Expected=$safeTier; Actual=$memberTier; SafeTier=$safeTier
            Member=$memberName; MemberTier=$memberTier; Role=$role
            Details='Tier 0 principals cannot have access to T1/T2 safes under strict profile'
          })
        }
      }

      # Permission risquée : Vault Admins sur Safe non-T0 (même hors EAM strict)
      if($safeTier -ne 'T0' -and $memberName -eq 'Vault Admins'){
        $violations.Add([pscustomobject]@{
          Type='ExcessivePrivilege'; Safe=$safeName; Issue='VaultAdminsOnNonT0Safe'
          Expected='No Vault Admins on non-T0 Safes'; Actual='Vault Admins present'
          SafeTier=$safeTier; Member=$memberName; MemberTier='T0'; Role=$role
          Details='Consider delegating via tier-appropriate groups'
        })
      }
    }

    $safeSummaries.Add([pscustomobject]@{
      SafeName     = $safeName
      SafeTier     = $safeTier
      ManagingCPM  = $managingCPM
      OLACEnabled  = $olac
      MembersCount = ($members | Measure-Object).Count
      Description  = $desc
    })

    # Inventaire structuré (pour export JSON)
    $inventory.Add([pscustomobject]@{
      SafeName = $safeName
      SafeTier = $safeTier
      Details  = $detail
      Members  = $members
    })
  }

  return [pscustomobject]@{
    Violations = $violations
    Summary    = $safeSummaries
    Inventory  = $inventory
  }
}

#endregion Policy & Platform Checks ------------------------------------------

#region Main ------------------------------------------------------------------

$ts = (Get-Date).ToString('yyyyMMdd_HHmmss')
$outCsvViol = Join-Path $OutDir "pvwa_violations_$ts.csv"
$outCsvSafe = Join-Path $OutDir "pvwa_safes_$ts.csv"
$outMd      = Join-Path $OutDir "pvwa_report_$ts.md"
$outJsonInv = Join-Path $OutDir "pvwa_inventory_$ts.json"
$outJsonViol= Join-Path $OutDir "pvwa_violations_$ts.json"

try{
  Write-Info "Connecting to PVWA: $PVWAUrl ..."
  $token = Connect-PVWA
  $headers = New-AuthHeader -Token $token

  Write-Info "Fetching platforms..."
  $platforms = Get-PVWA-Platforms -Headers $headers

  Write-Info "Fetching safes..."
  $safes = Get-PVWA-Safes -Headers $headers
  Write-Info ("Safes found: {0}" -f ($safes | Measure-Object).Count)

  Write-Info "Analyzing safes, members & policies..."
  $result = Analyze-Safes -Headers $headers -Safes $safes -SafeTierRegexMap $SafeTierRegexMap -IdentityTierRegexMap $IdentityTierRegexMap
  $viol = $result.Violations
  $sum  = $result.Summary
  $inv  = $result.Inventory

  Write-Info "Checking platform compliance (best-effort)..."
  $platformIssues = Test-PlatformCompliance -Platforms $platforms
  foreach($pi in $platformIssues){ $viol += $pi }

  Write-Info "Writing CSV reports..."
  $viol | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $outCsvViol
  $sum  | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $outCsvSafe

  Write-Info "Writing JSON exports..."
  $inv | ConvertTo-Json -Depth 12 | Out-File -FilePath $outJsonInv -Encoding UTF8
  $viol | ConvertTo-Json -Depth 8  | Out-File -FilePath $outJsonViol -Encoding UTF8

  # Markdown summary
  $totalSafes = ($safes | Measure-Object).Count
  $totalViol  = ($viol | Measure-Object).Count
  $byType = $viol | Group-Object Type | Sort-Object Count -Descending
  $md = @()
  $md += "# PVWA Validation Report ($ts)"
  $md += ""
  $md += "* PVWA: $PVWAUrl"
  $md += "* Auth: $AuthType"
  $md += "* Safes: $totalSafes"
  $md += "* Violations: $totalViol"
  $md += "* EAM strict profile: $EnableEAMStrictProfile"
  $md += ""
  if($byType){
    $md += "## Violations by Type"
    foreach($g in $byType){ $md += "- **$($g.Name)**: $($g.Count)" }
    $md += ""
  }
  if($platformIssues -and $platformIssues.Count -gt 0){
    $md += "## Platform Compliance (best-effort)"
    $md += "| PlatformID | Platform | Issue | Expected | Actual |"
    $md += "|---|---|---|---|---|"
    foreach($p in ($platformIssues | Select-Object -First 20)){
      $md += "| $($p.PlatformID) | $($p.Platform) | $($p.Issue) | $($p.Expected) | $($p.Actual) |"
    }
    $md += ""
  }
  $md += "## Top 25 Violations"
  $md += "| Type | Safe | Issue | Expected | Actual | SafeTier | Member | MemberTier | Role | Details |"
  $md += "|---|---|---|---|---|---|---|---|---|---|"
  foreach($v in ($viol | Select-Object -First 25)){
    $md += "| $($v.Type) | $($v.Safe) | $($v.Issue) | $($v.Expected) | $($v.Actual) | $($v.SafeTier) | $($v.Member) | $($v.MemberTier) | $($v.Role) | $($v.Details) |"
  }
  $md += ""
  $md += "## Notes"
  $md += "- Tier resolution uses RegEx on Safe name/description and on Member names. Tune **SafeTierRegexMap** and **IdentityTierRegexMap** as needed."
  if($ExpectManagingCPM){
    $md += "- ManagingCPM is expected on Safes (except those matching **ManagingCPM_ExemptSafePatterns**)."
  } else {
    $md += "- ManagingCPM check disabled (set **-ExpectManagingCPM:\$true** to enforce)."
  }
  $md += "- Global allowed principals bypass tier-leak: $(($GlobalAllowedPrincipals -join ', '))"
  $md += "- Platform checks are **best-effort** and rely on keywords in API outputs; adjust logic if your platform objects expose structured flags."

  $md | Out-File -FilePath $outMd -Encoding UTF8

  Write-Host ""
  Write-Host "✅ Done." -ForegroundColor Green
  Write-Host ("CSV (violations): {0}" -f $outCsvViol)
  Write-Host ("CSV (safes):      {0}" -f $outCsvSafe)
  Write-Host ("Markdown:         {0}" -f $outMd)
  Write-Host ("JSON (inventory): {0}" -f $outJsonInv)
  Write-Host ("JSON (violations):{0}" -f $outJsonViol)

} catch {
  Write-Err $_.Exception.Message
} finally {
  if($headers){ Disconnect-PVWA -Headers $headers }
}

#endregion Main ---------------------------------------------------------------
