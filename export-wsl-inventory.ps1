[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$InventoryFolder = Join-Path $ScriptRoot 'inventories'
$tick = [char]96

New-Item -ItemType Directory -Force -Path $InventoryFolder | Out-Null

$kaliCategories = [ordered]@{
    'Recon / Discovery'    = @('nmap', 'tcpdump', 'wireshark')
    'Web Pentesting'       = @('sqlmap', 'nikto', 'gobuster', 'ffuf', 'dirb', 'wpscan', 'burpsuite')
    'Passwords / Cracking' = @('hydra', 'john', 'hashcat')
    'Exploitation / Post'  = @('msfconsole', 'responder', 'netexec')
    'Wireless'             = @('aircrack-ng')
}

$ubuntuCategories = [ordered]@{
    'Shell / Navigation' = @('bash', 'tmux', 'vim', 'nano')
    'Network / Remote'   = @('ssh', 'curl', 'wget')
    'Development'        = @('git', 'python3', 'pip3', 'gcc', 'make')
    'Data / JSON'        = @('jq')
}

function Test-CommandInDistro {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistroName,
        [Parameter(Mandatory = $true)]
        [string]$CommandName,
        [string]$UserName
    )

    $arguments = @('-d', $DistroName)
    if ($UserName) {
        $arguments += @('-u', $UserName)
    }

    $arguments += @('--', 'which', $CommandName)

    & wsl.exe @arguments 1>$null 2>$null
    return $LASTEXITCODE -eq 0
}

function Get-DetectedToolMap {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistroName,
        [Parameter(Mandatory = $true)]
        [hashtable]$Categories,
        [string]$UserName
    )

    $result = [ordered]@{}

    foreach ($category in $Categories.Keys) {
        $detected = foreach ($commandName in $Categories[$category]) {
            if (Test-CommandInDistro -DistroName $DistroName -CommandName $commandName -UserName $UserName) {
                $commandName
            }
        }

        $result[$category] = @($detected)
    }

    return $result
}

function New-InventoryMarkdown {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [Parameter(Mandatory = $true)]
        [string]$DistroName,
        [Parameter(Mandatory = $true)]
        [hashtable]$ToolMap,
        [Parameter(Mandatory = $true)]
        [string]$DescriptionEnglish,
        [Parameter(Mandatory = $true)]
        [string]$DescriptionSpanish
    )

    $allTools = @($ToolMap.Values | ForEach-Object { $_ }) | Where-Object { $_ }
    $lines = New-Object System.Collections.Generic.List[string]

    $lines.Add("# $Title")
    $lines.Add('')
    $lines.Add('- Distro: ' + $tick + $DistroName + $tick)
    $lines.Add("- Detected tools / Herramientas detectadas: $($allTools.Count)")
    $lines.Add('')
    $lines.Add('## English')
    $lines.Add($DescriptionEnglish)
    $lines.Add('')

    foreach ($category in $ToolMap.Keys) {
        $lines.Add("### $category")
        $items = @($ToolMap[$category])
        if ($items.Count -gt 0) {
            foreach ($item in $items) {
                $lines.Add('- ' + $tick + $item + $tick)
            }
        }
        else {
            $lines.Add('- None detected in this category.')
        }
        $lines.Add('')
    }

    $lines.Add('## Espanol')
    $lines.Add($DescriptionSpanish)
    $lines.Add('')

    foreach ($category in $ToolMap.Keys) {
        $lines.Add("### $category")
        $items = @($ToolMap[$category])
        if ($items.Count -gt 0) {
            foreach ($item in $items) {
                $lines.Add('- ' + $tick + $item + $tick)
            }
        }
        else {
            $lines.Add('- No se detectaron herramientas en esta categoria.')
        }
        $lines.Add('')
    }

    return ($lines -join [Environment]::NewLine).TrimEnd() + [Environment]::NewLine
}

$kaliToolMap = Get-DetectedToolMap -DistroName 'kali-linux' -Categories $kaliCategories -UserName 'root'
$ubuntuToolMap = Get-DetectedToolMap -DistroName 'Ubuntu' -Categories $ubuntuCategories

$kaliMarkdown = New-InventoryMarkdown `
    -Title 'Kali Top Tools' `
    -DistroName 'kali-linux' `
    -ToolMap $kaliToolMap `
    -DescriptionEnglish 'This is a compact inventory of the main pentesting tools detected in the Kali WSL profile used by this project.' `
    -DescriptionSpanish 'Este es un inventario compacto de las principales herramientas de pentesting detectadas en el perfil Kali WSL usado por este proyecto.'

$ubuntuMarkdown = New-InventoryMarkdown `
    -Title 'Ubuntu Core Tools' `
    -DistroName 'Ubuntu' `
    -ToolMap $ubuntuToolMap `
    -DescriptionEnglish 'This is a compact inventory of the core CLI and development tools detected in the Ubuntu WSL profile used by this project.' `
    -DescriptionSpanish 'Este es un inventario compacto de las herramientas base de CLI y desarrollo detectadas en el perfil Ubuntu WSL usado por este proyecto.'

Set-Content -Path (Join-Path $InventoryFolder 'kali-top-tools.md') -Value $kaliMarkdown -Encoding UTF8
Set-Content -Path (Join-Path $InventoryFolder 'ubuntu-core-tools.md') -Value $ubuntuMarkdown -Encoding UTF8
