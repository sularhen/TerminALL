[CmdletBinding()]
param(
    [switch]$English,
    [switch]$Spanish
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom
cmd.exe /c chcp 65001 > $null

$ScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$BackgroundFolder = Join-Path $ScriptRoot 'terminal-background'
$BackgroundInstructions = Join-Path $BackgroundFolder 'PUT_IMAGE_HERE.txt'
$LauncherScriptPath = Join-Path $ScriptRoot 'launch-terminal-layout.cmd'
$LogPath = Join-Path $ScriptRoot 'setup-terminal.log'

try {
    $Host.UI.RawUI.WindowTitle = 'AllinOne Setup'
}
catch {
}

try {
    Start-Transcript -Path $LogPath -Force | Out-Null
}
catch {
}

$Messages = @{
    en = @{
        ChoosingLanguage = 'Selected language: English'
        RelaunchingAdmin = 'Restarting the setup as administrator...'
        RequiresAdmin = 'Administrator rights are required for WSL, Windows Terminal, and shortcut changes.'
        BackgroundFolderReady = 'Background folder ready: {0}'
        BackgroundMissing = 'No image was found in the background folder.'
        BackgroundPrompt = 'Place one image in that folder, then press ENTER to continue. Type SKIP to continue without a custom image or Q to cancel.'
        BackgroundChosen = 'Background image selected: {0}'
        BackgroundSkipped = 'Custom background skipped. The script will use the built-in terminal background only.'
        StartingChecks = 'Running system checks...'
        VirtualizationOk = 'Firmware virtualization support appears to be enabled.'
        VirtualizationWarn = 'Firmware virtualization does not look enabled. WSL 2 may fail until virtualization is enabled in BIOS/UEFI.'
        WslAlreadyInstalled = 'WSL features are already enabled.'
        WslInstallStart = 'Installing or updating WSL...'
        WslInstallDone = 'WSL platform is ready.'
        WslNeedsRestart = 'A restart is required before WSL distributions can finish installing. Re-run this script after reboot.'
        WslUnresponsive = 'WSL is not responding. Reboot Windows to reset WSL/Hyper-V, then run this script again.'
        WslSetVersion = 'Setting WSL default version to 2...'
        DistroPresent = '{0} is already installed.'
        DistroInstall = 'Installing {0} in WSL...'
        DistroInit = 'The distro {0} needs first-run initialization.'
        DistroInitPrompt = 'A distro window will open. Finish the Linux username/password setup, close it, then press ENTER here to continue.'
        DistroUnresponsive = 'The distro {0} is not responding. Reboot Windows to reset WSL/Hyper-V, then run this script again.'
        KaliToolsInstall = 'Installing the Kali large package set. This can take a while and may download many GB.'
        KaliToolsDone = 'Kali toolset installation finished.'
        TerminalPresent = 'Windows Terminal is already installed.'
        TerminalInstall = 'Installing Windows Terminal with winget...'
        TerminalDone = 'Windows Terminal is ready.'
        TerminalSettings = 'Configuring Windows Terminal settings...'
        TerminalSettingsDone = 'Windows Terminal settings updated.'
        ShortcutCreate = 'Creating the desktop shortcut...'
        ShortcutDone = 'Desktop shortcut created. It uses CTRL+ALT+T.'
        Complete = 'Setup finished.'
        OpenTerminal = 'Open Windows Terminal with CTRL+ALT+T.'
        WslFailed = 'WSL installation failed. See recommendations below.'
        TerminalFailed = 'Windows Terminal installation failed. See recommendations below.'
        Cancelled = 'Setup cancelled by the user.'
        PressEnter = 'Press ENTER to exit.'
        BackupCreated = 'A backup of settings.json was created at: {0}'
        LogFile = 'Log file: {0}'
    }
    es = @{
        ChoosingLanguage = 'Idioma seleccionado: Espanol'
        RelaunchingAdmin = 'Reiniciando la instalacion como administrador...'
        RequiresAdmin = 'Se requieren permisos de administrador para WSL, Windows Terminal y cambios en accesos directos.'
        BackgroundFolderReady = 'Carpeta de fondo lista: {0}'
        BackgroundMissing = 'No se encontro una imagen en la carpeta de fondo.'
        BackgroundPrompt = 'Coloca una imagen en esa carpeta y luego presiona ENTER para continuar. Escribe SKIP para seguir sin imagen personalizada o Q para cancelar.'
        BackgroundChosen = 'Imagen de fondo seleccionada: {0}'
        BackgroundSkipped = 'Se omitio la imagen personalizada. El script usara solo el fondo base de Terminal.'
        StartingChecks = 'Ejecutando revisiones del sistema...'
        VirtualizationOk = 'La virtualizacion de firmware parece estar habilitada.'
        VirtualizationWarn = 'La virtualizacion de firmware no parece habilitada. WSL 2 puede fallar hasta activarla en BIOS/UEFI.'
        WslAlreadyInstalled = 'Las caracteristicas de WSL ya estan habilitadas.'
        WslInstallStart = 'Instalando o actualizando WSL...'
        WslInstallDone = 'La plataforma WSL esta lista.'
        WslNeedsRestart = 'Se requiere reiniciar antes de terminar la instalacion de distribuciones WSL. Vuelve a ejecutar este script despues del reinicio.'
        WslUnresponsive = 'WSL no esta respondiendo. Reinicia Windows para reiniciar WSL/Hyper-V y luego vuelve a ejecutar este script.'
        WslSetVersion = 'Configurando la version predeterminada de WSL en 2...'
        DistroPresent = '{0} ya esta instalado.'
        DistroInstall = 'Instalando {0} en WSL...'
        DistroInit = 'La distro {0} necesita la inicializacion del primer arranque.'
        DistroInitPrompt = 'Se abrira una ventana de la distro. Completa el usuario/contrasena Linux, cierrala y luego presiona ENTER aqui para continuar.'
        DistroUnresponsive = 'La distro {0} no esta respondiendo. Reinicia Windows para reiniciar WSL/Hyper-V y luego vuelve a ejecutar este script.'
        KaliToolsInstall = 'Instalando el paquete grande de Kali. Esto puede tardar bastante y descargar varios GB.'
        KaliToolsDone = 'La instalacion de herramientas de Kali termino.'
        TerminalPresent = 'Windows Terminal ya esta instalado.'
        TerminalInstall = 'Instalando Windows Terminal con winget...'
        TerminalDone = 'Windows Terminal esta listo.'
        TerminalSettings = 'Configurando settings.json de Windows Terminal...'
        TerminalSettingsDone = 'La configuracion de Windows Terminal fue actualizada.'
        ShortcutCreate = 'Creando el acceso directo de escritorio...'
        ShortcutDone = 'Acceso directo de escritorio creado. Usa CTRL+ALT+T.'
        Complete = 'Instalacion terminada.'
        OpenTerminal = 'Abre Windows Terminal con CTRL+ALT+T.'
        WslFailed = 'La instalacion de WSL fallo. Revisa las recomendaciones de abajo.'
        TerminalFailed = 'La instalacion de Windows Terminal fallo. Revisa las recomendaciones de abajo.'
        Cancelled = 'Instalacion cancelada por el usuario.'
        PressEnter = 'Presiona ENTER para salir.'
        BackupCreated = 'Se creo un respaldo de settings.json en: {0}'
        LogFile = 'Archivo de log: {0}'
    }
}

function Select-Language {
    if ($English -and -not $Spanish) {
        return 'en'
    }

    if ($Spanish -and -not $English) {
        return 'es'
    }

    $defaultLanguage = if ((Get-Culture).Name -like 'es*') { 'es' } else { 'en' }
    Write-Host 'Select language / Selecciona idioma: [E]nglish / [S]panish'
    Write-Host "Default / Predeterminado: $defaultLanguage"
    $selection = Read-Host 'Choice / Opcion'

    switch -Regex ($selection) {
        '^[sS]' { return 'es' }
        '^[eE]' { return 'en' }
        default { return $defaultLanguage }
    }
}

$Language = Select-Language

function T {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,
        [object[]]$FormatArgs
    )

    $message = $Messages[$Language][$Key]
    if ($FormatArgs) {
        return [string]::Format($message, $FormatArgs)
    }

    return $message
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK]   $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ensure-Administrator {
    if (Test-IsAdministrator) {
        return
    }

    Write-Warn (T 'RequiresAdmin')
    Write-Info (T 'RelaunchingAdmin')
    $scriptPath = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.PSCommandPath }
    $argumentList = @(
        '-NoExit'
        '-NoProfile'
        '-ExecutionPolicy'
        'Bypass'
        '-File'
        $scriptPath
    )

    if ($English) {
        $argumentList += '-English'
    }
    elseif ($Spanish) {
        $argumentList += '-Spanish'
    }

    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $argumentList
    }
    catch {
        Write-Fail 'Elevation was cancelled or could not be started.'
        Read-Host (T 'PressEnter') | Out-Null
        exit 1
    }

    exit
}

