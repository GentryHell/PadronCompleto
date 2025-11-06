# ===========================================
# UploadPadronCompleto.ps1
# ===========================================
# Sube la BD PadronCompletoDB.sqlite3 comprimida como ZIP
# al repo publico GentryHell/PadronCompleto
# con nombre fijo y archivo .version (SHA256)
# ===========================================

$scriptDir = $PSScriptRoot
$dbPath = Join-Path $scriptDir "bin\Debug\net8.0-windows\DBs\PadronCompletoDB.sqlite3"
$githubRepo = "GentryHell/PadronCompleto"

# -------------------------------------------
# 0. Verificaciones
# -------------------------------------------
if (!(Test-Path $dbPath)) {
    Write-Error "No se encontro la base de datos en: $dbPath"
    exit 1
}
Write-Host "[OK] Archivo encontrado: $dbPath"

$repoInfo = gh repo view $githubRepo 2>$null
if (-not $repoInfo) {
    Write-Error "El repositorio $githubRepo no existe o no tienes acceso."
    exit 1
}

$commitCount = git ls-remote https://github.com/$githubRepo.git | Measure-Object | Select-Object -ExpandProperty Count
if ($commitCount -eq 0) {
    Write-Error "El repositorio $githubRepo esta vacio. Debes tener al menos un commit inicial."
    exit 1
}

# -------------------------------------------
# 1. Crear version basada en fecha
# -------------------------------------------
$dateStr = Get-Date -Format "yyyy.MM.dd-HHmm"
$tag = "v$dateStr"
$releaseTitle = "Version $dateStr"
$releaseNotes = "Base de datos PadronCompleto comprimida y subida automaticamente el $dateStr"

Write-Host "Preparando release: $tag"

# -------------------------------------------
# 2. Comprimir base de datos con nombre fijo
# -------------------------------------------
$zipName = "PadronCompletoDB.sqlite3.zip"
$zipPath = Join-Path $scriptDir $zipName
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

Write-Host "Comprimiendo base de datos..."
Compress-Archive -Path $dbPath -DestinationPath $zipPath

if (!(Test-Path $zipPath)) {
    Write-Error "No se pudo generar el archivo ZIP."
    exit 1
}
Write-Host "[OK] ZIP generado: $zipPath"

# -------------------------------------------
# 3. Generar hash y archivo .version
# -------------------------------------------
$hash = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash
$versionFile = Join-Path $scriptDir "PadronCompletoDB.version"

@"
SHA256: $hash
Fecha:  $(Get-Date -Format "yyyy-MM-dd HH:mm")
Archivo: $zipName
"@ | Set-Content -Path $versionFile -Encoding UTF8

Write-Host "[OK] Archivo de version generado: $versionFile"

# -------------------------------------------
# 4. Crear o actualizar release
# -------------------------------------------
$releaseExists = gh release view $tag --repo $githubRepo 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "El release $tag ya existe. Se actualizaran archivos..."
} else {
    Write-Host "Creando release $tag..."
    gh release create $tag --repo $githubRepo -t $releaseTitle -n $releaseNotes
}

# -------------------------------------------
# 5. Subir archivos al release
# -------------------------------------------
Write-Host "Subiendo archivos..."
gh release upload $tag $zipPath --repo $githubRepo --clobber
gh release upload $tag $versionFile --repo $githubRepo --clobber

if ($LASTEXITCODE -ne 0) {
    Write-Error "Fallo la subida de los archivos."
    exit 1
}

Write-Host "[OK] Archivos subidos correctamente."

# -------------------------------------------
# 6. Limpiar temporales
# -------------------------------------------
try {
    Remove-Item $zipPath -Force
    Remove-Item $versionFile -Force
    Write-Host "[OK] Archivos temporales eliminados."
}
catch {
    Write-Warning "No se pudieron eliminar los temporales: $_"
}

# -------------------------------------------
# 7. Finalizar
# -------------------------------------------
$releaseUrl = "https://github.com/$githubRepo/releases/tag/$tag"
Write-Host "[OK] COMPLETADO"
Write-Host "Revisa el release en: $releaseUrl"
Write-Output $releaseUrl
