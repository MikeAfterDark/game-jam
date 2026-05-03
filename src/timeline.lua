Timeline = Object:extend()
Timeline:implement(GameObject)
function Timeline:init(args)
    self:init_game_object(args)

    self.crotchet = 60 / self.bpm
    self.eighth = self.crotchet / 2
    self.sixteenth = self.eighth / 2

    self.new_beat_resolution = self.crotchet -- for notifying player
    self.beat_resolution = self.eighth    -- for internal logic

    self.beat_number = 0                  -- for tracking is_new_beat
    self.beats = {}
    self.beats_per_turn = {}
end

function Timeline:update(dt)
    self:update_game_object(dt)
end

function Timeline:add(unit, current_time)
    self.beats[unit.id] = self.beats[unit.id] or {}
    self.beats_per_turn[unit.id] = self.beats_per_turn[unit.id] or {}

    local dummy_time = 0
    if #self.beats[unit.id] == 0 and unit.is_player then
        -- insert # QoL dummy beats
        local num_dummy_beats = 4

        for i = 1, num_dummy_beats do
            local time = i * self.beat_resolution
            dummy_time = dummy_time + self.beat_resolution

            table.insert(self.beats[unit.id], { id = random:uid(), action = Timings.Empty, time = time })
        end
    end

    local earliest_valid_time = dummy_time +
    (self.beats_per_turn[unit.id][#self.beats_per_turn[unit.id]] or current_time)
    -- self.beats[unit.id][#self.beats[unit.id]].time + self.beat_resolution
    local valid_current_time = (current_time > earliest_valid_time - 0.001) and current_time or earliest_valid_time
    local insert_time = self:beat_aligned_time(math.max(valid_current_time, earliest_valid_time))

    -- NOTE:
    -- beat.is_hold: bool, absence implies 'is_tap'
    -- beat.duration: int, no safety checks, make sure its within the timeline
    local last_time = 0 -- for tracking turns
    for i, beat_list in ipairs(unit.timeline) do
        local time = insert_time + (i - 1) * self.beat_resolution
        for j, beat in ipairs(beat_list) do
            local end_time = beat.duration and time + beat.duration * self.beat_resolution or nil -- for held beats
            last_time = math.max(last_time, end_time or time)
            table.insert(self.beats[unit.id], { id = random:uid(), action = beat, time = time, end_time = end_time })
        end
    end

    last_time = last_time + self.beat_resolution
    table.insert(self.beats_per_turn[unit.id], last_time)
    -- print("last time for", unit.type.name, last_time)
    -- print("Inserted", last_beat_time, valid_current_time, insert_time)
    -- for i, beat in ipairs(self.beats[unit.id]) do
    --     print(beat.action.name, beat.time, beat.end_time)
    -- end
end

function Timeline:press(unit, current_time, input_type)
    if #self.beats[unit.id] == 0 then
        return {}
    end

    -- overlaps can happen if:
    -- > hit_window is big enough [fix: make sure hit_window < self.beat_resolution/2,
    --                              or beats dont happen that frequently in timeline setup]
    -- > held beats overlap [fix: be careful in timeline setup]
    -- If this is an issue, setup 'input_types' for each beat and filter by whichever is
    -- closer to being perfectly on beat

    local hits = table.foreachmap(self.beats[unit.id], function(v)
        local modified = false
        if
            not v.pressed --
            and v.action.input_type == input_type
            and (
                v.end_time and (v.time - unit.hit_window < current_time and v.end_time + unit.hit_window > current_time)
                or math.abs(v.time - current_time) < unit.hit_window
            )
        then
            v.pressed = current_time
            modified = true
        end
        return v, modified
    end)

    return hits
end

function Timeline:release(unit, current_time, input_type, min_percent)
    local releases
    releases, self.beats[unit.id] = table.reject(self.beats[unit.id], function(v)
        local is_valid = v.pressed and v.end_time and v.action.input_type == input_type
        if not is_valid then
            return false
        end

        local percent = (current_time - v.pressed) / (v.end_time - v.time)

        if not min_percent or percent > min_percent then
            v.released = current_time
            v.percent_complete = percent
        end

        return true
    end)
    return releases
end

-- for enemy AI to hit the beats
function Timeline:try_hit_or_release(unit, current_time)
    local beats = {}
    for key, type in pairs(Input_Type) do
        local hits = self:press(unit, current_time, type)
        _, hits = table.reject(hits, function(v)
            return v.end_time
        end)
        local releases = self:release(unit, current_time, type, unit.accuracy)
        table.append(beats, hits)
        table.append(beats, releases)
    end

    return beats
end

-- returns the closest time aligned to the beat closest to 'time'
function Timeline:beat_aligned_time(current_time)
    local prev_beat = math.floor(current_time / self.beat_resolution)
    local next_beat = math.ceil(current_time / self.beat_resolution)

    local prev_time = prev_beat * self.beat_resolution
    local next_time = next_beat * self.beat_resolution

    local prev_diff = math.abs(current_time - prev_time)
    local next_diff = math.abs(current_time - next_time)

    -- print("Nearest: ", prev_time, time, next_time)
    return prev_diff < next_diff and prev_time or next_time
end

function Timeline:beat_tracker(units, current_time)
    -- tracker(current_time, units)
    -- > get all non-pressed tap beats and pop any that are past their time
    -- > get all held beats and pop any with end_time too late for each unit's hit_window

    for i, unit in ipairs(units) do
        self.beats[unit.id] = self.beats[unit.id] or {}

        local hit_window = unit.hit_window
        local misses
        misses, self.beats[unit.id] = table.reject(self.beats[unit.id], function(v)
            local missed_hold = v.end_time and current_time > v.end_time + hit_window
            local missed_tap = not v.end_time and not v.pressed and current_time > v.time + hit_window

            return missed_hold or missed_tap
        end)

        if #misses > 0 then
            -- TODO: miss notification
            -- maybe unit:miss()?

            -- print("unit: ", unit.type.name, "missed beat at", time, "beat", misses[1].id)
        end

        -- TODO: cleanup completed pressed beats (future: add to stats)
        _, self.beats[unit.id] = table.reject(self.beats[unit.id], function(v)
            local is_tap = not v.end_time
            local is_pressed = v.pressed ~= nil

            local is_hold = v.end_time ~= nil
            local is_past_its_time = v.end_time and v.end_time + hit_window < current_time

            return (is_tap and is_pressed) or (is_hold and is_pressed and is_past_its_time)
        end)
    end

    -- WARN: janky hacks for drawing
    self.draw_units = units
    self.time = current_time

    local beat_num = math.floor(current_time / self.new_beat_resolution)
    local is_new_beat = beat_num ~= self.beat_number
    self.beat_number = beat_num

    return is_new_beat
end

function Timeline:is_end_of_turn(unit, current_time)
    local is_end = self.beats_per_turn[unit.id][1] < current_time
    if is_end then
        _, self.beats_per_turn[unit.id] = table.shift(self.beats_per_turn[unit.id])
    end

    return is_end
end

function Timeline:time_left_for(unit, current_time)
    local time_left = self.beats_per_turn[unit.id][#self.beats_per_turn[unit.id]] - current_time
    return time_left
end

function Timeline:draw()
    local units = self.draw_units
    if not units then
        return
    end

    local tau = 2 * math.pi
    local speed = ((state.timeline_speed or 0.3) + 0.1) * 20

    local radius = self.cell_size * 0.9
    local thickness = radius * 0.3
    local radians_per_segment = speed * (tau / self.max_beats)
    local rotation_speed = self.new_beat_resolution * radians_per_segment
    local visible_angle = math.pi * 3 / 2

    for j, unit in ipairs(units) do
        if #self.beats[unit.id] > 0 then
            graphics.push(unit.x, unit.y, self.r, unit.spring.x, unit.spring.y)

            -- TODO: unit.border doesnt work if it goes multiple times in a row
            local opacity = unit == main.current.focused_unit and 1 or 0.4
            graphics.circle(unit.x, unit.y, radius, Color(1, 1, 1, 0.8 * opacity), thickness * 1.2)

            -- 1. draw ticks at the correct angle
            local hit_window_angle = unit.hit_window * rotation_speed
            local border_angle = math.pi * 0.01
            for i, beat in ipairs(self.beats[unit.id]) do
                local angle = (beat.time - self.time) * rotation_speed
                local end_angle = ((beat.end_time or beat.time) - self.time) * rotation_speed

                if
                    beat.action ~= Timings.Empty and angle < visible_angle --[[ and not beat.end_time ]]
                then
                    local tap_can_be_hit = math.abs(beat.time - self.time) < unit.hit_window
                    local can_be_held = beat.end_time and
                    (self.time > beat.time - unit.hit_window and self.time < beat.end_time + unit.hit_window)

                    local border_color = Color(0, 0, 0, opacity)
                    local color = (not state.spacebar_controls or not unit.is_player) and beat.action.color
                        or (
                            (input.spacebar.down and beat.end_time == nil) and Timings.Hold.color
                            or ((input.spacebar.down and beat.end_time == nil) and Timings.Beat.color or beat.action.color)
                        )
                    color = (tap_can_be_hit or can_be_held) and color:clone():lighten(0.4) or color
                    color = (can_be_held and beat.pressed and not beat.released) and color:clone():darken(0.7) or color
                    color = color:clone()
                    color.a = color.a * opacity

                    local line_thickness = thickness
                    angle = math.max(0, angle) - math.pi / 2 -- centering it
                    end_angle = math.min(visible_angle - hit_window_angle, end_angle) - math.pi / 2

                    local start_angle = angle - hit_window_angle
                    end_angle = end_angle + hit_window_angle
                    local radius_shift = beat.action.input_type == Input_Type.Myon and thickness
                        or beat.action.input_type == Input_Type.Arix and thickness * 2
                        or 0
                    local draw_radius = radius + radius_shift

                    -- background/border
                    graphics.arc( --
                        "open",
                        unit.x,
                        unit.y,
                        draw_radius,
                        start_angle - border_angle,
                        end_angle + border_angle,
                        border_color,
                        line_thickness
                    )

                    graphics.arc( -- the hit_window of the tap beat
                        "open",
                        unit.x,
                        unit.y,
                        draw_radius,
                        start_angle,
                        end_angle,
                        color,
                        line_thickness
                    )

                    local half_thickness = thickness / 2

                    local ix = unit.x + math.cos(angle) * (draw_radius - half_thickness)
                    local iy = unit.y + math.sin(angle) * (draw_radius - half_thickness)
                    local ox = unit.x + math.cos(angle) * (draw_radius + half_thickness)
                    local oy = unit.y + math.sin(angle) * (draw_radius + half_thickness)

                    graphics.line(ix, iy, ox, oy, Color(0, 0, 0, 1), 2)
                end
            end

            local indicator_angle = -math.pi / 2
            local line_length = radius + 20
            local ix = unit.x + math.cos(indicator_angle) * radius
            local iy = unit.y + math.sin(indicator_angle) * radius
            local ox = unit.x + math.cos(indicator_angle) * line_length
            local oy = unit.y + math.sin(indicator_angle) * line_length

            graphics.line(ix, iy, ox, oy, Color(0, 0, 0, 1 * opacity), 2)

            graphics.pop()
        end
    end
end