function Ensure-ObjectProperty {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        $Value
    )

    if ($null -eq $Object.PSObject.Properties[$Name]) {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
    else {
        $Object.$Name = $Value
    }
}

function Remove-ObjectProperty {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($null -ne $Object.PSObject.Properties[$Name]) {
        $Object.PSObject.Properties.Remove($Name)
    }
}

function Invoke-WslCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,
        [int]$TimeoutSeconds = 60,
        [switch]$IgnoreExitCode
    )

    $stdoutPath = [System.IO.Path]::GetTempFileName()
    $stderrPath = [System.IO.Path]::GetTempFileName()
    $argumentString = ($ArgumentList | ForEach-Object {
            if ($_ -match '[\s"]') {
                '"' + ($_ -replace '"', '\"') + '"'
            }
            else {
                $_
            }
        }) -join ' '

    try {
        $process = Start-Process -FilePath 'wsl.exe' -ArgumentList $argumentString -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            try {
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            }
            catch {
            }

            return [pscustomobject]@{
                TimedOut = $true
                ExitCode = $null
                StdOut = (Get-Content -Path $stdoutPath -Raw -ErrorAction SilentlyContinue)
                StdErr = (Get-Content -Path $stderrPath -Raw -ErrorAction SilentlyContinue)
            }
        }

        $result = [pscustomobject]@{
            TimedOut = $false
            ExitCode = $process.ExitCode
            StdOut = (Get-Content -Path $stdoutPath -Raw -ErrorAction SilentlyContinue)
            StdErr = (Get-Content -Path $stderrPath -Raw -ErrorAction SilentlyContinue)
        }

        if (-not $IgnoreExitCode -and $result.ExitCode -ne 0) {
            $details = @($result.StdErr, $result.StdOut) | Where-Object { $_ -and $_.Trim() } | Select-Object -First 1
            if (-not $details) {
                $details = "wsl.exe exited with code $($result.ExitCode)."
            }

            throw $details.Trim()
        }

        return $result
    }
    finally {
        Remove-Item -Path $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

function Assert-WslResponsive {
    $result = Invoke-WslCommand -ArgumentList @('--status') -TimeoutSeconds 20 -IgnoreExitCode
    if ($result.TimedOut) {
        throw (T 'WslUnresponsive')
    }
}

function Get-BackgroundImage {
    New-Item -ItemType Directory -Force -Path $BackgroundFolder | Out-Null

    if (-not (Test-Path $BackgroundInstructions)) {
        Set-Content -Path $BackgroundInstructions -Value @(
            'Place one image here before running setup.'
            'Coloca una imagen aqui antes de ejecutar la instalacion.'
            'Supported / Soportado: .png .jpg .jpeg .bmp .gif'
        )
    }

    Write-Info (T 'BackgroundFolderReady' $BackgroundFolder)

    while ($true) {
        $image = Get-ChildItem -Path $BackgroundFolder -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -match '^\.(png|jpg|jpeg|bmp|gif)$' } |
            Select-Object -First 1

        if ($image) {
            Write-Ok (T 'BackgroundChosen' $image.FullName)
            return $image.FullName
        }

        Write-Warn (T 'BackgroundMissing')
        $response = Read-Host (T 'BackgroundPrompt')
        switch -Regex ($response) {
            '^(q|Q)$' {
                Write-Warn (T 'Cancelled')
                Read-Host (T 'PressEnter') | Out-Null
                exit 1
            }
            '^(skip|SKIP)$' {
                Write-Warn (T 'BackgroundSkipped')
                return $null
            }
            default { }
        }
    }
}

