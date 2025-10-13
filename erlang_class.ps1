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

    [bigint]fac_big([int]$my_input = 1) {
        [int]$n = $my_input -as [int]
        if ($my_input -le 1) {
            #return 1 -as [bigint]
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
        [double]$x = ($this.take_power($this.calc_intensity(), $agents) / $this.fac_big($agents)) * ($agents / ($agents - $this.calc_intensity()))
        [double]$y = 0

        for ($i = 0; $i -lt $agents; $i++) {
            [double]$new_y = ($this.take_power($intensity, $i) / ($this.fac_big($i))) -as [double]
            $y += $new_y
        }

        [double]$pw = $x / ($x + $y)  
        #Write-Host "pw: $pw x: $x , y: $y, agents: $agents"
        return $pw
    }
    [double]calculate_wait_probability() {
        return $this.calculate_wait_probability($this.minimum_agents())
    }
    [double]calulate_service_level($agents) {
        [double]$pw = $this.calculate_wait_probability($agents)
        [double]$time_metric = (($this.target_answer_time) / $this.average_Handle_time)
        [double]$per_agent = ($agents - $this.calc_intensity())

        [double]$answer = 1 - ($pw * ($this.take_power([math]::E, (-1 * ($per_agent * $time_metric)))))

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
    [pscustomobject]basic_export([float]$agents, [float]$shrinkage) {
        $export = $this
        $export | Add-Member -MemberType NoteProperty -Name "starting_agents" -Value ($this.minimum_agents()) -Force
        $export | Add-Member -MemberType NoteProperty -Name "intensity" -Value ($this.calc_intensity()) -Force
        $export | Add-Member -MemberType NoteProperty -Name "agents_real" -Value ($agents) -Force
        $export | Add-Member -MemberType NoteProperty -Name "agents_scheduled" -Value ($this.calc_shrinkage($agents, $shrinkage)) -Force
        $export | Add-Member -MemberType NoteProperty -Name "pw" -Value ($this.calculate_wait_probability($agents)) -Force
        $export | Add-Member -MemberType NoteProperty -Name "service_level" -Value ($this.calulate_service_level($agents)) -Force
        $export | Add-Member -MemberType NoteProperty -Name "occupancy" -Value ($this.occupancy($agents)) -Force
        $export | Add-Member -MemberType NoteProperty -Name "percent_immediately_answered" -Value ($this.calc_immediate_answer($agents)) -Force
        $export | Add-Member -MemberType NoteProperty -Name "average_speed_of_answer" -Value ($this.calc_average_speed_of_answer($agents)) -Force
        
        return $export
    }
    [pscustomobject]basic_export([float]$agents) {
        return $this.basic_export($agents, $this.shrinkage)
    }
    [pscustomobject]basic_export() {
        return $this.basic_export($this.walk_to_min_agents(), $this.shrinkage)
    }
}



#$hold = [ErlangC]::new(8, 30, 15, (180 / 60), 0.9, 0.3)
$hold = [ErlangC]::new(8, 30, 15, (120 / 60), 0.7, 0.3)
#$hold = [ErlangC]::new(100, 30, 3, (20 / 60), 0.8, 0.3)
$hold.basic_export()
#$hold.calculate_wait_probability(6)


#$agents = 11
#($hold.take_power($hold.calc_intensity(), $agents) / $hold.fac_big($agents)) * ($agents / ($agents - $hold.calc_intensity()))

#$hold.calculate_wait_probability($agents)