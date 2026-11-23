# KB-002 How to offboard a leaver

**Applies to:** Service desk · **Time:** about 1 minute · **Script:** `Remove-Leaver.ps1`

## Rules
- **Never delete** an account on the leave date. Disable it, so it can be restored and the audit trail stays.
- Offboard on the last working day, after the time HR confirms.

## Steps
1. Find the username: `Get-ADUser -Filter "Name -like '*Nielsen*'"`
2. Preview the changes:
    `.\Remove-Leaver.ps1 -SamAccountName lars.nielsen -Ticket INC0012345 -WhatIf`
3. Run it, including the cloud account:
    `.\Remove-Leaver.ps1 -SamAccountName lars.nielsen -Ticket INC0012345 -IncludeEntra -CloudDomain <tenant>.onmicrosoft.com`
4. Check the result:
    - The account is disabled and sits in `Disabled Users`
    - The description reads `Disabled <date> - <ticket>`
    - In the Entra admin center, sign-in is blocked
5. The log has the user's old groups, in case a manager asks what access they had.
6. Close the ticket.

## Restore by mistake?
`Enable-ADAccount <user>`, move the account back to its OU and re-add its groups using the list in the log.
