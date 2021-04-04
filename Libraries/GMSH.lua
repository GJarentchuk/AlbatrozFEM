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

GMSH = {}

function GMSH:new( new_attributes )
    local SELF = new_attributes or {}
    setmetatable( SELF, self )
    self.__index = self
    SELF.node         = {} --Just table
    SELF.node_n_id    = {}
    SELF.node_id_n    = {}
    SELF.element      = {} --Just table
    SELF.element_n_id = {}
    SELF.element_id_n = {}
    SELF.load         = {} --Just table
    return SELF
end

function GMSH:update()
    --For nodes
    for i = 1, self.node_data.itens do
        local row = self.node_data:get( i )
        self.node[ i ]      = { tonumber(row[2]), tonumber(row[3]), tonumber(row[4]) }
        self.node_n_id[ i ] = row[1]
        self.node_id_n[ row[1] ] = i
    end
    --For elements
    for i = 1, self.element_data.itens do
        local row = self.element_data:get( i )
        self.element[ i ]      = { self.node_id_n[ row[2] ], self.node_id_n[ row[3] ] }
        self.element_n_id[ i ] = row[1]
        self.element_id_n[ row[1] ] = i
    end
    --For loads
    for i = 1, self.load_data.itens do
        local row = self.load_data:get( i )
        local n   = self.node[ self.node_id_n[ row[2] ] ]
        self.load[ i ] = { n[1], n[2], n[3], row[3] } --x, y, z, magnitude, direction
        if( row[4] == "x (translation)" ) then self.load[ i ][5] = 1
        elseif( row[4] == "y (translation)" ) then self.load[ i ][5] = 2
        elseif( row[4] == "z (translation)" ) then self.load[ i ][5] = 3
        elseif( row[4] == "x (rotation)" ) then self.load[ i ][5] = 4
        elseif( row[4] == "y (rotation)" ) then self.load[ i ][5] = 5
        elseif( row[4] == "z (rotation)" ) then self.load[ i ][5] = 6
        end
    end
end

