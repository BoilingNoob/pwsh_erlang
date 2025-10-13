class ErlangC {
    $call_count
    $segment_duration
    $average_handle_time
    $target_answer_time
    $sla
    $shrinkage

    ErlangC($call_count, $segment_duration, $average_handle_time, $target_answer_time, $sla, $shrinkage) {
        $this.call_count = $call_count
        $this.segment_duration = $segment_duration
        $this.average_handle_time = $average_handle_time
        $this.target_answer_time = $target_answer_time
        $this.sla = $sla
        $this.shrinkage = $shrinkage
    }
    ErlangC([hashtable]$properties) {
        $this.call_count = $properties.call_count
        $this.segment_duration = $properties.segment_duration
        $this.average_handle_time = $properties.average_handle_time
        $this.target_answer_time = $properties.target_answer_time
        $this.sla = $properties.sla
        $this.shrinkage = $properties.shrinkage
    }

    [bigint]fac_big([int]$my_input = 1) {
        [int]$n = $my_input -as [int]
        if ($my_input -le 1) {
            return [bigint]::new(1)
        }
        else {
            $big = [bigint]::new($n)

            while (--$n -ge 1) {
                $big *= $n -as [bigint]
            }
            return $big
        }
    }
    [double]take_power([double]$base, [double]$power) {
        [double]$value = [math]::pow($base, $power) -as [double]
        return $value
    }
    [double]calc_intensity([double]$number_of_calls, [double]$average_Handle_time, $segment_duration) {
        [double]$calls_per_hour = $number_of_calls * (60 / $segment_duration)

        [double]$volume = ($calls_per_hour * $average_Handle_time) / 60
        return $volume
    }
    [double]calc_intensity() {
        return $this.calc_intensity($this.call_count, $this.average_handle_time, $this.segment_duration)
    }
    [double]minimum_agents() {
        return $this.calc_intensity() + 1
    }
    [double]calculate_wait_probability([int]$agents) {

        [double]$intensity = $this.calc_intensity()
        [double]$left = ([math]::pow($intensity, $agents) / $this.fac_big($agents)) -as [double]
        [double]$right = ($agents / ($agents - $intensity))
        [double]$x = $left * $right
        [double]$y = 0

        for ($i = 0; $i -lt $agents; $i++) {
            [double]$new_y = (([math]::pow($intensity, $i) -as [double]) / ($this.fac_big($i))) -as [double]
            $y += $new_y
        }

        [double]$pw = $x / ($x + $y)  
        #Write-Host "pw: $pw x: $x , y: $y, agents: $agents, intensity $intensity"
        return $pw
    }
    [double]calculate_wait_probability() {
        return $this.calculate_wait_probability($this.minimum_agents())
    }
    [double]calulate_service_level($agents) {
        [double]$pw = $this.calculate_wait_probability($agents)
        [double]$time_metric = (($this.target_answer_time) / $this.average_Handle_time)
        [double]$per_agent = ($agents - $this.calc_intensity())

        [double]$answer = 1.0 - ($pw * ([math]::pow([math]::E, (-1.0 * ($per_agent * $time_metric)))))

        return $answer
    }
    [double]calulate_service_level() {
        return $this.calulate_service_level($this.minimum_agents())
    }
    [int]walk_to_min_agents($starting_point, $step_size) {
        #write-host "startingPoint agents: $starting_point"
        $agents_req = $starting_point
        while ($this.calulate_service_level($agents_req) -lt $this.sla) {
            #write-host "current agents: $agents_req, sla: $(($this.calulate_service_level($agents_req)))"
            $agents_req += $step_size
        }

        #write-host "final agents: $agents_req, sla: $(($this.calulate_service_level($agents_req)))" -ForegroundColor green
        return [math]::Ceiling($agents_req)
    }
    [int]walk_to_min_agents() {
        return $this.walk_to_min_agents($this.minimum_agents(), 1)
    }
    [double]calc_shrinkage($raw_agents, $shrinkage) {
        return $raw_agents / (1 - $shrinkage)
    }
    [double]calc_shrinkage() {
        return $this.calc_shrinkage($this.walk_to_min_agents(), $this.shrinkage)
    }
    [double]occupancy($agents) {
        return ($this.calc_intensity() / $agents)
    }
    [double]occupancy() {
        return $this.occupancy($this.walk_to_min_agents())
    }
    [double]calc_immediate_answer($agents) {
        return (1 - $this.calculate_wait_probability($agents))
    }
    [double]calc_immediate_answer() {
        return $this.calc_immediate_answer($this.walk_to_min_agents())
    }
    [double]calc_average_speed_of_answer($agents) {
        #write-host "wait prob: $($this.calculate_wait_probability($agents))"
        return (($this.calculate_wait_probability($agents) * $this.average_handle_time * 60) / ($agents - $this.calc_intensity())) / 60
    }
    [double]calc_average_speed_of_answer() {
        return $this.calc_average_speed_of_answer($this.walk_to_min_agents())
    }
    [pscustomobject]basic_export() {
        $min_agents = $this.walk_to_min_agents()
        $export = $this
        $export | Add-Member -MemberType NoteProperty -Name "intensity" -Value ($this.calc_intensity()) -Force
        $export | Add-Member -MemberType NoteProperty -Name "agents_real" -Value ($min_agents) -Force
        $export | Add-Member -MemberType NoteProperty -Name "agents_scheduled" -Value ($this.calc_shrinkage($min_agents, $this.shrinkage)) -Force
        $export | Add-Member -MemberType NoteProperty -Name "pw" -Value ($this.calculate_wait_probability($min_agents)) -Force
        $export | Add-Member -MemberType NoteProperty -Name "service_level" -Value ($this.calulate_service_level($min_agents)) -Force
        $export | Add-Member -MemberType NoteProperty -Name "occupancy" -Value ($this.occupancy($min_agents)) -Force
        $export | Add-Member -MemberType NoteProperty -Name "percent_immediately_answered" -Value ($this.calc_immediate_answer($min_agents)) -Force
        $export | Add-Member -MemberType NoteProperty -Name "average_speed_of_answer" -Value ($this.calc_average_speed_of_answer($min_agents)) -Force
        
        return $export
    }
}

$properties = @{
    call_count          = 100
    segment_duration    = 30
    average_handle_time = 3
    target_answer_time  = 20 / 60
    sla                 = 0.8
    shrinkage           = 0.3 
}


#$hold = [ErlangC]::new(100, 30, 3, (20 / 60), 0.8, 0.3)
$hold = [ErlangC]::new($properties)

$hold.basic_export()