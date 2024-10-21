ardour {
	["type"]    = "dsp",
	name        = "MIDI CC Generator",
	category    = "Utility",
	license     = "GNU/GPL v3",
	author      = "Jean-Emmanuel Doucet",
	description = [[MIDI CC Generator - Exposes all CC as faders and inline controls]]
}

local state = {}
local params = {}


-- expose all 128 CCs
for i = 1, 128 do
	params[i] = { ["type"] = "input", cc = i - 1, name = "CC" .. (i - 1), doc="Set to -1 to bypass", min = -1, max = 127,  default = -1, integer = true }
end

-- or comment above loop and manually define which CCs should be exposed:
-- params[1] = { ["type"] = "input", cc = 0, name = "CC 0", doc="Set to -1 to bypass", min = -1, max = 127,  default = -1, integer = true }
-- params[2] = { ["type"] = "input", cc = 10, name = "CC 10 (something)", doc="Set to -1 to bypass", min = -1, max = 127,  default = -1, integer = true }
-- params[3] = { ["type"] = "input", cc = 20, name = "CC 20 (etc)", doc="Set to -1 to bypass", min = -1, max = 127,  default = -1, integer = true }


for i = 1, #params do
	state[i] = -1
end

function dsp_ioconfig ()
	return { { midi_in = 1, midi_out = 1, audio_in = 0, audio_out = 0}, }
end

function dsp_params ()
	return params
end

function dsp_run (_, _, n_samples)
	assert (type(midiin) == "table")
	assert (type(midiout) == "table")

	local ctrl = CtrlPorts:array ()
	local m = 1

	-- inject midi cc
	for i, param in ipairs(params) do

		-- only send once per cycle if value has changed
		-- could be interpolated, but hey...

		if ctrl[i] == -1 then
			-- reset cc to zero when sliding to -1 quickly
			if state[i] > 0 then
				midiout[m] = {}
				midiout[m]["time"] = 1
				midiout[m]["data"] = { 0xb0, param["cc"], 0 }
				m = m + 1
			end
			state[i] = -1
		else
			-- round cc value in case of automation
			local rctrl = math.floor(ctrl[i] + 0.5)
			if rctrl ~= state[i] then
				midiout[m] = {}
				midiout[m]["time"] = 1
				midiout[m]["data"] = { 0xb0, param["cc"], rctrl }
				m = m + 1
				state[i] = rctrl
			end
		end
	end

	-- forward incoming midi
	-- From MIDI LFO @ Ardour Team
	local i = 1
	for ts = 1, n_samples do
		if i <= #midiin then
			while midiin[i]["time"] == ts do
				midiout[m] = midiin[i]
				i = i + 1
				m = m + 1
				if i > #midiin then break end
			end
		end
	end

end
