## CONFIGURATION
# directories that might contain conda install folder
$installdirs = $env:SystemDrive,$env:ProgramData,$env:USERPROFILE
# potential names of conda install folders
$condanames = "anaconda","miniconda","anaconda3","miniconda3","anaconda2","miniconda2"
# potential names of conda uninstallers
$uninstallers = "Uninstall-Anaconda.exe","Uninstall-Miniconda.exe","Uninstall-Anaconda3.exe","Uninstall-Miniconda3.exe","Uninstall-Anaconda2.exe","Uninstall-Miniconda2.exe"
# configuration files/folders to remove from %USERPROFILE%
$userconfigs = ".anaconda",".astropy",".continuum",".conda",".condamanager",".condarc",".enthought",".idlerc",".glue",".ipynb_checkpoints",".ipython",".jupyter",".matplotlib",".python-eggs",".spyder2",".spyder2-py3",".theano"
# configuration files/folders to remove from %APPDATA$
$appdataconfigs = ".anaconda","jupyter"
# configuration files/folders to remove from %ProgramData%
$programdataconfigs = "jupyter"
# registry keys to remove
$registykeys = "HKLM:\SOFTWARE\Python","HKCU:\SOFTWARE\Python"
# system environment regisrty
$systemenv = "HKLM:\System\CurrentControlSet\Control\Session Manager\Environment"
# user environment regisrty
$userenv = "HKCU:\Environment"
# start menu directories
$startdirs = (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"),(Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs")
# start menu conda directory names
$startcondanames = "Anaconda3 (64-bit)","Anaconda3 (32-bit)","Anaconda2 (64-bit)","Anaconda2 (32-bit)"
# separator string
$sep = "--------------------------------------------------------------------"

## HELPERS
function Get-Timestamp {return "[$(Get-Date -Format HH:mm:ss)]"}

function Write-TimestampedHost ($string) {
    Write-Host "$(Get-Timestamp) $string"
}

function Remove-Object ($path) {
    if (Test-Path $path) {
        Write-TimestampedHost "Removing $path"
        Remove-Item -Recurse -Force -Path $path
    } else {
        Write-TimestampedHost "Did not find $path"
    }
}

function Remove-Objects ($list) {
    foreach ($obj in $list) {
            Remove-Object $obj
    }
}

function Remove-ObjectsWithPrefix ($prefix, $list){
    foreach ($obj in $list) {
        Remove-Object (Join-Path $prefix $obj)
    }
}

function Uninstall-Conda ($condaroot, $uninstallers) {
    Write-TimestampedHost "Looking for uninstallers"
    $success = $false
    foreach ($exe in $uninstallers) {
        $uninstaller = Join-Path $condaroot $exe
        if (Test-Path $uninstaller) {
            Write-TimestampedHost "Running uninstaller $uninstaller"
            Start-Process $uninstaller -ArgumentList "/S" -Wait
            Write-TimestampedHost "Finished running uninstaller"
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
            Write-TimestampedHost "Confirmed removal of $condaroot"
        } else {
            Write-TimestampedHost "[ERR] Unable to completely remove $condaroot"
        }
    } else {
        Write-TimestampedHost "Confirmed removal of $condaroot"
    }
}

function Assert-PathRemoval ($item, $pathtype, $installdirs, $condanames) {
    if (Test-Path $item) {
        foreach ($dir in $installdirs) {
            foreach ($name in $condanames) {
                if ((Join-Path (Resolve-Path $item) "\") -like (Join-Path (Join-Path $dir $name) "*")) {
                    Write-TimestampedHost "Removing $pathtype PATH entry $item"
                    return $true
                }
            }
        }
    } else {
        Write-TimestampedHost "Removing $pathtype PATH entry $item"
        return $true
    }
    return $false
}

function Remove-FromPath ($envreg, $pathtype, $installdirs, $condanames) {
    $path = (Get-ItemProperty -Path $envreg -Name "PATH").path.trimEnd(";")
    $newpath = ($path.Split(";") | Where-Object {-not (Assert-PathRemoval $_ $pathtype $installdirs $condanames)}) -join ";"
    if ($path -eq $newpath) {
        Write-TimestampedHost "Nothing to remove from $pathtype PATH"
    } else {
        Set-ItemProperty -Path $envreg -Name "PATH" -Value $newpath
    }
}

## MAIN
Write-TimestampedHost "Checking for existing conda installations"
foreach ($dir in $installdirs) {
    foreach ($name in $condanames) {
        $condaroot = Join-Path $dir $name
        if (Test-Path $condaroot) {
            Write-TimestampedHost "Detected installation at $condaroot"
            Remove-ObjectsWithPrefix $condaroot @("envs", "pkgs")
            Uninstall-Conda $condaroot $uninstallers
        } else {
            Write-TimestampedHost "No installation found at $condaroot"
        }
    }
}

Write-TimestampedHost $sep
Write-TimestampedHost "Checking common configuration files"
Remove-ObjectsWithPrefix $env:USERPROFILE $userconfigs
Remove-ObjectsWithPrefix  $env:APPDATA $appdataconfigs
Remove-ObjectsWithPrefix  $env:ProgramData $programdataconfigs

Write-TimestampedHost $sep
Write-TimestampedHost "Checking registry keys"
Remove-Objects $registykeys

Write-TimestampedHost $sep
Write-TimestampedHost "Checking system and user PATH"
Remove-FromPath $systemenv "system" $installdirs $condanames
Remove-FromPath $userenv "user" $installdirs $condanames

Write-TimestampedHost $sep
Write-TimestampedHost "Checking start menu"
foreach ($dir in $startdirs) {
    Remove-ObjectsWithPrefix $dir $startcondanames
}

Write-TimestampedHost $sep
Write-TimestampedHost "Best effort cleanup finished"
Write-TimestampedHost "DONE"