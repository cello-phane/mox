$ErrorActionPreference = "Stop"

# ============================================================
# Mox -> LLVM COFF OBJ -> Clang -> raylib
# ============================================================

$sourceDir = ".\examples"
$moduleName = "2_raylib.mox"

$sourceFile = Join-Path $sourceDir $moduleName
$objectBase = Join-Path $sourceDir "$moduleName.obj"
$outputFile = Join-Path $sourceDir "$moduleName.exe"

$raylibPath = "C:\repos\mox\modules\vendor\raylib\win64_mingw"
$raylibDll  = Join-Path $raylibPath "raylib.dll"
$clang = "C:\software\llvm\bin\clang.exe"
$w64devkit = "C:\repos\w64devkit"

$gccLibPath = "$w64devkit\lib\gcc\x86_64-w64-mingw32\16.1.0"
$mingwLibPath = "$w64devkit\x86_64-w64-mingw32\lib"
$mingwLibPath2 = "$w64devkit\x86_64-w64-mingw32\mingw\lib"
$w64LibPath = "$w64devkit\lib"
# ------------------------------------------------------------
# 1. Compile Mox -> LLVM COFF objects
# ------------------------------------------------------------

Get-ChildItem "$objectBase.*.obj" -File -ErrorAction SilentlyContinue |
    Remove-Item -Force

Write-Host ""
Write-Host "============================================"
Write-Host " Compiling Mox -> LLVM COFF OBJ"
Write-Host "============================================"

& .\mox.exe `
    backend=llvm `
    llvm_out_format=obj `
    compile=$sourceFile `
    out=$objectBase `
    linker=""

if ($LASTEXITCODE -ne 0) {
    throw "Mox compilation failed with exit code $LASTEXITCODE"
}

$objectFiles = @(
    Get-ChildItem "$objectBase.*.obj" -File |
        Sort-Object {
            if ($_.Name -match '\.obj\.(\d+)\.obj$') {
                [int]$Matches[1]
            }
            else {
                [int]::MaxValue
            }
        }
)

if ($objectFiles.Count -eq 0) {
    throw "No Mox object files were generated."
}

Write-Host ""
Write-Host "Generated object files:"
$objectFiles | ForEach-Object {
    Write-Host "  $($_.FullName)"
}

# ------------------------------------------------------------
# 2. Select linker
# ------------------------------------------------------------

$linker = $clang
$linkerName = "Clang"

if (-not (Test-Path $linker)) {
    throw "Clang not found: $linker"
}

Write-Host ""
Write-Host "============================================"
Write-Host " Linking with $linkerName"
Write-Host "============================================"

# ------------------------------------------------------------
# 3. Link
# ------------------------------------------------------------

$clangArgs = @(
    "-target", "x86_64-w64-windows-gnu"
    "-nodefaultlibs"
    "-Wl,--subsystem,console"

    $objectFiles.FullName

    "-L$raylibPath"
    "-L$gccLibPath"
    "-L$mingwLibPath"
    "-L$mingwLibPath2"
    "-L$w64LibPath"

    "-lraylibdll"

    "-luser32"
    "-lgdi32"
    "-lwinmm"
    "-lshell32"
    "-ladvapi32"
    "-lole32"
    "-loleaut32"
    "-luuid"
    "-lcomdlg32"
    "-limm32"
    "-lversion"

    "-lmingw32"
    "-lgcc"
    "-lmingwex"
    "-lmsvcrt"
    "-lkernel32"

    "-o"
    $outputFile
)

& $linker @clangArgs

if ($LASTEXITCODE -ne 0) {
    throw "$linkerName link failed with exit code $LASTEXITCODE"
}

# ------------------------------------------------------------
# 4. Deploy raylib.dll
# ------------------------------------------------------------

$outputDirectory = Split-Path -Parent $outputFile

if ([string]::IsNullOrEmpty($outputDirectory)) {
    $outputDirectory = "."
}

$dllOutput = Join-Path $outputDirectory "raylib.dll"

# 4. Deploy raylib.dll
# ------------------------------------------------------------

Copy-Item $raylibDll $sourceDir -Force

Write-Host ""
Write-Host "============================================"
Write-Host " Build successful"
Write-Host "============================================"
Write-Host " Linker: $linkerName"
Write-Host " EXE:    $outputFile"
Write-Host " DLL:    $(Join-Path $sourceDir 'raylib.dll')"