function Get-HackerFont {
    $preferredFonts = @(
        'PxPlus IBM VGA8'
        'Cascadia Mono'
        'Consolas'
    )

    $fontRegistryPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    $fontValues = (Get-ItemProperty -Path $fontRegistryPath).PSObject.Properties |
        Where-Object { $_.Name -notmatch '^PS' } |
        ForEach-Object { $_.Name }

    foreach ($font in $preferredFonts) {
        if ($fontValues -match [regex]::Escape($font)) {
            return $font
        }
    }

    return 'Cascadia Mono'
}

function Show-WslRecommendations {
    Write-Host ''
    Write-Warn (T 'WslFailed')
    Write-Host ' - Enable BIOS/UEFI virtualization (Intel VT-x or AMD-V).'
    Write-Host ' - Habilita virtualizacion en BIOS/UEFI (Intel VT-x o AMD-V).'
    Write-Host ' - Enable Windows features: Virtual Machine Platform and Windows Subsystem for Linux.'
    Write-Host ' - Habilita las caracteristicas Virtual Machine Platform y Windows Subsystem for Linux.'
    Write-Host ' - Reboot Windows, then run this script again.'
    Write-Host ' - Reinicia Windows y luego ejecuta este script otra vez.'
    Write-Host ' - Update WSL manually with: wsl --update'
    Write-Host ' - Actualiza WSL manualmente con: wsl --update'
    Write-Host ''
}

