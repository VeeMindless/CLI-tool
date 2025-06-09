##########################################################################################################################################
# Script Name:         CLI-tool.
# Description:         A simple utility to generate reports of running processes
# Args:                <>
# Author:              Vitek Cerny <vitto.black@gmail.com>
#
# Setup:               For first-time use, run:
#                      Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# Version:             1.0.1
# Changelog:
#                      05/06/2025 - V. 1.0.1 - Remove vars from Get-ProcessInfo() and consolidate conditionals into the custom object
#                                            - Add Status, PriorityClass, Path and Company to the reports
#
#                      04/06/2025 - V. 1.0.0 - Initial commit
#
#
# TODO:                - Add progress bar
#                      - Sign the script so it can be launched without bypassing exec policy (would require a commercial cert or self-signed with the CA imported on each host)
#
#
##########################################################################################################################################

param
(
    [ValidateSet("CSV", "JSON")]
    [string]$OutputFormat = "CSV",
    [string]$OutputFile = "",
    [switch]$Help
)

function Show-Help 
{
    Write-Host -ForegroundColor Green @"
    Process Reporter CLI Tool
    =========================

    DESCRIPTION:
        Generates a detailed report of running processes on Windows
        
    USAGE:
        .\CLI-tool.ps1 -OutputFormat CSV -OutputFile "processes.csv"
        PowerShell -ExecutionPolicy Bypass -File ".\CLI-tool.ps1" -OutputFormat JSON

    OPTIONS:
        -OutputFormat    Specify output format: CSV or JSON (default: CSV)
        -OutputFile      Specify output file path (optional)
        -Help           Show this help message

    EXAMPLES:
        .\CLI-tool.ps1 -OutputFormat CSV -OutputFile 'processes.csv'
        .\CLI-tool.ps1 -OutputFile 'Desktop\myreport.csv'
"@
}

function Get-ProcessInfo 
{
    Write-Host "Collecting process information..." -ForegroundColor Yellow
    
    Get-Process | ForEach-Object `
    {   
        #$processObject = New-Object psobject
        #$processObject | Add-Member -MemberType NoteProperty -Name "ProcessID" -Value $_.Id
        # ^ not optimal, better to use PSCustomObject
        
        # Get user - if unknown set to unknown, if cmd fails print err message
        try 
        {
            $owner = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId=$($_.Id)" | Invoke-CimMethod -MethodName GetOwner
            if ($owner.User) 
            {
                $user = "$($owner.Domain)\$($owner.User)"
            } 
            else 
            {     
                $user = 'Unknown'
            }
        } 
        catch 
        {
            $user = "Error: $($_.Exception.Message)"
             
        }
        
        [PSCustomObject]@{
        ProcessID     = $_.Id
        ProcessName   = $_.ProcessName
        User          = $user
        CPUUsage      = if ($_.CPU) { [math]::Round($_.CPU, 2) } else { 0 }
        MemoryUsageMB = if ($_.WorkingSet) { [math]::Round($_.WorkingSet / 1MB, 2) } else { 0 }
        StartTime     = if ($_.StartTime) { $_.StartTime.ToString("yyyy-MM-dd HH:mm:ss") } else { "Unknown" }
        Status        = if ($_.Responding) { "Responding" } else { "Not Responding" }
        PriorityClass = if ($_.PriorityClass) { $_.PriorityClass } else { "Unknown" }
        Path          = if ($_.Path) { $_.Path } else { "N/A" }
        Company       = if ($_.Company) { $_.Company } else { "Not Specified" }
        }
    }
}

# Export to CSV or JSON based on input format
function Export-Data 
{
    param
    (
        [Parameter(Mandatory)]
        $ProcessData,
        $FilePath,       
        [Parameter(Mandatory)]
        [ValidateSet("CSV", "JSON")]
        [string]$Format
    )
    
    try 
    {
        $outputPath = if ($FilePath) 
        {
            # Get basename without extension
            $fileName = [System.IO.Path]::GetFileName($FilePath)
            $baseFileName = $fileName.Split('.')[0]
            $directory = [System.IO.Path]::GetDirectoryName($FilePath)
    
            # Convert input path to absolute based on current working directory and append format extension based on 1st param
            # eg. script in C:/bin/scripts, user input: "report" => C:/bin/scripts/report.csv"
            if (-not [System.IO.Path]::IsPathRooted($FilePath)) 
            {
                $directory = if ($directory) 
                { 
                    Join-Path -Path (Get-Location) -ChildPath $directory 
                } 
                else 
                { 
                    Get-Location 
                }
            }
    
            # Add format as an extension
            $extension = $Format.ToLower()
            Join-Path -Path $directory -ChildPath "$baseFileName.$extension"
        }
        else
        {   # Default path if not specified by user
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            Join-Path -Path (Get-Location) -ChildPath "ProcessReport_$timestamp.$($Format.ToLower())"
        }

        # CRete directory if not exists
        $directory = Split-Path -Path $outputPath -Parent
        if ($directory -and !(Test-Path -Path $directory)) 
        {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        
        switch ($Format.ToUpper()) 
        {
            "CSV" 
            {
                $ProcessData | Export-Csv -Path $outputPath -NoTypeInformation
            }
            "JSON" 
            {
                $ProcessData | ConvertTo-Json -Depth 3 | Out-File -FilePath $outputPath -Encoding UTF8
            }
        }
         Write-Host "Report saved to: $outputPath" -ForegroundColor Green  
    }
    catch 
    {
        Write-Error "Failed to export $Format : $($_.Exception.Message)"
    }
}

function Show-Summary 
{
    param($ProcessData)
    
    $totalProcesses = $ProcessData.Count
    $totalMemory = ($ProcessData | Measure-Object -Property MemoryUsageMB -Sum).Sum
    $avgMemory = [math]::Round($totalMemory / $totalProcesses, 2)
    
    Write-Host ""
    Write-Host "PROCESS SUMMARY" -ForegroundColor Cyan
    Write-Host "===============" -ForegroundColor Cyan
    Write-Host "Total Processes: $totalProcesses"
    Write-Host "Total Memory Usage: $([math]::Round($totalMemory, 2)) MB"
    Write-Host "Average Memory per Process: $avgMemory MB"
    Write-Host ""
}

function Main 
{
    if ($Help) 
    {
        Show-Help
        return
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host "    PROCESS REPORTER CLI TOOL" -ForegroundColor Blue
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Gray
    Write-Host ""
    
    # Get process information
    $processData = Get-ProcessInfo
    
    if ($processData -eq $null) 
    {
        Write-Error "Failed to retrieve process information. Exiting."
        return
    }
    
    Show-Summary -ProcessData $processData
    
    Write-Host "Generating report in $OutputFormat format..." -ForegroundColor Yellow
    Export-Data -ProcessData $processData -Format $OutputFormat -FilePath $OutputFile
    
    Write-Host ""
    Write-Host "Process report generation completed successfully!" -ForegroundColor Green
    Write-Host ""
}

Main