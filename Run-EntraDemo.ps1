<#
.SYNOPSIS
    One-click real demo in YOUR OWN Microsoft Entra ID test tenant:
    onboards the 6 sample users, offboards one, exports a report,
    and saves real screenshots to Desktop\JML-Screenshots after each step.
.NOTES
    Needs a free Azure / Microsoft Entra test tenant (azure.microsoft.com/free).
    You sign in yourself in the browser window that opens.
    Start it with Run-EntraDemo.bat (double-click).
#>
$ErrorActionPreference = 'Stop'
$root    = $PSScriptRoot
$shotDir = Join-Path ([Environment]::GetFolderPath('Desktop')) 'JML-Screenshots'
New-Item -ItemType Directory -Path $shotDir -Force | Out-Null
$Host.UI.RawUI.WindowTitle = 'JML Automation - Entra ID demo'

function Save-Shot($name) {
    Start-Sleep -Milliseconds 800
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
    $file = Join-Path $shotDir "$name.png"
    $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Host "   [screenshot saved] $file" -ForegroundColor DarkGray
}
function Step($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($t)   { Write-Host "[OK]    $t" -ForegroundColor Green }
function Err($t)  { Write-Host "[ERROR] $t" -ForegroundColor Red }

try {
    Step 'Step 1/5  Preparing PowerShell modules'
    if (-not (Get-Module -ListAvailable Microsoft.Graph.Users)) {
        Write-Host 'Installing Microsoft Graph PowerShell (first time only, a few minutes)...'
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Install-Module Microsoft.Graph.Authentication, Microsoft.Graph.Users, Microsoft.Graph.Identity.DirectoryManagement -Scope CurrentUser -Force
    }
    Import-Module Microsoft.Graph.Users, Microsoft.Graph.Identity.DirectoryManagement
    Ok 'Microsoft Graph module ready'

    Step 'Step 2/5  Sign in to your Entra ID test tenant (a browser window opens)'
    Connect-MgGraph -Scopes 'User.ReadWrite.All','Directory.Read.All' -NoWelcome
    $domain = (Get-MgDomain | Where-Object IsDefault).Id
    $org    = (Get-MgOrganization).DisplayName
    Ok "Connected to tenant '$org' ($domain)"

    Step "Step 3/5  JOINER - onboarding users from new_hires.csv"
    $users = Import-Csv (Join-Path $root 'samples\new_hires.csv')
    foreach ($u in $users) {
        $sam = ("$($u.FirstName).$($u.LastName)").ToLower() -replace 'æ','ae' -replace 'ø','oe' -replace 'å','aa'
        $upn = "$sam@$domain"
        if (Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue) {
            Write-Host "[SKIP]  $upn already exists" -ForegroundColor Yellow; continue
        }
        $pw = 'Jml!' + (Get-Random -Minimum 100000 -Maximum 999999) + 'xQ'
        New-MgUser -DisplayName "$($u.FirstName) $($u.LastName)" -GivenName $u.FirstName -Surname $u.LastName `
            -MailNickname $sam -UserPrincipalName $upn -Department $u.Department -JobTitle $u.JobTitle `
            -AccountEnabled -PasswordProfile @{ Password = $pw; ForceChangePasswordNextSignIn = $true } | Out-Null
        Ok ("{0,-34} Dept: {1,-6} Title: {2}" -f $upn, $u.Department, $u.JobTitle)
    }
    Save-Shot '01-joiner-onboarding'

    Step 'Step 4/5  LEAVER - offboarding lars.nielsen (ticket INC0012345)'
    $leaver = "lars.nielsen@$domain"
    Update-MgUser -UserId $leaver -AccountEnabled:$false
    Ok "Sign-in blocked for $leaver"
    Revoke-MgUserSignInSession -UserId $leaver | Out-Null
    Ok "All sessions revoked for $leaver"
    Update-MgUser -UserId $leaver -JobTitle 'LEFT - INC0012345'
    Ok "Ticket reference INC0012345 written to the account"
    Save-Shot '02-leaver-offboarding'

    Step 'Step 5/5  REPORT - all users in the tenant'
    $report = Get-MgUser -All -Property DisplayName,UserPrincipalName,Department,JobTitle,AccountEnabled |
        Where-Object Department |
        Select-Object DisplayName, UserPrincipalName, Department, JobTitle, AccountEnabled |
        Sort-Object Department, DisplayName
    $report | Format-Table -AutoSize | Out-Host
    $csv = Join-Path $root "reports\entra_users_$(Get-Date -Format 'yyyy-MM-dd').csv"
    New-Item -ItemType Directory -Path (Split-Path $csv) -Force | Out-Null
    $report | Export-Csv $csv -NoTypeInformation -Encoding UTF8
    Ok "Report saved to $csv"
    Save-Shot '03-report'

    Write-Host "`nDone! Screenshots are in $shotDir" -ForegroundColor Cyan
    Write-Host 'Now open https://entra.microsoft.com -> Users and take one more screenshot (Win+Shift+S).' -ForegroundColor Cyan
    Start-Process explorer.exe $shotDir
}
catch {
    Err $_.Exception.Message
    if ($_.Exception.Message -match 'AADSTS|tenant|consent') {
        Write-Host 'Tip: sign in with your Azure test tenant admin account (name@yourtenant.onmicrosoft.com), not a personal Hotmail/Outlook account.' -ForegroundColor Yellow
    }
}
Read-Host "`nPress Enter to close"
