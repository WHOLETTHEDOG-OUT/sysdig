--[[
Copyright (C) 2013-2014 Draios inc.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]]

-- Chisel description
description = "Print the standard error of any process on screen. Combine this script with a filter to limit the output to a specific process or pid. This chisel is compatable with containers using the sysdig -pc or -pcontainer argument, otherwise no container information will be shown. (Blue represents a process running within a container, and Green represents a host process)";
short_description = "Print stderr of processes";
category = "I/O";

-- Chisel argument list
args =
{
	{
		name = "disable_color",
		description = "Set to 'disable_colors' if you want to disable color output",
		argtype = "string",
		optional = true
	},
}

terminal = require "ansiterminal"
terminal.enable_color(true)

-- Argument notification callback
function on_set_arg(name, val)
	if name == "disable_color" and val == "disable_color" then
		terminal.enable_color(false)
		return true
	end

	return false
end

-- Initialization callback
function on_init()
	-- Request the fields that we need
	fbuf = chisel.request_field("evt.rawarg.data")
	fcontainername = chisel.request_field("container.name")
	fcontainerid = chisel.request_field("container.id")

	-- The -pc or -pcontainer options was supplied on the cmd line
	print_container = sysdig.is_print_container_data()

	-- increase the snaplen so we capture more of the conversation
	sysdig.set_snaplen(2000)

	-- set the filter
	chisel.set_filter("fd.num=2 and evt.is_io=true")
	
	return true
end

-- Event parsing callback
function on_event()

	-- Default colot is black
	local color = terminal.black

	-- If -pc or -pcontainer option change default to green
	if  print_container then
		color = terminal.green
	end

	local buf = evt.field(fbuf)
	local containername = evt.field(fcontainername)
	local containerid = evt.field(fcontainerid)
	
	if buf ~= nil then
		-- The -pc or -pcontainer options was supplied on the cmd line
		if  print_container then

			-- Conatiner will print out as blue
			if containername ~= "host" then
				color = terminal.blue
			end

			print(color .. string.format("%-20.20s %-20.20s %s",
										 containerid,
										 containername,
										 buf ))

		else
			print(buf)
		end
	end
	
	return true
end
