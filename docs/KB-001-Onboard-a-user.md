# KB-001 How to onboard a new user

**Applies to:** Service desk · **Time:** about 2 minutes · **Script:** `New-Joiner.ps1`

## Before you start
- You have a ticket from HR with the name, department and job title
- The department exists as an OU (`Users\<Department>`) and as a group (`GRP-<Department>`)

## Steps
1. Add the new hire to `samples\new_hires.csv` (one row per person):
    `FirstName,LastName,Department,JobTitle`
2. Open PowerShell as a domain admin and go to the `scripts` folder.
3. Preview the changes:
    `.\New-Joiner.ps1 -CsvPath ..\samples\new_hires.csv -WhatIf`
4. Run it for real, and add `-IncludeEntra -CloudDomain <tenant>.onmicrosoft.com` for the cloud account:
    `.\New-Joiner.ps1 -CsvPath ..\samples\new_hires.csv -IncludeEntra -CloudDomain <tenant>.onmicrosoft.com`
5. Copy the **temporary password** from the yellow line. Give it to the manager by phone or another secure channel, never by plain email.
6. Check that the user is in the right OU and groups (Active Directory Users and Computers).
7. Close the ticket with the username and a note: "Password handed over by phone to manager."

## Expected result
- An enabled user who must change the password at first logon
- Members of `GRP-<Department>` and `GRP-AllStaff`
- A log line in `logs\jml_<date>.log`
