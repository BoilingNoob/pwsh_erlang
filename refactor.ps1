
$number_of_calls = 25 #count
$average_Handle_time = 60 #minutes
$target_handle_time = 15
$agents = 10

#$agents = 35 #n

function fac_big() {
    param(
        [double]$my_input = 1
    )
    [double]$n = $my_input -as [int]
    if ($my_input -le 1) {
        return 1
    }
    else {
        $big = [bigint]::new($n)

        while (--$n -ge 1) {
            $big *= $n
        }
        return $big
    }
}
function calc_intensity() {
    param(
        [double]$number_of_calls,
        [double]$average_Handle_time
    )
    [double]$volume = ($number_of_calls * $average_Handle_time) / 60
    return $volume
}
function take_power() {
    param(
        $base,
        $power
    )
    [double]$value = $null
    $value = [math]::pow($base, $power) -as [double]
    return $value
}
function calculate_wait_probability() {
    param(
        $number_of_calls = 25, #count
        $average_Handle_time = 15, #minutes
        $volume = ($number_of_calls * $average_Handle_time) / 60, #erlangs or call hours/hour
        $agents = $volume + 1      
    )
    
    [double]$upper = (([math]::pow($volume, $agents)) / (fac_big -my_input $agents))
    [double]$lower = ($agents / ($agents - $volume))
    [double]$x = ($upper) * ($lower)
    #[double]$x = (([math]::pow($volume, $agents)) / (fac_big -my_input $agents)) * ($agents / ($agents - $volume))

    [double]$y = 0

    for ($i = 0; $i -lt $agents; $i++) {
        [double]$new_y = ([math]::pow($volume, $i)) / (fac_big -my_input $i)
        $y += $new_y
    }

    [double]$pw = $x / ($x + $y)  
    return $pw 
}
function calulate_service_level() {
    param(
        $number_of_calls = 25,
        $average_Handle_time = 15,
        $target_answer_time = 15,
        $agents = 10
    )
    $volume = calc_intensity -number_of_calls $number_of_calls -average_Handle_time $average_Handle_time
    [double]$pw = calculate_wait_probability -number_of_calls $number_of_calls -average_Handle_time $average_Handle_time -agents $agents -volume $volume
    [double]$service_level = 1 - ($pw * ([math]::Pow([math]::E, (-1 * (($agents - $volume) * ($target_answer_time / $average_Handle_time))))))

    $temp = [pscustomobject]@{
        agents        = $agents
        volume        = $volume
        pw            = $pw
        service_level = $service_level
    }
    return $temp
}

function walk_to_min_agents_for_sla() {
    param(
        $number_of_calls = 25,
        $average_Handle_time = 15,
        $target_answer_time = 15,
        $min_service_level = 0.9,
        $agent_starting_point = 1
    )
    $agent_count = $agent_starting_point - 1
    $calc_service_level = 0
    while ($calc_service_level -lt $min_service_level -or $calc_service_level -eq "NaN") {
        $agent_count++
        write-host "agents: $agent_count"
        $temp = calulate_service_level -number_of_calls $number_of_calls -average_Handle_time $average_Handle_time -target_answer_time $target_answer_time -agents $agent_count
        write-host "temp: $temp"
        $calc_service_level = $temp.service_level
        write-host "agents: $agent_count, service level: $calc_service_level"
    }

    return $agent_count
}

function test_gambit_of_agents() {
    param(
        $min_agents = 10,
        $max_agents = 100,
        $number_of_calls = 25,
        $average_Handle_time = 15,
        $target_handle_time = 15
    )
    $results = New-Object System.Collections.ArrayList

    for ($i = $min_agents; $i -le $max_agents; $i++) {
        $agents = $i
        $volume = calc_intensity -number_of_calls $number_of_calls -average_Handle_time $average_Handle_time

        [double]$pw = calculate_wait_probability -number_of_calls $number_of_calls -average_Handle_time $average_Handle_time -agents $agents -volume $volume

        [double]$service_level = 1 - ($pw * ([math]::Pow([math]::E, (-1 * (($agents - $volume) * ($target_handle_time / $average_Handle_time))))))

        $temp = [pscustomobject]@{
            agents        = $agents
            volume        = $volume
            pw            = $pw
            service_level = $service_level
        }
        $null = $results.add($temp)
    }
    return $results  
}


#test_gambit_of_agents -min_agents 10 -max_agents 60 -number_of_calls 100 -average_Handle_time 15 -target_handle_time 15

walk_to_min_agents_for_sla -number_of_calls 45 -average_Handle_time 15 -target_answer_time 0.3 -min_service_level 0.90 -agent_starting_point 1