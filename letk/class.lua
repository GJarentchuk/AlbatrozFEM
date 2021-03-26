local Class = function( init, ... )
    local parents = type( init ) == 'function' and { ... } or { init, ... }
    local c = {}
    c.__index = function( t, k )
        if rawget( c, k ) then return rawget( c, k ) end
        for pk, p in ipairs( parents ) do
            if p[k] then return p[k] end
        end
        return nil
    end
    setmetatable(c, c)

    if type( init ) == 'function' then
        c.__super = init
    end

    function c.new( ... )
        local self = {}
        setmetatable( self, c )
        if type( init ) == 'function' then
            local results = { init( self, ... ) }
            results[ 1 ] = results[ 1 ] or self
            return unpack( results )
        end
        return self
    end

    return c
end

return Class