function Show-TerminalRecommendations {
    Write-Host ''
    Write-Warn (T 'TerminalFailed')
    Write-Host ' - Make sure winget/App Installer is available from Microsoft Store.'
    Write-Host ' - Asegura que winget/App Installer este disponible desde Microsoft Store.'
    Write-Host ' - Install Windows Terminal manually from: https://aka.ms/terminal'
    Write-Host ' - Instala Windows Terminal manualmente desde: https://aka.ms/terminal'
    Write-Host ' - Re-run this script once the app opens at least once.'
    Write-Host ' - Vuelve a ejecutar este script cuando la app abra al menos una vez.'
    Write-Host ''
}

function Get-VirtualizationStatus {
    $processor = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    return [pscustomobject]@{
        VirtualizationFirmwareEnabled = [bool]$processor.VirtualizationFirmwareEnabled
        SecondLevelAddressTranslation = [bool]$processor.SecondLevelAddressTranslationExtensions
        VmMonitorMode = [bool]$processor.VMMonitorModeExtensions
    }
}

function Test-WslFeatureEnabled {
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    $vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
    return $wslFeature.State -eq 'Enabled' -and $vmFeature.State -eq 'Enabled'
}

function Ensure-WslPlatform {
    if (Test-WslFeatureEnabled) {
        Write-Ok (T 'WslAlreadyInstalled')
    }
    else {
        Write-Info (T 'WslInstallStart')
        try {
            & wsl.exe --install --no-distribution | Out-Host
        }
        catch {
            Show-WslRecommendations
            throw
        }
    }

    Write-Info (T 'WslSetVersion')
    try {
        & wsl.exe --set-default-version 2 | Out-Host
        & wsl.exe --update | Out-Host
    }
    catch {
        Show-WslRecommendations
        throw
    }

    Assert-WslResponsive

    Write-Ok (T 'WslInstallDone')
}

function Get-InstalledDistros {
    $result = Invoke-WslCommand -ArgumentList @('-l', '-q') -TimeoutSeconds 30 -IgnoreExitCode
    if ($result.TimedOut) {
        throw (T 'WslUnresponsive')
    }

    if ($result.ExitCode -ne 0) {
        return @()
    }

    return @(
        ($result.StdOut -split "`r?`n") |
        ForEach-Object { $_.ToString().Replace([string][char]0, '').Trim() } |
        Where-Object { $_ }
    )
}

