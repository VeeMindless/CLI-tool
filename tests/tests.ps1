# Simple Test Suite for CLI-tool.ps1
# No external dependencies - just basic PowerShell testing

param(
    [switch]$NonInteractive
)

# Prevent window from closing immediately
#$Host.UI.RawUI.WindowTitle = "CLI-tool Tests"

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "    CLI-TOOL SIMPLE TESTS" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

$TestsPassed = 0
$TestsFailed = 0
$TestResults = @()

function Test-Feature 
{
    param
    (
        [string]$TestName,
        [scriptblock]$TestCode
    )
    
    Write-Host "Testing: $TestName" -ForegroundColor Yellow
    
    try 
    {
        $result = & $TestCode
        if ($result) 
        {
            Write-Host "PASSED" -ForegroundColor Green
            $script:TestsPassed++
            $script:TestResults += [PSCustomObject]@{
                Test = $TestName
                Result = "PASSED"
                Error = ""
            }
        } 
        else 
        {
            Write-Host "FAILED" -ForegroundColor Red
            $script:TestsFailed++
            $script:TestResults += [PSCustomObject]@{
                Test = $TestName
                Result = "FAILED"
                Error = "Test returned false"
            }
        }
    } 
    catch 
    {
        Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestsFailed++
        $script:TestResults += [PSCustomObject]@{
            Test = $TestName
            Result = "FAILED"
            Error = $_.Exception.Message
        }
    }
}

# Get the directory where this test script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CLIToolPath = if ($ScriptDir -like "*tests") 
{
    # If running from tests directory, go up one level
    Join-Path (Split-Path -Parent $ScriptDir) "CLI-tool.ps1"
} 
else 
{
    # If running from root directory
    Join-Path $ScriptDir "CLI-tool.ps1"
}

Write-Host "Looking for CLI-tool.ps1 at: $CLIToolPath" -ForegroundColor Gray

# Test 1: Check if script file exists
Test-Feature "Script file exists" {
    Test-Path $CLIToolPath
}

# Test 2: Script has valid PowerShell syntax
Test-Feature "Valid PowerShell syntax" {
    if (-not (Test-Path $CLIToolPath)) 
    {
        Write-Host "  CLI-tool.ps1 not found at $CLIToolPath" -ForegroundColor Red
        return $false
    }
    try 
    {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $CLIToolPath -Raw), [ref]$null)
        return $true
    } 
    catch 
    {
        return $false
    }
}

# Test 3: Help parameter works
Test-Feature "Help parameter works" {
    if (-not (Test-Path $CLIToolPath)) 
    { 
        return $false 
    }
    try 
    {
        & $CLIToolPath -Help > $null 2>&1
        return $true  # If no error thrown, help works
    } 
    catch 
    {
        return $false
    }
}

# Test 4: CSV output generation
Test-Feature "CSV output generation" {
    if (-not (Test-Path $CLIToolPath)) 
    { 
        return $false 
    }
    $testFile = "test-output.csv"
    if (Test-Path $testFile) 
    { 
        Remove-Item $testFile -Force 
    }
    
    try 
    {
        & $CLIToolPath -OutputFormat CSV -OutputFile $testFile 2>$null
        $exists = Test-Path $testFile
        
        if ($exists) 
        {
            Remove-Item $testFile -Force
        }
        return $exists
    } 
    catch 
    {
        if (Test-Path $testFile) 
        { 
            Remove-Item $testFile -Force 
        }
        return $false
    }
}

# Test 5: JSON output generation
Test-Feature "JSON output generation" {
    if (-not (Test-Path $CLIToolPath)) 
    { 
        return $false 
    }
    $testFile = "test-output.json"
    if (Test-Path $testFile) 
    { 
        Remove-Item $testFile -Force 
    }
    
    try 
    {
        & $CLIToolPath -OutputFormat JSON -OutputFile $testFile 2>$null
        $exists = Test-Path $testFile
        
        if ($exists) 
        {
            Remove-Item $testFile -Force
        }
        return $exists
    } 
    catch 
    {
        if (Test-Path $testFile) 
        { 
            Remove-Item $testFile -Force 
        }
        return $false
    }
}