function GMSH:export( type, post ) --post = table with post-processing values
    if( type == "geometry" ) then
        print( "Exporting mesh geometry" )
        --self.file_path = "C:\\Users\\Guilherme\\Documents\\Udesc\\Albatroz\\gmsh\\".."\\"..self.name..".geo"
        if not ( io.open( config.gmsh_model_folder.."/"..self.name..".geo", "r" ) ) then
            print(config.gmsh_model_folder)
        end
        self.file_path = config.gmsh_model_folder.."/"..self.name..".geo"
        --Pos file with ids and loads
        local file = io.open( config.gmsh_model_folder.."/"..self.name..".pos", "w" )
        --Options
        file:write( "View.Axes = 1;\n" )
        file:write( "View.PointType = 1;\n" )
        file:write( "View.PointSize = 4;\n" )
        file:write( "View.LineType = 1;\n" )
        file:write( "View.LineWidth = 3;\n" )
        --Nodes ids
        file:write( "View \"Node_ids\" {\n" )
        for k, v in ipairs( self.node ) do
            file:write( "T3("..v[1]..","..v[2]..","..v[3]..",0){\""..self.node_n_id[ k ].."\"};\n" )
        end
        file:write( "};\n" )
        --Element ids
        file:write( "View \"Element_ids\" {\n" )
        for k, v in ipairs( self.element ) do
            local n1 = self.node[ v[1] ]
            local n2 = self.node[ v[2] ]
            local n = { (n1[1]+n2[1])/2, (n1[2]+n2[2])/2, (n1[3]+n2[3])/2 }
            file:write( "T3("..n[1]..","..n[2]..","..n[3]..",0){\""..self.element_n_id[ k ].."\"};\n" )
        end
        file:write( "};\n" )
        file:write( "View[0].Visible = 0;\n" )
        file:write( "View[1].Visible = 0;\n" )
        --Loads
        file:write( "View \"Loads\" {\n" )
        for k, v in ipairs( self.load ) do
            local signal
            if( tonumber(v[4]) >= 0 ) then signal = 1
            else signal = -1
            end
            if( v[5] == 1 ) then
                file:write( "VP("..v[1]..","..v[2]..","..v[3].."){"..tostring(1*signal)..",0,0};\n" )
            elseif( v[5] == 2 ) then
                file:write( "VP("..v[1]..","..v[2]..","..v[3].."){0,"..tostring(1*signal)..",0};\n" )
            elseif( v[5] == 3 ) then
                file:write( "VP("..v[1]..","..v[2]..","..v[3].."){0,0,"..tostring(1*signal).."};\n" )
            elseif( v[5] == 4 ) then
                file:write( "VP("..v[1]..","..v[2]..","..v[3].."){"..tostring(1.5*signal)..",0,0};\n" )
            elseif( v[5] == 5 ) then
                file:write( "VP("..v[1]..","..v[2]..","..v[3].."){0,"..tostring(1.5*signal)..",0};\n" )
            elseif( v[5] == 6 ) then
                file:write( "VP("..v[1]..","..v[2]..","..v[3].."){0,0,"..tostring(1.5*signal).."};\n" )
            end
        end
        file:write( "};\n" )
        file:write( "View[2].Axes = 0;\n" )
        file:close()

        --Geometry file
        file = io.open( self.file_path, "w" )
        file:write( "// "..self.name.." mesh\n" )
        file:write( "Merge \""..self.name..".pos\";\n" )
        file:write( "lc = "..self.lc..";\n" )
        --Nodes
        for k, v in ipairs( self.node ) do
            file:write( "Point("..k..") = { "..v[1]..", "..v[2]..", "..v[3]..", lc };\n" )
        end
        --Elements
        for k, v in ipairs( self.element ) do
            file:write( "Line("..k..") = { "..v[1]..", "..v[2].." };\n" )
        end
        file:close()
    elseif( type == "post" ) then
        print( "Exporting mesh stresses" )
        --self.file_path = "C:\\Users\\Guilherme\\Documents\\Udesc\\Albatroz\\gmsh\\".."\\"..self.name..".pos"
        self.file_path = config.gmsh_model_folder.."/"..self.name..".pos"
        local file = io.open( self.file_path, "w" )
        --Options
        file:write( "View.Axes = 1;\n" )
        file:write( "View.PointType = 1;\n" )
        file:write( "View.PointSize = 4;\n" )
        file:write( "View.LineType = 1;\n" )
        file:write( "View.LineWidth = 3;\n" )
        --Elements
        file:write( "View \"Stresses\" {\n" )
        for k, v in pairs( post ) do
            file:write( "SL("..v[1]..","..v[2]..","..v[3]..","..v[4]..","..v[5]..","..v[6].."){"..v[8]..",1};\n" )
        end
        --Nodes
        for k, v in ipairs( self.node ) do
            file:write( "SP("..v[1]..","..v[2]..","..v[3].."){0};\n" )
        end
        file:write( "};\n" )
        --Stresses values in string
        file:write( "View \"Stress_value\" {\n" )
        for k, v in pairs( post ) do
            local n1 = { v[1], v[2], v[3] }
            local n2 = { v[4], v[5], v[6] }
            local n = { (n1[1]+n2[1])/2, (n1[2]+n2[2])/2, (n1[3]+n2[3])/2 }
            file:write( "T3("..n[1]..","..n[2]..","..n[3]..",0){\""..string.format( "%.3f", v[8] ).."\"};\n" )
        end
        file:write( "};\n" )
        --Buckling strings
        file:write( "View \"Buckling_stress\" {\n" )
        for k, v in ipairs( self.element ) do
            if( post[ self.element_n_id[ k ] ][8] == -1 ) then
                local n1 = self.node[ v[1] ]
                local n2 = self.node[ v[2] ]
                local n = { (n1[1]+n2[1])/2, (n1[2]+n2[2])/2, (n1[3]+n2[3])/2 }
                file:write( "T3("..n[1]..","..n[2]..","..n[3]..",0){\"Buckling: "..string.format( "%.3f", Element[ self.name ][ self.element_n_id[ k ] ].buckling_stress ).." MPa\"};\n" )
            end
        end
        file:write( "};\n" )
        --Nodes ids
        file:write( "View \"Node_ids\" {\n" )
        for k, v in ipairs( self.node ) do
            file:write( "T3("..v[1]..","..v[2]..","..v[3]..",0){\""..self.node_n_id[ k ].."\"};\n" )
        end
        file:write( "};\n" )
        --Element ids
        file:write( "View \"Element_ids\" {\n" )
        for k, v in ipairs( self.element ) do
            local n1 = self.node[ v[1] ]
            local n2 = self.node[ v[2] ]
            local n = { (n1[1]+n2[1])/2, (n1[2]+n2[2])/2, (n1[3]+n2[3])/2 }
            file:write( "T3("..n[1]..","..n[2]..","..n[3]..",0){\""..self.element_n_id[ k ].."\"};\n" )
        end
        file:write( "};\n" )
        file:write( "View[1].Visible = 0;\n" )
        file:write( "View[2].Visible = 0;\n" )
        file:write( "View[3].Visible = 0;\n" )
        file:write( "View[4].Visible = 0;\n" )
        --file:write( "Print Sprintf(\""..proj.name..".png\");\n" )
        file:close()
    end
end

function GMSH:view( type )
    --GAMBI PARA ABRIR ARQUIVO EXTERNO
    print( "Opening mesh file" )
    if( type == "geometry" ) then
        self.file_path = string.gsub( self.file_path, "\\", "/" )
        print( "\""..config.gmsh_folder.."\\gmsh.exe\" \""..config.gmsh_model_folder.."/"..self.name..".geo\"" )
        --os.execute( "cd Projects" )
        os.execute( "Gmsh\\gmsh.exe \""..config.gmsh_model_folder.."/"..self.name..".geo\"" )
        --str1 = "cd Gmsh\r"
        --str2 = "gmsh.exe \""..config.gmsh_model_folder.."/"..self.name..".geo\""
        --os.execute( str1..str2 )


        --os.execute( "\""..config.gmsh_folder.."\\gmsh.exe\"  C:/Users/Guilherme/Documents/Udesc/Albatroz/gmsh/Forca_ponta.geo" )
        --os.execute( "\""..config.gmsh_folder.."\\gmsh.exe\" \""..self.file_path.."\" " )
    elseif( type == "post" ) then
        os.execute( "Gmsh\\gmsh.exe \""..config.gmsh_model_folder.."/"..self.name..".pos\"" )
        --os.execute( "\""..config.gmsh_folder.."\\gmsh.exe\" \""..config.gmsh_model_folder.."/"..self.name..".pos\"" )
    end
end

function GMSH:export_and_view( type, post )
    self:export( type, post )
    self:view( type )
end
