$bytes = Get-Process | Measure-Object -Property WorkingSet64 -Sum | Select-Object -ExpandProperty Sum
$kbs = $bytes / 1024
$mbs = $kbs / 1024
$gbs = $mbs / 1024
$output = "Memory usage: {0} bytes, {1:N2} Kbs {2:N2} Mbs {3:N2} Gbs" -f $bytes, $kbs, $mbs, $gbs
Write-Output $output

