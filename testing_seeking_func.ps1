
function seek_sla() {
    param(
        $number_of_calls = 25,
        $average_Handle_time = 15,
        $target_handle_time = 15,
        $agent_starting_point = 10,
        $target_sla = 0.9,
        $variance = 0.1
    )

    $agents = $agent_starting_point
    $volume = calc_intensity -number_of_calls $number_of_calls -average_Handle_time $average_Handle_time

    [double]$pw = calculate_wait_probability -number_of_calls $number_of_calls -average_Handle_time $average_Handle_time -agents $agents -volume $volume

    [double]$service_level = 1 - ($pw * ([math]::Pow([math]::E, (-1 * (($agents - $volume) * ($target_handle_time / $average_Handle_time))))))

    $temp = [pscustomobject]@{
        agents        = $agents
        volume        = $volume
        pw            = $pw
        service_level = $service_level
    }

    if ($temp.service_level -gt $target_sla + $variance) {
        Write-Host $temp -ForegroundColor Yellow
        return (seek_sla -number_of_calls $number_of_calls -average_Handle_time $average_Handle_time -target_handle_time $target_handle_time -agent_starting_point ($agents - 1) -target_sla $target_sla -variance $variance)
    }
    elseif ($temp.service_level -lt $target_sla) {
        Write-Host $temp -ForegroundColor red
        return (seek_sla -number_of_calls $number_of_calls -average_Handle_time $average_Handle_time -target_handle_time $target_handle_time -agent_starting_point ($agents + 1) -target_sla $target_sla -variance $variance)
    }
    else {
        return $temp
    }
}


seek_sla -number_of_calls 100 -average_Handle_time 15 -target_handle_time 15 -agent_starting_point 10 -target_sla 0.9 -variance 0.05
