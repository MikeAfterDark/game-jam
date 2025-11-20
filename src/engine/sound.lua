-- TODO: actually implement this later, for now ripple works fine with just name swaps on top of it for naming consistency.

-- Sound Options:
-- sound:play({
--   volume = 0.8,
--   pitch = 1.2, -- pitch changes via speed playback, so this increases the playback speed
--   loop = true,
--   seek = 15.0, -- where it starts
--   fadeDuration = 0.5, -- fade-in, requires sound:update(dt)
--   tags = { your_tag },
--   effects = {
--     reverb = true
--   }
-- })

Sound = function(asset_name, options, info)
	local sound = ripple.newSound(love.audio.newSource("assets/sounds/" .. asset_name, "static"), options)
	sound.data = info
	return sound
end
SoundTag = ripple.newTag
Effect = love.audio.setEffect

Map_Song = function(folder_name, options)
	local path = "maps/" .. folder_name
	local files = love.filesystem.getDirectoryItems(path)

	local found_audio_file = nil
	for _, file in ipairs(files) do
		if file:match("%.ogg$") then
			found_audio_file = file
			break
		end
	end

	if not found_audio_file then
		error("No .ogg file found in folder: " .. path)
	end

	return ripple.newSound(love.audio.newSource(path .. "/" .. found_audio_file, "static"), options)
end
