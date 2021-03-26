-- Taken from: http://lua-users.org/wiki/StringRecipes (Philippe Lhoste, Take Three)
function string.split( str, delim, maxNb )
    if string.find( str, delim ) == nil then
        return { str }
    end

    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end

    local result = { }
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind( str, pat ) do
        nb = nb + 1
        result[ nb ] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[ nb + 1 ] = string.sub( str, lastPos )
    end

    return result
end

function string.trim( s )
    return ( string.gsub( s, '^%s*(.-)%s*$', '%1' ) )
end
