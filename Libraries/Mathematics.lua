--[[
    This file is part of AlbatrozFEM.

    AlbatrozFEM is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    AlbatrozFEM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

    Copyright (C) 2020 Guilherme Jarentchuk
--]]


--Math library

--Point
point = {}
point.__index = point
point.__eq = function( self, v2 ) return point.eq( self, v2 ) end

function point.new( coord )
    self = {}
    setmetatable(self, Point)
    local i
    for i = 1, 3 do
        self[ i ] = coord[ i ]
    end
    return self
end

function point:eq( v2 )
    return self[1] == v2[1] and self[2] == v2[2] and self[3] == v2[3]
end

--Vector
vector = {}
vector.__index = vector
vector.__eq = function( self, v2 ) return vector.eq( self, v2 ) end
vector.__mul = function( s, v ) return vector.new( { 0,0,0 }, { s*v[1], s*v[2], s*v[3] } ) end
vector.__add = function( v1, v2 ) return vector.new( { 0,0,0 }, { v1[1]+v2[1], v1[2]+v2[2], v1[3]+v2[3] } ) end

function vector:eq( v2 )
    return self[1] == v2[1] and self[2] == v2[2] and self[3] == v2[3]
end

function vector:cross( other_vector )
    local result = {}
    --i(y1z2 - y2z1)
    result[1] = ((self[2]*other_vector[3]) - (other_vector[2]*self[3]))
    --j(z1x2 - z2x1)
    result[2] = ((self[3]*other_vector[1]) - (other_vector[3]*self[1]))
    --k(x1y2 - x2y1)
    result[3] = ((self[1]*other_vector[2]) - (other_vector[1]*self[2]))
    return result
end

function vector:dot( other_vector )
    local result = 0, i
    for i = 1, 3 do
        result = result + self[ i ]*other_vector[ i ]
    end
    return result
end

function vector:proj_to( other_vector )
    other_vector:normalize()
    local unit = vector:new( nil, nil, other_vector.unit )
    local s = self:dot( unit )
    return s*unit
end

function vector:print()
    return tostring( self[1].." "..self[2].." "..self[3] )
end

function vector:scan( text ) --Reads a vector in "x y z" format
    local i = 1
    local buf = ""
    for number in string.gmatch( text, "[-%d+.%d+%s]" ) do --Find number.number and space
        if( number == " " ) then
            self[i] = tonumber( buf )
            i = i + 1
            buf = ""
        else
            --print( buf )
            buf = buf..number
        end
    end
    self[3] = buf
    --print( self[1], self[2], self[3] )
    return self
end

function vector:normalize()
    self.abs = ( ( self[ 1 ]^2 ) + ( self[ 2 ]^2 ) + ( self[ 3 ]^2 ) )^0.5
    self.unit = {}
    for i = 1, 3 do
        self.unit[ i ] = self[ i ]/self.abs
    end
end

