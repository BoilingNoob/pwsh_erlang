#credit to https://github.com/mhicoayala/erlang_c/blob/main/erlang.py for implmentation, converted to powershell
function integer_factorial() {
    param(
        [int]$n
    )
    if ($n -eq 0) {
        return 1
    }
    $fact = 1
    1..$n | ForEach-Object {
        $fact *= $_
    }
    return $fact
}

function traffic_intensity() {
    param(
        $average_call_duration = 3, # minutes
        $calls_per_segment = 100 # calls/segment
    )
    return ($average_call_duration * $calls_per_segment) / 60 #returns as erlangs (call hours)
}

function probability_waiting() {
    param(
        $traffic_intensity,
        $number_of_agents
    )
    $x = ([math]::pow($traffic_intesity, $number_of_agents) / (integer_factorial([math]::round($number_of_agents, 0)))) * $number_of_agents / ($number_of_agents - $traffic_intensity)
    $y = 1

    for ($i = 0; $i -lt [math]::round($number_of_agents, 0); $i++) {
        $y += [math]::pow($traffic_intensity, $i) / (integer_factorial($i))
    }
    return $x / ($y + $x)
}

function service_level() {
    param(
        $pw,
        $traffic_intensity,
        $number_of_agents,
        $target_answer_time,
        $average_handle_time
    )
    return 1 - ($pw * [Math]::Pow([Math]::E, (-1 * ($number_of_agents - $traffic_intensity) * ($target_answer_time / $average_handle_time))))
}


function get_erlang_c() {
    param(
        $volume,
        $traffic_intensity,
        $target_answer_time,
        $average_handle_time_seconds,
        $target_sla,
        $shrinkage
    )
    # Raw Number of Agents
    $raw_agent = 1
    $n = [math]::round($traffic_intensity + $raw_agent, 0)

    $pw = probability_waiting($traffic_intensity, $n)

    $act_sla = service_level($pw, $traffic_intensity, $n, $target_answer_time, $average_handle_time_seconds)

    while ($act_sla -lt $target_sla) {
        $raw_agent += 1
        $n = [math]::round($traffic_intensity + $raw_agent)
        $pw = probability_waiting($traffic_intensity, $n)
        $act_sla = service_level($pw, $traffic_intesity, $n, $target_answer_time, $average_handle_time_seconds)
    }
        

    $average_speed_of_answer = ($pw * $average_handle_time_seconds) / ($n - $traffic_intesity)

    $percent_calls_answered_immediately = (1 - $pw) * 100

    $maximum_occupancy = ($traffic_intesity / $n) * 100

    $n_shrinkage = $n / (1 - $shrinkage)

    return [pscustomobject]@{
        'Volume' = int($volume),
        'Traffic Intensity'= int($traffic_intesity),
        'No. of Required Agents'= int($n),
        'No. of Required Agents w/ Shrinkage'= [math]::Ceiling($n_shrinkage),
        'Average Speed of Answer'= [math]::round($average_speed_of_answer, 1),
        '% of Calls Answered Immediately'= [math]::round($percent_calls_answered_immediately, 2),
        'Maximum Occupancy'= [math]::round($maximum_occupancy, 2),
        'SLA'= [math]::round(($act_sla * 100), 2) #
    }  
}




