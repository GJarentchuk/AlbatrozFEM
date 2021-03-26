--[[
	This file is part of ldbi.

	ldbi is free software: you can redistribute it and/or modify
	it under the terms of the GNU Lesser General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	ldbi is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public License
	along with ldbi.  If not, see <http://www.gnu.org/licenses/>.

	Copyright (C) 2008 Lucas Hermann Negri
--]]

local l = require("ldbi._postgres")

-- Change the connect function to use fixed parameters
local oldconnect = postgres.connect

local function escape(str)
	return str:gsub("\\", "\\\\"):gsub("'", "\\'")
end

function postgres.connect(config)
	local str = {}

	if config["host"] then
		local tmp = string.format("host='%s'", escape(config["host"]))
		table.insert(str, tmp)
	end

	if config["port"] then
		local tmp = string.format("port='%i'", tonumber(config["port"]))
		table.insert(str, tmp)
	end

	if config["dbname"] then
		local tmp = string.format("dbname='%s'", escape(config["dbname"]))
		table.insert(str, tmp)
	end

	if config["user"] then
		local tmp = string.format("user='%s'", escape(config["user"]))
		table.insert(str, tmp)
	end

	if config["password"] then
		local tmp = string.format("password='%s'", escape(config["password"]))
		table.insert(str, tmp)
	end

	if config["timeout"] then
		local tmp = string.format("connect_timeout='%i'", tonumber(config["timeout"]))
		table.insert(str, tmp)
	end

	return oldconnect(table.concat(str))
end

return l
