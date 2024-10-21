ardour {
	["type"]    = "dsp",
	name        = "Record Monitor",
	category    = "Utility",
	license     = "GNU/GPL v3",
	author      = "Jean-Emmanuel Doucet",
	description = [[
		When recording and hardware monitoring, one might want to inject sound from a track/bus bus into
		the musicians' monitors. Putting this plugin in the track/bus' chain will mute it automatically
		when not recording so that it doesn't pollute regular playback.
	]]
}

-- Derived from ACE Mute

function dsp_ioconfig ()
	return { { audio_in = -1, audio_out = -1} }
end

local sr = 48000
local cur_gain = 0.0

function dsp_init (rate)
	sr = rate
end

function dsp_configure (ins, outs)
	n_out   = outs
	n_audio = outs:n_audio ()
	n_midi  = outs:n_midi ()
	assert (n_midi == 0)
end

-- the DSP callback function
function dsp_runmap (bufs, in_map, out_map, n_samples, offset)
	local ctrl = CtrlPorts:array() -- get control port array
	local target_gain = Session:record_status() ~= ARDOUR.Session.RecordState.Disabled and 1.0 or 0.0; -- when recording, target_gain = 0.0; otherwise use 1.0
	-- apply I/O map
	ARDOUR.DSP.process_map (bufs, n_out, in_map, out_map, n_samples, offset)

	local g = cur_gain
	for c = 1, n_audio do
		local ob = out_map:get (ARDOUR.DataType ("audio"), c - 1); -- get id of mapped output buffer for given cannel
		if (ob ~= ARDOUR.ChanMapping.Invalid) then
			cur_gain = ARDOUR.Amp.apply_gain (bufs:get_audio(ob), sr, n_samples, g, target_gain, offset)
		end
	end

end