# Test 6: CSV file has correct headers
Test-Feature "CSV file has correct headers" {
    if (-not (Test-Path $CLIToolPath)) 
    { 
        return $false 
    }
    $testFile = "test-headers.csv"
    if (Test-Path $testFile) 
    { 
        Remove-Item $testFile -Force 
    }
    
    try 
    {
        & $CLIToolPath -OutputFormat CSV -OutputFile $testFile 2>$null
        
        if (Test-Path $testFile) 
        {
            $content = Get-Content $testFile -First 1
            $hasHeaders = $content -match "ProcessID.*ProcessName.*User.*CPUUsage.*MemoryUsageMB.*StartTime.*Status.*PriorityClass.*Path"
            Remove-Item $testFile -Force
            return $hasHeaders
        }
        return $false
    } 
    catch 
    {
        if (Test-Path $testFile) 
        { 
            Remove-Item $testFile -Force 
        }
        return $false
    }
}

# Test 7: JSON file is valid JSON
Test-Feature "JSON file is valid JSON" {
    if (-not (Test-Path $CLIToolPath)) 
    { 
        return $false 
    }
    $testFile = "test-json.json"
    if (Test-Path $testFile) 
    { 
        Remove-Item $testFile -Force 
    }
    
    try 
    {
        & $CLIToolPath -OutputFormat JSON -OutputFile $testFile 2>$null
        
        if (Test-Path $testFile) 
        {
            try 
            {
                $null = Get-Content $testFile -Raw | ConvertFrom-Json
                Remove-Item $testFile -Force
                return $true
            } 
            catch 
            {
                if (Test-Path $testFile) 
                { 
                    Remove-Item $testFile -Force 
                }
                return $false
            }
        }
        return $false
    } 
    catch 
    {
        if (Test-Path $testFile) 
        { 
            Remove-Item $testFile -Force 
        }
        return $false
    }
}

# Test 8: Invalid format parameter is rejected
Test-Feature "Invalid format parameter rejected" {
    if (-not (Test-Path $CLIToolPath)) 
    { 
        return $false 
    }
    try 
    {
        $ErrorActionPreference = "Stop"
        & $CLIToolPath -OutputFormat "INVALID" 2>$null
        return $false  # Should have failed
    } 
    catch 
    {
        return $true   # Expected to fail
    }
}

# Display Results
Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "         TEST SUMMARY" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($TestsPassed + $TestsFailed)" -ForegroundColor White
Write-Host "Passed: $TestsPassed" -ForegroundColor Green
Write-Host "Failed: $TestsFailed" -ForegroundColor Red

if ($TestsFailed -gt 0) 
{
    Write-Host ""
    Write-Host "Failed Tests:" -ForegroundColor Red
    $TestResults | Where-Object { $_.Result -eq "FAILED" } | ForEach-Object {
        Write-Host "  - $($_.Test): $($_.Error)" -ForegroundColor Red
    }
}

Write-Host ""
if ($TestsFailed -eq 0) 
{
    Write-Host "All tests passed! CLI-tool is working correctly." -ForegroundColor Green
    if (-not $NonInteractive) {
        Write-Host ""
        Write-Host "Press any key to continue..." -ForegroundColor Gray
        try 
        {
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        } 
        catch 
        {
            # Fallback for environments where ReadKey doesn't work
            Read-Host "Press Enter to continue"
        }
    }
    exit 0
} 
else 
{
    Write-Host "Some tests failed. Please check the CLI-tool script." -ForegroundColor Red
    if (-not $NonInteractive) {
        Write-Host ""
        Write-Host "Press any key to continue..." -ForegroundColor Gray
        try 
        {
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        } 
        catch 
        {
            # Fallback for environments where ReadKey doesn't work
            Read-Host "Press Enter to continue"
        }
    }
    exit 1
}
