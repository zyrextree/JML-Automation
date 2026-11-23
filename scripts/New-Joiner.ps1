<#
.SYNOPSIS
    Onboards new users from a CSV file into Active Directory and (optionally) Microsoft Entra ID.
.DESCRIPTION
    For each row in the CSV: creates the AD user in the department OU, sets a random temporary
    password that must be changed at first logon, adds department + all-staff groups, and
    (with -IncludeEntra) creates the matching cloud user through Microsoft Graph.
    Run in a LAB only. Use -WhatIf first to preview changes.
.EXAMPLE
    .\New-Joiner.ps1 -CsvPath ..\samples\new_hires.csv -WhatIf
    .\New-Joiner.ps1 -CsvPath ..\samples\new_hires.csv -IncludeEntra
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$CsvPath,
    [string]$DomainDN    = 'DC=lab,DC=local',
    [string]$UpnSuffix   = 'lab.local',
    [string]$CloudDomain = '',          # e.g. yourtenant.onmicrosoft.com
    [switch]$IncludeEntra
)

Import-Module ActiveDirectory -ErrorAction Stop
. "$PSScriptRoot\Common.ps1"

if ($IncludeEntra) {
    if (-not $CloudDomain) { throw 'Use -CloudDomain yourtenant.onmicrosoft.com together with -IncludeEntra' }
    Connect-MgGraph -Scopes 'User.ReadWrite.All' -NoWelcome
}

$users = Import-Csv -Path $CsvPath
Write-Log "Joiner run started: $($users.Count) user(s) in $CsvPath"

foreach ($u in $users) {
    try {
        # --- validate input -------------------------------------------------
        foreach ($field in 'FirstName','LastName','Department','JobTitle') {
            if ([string]::IsNullOrWhiteSpace($u.$field)) { throw "Missing $field" }
        }
        $sam  = New-Username -FirstName $u.FirstName -LastName $u.LastName
        $ou   = "OU=$($u.Department),OU=Users,$DomainDN"
        $pass = New-TempPassword

        # --- Active Directory ----------------------------------------------
        if ($PSCmdlet.ShouldProcess($sam, 'Create AD user')) {
            New-ADUser -Name "$($u.FirstName) $($u.LastName)" `
                       -GivenName $u.FirstName -Surname $u.LastName `
                       -SamAccountName $sam -UserPrincipalName "$sam@$UpnSuffix" `
                       -Department $u.Department -Title $u.JobTitle `
                       -Path $ou -Enabled $true `
                       -AccountPassword (ConvertTo-SecureString $pass -AsPlainText -Force) `
                       -ChangePasswordAtLogon $true

            Add-ADGroupMember -Identity "GRP-$($u.Department)" -Members $sam
            Add-ADGroupMember -Identity 'GRP-AllStaff'          -Members $sam
            Write-Log "AD: created $sam in $ou and added groups" -Level OK
        }

        # --- Microsoft Entra ID --------------------------------------------
        if ($IncludeEntra -and $PSCmdlet.ShouldProcess($sam, 'Create Entra ID user')) {
            New-MgUser -DisplayName "$($u.FirstName) $($u.LastName)" `
                       -GivenName $u.FirstName -Surname $u.LastName `
                       -MailNickname $sam -UserPrincipalName "$sam@$CloudDomain" `
                       -Department $u.Department -JobTitle $u.JobTitle `
                       -AccountEnabled `
                       -PasswordProfile @{ Password = $pass; ForceChangePasswordNextSignIn = $true } | Out-Null
            Write-Log "Entra: created $sam@$CloudDomain" -Level OK
        }

        # Temporary password goes to the manager via a secure channel - never into the log.
        Write-Host "  $sam  temp password: $pass" -ForegroundColor Yellow
    }
    catch {
        Write-Log "FAILED for $($u.FirstName) $($u.LastName): $($_.Exception.Message)" -Level ERROR
    }
}
Write-Log 'Joiner run finished'
