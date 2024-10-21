ardour {
	["type"]    = "dsp",
	name        = "MIDI CC Generator",
	category    = "Utility",
	license     = "GNU/GPL v3",
	author      = "Jean-Emmanuel Doucet",
	description = [[MIDI CC Generator - Exposes all CC as faders and inline controls]]
}

local state = {}
local ncc = 128

for i = 1, ncc do
	state[i] = -1
end

function dsp_ioconfig ()
	return { { midi_in = 1, midi_out = 1, audio_in = 0, audio_out = 0}, }
end

function dsp_params ()
	local params = {}
	for i = 1, ncc do
		params[i] = { ["type"] = "input", name = "CC" .. (i - 1), doc="Set to -1 to bypass", min = -1, max = 127,  default = -1, integer = true }
	end
	return params
end

function dsp_run (_, _, n_samples)
	assert (type(midiin) == "table")
	assert (type(midiout) == "table")

	local ctrl = CtrlPorts:array ()
	local m = 1

	-- inject midi cc
	for i = 1, ncc do

		-- round cc value in case of automation
		local rctrl = math.floor(ctrl[i] + 0.5)

		-- only send once per cycle if value has changed
		-- could be interpolated, but hey...
		if state[i] ~= rctrl then
			if rctrl >= 0 then
				midiout[m] = {}
				midiout[m]["time"] = 1
				midiout[m]["data"] = { 0xb0, i - 1, rctrl }
				m = m + 1
			end

			-- reset cc to zero when sliding to -1 quickly
			if rctrl < 0 and state[i] ~= 0 then
				midiout[m] = {}
				midiout[m]["time"] = 1
				midiout[m]["data"] = { 0xb0, i - 1, 0 }
				m = m + 1
			end

			-- update last sent value
			state[i] = rctrl
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
