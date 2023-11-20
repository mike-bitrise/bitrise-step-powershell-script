#!/usr/bin/env pwsh

# Set up environment variables
$content = $env:content
$working_dir = $env:working_dir
$script_file_path = $env:script_file_path
$is_debug = $env:is_debug

# Helper function for debug output
function Debug-Print {
    param (
        [String] $msg
    )

    if ($is_debug -eq "yes") {
        Write-Host $msg
    }
}

# Default the runner_bin to the current PowerShell interpreter
$runner_bin = $env:runner_bin
if ([String]::IsNullOrWhiteSpace($runner_bin)) {
    $currentProcess = Get-Process -Id $PID
    $runner_bin = $currentProcess.Path

    Debug-Print "==> No script executor defined, using current PowerShell interpreter: $runner_bin"
}

# Get the directory of the current script
$THIS_SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition

$CONFIG_tmp_script_file_path = Join-Path $THIS_SCRIPT_DIR "._script_cont.ps1"

if ([String]::IsNullOrWhiteSpace($content)) {
    Write-Host " [!] => Failed: No script (content) defined for execution!"
    exit 1
}

if ([String]::IsNullOrWhiteSpace($runner_bin)) {
    Write-Host " [!] => Failed: No script executor defined!"
    exit 1
}

Debug-Print "==> Start"

if (![String]::IsNullOrWhiteSpace($working_dir)) {
    Debug-Print "==> Switching to working directory: $working_dir"
    try {
        Set-Location $working_dir -ErrorAction Stop
    } catch {
        Write-Host " [!] => Failed to switch to working directory: $working_dir"
        exit 1
    }
}

if (![String]::IsNullOrWhiteSpace($script_file_path)) {
    Debug-Print "==> Script (tmp) save path specified: $script_file_path"
    $CONFIG_tmp_script_file_path = $script_file_path
}

[System.IO.File]::WriteAllText($CONFIG_tmp_script_file_path, $content)

Debug-Print ""

& $runner_bin $CONFIG_tmp_script_file_path
$script_result = $LASTEXITCODE

Debug-Print ""
Debug-Print "==> Script finished with exit code: $script_result"

Remove-Item $CONFIG_tmp_script_file_path
exit $script_result
