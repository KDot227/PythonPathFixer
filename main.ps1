function Main {
    CheckAdmin
    Write-Host "Testing python"
    RemoveAlias
    PythonAppstore

    Add-Python-To-Path

    Write-Host "Python seems to be working now!"
    Read-Host "Press enter to quit"
}

function DownloadPython {
    Write-Host "Downloading Python"
    $download_ver = Invoke-WebRequest "https://www.python.org/ftp/python/" -UseBasicParsing | Select-String -Pattern '3.11.[0-9]{1,2}' -AllMatches | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Value | Sort-Object -Descending -Unique | Select-Object -First 1
    $download_link = "https://www.python.org/ftp/python/$download_ver/python-$download_ver-amd64.exe"
    $python_exe = "$env:TEMP\python-installer.exe"

    Invoke-WebRequest $download_link -OutFile $python_exe -UseBasicParsing

    Write-Host "Installing Python. (This may take awhile)"

    Start-Process $python_exe -ArgumentList "/quiet InstallAllUsers=0 PrependPath=1 Include_test=0 Incude_pip=1 Include_doc=0" -Wait

    Write-Host "Python downloaded and Installed. Please restart script."
    Read-Host "Press enter to quit"
    exit 0
}

function PythonAppstore {
    #see if python is installed from the appstore
    $python = Get-AppxPackage -AllUsers | Where-Object {$_.Name -like "Python*"}
    if ($python) {
        Write-Host "Python is installed from the appstore. Please uninstall it and try again"
        Read-Host "Press enter to quit"
        exit 1
    }
}

function FindPython {
    $python = Get-Command python -ErrorAction SilentlyContinue
    #check if multiple versions of python are installed. If so, warn the user and tell them to delete one
    if ($python.Count -gt 1) {
        Write-Host "Multiple versions of python found. Please delete one"
        Read-Host "Press enter to quit"
        exit 1
    }
    $pattern = 'AppData\\Local\\Programs\\Python\\Python\d+\\python\.exe'
    if ($python -and $python.Path -match $pattern) {
        Write-Host "Found python at $($python.Path)"
    } else {
        DownloadPython
    }
    return $python.Path
}

function RemoveAlias {
    Remove-Item $env:LOCALAPPDATA\Microsoft\WindowsApps\python.exe -ErrorAction SilentlyContinue
    Remove-Item $env:LOCALAPPDATA\Microsoft\WindowsApps\python3.exe -ErrorAction SilentlyContinue
}

function Add-Python-To-Path {
    $path = FindPython
    $new_path = $path.Substring(0, $path.LastIndexOf("\"))
    $scripts_path = "$new_path\Scripts"
    $full_path = $env:Path
    #see if path is in full_path
    if ($full_path -match $new_path.Replace('\', '\\')) {
        Write-Host "Python is already in path"
        return
    }
    Backup-Environment-Variables
    $answer = Read-Host "Do you want to add python to path? (y/n) NOTE THIS SHOULD WORK BUT IF IT DOESN'T DON'T KEEP RETRYING OR IT CAN MESSUP ENV VARS"
    if ($answer) {
        [System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";$new_path;$scripts_path", "User")
        Write-Host "Added python to path"
    }
}

function Backup-Environment-Variables {
    #output to dir of script
    $env:Path | Out-File -FilePath $PSScriptRoot\path.txt
}

function CheckAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $isElevated = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (!$isElevated) {
        Get-Admin-Privileges
        exit 1
    }
}

function Get-Admin-Privileges {
    $path = $PSScriptRoot + "\main.ps1"
    Start-Process powershell -Verb runAs -ArgumentList "-NoExit -File $path"
}

Main