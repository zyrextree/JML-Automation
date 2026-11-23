<#
.SYNOPSIS
    Exports a CSV report of all users: department, title, enabled, last logon and groups.
.EXAMPLE
    .\Get-UserReport.ps1
#>
param([string]$SearchBase = 'OU=Users,DC=lab,DC=local')

Import-Module ActiveDirectory -ErrorAction Stop
. "$PSScriptRoot\Common.ps1"

$out = Join-Path $PSScriptRoot "..\reports\users_$(Get-Date -Format 'yyyy-MM-dd').csv"
New-Item -ItemType Directory -Path (Split-Path $out) -Force | Out-Null

Get-ADUser -Filter * -SearchBase $SearchBase -Properties Department, Title, Enabled, LastLogonDate, MemberOf |
    Select-Object SamAccountName, Name, Department, Title, Enabled, LastLogonDate,
        @{ n = 'Groups'; e = { ($_.MemberOf | ForEach-Object { ($_ -split ',')[0] -replace '^CN=' }) -join '; ' } } |
    Sort-Object Department, Name |
    Export-Csv -Path $out -NoTypeInformation -Encoding UTF8

Write-Log "Report saved to $out" -Level OK
