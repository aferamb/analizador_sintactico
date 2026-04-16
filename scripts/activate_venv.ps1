$ScriptDir = Split-Path -Parent $PSCommandPath
$RootDir = Split-Path -Parent $ScriptDir
$ActivateScript = Join-Path $RootDir ".venv\Scripts\Activate.ps1"

if (-not (Test-Path $ActivateScript)) {
    Write-Host "Virtual environment not found at $RootDir\.venv" -ForegroundColor Red
    Write-Host "Run setup first: python scripts/dev_setup.py" -ForegroundColor Yellow
    exit 1
}

. $ActivateScript
Write-Host "Virtual environment activated (.venv)." -ForegroundColor Green
