## CONFIGURATION
# directories that might contain conda install
$installdirs = "C:\anaconda","C:\ProgramData\Anaconda3","C:\ProgramData\Miniconda3"
# potential names of conda uninstallers
$uninstallers = "Uninstall-Anaconda3.exe","Uninstall-Miniconda3.exe","Uninstall-Anaconda.exe","Uninstall-Miniconda.exe"
# registry keys to remove
$registykeys = "HKLM:\SOFTWARE\Python"
# folders in %AppData% to remove
$appdatafolders = ".anaconda","Thonny"
# folders in %ProgramData% to remove
$programdatafolders = "jupyter"
# %AppData% folder for Default user
$appdata = "C:\Users\Default\AppData\Roaming"

## HELPERS
function Get-Timestamp {return "[$(Get-Date -Format HH:mm:ss)]"}

function Write-TimestampedHost ($string) {
    Write-Host "$(Get-Timestamp) $string"
}

function Remove-Dir ($path) {
    Write-TimestampedHost "Checking for $path"
    if (Test-Path $path) {
        Write-TimestampedHost "Removing $path"
        Remove-Item -Recurse -Force -Path $path
    } else {
        Write-TimestampedHost "Did not find $path"
    }
}

function Remove-Dirs ($list) {
    foreach ($dir in $list) {
            Remove-Dir $dir
    }
}

function Remove-DirsWithPrefix ($prefix, $list){
    foreach ($dir in $list) {
        Remove-Dir (Join-Path $prefix $dir)
    }
}

function Uninstall-Conda ($condaroot, $uninstallers) {
    Write-TimestampedHost "Checking for uninstallers"
    $success = $false
    foreach ($exe in $uninstallers) {
        $uninstaller = Join-Path $dir $exe
        if (Test-Path $uninstaller) {
            Write-TimestampedHost "Found $uninstaller"
            Write-TimestampedHost "Running $uninstaller"
            Start-Process $uninstaller -ArgumentList "/S" -Wait
            Write-TimestampedHost "Finished running uninstaller"
            Write-TimestampedHost "Checking removal of $condaroot"
            $success = $true
            Break
        }
    }
    if (-Not $success) {
        Write-TimestampedHost "No uninstaller found, attempting manual removal"
    }
    if (Test-Path $condaroot) {
        Write-TimestampedHost "Removing $condaroot"
        Remove-Item -Recurse -Force -Path $condaroot
        if ($?) {
            Write-TimestampedHost "Successfully removed $condaroot"
        } else {
            Write-TimestampedHost "[ERR] Unable to completely remove $condaroot"
        }
    } else {
        Write-TimestampedHost "Confirmed removal of $condaroot"
    }
}

## MAIN
$installfound = $false
foreach ($dir in $installdirs) {
    Write-TimestampedHost "Checking path $dir"
    if (Test-Path $dir) {
        Write-TimestampedHost "Detected installation at $dir"
        Remove-DirsWithPrefix $dir @("envs", "pkgs")
        Uninstall-Conda $dir $uninstallers
        $installfound = $true
    } else {
        Write-TimestampedHost "No installation found at $dir"
    }
}

if ($installfound) {
    Write-TimestampedHost "Checking registry keys"
    Remove-Dirs $registykeys
    Write-TimestampedHost "Checking configuration files"
    Remove-DirsWithPrefix $env:ProgramData $programdatafolders
    Remove-DirsWithPrefix $appdata $appdatafolders
    Write-TimestampedHost "Best effort cleanup finished"
} else {
    Write-TimestampedHost "No installations found on system"
}
Write-TimestampedHost "DONE"