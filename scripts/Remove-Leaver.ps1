<#
.SYNOPSIS
    Securely offboards a user: disable (never delete), remove access, block cloud sign-in.
.DESCRIPTION
    - Disables the AD account and adds the leave date + ticket number to the description
    - Removes all group memberships except Domain Users (list saved to the log for audit)
    - Moves the account to the "Disabled Users" OU
    - With -IncludeEntra: blocks sign-in and revokes all active sessions in Entra ID
.EXAMPLE
    .\Remove-Leaver.ps1 -SamAccountName lars.nielsen -Ticket INC0012345 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$SamAccountName,
    [Parameter(Mandatory)] [string]$Ticket,
    [string]$DomainDN = 'DC=lab,DC=local',
    [string]$CloudDomain = '',
    [switch]$IncludeEntra
)

Import-Module ActiveDirectory -ErrorAction Stop
. "$PSScriptRoot\Common.ps1"

try {
    $user   = Get-ADUser -Identity $SamAccountName -Properties MemberOf -ErrorAction Stop
    $groups = $user.MemberOf | ForEach-Object { (Get-ADGroup $_).Name }
    $today  = Get-Date -Format 'yyyy-MM-dd'

    if ($PSCmdlet.ShouldProcess($SamAccountName, 'Offboard user')) {
        Write-Log "Leaver $SamAccountName ($Ticket) had groups: $($groups -join ', ')"

        Disable-ADAccount -Identity $SamAccountName
        Set-ADUser -Identity $SamAccountName -Description "Disabled $today - $Ticket"
        foreach ($g in $groups) {
            Remove-ADGroupMember -Identity $g -Members $SamAccountName -Confirm:$false
        }
        Move-ADObject -Identity $user.DistinguishedName -TargetPath "OU=Disabled Users,$DomainDN"
        Write-Log "AD: disabled $SamAccountName, removed $($groups.Count) group(s), moved to Disabled Users" -Level OK

        if ($IncludeEntra) {
            Connect-MgGraph -Scopes 'User.ReadWrite.All' -NoWelcome
            $upn = "$SamAccountName@$CloudDomain"
            Update-MgUser -UserId $upn -AccountEnabled:$false
            Revoke-MgUserSignInSession -UserId $upn | Out-Null
            Write-Log "Entra: blocked sign-in and revoked sessions for $upn" -Level OK
        }
    }
}
catch {
    Write-Log "FAILED to offboard ${SamAccountName}: $($_.Exception.Message)" -Level ERROR
}
