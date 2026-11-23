# Shared helper functions, dot-sourced by the other scripts.

$script:LogFile = Join-Path $PSScriptRoot "..\logs\jml_$(Get-Date -Format 'yyyy-MM-dd').log"
New-Item -ItemType Directory -Path (Split-Path $script:LogFile) -Force | Out-Null

function Write-Log {
    param(
        [Parameter(Mandatory)] [string]$Message,
        [ValidateSet('INFO','OK','WARN','ERROR')] [string]$Level = 'INFO'
    )
    $line = "{0} [{1}] {2} (by {3})" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message, $env:USERNAME
    Add-Content -Path $script:LogFile -Value $line
    $color = @{ INFO = 'Gray'; OK = 'Green'; WARN = 'Yellow'; ERROR = 'Red' }[$Level]
    Write-Host $line -ForegroundColor $color
}

function New-Username {
    # firstname.lastname, lowercase, Danish letters replaced, number added if it already exists
    param([string]$FirstName, [string]$LastName)
    $base = ("$FirstName.$LastName").ToLower() -replace 'æ','ae' -replace 'ø','oe' -replace 'å','aa' -replace '[^a-z0-9.]',''
    if ($base.Length -gt 20) { $base = $base.Substring(0,20) }   # sAMAccountName limit
    $name = $base; $i = 1
    while (Get-ADUser -Filter "SamAccountName -eq '$name'" -ErrorAction SilentlyContinue) {
        $i++; $name = "$($base.Substring(0, [Math]::Min($base.Length, 19)))$i"
    }
    return $name
}

function New-TempPassword {
    param([int]$Length = 14)
    $upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; $lower = 'abcdefghijkmnopqrstuvwxyz'
    $digit = '23456789';                $sym   = '!#%+?'
    $all   = $upper + $lower + $digit + $sym
    $chars = @($upper[(Get-Random -Max $upper.Length)], $lower[(Get-Random -Max $lower.Length)],
               $digit[(Get-Random -Max $digit.Length)], $sym[(Get-Random -Max $sym.Length)])
    $chars += 1..($Length - 4) | ForEach-Object { $all[(Get-Random -Max $all.Length)] }
    return -join ($chars | Sort-Object { Get-Random })
}
