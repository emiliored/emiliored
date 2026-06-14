# Script de PowerShell para descargar ClamAV (versión portable) y Sysinternals Suite
# Última versión - Junio 2026

# Requiere ejecutar como administrador
#Requires -RunAsAdministrator

# Configuración
$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"

# Obtener la carpeta del script
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClamAVPath = Join-Path $ScriptPath "ClamAV"
$SysinternalsPath = Join-Path $ScriptPath "SysinternalsSuite"

# Funciones auxiliares
function Write-Header {
    param([string]$Message)
    Write-Host "`n" -NoNewline
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "=" * 70 -ForegroundColor Cyan
}

function Write-Status {
    param([string]$Message)
    Write-Host "[*] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "[+] $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[-] ERROR: $Message" -ForegroundColor Red
}

function Calculate-MD5 {
    param([string]$FilePath)
    $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $file = [System.IO.File]::Open($FilePath, [System.IO.FileMode]::Open)
    $hash = [System.BitConverter]::ToString($md5.ComputeHash($file))
    $file.Close()
    return $hash -replace '-', ''
}

# ========== LIMPIAR Y CREAR DIRECTORIOS ==========
Write-Header "Preparando directorios"

# Limpiar ClamAV
if (Test-Path $ClamAVPath) {
    Write-Status "Eliminando carpeta ClamAV existente..."
    Remove-Item -Path $ClamAVPath -Recurse -Force
    Write-Success "Carpeta ClamAV eliminada"
}

# Limpiar Sysinternals
if (Test-Path $SysinternalsPath) {
    Write-Status "Eliminando carpeta SysinternalsSuite existente..."
    Remove-Item -Path $SysinternalsPath -Recurse -Force
    Write-Success "Carpeta SysinternalsSuite eliminada"
}

# Crear directorios
New-Item -ItemType Directory -Path $ClamAVPath | Out-Null
Write-Success "Carpeta ClamAV creada: $ClamAVPath"

New-Item -ItemType Directory -Path $SysinternalsPath | Out-Null
Write-Success "Carpeta SysinternalsSuite creada: $SysinternalsPath"

# ========== CLAMAV PORTABLE ==========
Write-Header "Descargando ClamAV (versión portable)"

try {
    Write-Status "Obteniendo información de la última versión de ClamAV..."
    
    # Obtener la última versión de ClamAV desde GitHub
    $ClamAVReleases = Invoke-RestMethod -Uri "https://api.github.com/repos/Cisco-Talos/clamav/releases/latest" -ErrorAction Stop
    $ClamAVVersion = $ClamAVReleases.tag_name -replace '^v', ''
    
    Write-Success "Última versión de ClamAV encontrada: $ClamAVVersion"
    
    # URL de descarga (versión portable para Windows x64)
    $ClamAVUrl = "https://www.clamav.net/downloads/production/clamav-$ClamAVVersion.win.x64.zip"
    $ClamAVZipPath = Join-Path $ClamAVPath "clamav-$ClamAVVersion.win.x64.zip"
    
    Write-Status "Descargando ClamAV portable desde: $ClamAVUrl"
    Invoke-WebRequest -Uri $ClamAVUrl -OutFile $ClamAVZipPath -ErrorAction Stop
    Write-Success "ClamAV descargado correctamente"
    
    # Descomprimir
    Write-Status "Descomprimiendo ClamAV..."
    Expand-Archive -Path $ClamAVZipPath -DestinationPath $ClamAVPath -ErrorAction Stop
    Write-Success "ClamAV descomprimido correctamente"
    
    # Eliminar ZIP después de descomprimir
    Remove-Item -Path $ClamAVZipPath -Force
    
}
catch {
    Write-Error-Custom "Error al descargar ClamAV: $_"
}

# ========== SYSINTERNALS SUITE ==========
Write-Header "Descargando Sysinternals Suite"

