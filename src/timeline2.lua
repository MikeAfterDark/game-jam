Timeline2 = Object:extend()
Timeline2:implement(GameObject)
function Timeline2:init(args)
    self:init_game_object(args)

    self.crotchet = 60 / self.bpm
    self.eighth = self.crotchet / 2
    self.sixteenth = self.eighth / 2

    self.new_beat_resolution = self.crotchet -- for notifying player
    self.beat_resolution = self.eighth    -- for internal logic

    self.beat_number = 0                  -- for tracking is_new_beat
    self.beats = {}
end

function Timeline2:update(dt)
    self:update_game_object(dt)
end

function Timeline2:add(unit, current_time)
    self.beats[unit.id] = self.beats[unit.id] or {}

    if #self.beats[unit.id] == 0 then
        -- insert # QoL dummy beats
        local num_dummy_beats = 4
        for i = 1, num_dummy_beats do
            local time = i * self.beat_resolution
            table.insert(self.beats[unit.id], { action = Timings.Empty, time = time })
        end
    end

    local last_beat_time = self.beats[unit.id][#self.beats[unit.id]].time + self.beat_resolution
    local valid_current_time = (current_time > last_beat_time - 0.001) and current_time or last_beat_time
    local insert_time = self:beat_aligned_time(math.max(valid_current_time, last_beat_time))

    -- NOTE:
    -- beat.is_hold: bool, absence implies 'is_tap'
    -- beat.duration: int, no safety checks, make sure its within the timeline
    for i, beat in ipairs(unit.timeline) do
        local time = insert_time + (i - 1) * self.beat_resolution
        local end_time = beat.duration and time + beat.duration * self.beat_resolution or nil -- for held beats

        table.insert(self.beats[unit.id], { action = beat, time = time, end_time = end_time })
    end

    -- print("Inserted", last_beat_time, valid_current_time, insert_time)
    -- for i, beat in ipairs(self.beats[unit.id]) do
    --     print(beat.action.name, beat.time, beat.end_time)
    -- end
end

function Timeline2:press(unit, current_time, input_type)
    local hit_window = unit.hit_window

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
        if not v.pressed and v.action.input_type == input_type and math.abs(v.time - current_time) < hit_window then
            v.pressed = current_time
            modified = true
        end
        return v, modified
    end)

    return hits
end

function Timeline2:release(unit, current_time, input_type)
    local releases
    releases, self.beats[unit.id] = table.reject(self.beats[unit.id], function(v)
        local valid_release = v.pressed and v.end_time and v.beat.input_type == input_type

        if valid_release then
            v.released = current_time
            v.percent_complete = (v.released - v.pressed) / (v.end_time - v.time)
        end

        return valid_release
    end)

    return releases
end

-- returns the closest time aligned to the beat closest to 'time'
function Timeline2:beat_aligned_time(time)
    local prev_beat = math.floor(time / self.beat_resolution)
    local next_beat = math.ceil(time / self.beat_resolution)

    local prev_time = prev_beat * self.beat_resolution
    local next_time = next_beat * self.beat_resolution

    local prev_diff = math.abs(time - prev_time)
    local next_diff = math.abs(time - next_time)

    -- print("Nearest: ", prev_time, time, next_time)
    return prev_diff < next_diff and prev_time or next_time
end

function Timeline2:beat_tracker(units, time)
    -- tracker(current_time, units)
    -- > get all non-pressed tap beats and pop any that are past their time
    -- > get all held beats and pop any with end_time too late for each unit's hit_window

    for i, unit in ipairs(units) do
        local hit_window = unit.hit_window
        local misses
        misses, self.beats[unit.id] = table.reject(self.beats[unit.id], function(v)
            local missed_hold = v.end_time and time > v.end_time + hit_window
            local missed_tap = not v.end_time and time > v.time + hit_window

            return missed_hold or missed_tap
        end)

        if #misses > 0 then
            -- TODO: miss notification
            -- maybe unit:miss()?

            -- print("unit: ", unit.type.name, "missed beat at", time, "beat", misses[1].action.id)
        end
    end

    local beat_num = time / self.new_beat_resolution
    local is_new_beat = beat_num ~= self.beat_number
    self.beat_number = beat_num

    return is_new_beat
end

function Timeline2:draw() end

--
--
--
--
--
--
--
--
--
--
-- function Timeline2:add(unit, current_song_time)
--     local unit_id = unit.id
--     self.beats[unit_id] = self.beats[unit_id] or {} -- init ifndef
--
--     local insert_dummy_beat = false
--     local last_beat_time = 0
--     if #self.beats[unit_id] > 0 then
--         last_beat_time = self.beats[unit_id][1].time
--     else
--         insert_dummy_beat = true
--     end
--
--     local beat_start, section_start_time = self:beat_nearest_to(math.max(current_song_time, last_beat_time + self.eighth))
--     print("last time: ", last_beat_time, beat_start, section_start_time)
--
--     if insert_dummy_beat then
--         local beat = { action = Timings.Empty, time = section_start_time, beat_num = 1 }
--         table.unshift(self.beats[unit_id], beat)
--
--         beat = { action = Timings.Empty, time = section_start_time + self.eighth, beat_num = 2 }
--         table.unshift(self.beats[unit_id], beat)
--         section_start_time = section_start_time + self.crotchet
--     end
--
--     for i, action in ipairs(unit.timeline) do
--         local beat_time = section_start_time + (i + (insert_dummy_beat and 1 or -1)) * self.eighth
--         local beat_num = self:get_beat_number(beat_time)
--
--         local beat = { action = action, time = beat_time, beat_num = beat_num }
--         table.unshift(self.beats[unit_id], beat)
--     end
--
--     print("Inserted", current_song_time, beat_start, section_start_time)
--     for i, beat in ipairs(self.beats[unit_id]) do
--         print(beat.action.name, beat.beat_num, beat.time)
--     end
-- end
--
-- function Timeline2:beat_nearest_to(time)
--     local prev_beat = math.floor(time / self.crotchet)
--     local next_beat = math.ceil(time / self.crotchet)
--
--     local prev_time = prev_beat * self.crotchet
--     local next_time = next_beat * self.crotchet
--
--     local prev_diff = math.abs(time - prev_time)
--     local next_diff = math.abs(time - next_time)
--
--     -- print("Nearest: ", prev_time, time, next_time)
--     if prev_diff < next_diff then
--         return prev_beat, prev_time
--     else
--         return next_beat, next_time
--     end
-- end
--
-- function Timeline2:get_beat_number(time)
--     return time / self.crotchet
-- end
