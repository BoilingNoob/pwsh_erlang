#credit to https://github.com/mhicoayala/erlang_c/blob/main/erlang.py for implmentation, converted to powershell
function integer_factorial() {
    param(
        [int]$n
    )
    if ($n -eq 0) {
        return 1
    }
    [double]$fact = 1
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
    $basic_pow = [math]::pow($traffic_intensity, $number_of_agents)
    $odd_facotrial = (integer_factorial([math]::round($number_of_agents, 0)))
    $agent_traffic_diff = ($number_of_agents - $traffic_intensity)

    $x = ($basic_pow / $odd_facotrial) * $number_of_agents / ($agent_traffic_diff)
    $y = 1

    for ($i = 1; $i -le [math]::round($number_of_agents, 0); $i++) {
        $y += [math]::pow($traffic_intensity, $i) / (integer_factorial($i))
    }
    $result = $x / ($y + $x)

    return $result
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

    $pw = probability_waiting $traffic_intensity $n

    $act_sla = service_level $pw $traffic_intensity $n $target_answer_time $average_handle_time_seconds

    while ($act_sla -lt $target_sla) {
        $raw_agent += 1
        $n = [math]::round($traffic_intensity + $raw_agent)
        $pw = probability_waiting $traffic_intensity $n
        $act_sla = service_level $pw $traffic_intensity $n $target_answer_time $average_handle_time_seconds
    }


    $average_speed_of_answer = ($pw * $average_handle_time_seconds) / ($n - $traffic_intensity)

    $percent_calls_answered_immediately = (1 - $pw) * 100

    $maximum_occupancy = ($traffic_intensity / $n) * 100

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




