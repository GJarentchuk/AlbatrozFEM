--[[
    This file is part of letk.

    letk is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    letk is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with nadzoru.  If not, see <http://www.gnu.org/licenses/>.

    Copyright (C) 2011 Yuri Kaszubowski Lopes
--]]

--[[
[a,b,c] -4:[1,1] -3:[1,1], -2:[2,2], -1:[3,3], 0:[3,4], 1:[1,1], 2:[2,2], 3:[3,3], 4:[3,4]
--]]

local List    = letk.Class( function( self )
    self.root  = nil
    self.tail  = nil
    self.itens = 0
end )

function List.new_from_table( tbl )
    local self = List.new()
    for k,v in ipairs( tbl ) do
        self:append( v )
    end

    return self
end

function List:normalize_position( pos )
    --return GET, INSERT
    if self.itens == 0 then
        return false, 1
    end
    if pos == 0 or pos > self.itens then
        return self.itens, self.itens + 1
    end
    if pos < 0 then
        local aux = self.itens + pos +1
        if aux <= 0 then
            return 1, 1
        else
            return aux, aux
        end
    end
    return pos, pos
end

function List:add( data, pos )
    local gpos, ipos = self:normalize_position( pos )

    local node = {
        data = data,
    }

    if ipos > self.itens then
        if self.tail then
            node.prev      = self.tail
            self.tail.next = node
        end
        if not self.root then
            self.root = node
        end
        self.tail      = node
    else
        local p_prev  = nil
        local p_atual = self.root

        while ipos > 1 and p_atual do
            ipos = ipos - 1
            p_prev   = p_atual
            p_atual  = p_atual.next
        end

        if p_atual and p_prev then
            node.next    = p_atual
            node.prev    = p_prev
            p_prev.next  = node
        elseif p_atual then
            node.next    = p_atual
            self.root    = node
        elseif p_prev then
            p_prev.next = node
            node.prev   = p_prev
        else
            self.root = node
        end
    end

    self.itens = self.itens + 1
end

function List:get( pos )
    local gpos, ipos = self:normalize_position( pos )

    if not gpos then
        return
    end

    if gpos == self.itens then
        return self.tail.data
    end

    local p_atual = self.root

    while gpos > 1 and p_atual do
        gpos = gpos - 1
        p_atual = p_atual.next
    end

    if p_atual then
        return p_atual.data
    end

end

function List:remove( pos )
    local gpos, ipos
    local type_pos = type( pos )

    local p_prev  = nil
    local p_atual = nil
    local p_next  = self.root

    if type_pos == 'number' then
        gpos, ipos = self:normalize_position( pos )
        if not gpos then
            return
        end

        if gpos == self.itens then
            local node = self.tail
            self.tail  = node.prev
            if self.tail then
                self.tail.next = nil
            else
                self.root = nil
            end
            self.itens = self.itens - 1
            return node.data
        end
    elseif type_pos == 'table' then
        p_atual = pos
        p_prev  = pos.prev
        p_next  = pos.next
        gpos    = 0
    else
        return
    end

    while gpos > 0 and p_next do
        gpos    = gpos - 1
        p_prev  = p_atual
        p_atual = p_next
        p_next  = p_next.next
    end

    if p_atual then
        if p_prev then
            p_prev.next = p_next
        else
            self.root   = p_next
        end

        if p_next then
            p_next.prev = p_prev
        else --yeah, it will never happen
            self.tail   = p_prev
        end

        self.itens = self.itens - 1
        return p_atual.data
    end
end

function List:iremove( fn )
    local node      = self.root
    local result, i = {}, 1
    while node do
        if fn( node.data ) then
            self:remove( node )
            result[ i ] = node.data
            i           = i + 1
        end
        node = node.next
    end

    return result
end

function List:append( data )
    self:add( data, 0) --last position
    return self.itens
end

function List:prepend( data )
    self:add( data, 1) --first position
    return 1
end

function List:ipairs()
    local node
    local iter = function( list, last_pos )
        local pos  = last_pos + 1
        if pos == 1 then
            node = self.root
        else
            node = node.next
        end
        if not node then return end
        return  pos, node.data
    end
    return iter, self, 0
end

function List:find( arg, force_data )
    force_data = force_data or false
    local t = type( arg )
    if t == 'number' and not force_data then
        return self:get( arg ), arg
    end

    for pos, data in self:ipairs() do
        if t == 'function' then
            if arg( data ) then
                return data, pos
            end
        else
            if data == arg then
                return data, pos
            end
        end
    end
end

function List:find_remove( arg, force_data )
     while true do
        local _, pos = self:find( arg, force_data )
        if not pos then return end

        self:remove( pos )
    end
end

function List:len()
    return self.itens
end

function List:clear()
    self.itens = 0
    self.root  = nil
    self.tail  = nil
end

return List
