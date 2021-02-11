# condaremove

PowerShell script to completely remove any preexisting user or system-wide installations of Anaconda and/or Miniconda. Does the following:

1. Searches for user or system installations of Anaconda or Miniconda from common install locations.
2. For each detected installation, removes `pkgs` and `envs` directories (if present).
3. Looks for and attempts to run the uninstaller. Deletes install directory if uninstaller fails or is not found.
4. Deletes all user configuration files as the `anaconda-clean` tool would.
5. Deletes additional common user and system configuration files from `%APPDATA%` and `%ProgramData%`.
6. Removes **ALL** Python-related registry keys (you will need to restore any non-conda Python registry keys).
7. Removes all invalid and conda-related entries from both user and system PATH. (Any entries that do not resolve to an existing directory will be removed.)
8. Clears the Start menu of any conda-related entries.

When running on a multi-user system, note that the script only removes user-based installs and user configuration files for the user running the script. This means that any configuration files resulting from a system-wide installation will still be present in other user accounts.

To run the script, run the following commands in an elevated (administrator) PowerShell:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ukukas/condaremove/main/condaremove.ps1"
Invoke-Expression .\condaremove.ps1
Remove-Item .\condaremove.ps1
```