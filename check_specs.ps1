$gpu = Get-CimInstance Win32_VideoController | Where-Object Name -notlike '*Oray*' | Select-Object -First 1
$vram = [math]::Round($gpu.AdapterRAM / 1GB, 2)
Write-Output "GPU: $($gpu.Name)"
Write-Output "VRAM: ${vram}GB"

$ram = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB
Write-Output "RAM: $([math]::Round($ram, 1))GB"

$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
Write-Output "CPU: $($cpu.Name)"
Write-Output "Cores: $($cpu.NumberOfCores) / Threads: $($cpu.NumberOfLogicalProcessors)"
