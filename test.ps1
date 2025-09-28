Import-Module .\erlang_C.psm1 -Force

$splat = @{
    volume                      = 200
    average_handle_time_seconds = 180
    traffic_intensity           = $null
    target_sla                  = 0.8
    shrinkage                   = 80
}
$splat.traffic_intensity = ($splat.volume * 3) / 60

$results = get_erlang_c @splat

$results | Format-List