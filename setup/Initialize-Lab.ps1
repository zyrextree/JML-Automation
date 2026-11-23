<#
.SYNOPSIS
    Creates the OUs and security groups the JML scripts expect. Run once on the lab domain controller.
#>
param([string]$DomainDN = 'DC=lab,DC=local')

Import-Module ActiveDirectory -ErrorAction Stop
$departments = 'IT', 'Sales', 'HR'

function Add-OU($Name, $Path) {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$Name'" -SearchBase $Path -SearchScope OneLevel -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $Name -Path $Path -ProtectedFromAccidentalDeletion $true
        Write-Host "Created OU $Name in $Path" -ForegroundColor Green
    }
}

Add-OU 'Users'          $DomainDN
Add-OU 'Groups'         $DomainDN
Add-OU 'Disabled Users' $DomainDN
foreach ($d in $departments) { Add-OU $d "OU=Users,$DomainDN" }

foreach ($g in ($departments | ForEach-Object { "GRP-$_" }) + 'GRP-AllStaff') {
    if (-not (Get-ADGroup -Filter "Name -eq '$g'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $g -GroupScope Global -GroupCategory Security -Path "OU=Groups,$DomainDN"
        Write-Host "Created group $g" -ForegroundColor Green
    }
}
Write-Host 'Lab structure ready.' -ForegroundColor Cyan