function Ensure-DistroInstalled {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistroName
    )

    $installed = Get-InstalledDistros
    if ($installed -contains $DistroName) {
        Write-Ok (T 'DistroPresent' $DistroName)
        return
    }

    Write-Info (T 'DistroInstall' $DistroName)
    try {
        & wsl.exe --install -d $DistroName --no-launch | Out-Host
    }
    catch {
        Show-WslRecommendations
        throw
    }
}

function Test-DistroReady {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistroName
    )

    $result = Invoke-WslCommand -ArgumentList @('-d', $DistroName, '-u', 'root', '--', 'sh', '-lc', 'echo ready') -TimeoutSeconds 25 -IgnoreExitCode
    if ($result.TimedOut) {
        throw (T 'DistroUnresponsive' $DistroName)
    }

    $normalizedOutput = ($result.StdOut -replace [string][char]0, '').Trim()
    $normalizedExitCode = if ($null -eq $result.ExitCode -and $normalizedOutput -match '\bready\b') { 0 } else { $result.ExitCode }
    return ($null -eq $normalizedExitCode -or $normalizedExitCode -eq 0) -and $normalizedOutput -match '\bready\b'
}

function Get-DistroRegistryInfo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistroName
    )

    foreach ($item in Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' -ErrorAction SilentlyContinue) {
        $properties = Get-ItemProperty -Path $item.PSPath -ErrorAction SilentlyContinue
        if ($properties.DistributionName -eq $DistroName) {
            return $properties
        }
    }

    return $null
}

function Ensure-DistroInitialized {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistroName
    )

    if (Test-DistroReady -DistroName $DistroName) {
        $distroInfo = Get-DistroRegistryInfo -DistroName $DistroName
        if ($distroInfo -and $distroInfo.PSObject.Properties['RunOOBE'] -and $distroInfo.RunOOBE -eq 1 -and $distroInfo.DefaultUid -eq 0) {
            try {
                Set-ItemProperty -Path $distroInfo.PSPath -Name 'RunOOBE' -Value 0
            }
            catch {
            }
        }

        return
    }

    Write-Warn (T 'DistroInit' $DistroName)
    Start-Process -FilePath 'wsl.exe' -ArgumentList @('-d', $DistroName)
    Read-Host (T 'DistroInitPrompt') | Out-Null

    if (-not (Test-DistroReady -DistroName $DistroName)) {
        throw "The distro $DistroName is not ready yet."
    }
}

function Install-KaliTools {
    Write-Info (T 'KaliToolsInstall')
    Assert-WslResponsive
    if (-not (Test-DistroReady -DistroName 'kali-linux')) {
        throw (T 'DistroUnresponsive' 'kali-linux')
    }

    $command = @(
        'export DEBIAN_FRONTEND=noninteractive'
        'apt-get update'
        'apt-get install -y kali-linux-large'
    ) -join ' && '

    & wsl.exe -d 'kali-linux' -u root -- sh -lc $command | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw 'Kali package installation failed.'
    }

    Write-Ok (T 'KaliToolsDone')
}

function Test-WindowsTerminalInstalled {
    $packages = Get-AppxPackage -Name 'Microsoft.WindowsTerminal*' -ErrorAction SilentlyContinue
    return $packages.Count -gt 0
}

function Ensure-WindowsTerminalInstalled {
    if (Test-WindowsTerminalInstalled) {
        Write-Ok (T 'TerminalPresent')
        return
    }

    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        Show-TerminalRecommendations
        throw 'winget.exe is not available.'
    }

    Write-Info (T 'TerminalInstall')
    try {
        & winget.exe install --id Microsoft.WindowsTerminal -e --accept-source-agreements --accept-package-agreements | Out-Host
    }
    catch {
        Show-TerminalRecommendations
        throw
    }

    if (-not (Test-WindowsTerminalInstalled)) {
        Show-TerminalRecommendations
        throw 'Windows Terminal package not detected after installation.'
    }

    Write-Ok (T 'TerminalDone')
}

