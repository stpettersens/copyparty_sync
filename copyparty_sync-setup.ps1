# copyparty_sync-setup.ps1
# Install copyparty_sync on a Windows system
#
# Author: Sam Saint-Pettersen, October 2025.
# https://stpettersen.xyz
#
# Usage in PowerShell:
# iex (iwr 'https://sh.homelab.stpettersen.xyz/copyparty-sync/copyparty_sync-setup.ps1' -UseBasicParsing)
#

# Define the server root for assets served by this script.
$global:server = "https://sh.homelab.stpettersen.xyz/copyparty-sync"

function Check-Is-Admin {
    [OutputType([bool])]
    param()
    process {
        [Security.Principal.WindowsPrincipal]$user = [Security.Principal.WindowsIdentity]::GetCurrent()
        return $user.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }
}

function SHA256-Cksum {
    param(
        [string]$file
    )
    $cksum_file = $file.Split(".")[0] + "_sha256.txt"
    $cksum_url = "${global:server}/${cksum_file}"
    Invoke-WebRequest $cksum_url -OutFile $cksum_file
    $actual_cksum_file = (Get-Item $cksum_file)
    $expected = (Get-Content -Path $actual_cksum_file).SubString(0, 64)
    $cksum = (Get-FileHash -Path $file -Algorithm SHA256).Hash.ToLower()
    if ($cksum -ne $expected) {
        echo "SHA256 checksum failed for '${file}'."
        echo "Aborting..."
        exit 1
    }
    echo "SHA256 checksum OK for '${file}'."
    rm -fo $cksum_file
}

function Script-Cksum {
    $script ="copyparty_sync-setup.ps1"
    if (!(Test-Path -Path $script)) {
        Invoke-WebRequest "${global:server}/${script}" -OutFile $script
    }
    SHA256-Cksum $script
    if ($MyInvocation.ScriptName) {
        $this_script = Split-Path -Path $MyInvocation.ScriptName -Leaf
        if ($this_script -ne $script) {
            rm -fo $script
        }
    }
}

function Main {
    if(-not (Check-Is-Admin)) {
        echo "This script must be executed as Administrator."
        exit 1
    }
    $archive = "copyparty_sync_win64.zip"
    $archive_url = "${global:server}/${archive}"
    echo "Installing copyparty_sync (Windows x64)..."
    Script-Cksum
    if ((Test-Path -Path $archive)) {
        rm -fo $archive
    }
    Invoke-WebRequest $archive_url -OutFile $archive
    SHA256-Cksum $archive
    $install_dir = "C:\Dev\copyparty_sync"
    New-Item -ItemType Directory -Force -Path $install_dir
    Expand-Archive -Force -Path $archive -DestinationPath $install_dir
    rm -fo $archive
    echo "Done."
    Write-Host -NoNewLine 'Press any key to continue...'
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

Main
