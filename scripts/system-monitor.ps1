# System Monitor - appends system stats to system.md every run
param([string]$OutFile = "$PSScriptRoot\..\memory\system.md")

$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Disk stats (fixed drives)
$disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
$diskLines = foreach($d in $disks){
  $total = [math]::Round($d.Size/1GB,2)
  $free  = [math]::Round($d.FreeSpace/1GB,2)
  $used  = [math]::Round(($d.Size - $d.FreeSpace)/1GB,2)
  "$($d.DeviceID): Total ${total}GB, Used ${used}GB, Free ${free}GB"
}
$diskSection = "Disks:`n" + ($diskLines -join "`n")

# RAM stats
$os = Get-WmiObject Win32_OperatingSystem
$totalRam = [math]::Round($os.TotalVisibleMemorySize/1MB,2)
$freeRam  = [math]::Round($os.FreePhysicalMemory/1MB,2)
$usedRam  = [math]::Round($totalRam - $freeRam,2)
$ramSection = "RAM: Total ${totalRam}GB, Used ${usedRam}GB, Free ${freeRam}GB"

# CPU load (rough average, 1 sec)
$cpu = Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object Average
$cpuSection = "CPU Load: $([math]::Round($cpu.Average,1))%"

# Combine entry
$entry = @"
[${ts}]
${diskSection}
${ramSection}
${cpuSection}
---
"@

# Ensure directory exists
$dir = Split-Path $OutFile
if(!(Test-Path $dir)){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }

# Append to file
Add-Content -Path $OutFile -Value $entry