function Get-WindowsTerminalSettingsPath {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json')
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json')
        (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json')
    )

    foreach ($candidate in $candidates) {
        $directory = Split-Path -Parent $candidate
        if (Test-Path $directory) {
            return $candidate
        }
    }

    $defaultPath = $candidates[0]
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $defaultPath) | Out-Null
    return $defaultPath
}

function New-TerminalSettingsSkeleton {
    return [pscustomobject]@{
        '$schema' = 'https://aka.ms/terminal-profiles-schema'
        actions = @()
        schemes = @()
        profiles = [pscustomobject]@{
            defaults = [pscustomobject]@{}
            list = @()
        }
    }
}

function Set-TerminalActions {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Settings
    )

    $moveFocusBindings = @(
        @{ keys = 'ctrl+left'; direction = 'left' }
        @{ keys = 'ctrl+right'; direction = 'right' }
        @{ keys = 'ctrl+up'; direction = 'up' }
        @{ keys = 'ctrl+down'; direction = 'down' }
    )

    $existing = @($Settings.actions)
    $filtered = @()

    foreach ($action in $existing) {
        $keys = $null
        if ($null -ne $action.keys) {
            $keys = @($action.keys)
        }

        if ($keys -contains 'ctrl+left' -or $keys -contains 'ctrl+right' -or $keys -contains 'ctrl+up' -or $keys -contains 'ctrl+down') {
            continue
        }

        $filtered += $action
    }

    foreach ($binding in $moveFocusBindings) {
        $filtered += [pscustomobject]@{
            command = [pscustomobject]@{
                action = 'moveFocus'
                direction = $binding.direction
            }
            keys = $binding.keys
        }
    }

    Ensure-ObjectProperty -Object $Settings -Name 'actions' -Value $filtered
}

function Set-TerminalScheme {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Settings
    )

    $schemeName = 'AllinOneHacker'
    $schemes = @($Settings.schemes)
    $filteredSchemes = @()

    foreach ($scheme in $schemes) {
        if ($scheme.name -eq $schemeName) {
            continue
        }

        $filteredSchemes += $scheme
    }

    $filteredSchemes += [pscustomobject]@{
        name = $schemeName
        background = '#0A0F0D'
        black = '#0C0C0C'
        blue = '#2E8B57'
        brightBlack = '#1E1E1E'
        brightBlue = '#44FFB0'
        brightCyan = '#6AFFE9'
        brightGreen = '#6BFF6B'
        brightPurple = '#71B7FF'
        brightRed = '#FF6B6B'
        brightWhite = '#E8FFE8'
        brightYellow = '#D0FF5C'
        cursorColor = '#99FF99'
        cyan = '#00B894'
        foreground = '#C8FFD4'
        green = '#00FF66'
        purple = '#55D6FF'
        red = '#FF5E5B'
        selectionBackground = '#1B5E20'
        white = '#D6FFD6'
        yellow = '#C7F464'
    }

    Ensure-ObjectProperty -Object $Settings -Name 'schemes' -Value $filteredSchemes
}

