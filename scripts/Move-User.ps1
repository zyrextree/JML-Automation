<#
.SYNOPSIS
    Moves a user to a new department: OU, groups and job title (AD and optionally Entra ID).
.EXAMPLE
    .\Move-User.ps1 -SamAccountName mette.jensen -NewDepartment Sales -NewJobTitle "Account Manager" -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$SamAccountName,
    [Parameter(Mandatory)] [string]$NewDepartment,
    [string]$NewJobTitle,
    [string]$DomainDN = 'DC=lab,DC=local',
    [string]$CloudDomain = '',
    [switch]$IncludeEntra
)

Import-Module ActiveDirectory -ErrorAction Stop
. "$PSScriptRoot\Common.ps1"

try {
    $user  = Get-ADUser -Identity $SamAccountName -Properties Department, Title -ErrorAction Stop
    $oldDept = $user.Department
    $newOU = "OU=$NewDepartment,OU=Users,$DomainDN"

    if ($PSCmdlet.ShouldProcess($SamAccountName, "Move $oldDept -> $NewDepartment")) {
        Remove-ADGroupMember -Identity "GRP-$oldDept" -Members $SamAccountName -Confirm:$false -ErrorAction SilentlyContinue
        Add-ADGroupMember    -Identity "GRP-$NewDepartment" -Members $SamAccountName

        $set = @{ Department = $NewDepartment }
        if ($NewJobTitle) { $set.Title = $NewJobTitle }
        Set-ADUser -Identity $SamAccountName @set
        Move-ADObject -Identity $user.DistinguishedName -TargetPath $newOU
        Write-Log "AD: moved $SamAccountName from $oldDept to $NewDepartment" -Level OK

        if ($IncludeEntra) {
            Connect-MgGraph -Scopes 'User.ReadWrite.All' -NoWelcome
            $cloud = @{ Department = $NewDepartment }
            if ($NewJobTitle) { $cloud.JobTitle = $NewJobTitle }
            Update-MgUser -UserId "$SamAccountName@$CloudDomain" @cloud
            Write-Log "Entra: updated department for $SamAccountName@$CloudDomain" -Level OK
        }
    }
}
catch {
    Write-Log "FAILED to move ${SamAccountName}: $($_.Exception.Message)" -Level ERROR
}