try {
    Write-Status "Descargando Sysinternals Suite..."
    
    # URL oficial de Sysinternals Suite
    $SysinternalsUrl = "https://download.sysinternals.com/files/SysinternalsSuite.zip"
    $SysinternalsZipPath = Join-Path $SysinternalsPath "SysinternalsSuite.zip"
    
    Invoke-WebRequest -Uri $SysinternalsUrl -OutFile $SysinternalsZipPath -ErrorAction Stop
    Write-Success "Sysinternals Suite descargado correctamente"
    
    # Descomprimir
    Write-Status "Descomprimiendo Sysinternals Suite..."
    Expand-Archive -Path $SysinternalsZipPath -DestinationPath $SysinternalsPath -ErrorAction Stop
    Write-Success "Sysinternals Suite descomprimido correctamente"
    
    # Eliminar ZIP después de descomprimir
    Remove-Item -Path $SysinternalsZipPath -Force
    
}
catch {
    Write-Error-Custom "Error al descargar Sysinternals Suite: $_"
}

# ========== CALCULAR MD5 ==========
Write-Header "Calculando checksums MD5"

# ClamAV MD5
Write-Status "Calculando MD5 de archivos ClamAV..."
$ClamAVMD5File = Join-Path $ClamAVPath "MD5.txt"
$ClamAVFiles = Get-ChildItem -Path $ClamAVPath -File -Recurse | Where-Object { $_.Name -ne "MD5.txt" }

$ClamAVMD5Content = @()
foreach ($file in $ClamAVFiles) {
    $md5Hash = Calculate-MD5 -FilePath $file.FullName
    $relativePath = $file.FullName -replace [regex]::Escape($ClamAVPath), ""
    $relativePath = $relativePath.TrimStart("\")
    $ClamAVMD5Content += "$md5Hash  $relativePath"
    Write-Success "MD5 calculado para: $($file.Name)"
}

# Guardar MD5 de ClamAV
$ClamAVMD5Content | Out-File -FilePath $ClamAVMD5File -Encoding UTF8
Write-Success "Archivo MD5.txt guardado en ClamAV"

# Sysinternals MD5
Write-Status "Calculando MD5 de archivos Sysinternals..."
$SysinternalsMD5File = Join-Path $SysinternalsPath "MD5.txt"
$SysinternalsFiles = Get-ChildItem -Path $SysinternalsPath -File -Recurse | Where-Object { $_.Name -ne "MD5.txt" }

$SysinternalsMD5Content = @()
foreach ($file in $SysinternalsFiles) {
    $md5Hash = Calculate-MD5 -FilePath $file.FullName
    $relativePath = $file.FullName -replace [regex]::Escape($SysinternalsPath), ""
    $relativePath = $relativePath.TrimStart("\")
    $SysinternalsMD5Content += "$md5Hash  $relativePath"
    Write-Success "MD5 calculado para: $($file.Name)"
}

# Guardar MD5 de Sysinternals
$SysinternalsMD5Content | Out-File -FilePath $SysinternalsMD5File -Encoding UTF8
Write-Success "Archivo MD5.txt guardado en SysinternalsSuite"

# ========== RESUMEN FINAL ==========
Write-Header "Descarga completada"

Write-Host "`nEstructura de carpetas creada:`n" -ForegroundColor Green
Write-Host "  📁 ClamAV" -ForegroundColor Cyan
Write-Host "     └─ Archivos portables de ClamAV" -ForegroundColor White
Write-Host "     └─ MD5.txt (hashes de verificación)" -ForegroundColor White
Write-Host "`n  📁 SysinternalsSuite" -ForegroundColor Cyan
Write-Host "     └─ Herramientas Sysinternals" -ForegroundColor White
Write-Host "     └─ MD5.txt (hashes de verificación)" -ForegroundColor White

Write-Host "`n"
Write-Success "¡Descarga y verificación completadas!"
Write-Status "Revisa el README.md para instrucciones adicionales"
Write-Host "`n"