function Configure-WindowsTerminal {
    param(
        [string]$BackgroundImagePath,
        [string]$FontFace
    )

    Write-Info (T 'TerminalSettings')
    $settingsPath = Get-WindowsTerminalSettingsPath
    $settings = if (Test-Path $settingsPath) {
        Get-Content -Path $settingsPath -Raw | ConvertFrom-Json
    }
    else {
        New-TerminalSettingsSkeleton
    }

    $backupPath = '{0}.{1}.bak' -f $settingsPath, (Get-Date -Format 'yyyyMMddHHmmss')
    if (Test-Path $settingsPath) {
        Copy-Item -Path $settingsPath -Destination $backupPath -Force
        Write-Info (T 'BackupCreated' $backupPath)
    }

    if ($null -eq $settings.profiles) {
        Ensure-ObjectProperty -Object $settings -Name 'profiles' -Value ([pscustomobject]@{
                defaults = [pscustomobject]@{}
                list = @()
            })
    }

    if ($null -eq $settings.profiles.defaults) {
        Ensure-ObjectProperty -Object $settings.profiles -Name 'defaults' -Value ([pscustomobject]@{})
    }

    if ($null -eq $settings.profiles.list) {
        Ensure-ObjectProperty -Object $settings.profiles -Name 'list' -Value @()
    }

    Ensure-ObjectProperty -Object $settings -Name '$schema' -Value 'https://aka.ms/terminal-profiles-schema'
    $wslLauncherPath = Join-Path $ScriptRoot 'launch-wsl-profile.ps1'
    $kaliCommand = "powershell.exe -NoLogo -ExecutionPolicy Bypass -File `"$wslLauncherPath`" -DistroName `"kali-linux`" -FriendlyName `"Kali Linux`" -UserName `"root`""
    $ubuntuCommand = "powershell.exe -NoLogo -ExecutionPolicy Bypass -File `"$wslLauncherPath`" -DistroName `"Ubuntu`" -FriendlyName `"Ubuntu`""
    $powerShellCommand = '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe'
    Ensure-ObjectProperty -Object $settings -Name 'startupActions' -Value 'new-tab --title "Kali Linux" -p "AllinOne Kali" ; split-pane -H -s 0.40 --title "Windows PowerShell" -p "AllinOne PowerShell" ; split-pane -V --title "Ubuntu" -p "AllinOne Ubuntu" ; move-focus up'
    Ensure-ObjectProperty -Object $settings -Name 'startOnUserLogin' -Value $false
    Ensure-ObjectProperty -Object $settings -Name 'windowingBehavior' -Value 'useNew'
    Ensure-ObjectProperty -Object $settings -Name 'launchMode' -Value 'default'
    Ensure-ObjectProperty -Object $settings -Name 'initialCols' -Value 108
    Ensure-ObjectProperty -Object $settings -Name 'initialRows' -Value 28
    Remove-ObjectProperty -Object $settings -Name 'centerOnLaunch'
    Remove-ObjectProperty -Object $settings -Name 'initialPosition'

    $defaults = $settings.profiles.defaults
    Ensure-ObjectProperty -Object $defaults -Name 'colorScheme' -Value 'AllinOneHacker'
    Ensure-ObjectProperty -Object $defaults -Name 'font' -Value ([pscustomobject]@{
            face = $FontFace
            size = 12
        })
    Ensure-ObjectProperty -Object $defaults -Name 'useAcrylic' -Value $true
    Ensure-ObjectProperty -Object $defaults -Name 'opacity' -Value 76
    Ensure-ObjectProperty -Object $defaults -Name 'cursorShape' -Value 'bar'
    Ensure-ObjectProperty -Object $defaults -Name 'padding' -Value '6, 6, 6, 6'
    Ensure-ObjectProperty -Object $defaults -Name 'experimental.retroTerminalEffect' -Value $true
    Ensure-ObjectProperty -Object $defaults -Name 'backgroundImageStretchMode' -Value 'uniformToFill'

    if ($BackgroundImagePath) {
        Ensure-ObjectProperty -Object $defaults -Name 'backgroundImage' -Value $BackgroundImagePath
        Ensure-ObjectProperty -Object $defaults -Name 'backgroundImageOpacity' -Value 0.45
    }
    else {
        Remove-ObjectProperty -Object $defaults -Name 'backgroundImage'
        Remove-ObjectProperty -Object $defaults -Name 'backgroundImageOpacity'
    }

    $existingProfileList = @($settings.profiles.list)
    $safeProfileList = @()

    foreach ($profile in $existingProfileList) {
        $isCustomStub = $false

        if (
            ($profile.name -in @('Kali Linux', 'Ubuntu', 'Windows PowerShell', 'AllinOne Kali', 'AllinOne Ubuntu', 'AllinOne PowerShell')) -and
            (
                $null -eq $profile.source -or
                $profile.commandline -like '*launch-wsl-profile.ps1*' -or
                $profile.commandline -eq $powerShellCommand
            )
        ) {
            $isCustomStub = $true
        }

        if (-not $isCustomStub) {
            $safeProfileList += $profile
        }
    }

    $safeProfileList += @(
        [pscustomobject]@{
            guid = '{7ec60a1a-a334-4c13-b6a3-34f2f04b7745}'
            hidden = $false
            name = 'AllinOne Kali'
            commandline = $kaliCommand
        },
        [pscustomobject]@{
            guid = '{f4a45645-3680-4fe8-9806-56f7384796a0}'
            hidden = $false
            name = 'AllinOne PowerShell'
            commandline = $powerShellCommand
        },
        [pscustomobject]@{
            guid = '{2d7d4bd9-9cca-4c3f-9a4d-e4c214d2f19b}'
            hidden = $false
            name = 'AllinOne Ubuntu'
            commandline = $ubuntuCommand
        }
    )

    Ensure-ObjectProperty -Object $settings.profiles -Name 'list' -Value $safeProfileList
    Remove-ObjectProperty -Object $settings -Name 'defaultProfile'
    Set-TerminalScheme -Settings $settings
    Set-TerminalActions -Settings $settings

    $json = $settings | ConvertTo-Json -Depth 100
    Set-Content -Path $settingsPath -Value $json -Encoding UTF8
    Write-Ok (T 'TerminalSettingsDone')
}

function New-Shortcut {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ShortcutPath,
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [string]$HotKey,
        [string]$WorkingDirectory,
        [string]$IconLocation
    )

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($ShortcutPath)
    $shortcut.TargetPath = $TargetPath
    $shortcut.WorkingDirectory = $WorkingDirectory
    $shortcut.WindowStyle = 1

    if ($HotKey) {
        $shortcut.Hotkey = $HotKey
    }

    if ($IconLocation) {
        $shortcut.IconLocation = $IconLocation
    }

    $shortcut.Save()
}

function Create-LauncherShortcuts {
    Write-Info (T 'ShortcutCreate')

    $desktopShortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) 'AllinOne Terminal.lnk'
    $bundledIcon = Join-Path $ScriptRoot 'terminal-shortcut.ico'
    $portableIcon = Join-Path $ScriptRoot 'windows-terminal-portable\app\terminal-1.24.10621.0\WindowsTerminal.exe'
    $terminalIcon = if (Test-Path $bundledIcon) {
        $bundledIcon
    }
    elseif (Test-Path $portableIcon) {
        $portableIcon
    }
    else {
        Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\wt.exe'
    }

    New-Shortcut -ShortcutPath $desktopShortcut -TargetPath $LauncherScriptPath -HotKey 'CTRL+ALT+T' -WorkingDirectory $ScriptRoot -IconLocation $terminalIcon

    $startupShortcut = Join-Path ([Environment]::GetFolderPath('Startup')) 'AllinOne Terminal Startup.lnk'
    if (Test-Path $startupShortcut) {
        Remove-Item -Path $startupShortcut -Force -ErrorAction SilentlyContinue
    }

    Write-Ok (T 'ShortcutDone')
}

try {
    Write-Info (T 'ChoosingLanguage')
    Write-Info (T 'LogFile' $LogPath)
    Ensure-Administrator

    Write-Info (T 'StartingChecks')
    $backgroundImage = Get-BackgroundImage
    $virtualization = Get-VirtualizationStatus
    if ($virtualization.VirtualizationFirmwareEnabled) {
        Write-Ok (T 'VirtualizationOk')
    }
    else {
        Write-Warn (T 'VirtualizationWarn')
    }

    Ensure-WslPlatform
    Ensure-DistroInstalled -DistroName 'Ubuntu'
    Ensure-DistroInstalled -DistroName 'kali-linux'
    Ensure-DistroInitialized -DistroName 'Ubuntu'
    Ensure-DistroInitialized -DistroName 'kali-linux'
    Install-KaliTools

    Ensure-WindowsTerminalInstalled
    Configure-WindowsTerminal -BackgroundImagePath $backgroundImage -FontFace (Get-HackerFont)
    Create-LauncherShortcuts

    Write-Ok (T 'Complete')
    Write-Info (T 'OpenTerminal')
}
catch {
    Write-Fail $_.Exception.Message
    if ($_ | Out-String | Select-String -SimpleMatch 'restart') {
        Write-Warn (T 'WslNeedsRestart')
    }
    else {
        Write-Host $_.ScriptStackTrace
    }
    exit 1
}
finally {
    try {
        Stop-Transcript | Out-Null
    }
    catch {
    }
}
