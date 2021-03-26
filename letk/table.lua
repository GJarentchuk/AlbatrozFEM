function table.keys( t )
    local r = {}
    local i = 1
    for k in pairs( t ) do
        r[ i ] = k
        i = i + 1
    end
    return r
end

function table.values( t )
    local r = {}
    local i = 1
    for _, v in pairs( t ) do
        r[ i ] = v
        i = i + 1
    end
    return r
end

local function spairs_iter( s, id )
    id = id + 1
    local k = s[ index ]
    return k, s.__src[ k ]
end

function spairs( src )
    local t = table.keys( src )
    table.sort( t )
    t.__src = src
    return spairs_iter, t, 0
end

function table.count( t )
    local i = 0
    for _ in pairs( t ) do
        i = i + 1
    end
    return i
end

function table.complete( dst, src )
    for k, v in pairs( src ) do
        if dst[ k ] == nil then
            dst[ k ] = v
        end
    end
    return dst
end


