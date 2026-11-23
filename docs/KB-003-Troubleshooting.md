# KB-003 Troubleshooting script errors

| Error message | Cause | Fix |
|---|---|---|
| `running scripts is disabled on this system` | The execution policy blocks scripts | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| `The term 'Get-ADUser' is not recognized` | The RSAT AD module is missing | Install RSAT Active Directory tools, or run the script on the domain controller |
| `Directory object not found` | The OU in the CSV does not exist | Check the spelling of `Department`, or run `setup\Initialize-Lab.ps1` |
| `The password does not meet the length, complexity...` | Domain password policy is stricter than the script | Raise `-Length` in `New-TempPassword` (Common.ps1) |
| `Missing Department` | Empty cell in the CSV | Fix the row in the CSV and run again. Other users are not affected |
| `Insufficient privileges to complete the operation` (Graph) | Missing Graph permission | `Connect-MgGraph -Scopes User.ReadWrite.All` and accept consent as an admin |
| `Another object with the same value for property userPrincipalName already exists` | The user already exists in Entra ID | Check the Entra admin center, then remove the duplicate row |

**Tip:** every run writes to `logs\jml_<date>.log`. Red `[ERROR]` lines show which user failed and why.
