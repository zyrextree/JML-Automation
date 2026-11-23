@echo off
REM Double-click to run the Entra ID demo (allows this one script to run without changing system settings)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Run-EntraDemo.ps1"
