#credit to https://github.com/mhicoayala/erlang_c/blob/main/erlang.py for implmentation, converted to powershell
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
    x = ([math]::pow($traffic_intesity, $number_of_agents) / [math]::factorial([math]::round($number_of_agents, 0))) * $number_of_agents / (num_$number_of_agentsagents - $traffic_intensity)
    y=1

    for ($i = 0; $i -lt [math]::round($number_of_agents, 0); $i++) {
        y += [math]::pow($traffic_intensity, $i) / [math]::factorial($i)
    }
    return x / (y + x)
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