function vector.new( pnt1, pnt2, explicit )
    self = {}
    setmetatable(self, vector)
    local i
    --The vector itself
    if( explicit ~= nil ) and ( #explicit == 3 ) then
        for i = 1, 3 do
        self[ i ] = tonumber( explicit[ i ] )
        end
    else
        for i = 1, 3 do
            self[ i ] = tonumber( pnt2[ i ] ) - tonumber( pnt1[ i ] )
        end
    end
    --Its module
    self.abs = ( ( self[ 1 ]^2 ) + ( self[ 2 ]^2 ) + ( self[ 3 ]^2 ) )^0.5
    --Its normalization
    self.unit = {}
    for i = 1, 3 do
        self.unit[ i ] = self[ i ]/self.abs
    end
    --Equality operator

    return self
end

--Matrix
Matrix = {}
Matrix.__mul = function( M, N ) --[M]*[N] = [O]
                --Checks if matrices multiplication is applied
                local O
                if( M.columns == N.rows ) then
                    O = Matrix:new( { rows = M.rows, columns = N.columns } )
                    for i = 1, O.rows do
                        O[i] = {}
                        for j = 1, O.columns do
                            O[i][j] = 0
                            for a = 1, M.columns do
                                O[i][j] = O[i][j] + ( M[ i ][ a ]*N[ a ][ j ] )
                            end
                        end
                    end
                end
                return O
               end
    --return Matrix.new( { 0,0,0 }, { s*v[1], s*v[2], s*v[3] } ) end

function Matrix:clone( scalar_factor )
    local cln = Matrix:new( { rows = self.rows, columns = self.columns } )
    for i = 1, self.rows do
        for j = 1, self.columns do
            cln[i][j] = self[i][j]*scalar_factor
        end
    end
    return cln
end

function Matrix:export_to_Excel( file_name ) --WARNING!!!! FOR WINDOWS OS ONLY
    local file = io.open( config.working_directory.."\\Matrix_print.txt", "w" )
    if( file_name ~= nil ) then
        file:close()
        file = io.open( config.working_directory.."\\"..file_name..".txt", "w" )
        file_name = file_name..".txt"
    else
        file_name = "Matrix_print.txt"
    end
    for i = 1, self.rows do
        for j = 1, self.columns do
            if( j == self.columns ) then
                file:write( self[i][j].."\n" )
            else
                file:write( self[i][j].."\t" )
            end
        end
    end
    file:close()
    os.execute("start excel.exe /r \""..config.working_directory.."\\"..file_name.."\"")
end

function Matrix:print()
    for i = 1, #self do
        local row = ""
        for j = 1, #self[i] do
            if( self[i][j] ~= nil ) then
                if( tonumber( self[i][j] ) == nil ) then
                    row = row.."   "..self[i][j]
                else
                    --row = row..string.format( "   %.3f", self[i][j] )
                    row = row..self[i][j]
                end
            end
        end
        print( row )
    end
    print( "" )
end

function Matrix:print_to_file( file, opt1, opt2 )
    if( opt1 == "readable" ) then
        if( opt2 == "all" ) then
            file:write( "{\n" )
            for i, v1 in ipairs( self ) do
                file:write( "{ " )
                for j, v2 in ipairs( self[ i ] ) do
                    file:write( v2 )
                    if( j == self.columns ) then
                        file:write( " },\n" )
                    else
                        file:write( ", " )
                    end
                end
            end
            file:write( "}\n" )
        end
    end
end

function Matrix:transpose()
    local T = Matrix:new( { rows = self.columns, columns = self.rows } )
    for i = 1, T.rows do
        for j = 1, T.columns do
            T[i][j] = self[j][i]
        end
    end
    return T
end

function Matrix:Cholesky_decompostion()
    --This function uses Cholesky–Banachiewicz algortihm
    local L = Matrix:new( { rows = self.rows, columns = self.columns } )
    for i = 1, self.rows do
        for j = 1, self.columns do
            if( i == j ) then
                for k = 1, j - 1 do
                    L[i][i] = L[i][i] + (L[j][k]^2)
                end
                print( self[26][26], L[26][26] )
                L[i][i] = ( self[i][i] - L[i][j] )^0.5
                break
            else
                for k = 1, j - 1 do
                    L[i][j] = L[i][j] + ( L[i][k]*L[j][k] )
                end
                L[i][j] = self[i][j] - L[i][j]
                L[i][j] = L[i][j]/L[j][j]
            end
        end
    end
    local Lt = L:transpose() --
    return L, Lt
end

function Matrix:Solve_linsys_with_Cholesky( B ) --B is the constant vector
    if( B.columns ~= 1 ) or ( B.rows ~= self.rows ) then
        return nil
    end
    local y = Matrix:new( { rows = self.rows, columns = 1 } )
    local x = Matrix:new( { rows = self.rows, columns = 1 } )
    local L, Lt = self:Cholesky_decompostion()
    L:export_to_Excel()
    --L*y = b
    for i = 1, L.rows do
        for j = 1, i - 1 do
            y[i][1] = y[i][1] + L[i][j]*y[j][1]
        end
        y[i][1] = B[i][1] - y[i][1]
        y[i][1] = (y[i][1]/L[i][i])
    end
    y:print()
    --Lt*x = y
    for i = L.rows, 1, -1 do
        if( i < L.rows ) then
            for j = L.rows, i + 1, -1 do
                x[i][1] = x[i][1] + Lt[i][j]*x[j][1]
            end
        end
        x[i][1] = y[i][1] - x[i][1]
        x[i][1] = (x[i][1]/Lt[i][i])
    end
    x:print()
    return x
end

function Matrix:Reduce_to_nonsparse_table()
    local nsparse = {}
    for i = 1, self.rows do
        nsparse[ i ] = {}
        local j = 1
        for k, v in ipairs( self[ i ] ) do
            if( v ~= 0 ) then
                nsparse[i][j]    = {}
                nsparse[i][j][1] = v
                nsparse[i][j][2] = k
                j = j + 1
            end
        end
    end
    self.nsparse = nsparse
end

function Matrix:Solve_linsys_with_gauss_reduction( B )
    local mat = {}
    for i = 1, self.rows do
        mat[i] = {}
        for j = 1, (self.columns + 1) do
            if( j == self.columns + 1 ) then
                mat[i][j] = B[i][1]
            else
                mat[i][j] = self[i][j]
            end
        end
    end
    mat = Matrix:new( mat )
    local x = Matrix:new( { rows = mat.rows, columns = 1 } )
    local eps = 1.0e-15
    local last_line = (mat.rows - 1)
    local big, term, line
    for i = 1, last_line do
        big = 0
        for k = 1, mat.rows do
            term = math.abs( self[k][i] )
            if( ( term - big ) > 0 ) then
                big = term
                line = k
            end
        end
        if( math.abs( big ) <= eps ) then
            print( "Singular matrix. System has no unique solution!!!" )
            return nil
        end
        if( i ~= line ) then
            for j = 1, mat.columns do
                local temp   = self[i][j]
                mat[i][j]    = mat[line][j]
                mat[line][j] = temp
            end
        end
        local pivot     = mat[i][i]
        local next_line = i + 1
        local cnt
        for j = next_line, mat.rows do
            cnt = (mat[j][i]/pivot)
            for k = i, mat.columns do
                --print( mat[j][k], mat[i][k], i, j, k, cnt, pivot )
                mat[j][k] = mat[j][k] - cnt*mat[i][k]
            end
        end
    end
    --Seek for "zero" values in main diagonal
    for i = 1, mat.rows do
        if( math.abs( mat[i][i] ) <= eps ) then
            print( "Singular matrix. System has no unique solution!!!" )
            return nil
        end
    end
	for i = 1, mat.rows do
        local rev = mat.rows - i
        local y = B[rev][1]
        if( rev ~= mat.rows ) then
            for j = 0, i do
                k = mat.rows - j
                y = y - mat[rev][k]*x[k][1]
            end
        end
        x[rev][1] = y / mat[rev][rev]
	end
    return x
end

function Matrix:Solve_linsys_with_iterative_method( x, B, error, use_sparse ) --Based on Gauss-Siedel -> x is the initial value variables (can be nil) and B the constants vector
    local it = 0
    if( x == nil ) then --Builds a initial value vector
        x = Matrix:new( { rows = self.rows, columns = 1 } )
        for i = 1, self.rows do
            x[ i ][1] = 0
        end
    end
    x0 = Matrix:new( { rows = self.rows, columns = 1 } )
    for i = 1, self.rows do
        x0[ i ][1] = x[ i ][1]
    end
    if( use_sparse == "yes" ) then
        self:Reduce_to_nonsparse_table()
        if( x.rows == self.rows ) and ( x.rows == B.rows ) then
            local run = 1
            while( run == 1 ) do
                it = it + 1 --Iteration number
                for i = 1, self.rows do
                    local exp = B[i][1]
                    if( #self.nsparse[i] == 0 ) then
                        x[i][1] = 0
                        x0[i][1] = 0
                    else
                        for j = 1, #self.nsparse[i] do
                            if( self.nsparse[i][j][2] ~= i ) then
                                local row = self.nsparse[i][j][2]
                                --print( "OLA", exp, x0[ row ][1], self.nsparse[i][j][1], exp - x0[ row ][1]*self.nsparse[i][j][1] )
                                exp = exp - x0[ row ][1]*self.nsparse[i][j][1]
                            end
                        end
                        --print( i.."=", ( exp/self[i][i] ) )
                        x[i][1] = ( exp/self[i][i] ) ---( exp/self.nsparse[i][i][1] )
                    end
                end
                x:print()
                --Checks if got there
                run = 0
                for i = 1, self.rows do
                    if( x[i][1] >= x0[i][1] ) then
                        --print( x[i][1], x0[i][1], (x[i][1] - x0[i][1]), error, (x[i][1] - x0[i][1]) < error )
                        if( (x[i][1] - x0[i][1]) > error ) then run = 1 end
                    elseif( x[i][1] < x0[i][1] ) then
                        --print( x[i][1], x0[i][1], (x0[i][1] - x[i][1]), error, (x0[i][1] - x[i][1]) < error )
                        if( (x0[i][1] - x[i][1]) > error ) then run = 1 end
                    end
                    x0[i][1] = x[i][1]
                end
                print( it,"\n" )
                --if( it == 3 ) then run = 0 end
            end
        else
            --Put error message
        end
    else --No sparse matrix
        if( x.rows == self.rows ) and ( x.rows == B.rows ) then
            local it = 0
            local run = 1
            while( run == 1 ) do
                it = it + 1 --Iteration number
                for i = 1, self.rows do
                local exp = B[i][1]
                    for j = 1, self.columns do
                        if( i ~= j ) then
                            exp = exp - x[ j ][1]*self[i][j]
                        end
                    end
                    --print( i.."=", ( exp/self[i][i] ) )
                    x[i][1] = ( exp/self[i][i] ) ---( exp/self.nsparse[i][i][1] )
                end
                --x:print()
                run = 0
                for i = 1, self.rows do
                    if( x[i][1] >= x0[i][1] ) then
--                        print( x[i][1], x0[i][1], (x[i][1] - x0[i][1]), error, (x[i][1] - x0[i][1]) < error )
                        if( (x[i][1] - x0[i][1]) > error ) then
                            run = 1
                        end
                    elseif( x[i][1] < x0[i][1] ) then
--                        print( x[i][1], x0[i][1], (x0[i][1] - x[i][1]), error, (x0[i][1] - x[i][1]) < error )
                        if( (x0[i][1] - x[i][1]) > error ) then
                            run = 1
                        end
                    end
                    x0[i][1] = x[i][1]
                end
                --print( it,"\n" )
                --if it == 10 then run = 0 end
            end
        end
    end
    return x
end

function Matrix:Solve_linsys_with_Espindola_solver( B )
    local file = io.open( "in", "w" )
    file:write( self.rows.."\n" ) --Number of rows ("neq")
    for i = 1, self.rows do
        for j = 1, (self.rows + 1) do
            if( j == (self.rows + 1)) then
                file:write( B[i][1].."\n" )
            else
                file:write( self[i][j].." " )
            end
        end
    end
    file:close()

    local p = assert( io.popen( "Solver\\solver_espindola.exe < in", 'r' ), "error" )
    print( "Calculation complete" )
    local mat = {}
    local i = 0
    for line in p:lines() do
        i = i + 1
        mat[ i ] = {}
        mat[ i ][ 1 ] = tonumber( line )
        --print( line )
    end
    p:close()
    return Matrix:new( mat )
end

function Matrix:new( new_attributes )
    local SELF = new_attributes or {}
    setmetatable( SELF, self )
    self.__index = self
    if( #SELF == 0 ) and ( SELF.rows ~= nil ) and ( SELF.columns ~= nil ) then
        for i = 1, SELF.rows do
            SELF[ i ] = {}
            for j = 1, SELF.columns do
                SELF[ i ][ j ] = 0
            end
        end
    end
    SELF.rows = #SELF
    if( SELF.rows > 0 ) then SELF.columns = #SELF[1] end
    return SELF
end
