# Humanizer Launcher — loads .env and starts Ollama
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "   Humanizer Launcher" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Load .env file from same directory as this script
$envFile = Join-Path $PSScriptRoot ".env"

if (Test-Path $envFile) {
    Write-Host "Loading .env file..." -ForegroundColor Cyan
    Get-Content $envFile | ForEach-Object {
        $line = $_.Trim()
        # Skip empty lines and comments
        if ($line -and !$line.StartsWith("#")) {
            $parts = $line -split "=", 2
            if ($parts.Length -eq 2) {
                $key = $parts[0].Trim()
                $value = $parts[1].Trim()
                [System.Environment]::SetEnvironmentVariable($key, $value, "Process")
                Write-Host "  Set $key=$value" -ForegroundColor Gray
            }
        }
    }
    Write-Host "  .env loaded OK" -ForegroundColor Green
} else {
    Write-Host "  No .env file found, using defaults" -ForegroundColor Yellow
    $env:OLLAMA_ORIGINS = "*"
}

Write-Host ""

# Check if Ollama is already running
$ollamaRunning = $false
try {
    $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -TimeoutSec 2 -ErrorAction Stop
    $ollamaRunning = $true
} catch {}

if ($ollamaRunning) {
    Write-Host "Ollama is already running!" -ForegroundColor Green
} else {
    # Kill any existing Ollama process (which might be running without OLLAMA_ORIGINS)
    $existing = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "Stopping old Ollama instance (didn't have OLLAMA_ORIGINS set)..." -ForegroundColor Yellow
        Stop-Process -Name "ollama" -Force
        Start-Sleep -Seconds 2
    }

    Write-Host "Starting Ollama with OLLAMA_ORIGINS=* ..." -ForegroundColor Cyan
    Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Minimized

    # Wait for Ollama to be ready
    Write-Host "Waiting for Ollama to start" -NoNewline -ForegroundColor Cyan
    $tries = 0
    $ready = $false
    while ($tries -lt 15) {
        Start-Sleep -Seconds 1
        Write-Host "." -NoNewline -ForegroundColor Cyan
        try {
            $r = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -TimeoutSec 2 -ErrorAction Stop
            $ready = $true
            break
        } catch {}
        $tries++
    }

    Write-Host ""
    if ($ready) {
        Write-Host "Ollama is ready!" -ForegroundColor Green
    } else {
        Write-Host "Ollama may still be starting — open the app and click 'Test connection'" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Opening Humanizer in your browser..." -ForegroundColor Cyan

# Open humanizer.html in default browser
$htmlFile = Join-Path $PSScriptRoot "humanizer.html"
if (Test-Path $htmlFile) {
    Start-Process $htmlFile
    Write-Host "Done! humanizer.html opened." -ForegroundColor Green
} else {
    Write-Host "humanizer.html not found in $PSScriptRoot" -ForegroundColor Red
    Write-Host "Make sure humanizer.html is in the same folder as this script." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Ollama is running in the background." -ForegroundColor Green
Write-Host "  Close this window when you are done." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Keep window open
Read-Host "Press Enter to stop Ollama and exit"

# Cleanup — stop Ollama on exit
Write-Host "Stopping Ollama..." -ForegroundColor Yellow
Stop-Process -Name "ollama" -Force -ErrorAction SilentlyContinue
Write-Host "Done. Goodbye!" -ForegroundColor Green
