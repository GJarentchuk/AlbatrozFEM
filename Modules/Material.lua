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


require("lgob.gdk")
require("lgob.gtk")

require("Languages\\lang_en")

material = {--Fixed entities
    lib = {},
    main_hbox = gtk.HBox.new( false, 0 ),
    list = {},
    x_section = { --Controls cross section type
        Rectangular = {
            name = lang_en.MATERIAL.rectangular,
            image = "Material library\\rec_img.png",
            width = lang_en.MATERIAL.rec_width_label,
            height = lang_en.MATERIAL.rec_height_label,
        },
        Circular = {
            name = lang_en.MATERIAL.circular,
            image = "Material library\\cir_img.png",
            diameter = lang_en.MATERIAL.cir_diameter_label,
        },
        Tubular = {
            name = lang_en.MATERIAL.tubular,
            image = "Material library\\tub_img.png",
            in_diameter = lang_en.MATERIAL.tub_in_diameter_label,
            out_diameter = lang_en.MATERIAL.tub_out_diameter_label,
        },
    },
    element_type = {
        Standard = {
            density   = { var = lang_en.MATERIAL.density, unit = "kg/m^3" },
            area      = { var = lang_en.MATERIAL.area, unit = "mm^2" },
            Iyy       = { var = lang_en.MATERIAL.Iyy, unit = "mm^4" },
            Izz       = { var = lang_en.MATERIAL.Izz, unit = "mm^4" },
            polar     = { var = lang_en.MATERIAL.polar, unit = "mm^4" },
            E         = { var = lang_en.MATERIAL.E, unit = "MPa" },
            G         = { var = lang_en.MATERIAL.G, unit = "MPa" },
            f_shear_y = { var = lang_en.MATERIAL.f_shear_y, unit = "" },
            f_shear_z = { var = lang_en.MATERIAL.f_shear_z, unit = "" },
            f_torsion = { var = lang_en.MATERIAL.f_torsion, unit = "" },
            fail      = { var = lang_en.MATERIAL.fail, unit = "MPa" },
            fail_type = { var = lang_en.MATERIAL.fail_type, unit = "" },
        },
        Variable = {
        },
        Spring = {
        },
    },
}

MATERIAL = {}

MATERIAL.__index = MATERIAL

function MATERIAL.new( name, x_section, element_type, data )
    self = {}
    setmetatable(self, MATERIAL)
    self.name         = name
    self.geom         = x_section
    self.element_type = element_type
    if( x_section == "Rectangular" ) then
        self.geom   = x_section
        self.width  = data.width
        self.height = data.height
    elseif( x_section == "Circular" ) then
        self.geom     = x_section
        self.diameter = data.diameter
    elseif( x_section == "Tubular" ) then
        self.geom         = x_section
        self.in_diameter  = data.in_diameter
        self.out_diameter = data.out_diameter
    end
    if( element_type == "Standard" ) then
        self.density   = data.density
        self.area      = data.area
        self.Iyy       = data.Iyy
        self.Izz       = data.Izz
        self.polar     = data.polar
        self.E         = data.E
        self.G         = data.G
        self.fail      = data.fail
        self.fail_type = data.fail_type
        self.f_shear_y = data.f_shear_y
        self.f_shear_z = data.f_shear_z
        self.f_torsion = data.f_torsion
    elseif( element_type == "Variable" ) then
    elseif( element_type == "Spring" ) then
--        self.mass      = data.mass
--        self.k         = data.k
--        self.max_force = data.max_force
    end
    return self
end

function material:create_material_dialog()
--Material name window
    local window = gtk.Window.new( gtk.WINDOW_TOPLEVEL )
    local entry  = gtk.Entry.new()
    local name
    window:set_title( Label.MATERIAL.new_material_dialog )
    window:set( "width-request", 250 )
    window:connect( "delete-event", function() window:destroy() end )
    entry:connect( "activate", function()
        material.save_button:set( "sensitive", true )
        material.cancel_button:set( "sensitive", true )
        material.set_geometry_combobox:set( "sensitive", true )
        material.set_element_type_combobox:set( "sensitive", true )
        name = entry:get_text()
        material.set_new_material:set( "sensitive", false )
        material.set_edit_material:set( "sensitive", false )
        material.set_del_material:set( "sensitive", false )
        window:destroy()
        material.handlers = self:create_material( name )
        end )
    window:add( entry )
    window:show_all()
end

function material:change_x_section( geom )
    --Image change
    if( self.x_section[ geom ].image ~= nil ) then
        self.set_geometry_image:set_from_file( self.x_section[ geom ].image )
    end
    --Fake treeview
    self.x_section.tree = Treeview.new( false )
    self.x_section.tree:add_column_text( Label.MATERIAL.view_column_3, 150 )
    self.x_section.tree:add_column_text( Label.MATERIAL.view_column_4, 100 )
    self.x_section.tree:add_column_text( Label.MATERIAL.view_column_5, 100 )
    --Data
    for k, v in pairs( self.x_section[ geom ] ) do
        if( k ~= "name" ) and ( k ~= "image" ) then
            self.x_section.tree:add_row( { v, "", "mm" } )
        end
    end
    self.set_geometry_image:show()
end

function material:change_element_type( type )
    --Fake treeview
    self.element_type.tree = Treeview.new( false )
    self.element_type.tree:add_column_text( Label.MATERIAL.view_column_3, 150 )
    self.element_type.tree:add_column_text( Label.MATERIAL.view_column_4, 100 )
    self.element_type.tree:add_column_text( Label.MATERIAL.view_column_5, 100 )
    --Data
    for k, v in pairs( self.element_type[ type ] ) do
        self.element_type.tree:add_row( { v.var, "", v.unit } )
    end
end

function material:create_material( name )
    self.editable = true
    local event = {}
    --Settings treeview
    self.set.tree.data:clear()
    self.set.tree.data:append( { Label.MATERIAL.name, name, "" } )
    --Change cross section
    event[1] = self.set_geometry_combobox:connect( "changed", function()
                                                                local name = self.set.tree.data:get( 1 )[ 2 ]
                                                                self.set.tree.data:clear()
                                                                self.set.tree.data:append( { Label.MATERIAL.name, name, "" } )
                                                                self:change_x_section( self.set_geometry_combobox:get_active_text() )
                                                                for i = 1, self.x_section.tree.data.itens do
                                                                    self.set.tree.data:append( self.x_section.tree.data:get( i ) )
                                                                end
                                                                if( self.set_element_type_combobox:get_active_text() ~= nil ) then
                                                                    self:change_element_type( self.set_element_type_combobox:get_active_text() )
                                                                    for i = 1, self.element_type.tree.data.itens do
                                                                        self.set.tree.data:append( self.element_type.tree.data:get( i ) )
                                                                    end
                                                                end
                                                                self.set.tree:update()
                                                                end )
    event[2] = self.set_element_type_combobox:connect( "changed", function()
                                                                    local name = self.set.tree.data:get( 1 )[ 2 ]
                                                                    self.set.tree.data:clear()
                                                                    self.set.tree.data:append( { Label.MATERIAL.name, name, "" } )
                                                                    if( self.set_geometry_combobox:get_active_text() ~= nil ) then
                                                                        self:change_x_section( self.set_geometry_combobox:get_active_text() )
                                                                        for i = 1, self.x_section.tree.data.itens do
                                                                            self.set.tree.data:append( self.x_section.tree.data:get( i ) )
                                                                        end
                                                                    end
                                                                    self:change_element_type( self.set_element_type_combobox:get_active_text() )
                                                                    for i = 1, self.element_type.tree.data.itens do
                                                                        self.set.tree.data:append( self.element_type.tree.data:get( i ) )
                                                                    end
                                                                    self.set.tree:update()
                                                                    end )
    self.set.tree:update()
    return event
end

function material:edit_material( name )
    --Changes buttons and stuff
    self.editable = true
    self.save_button:set( "sensitive", true )
    self.cancel_button:set( "sensitive", true )
    self.set_geometry_combobox:set( "sensitive", true )
    self.set_element_type_combobox:set( "sensitive", true )
    self.set_new_material:set( "sensitive", false )
    self.set_edit_material:set( "sensitive", false )
    self.set_del_material:set( "sensitive", false )

    material.handlers[ 1 ] = self.set_geometry_combobox:connect( "changed", function()
                                local buffer = {}
                                local element_type = self.set_element_type_combobox:get_active_text()
                                --Copy element type info
                                for i = 1, self.set.tree.data.itens do
                                    local row = self.set.tree.data:get( i )
                                    for k, v in pairs( self.element_type[ element_type ] ) do
                                        local K, V = k, v
                                        if( self.element_type[ element_type ][ K ].var == row[ 1 ] ) then
                                            buffer[ #buffer + 1 ] = row
                                        end
                                    end
                                end
                                --Updates treeview
                                local name = self.set.tree.data:get( 1 )[ 2 ]
                                self.set.tree.data:clear()
                                self.set.tree.data:append( { Label.MATERIAL.name, name, "" } )
                                self:change_x_section( self.set_geometry_combobox:get_active_text() )
                                for i = 1, self.x_section.tree.data.itens do
                                    self.set.tree.data:append( self.x_section.tree.data:get( i ) )
                                end
                                for i = 1, #buffer do
                                    self.set.tree.data:append( buffer[ i ] )
                                end
                                self.set.tree:update()
                                end )
    material.handlers[ 2 ] = self.set_element_type_combobox:connect( "changed", function()
                                local buffer = {}
                                local x_section = self.set_geometry_combobox:get_active_text()
                                --Copy cross section info
                                for i = 1, self.set.tree.data.itens do
                                    local row = self.set.tree.data:get( i )
                                    for k, v in pairs( self.x_section[ x_section ] ) do
                                        local K, V = k, v
                                        if( K ~= "name" ) and ( K ~= "image" ) then
                                            if( V == row[ 1 ] ) then
                                                buffer[ #buffer + 1 ] = row
                                            end
                                        end
                                    end
                                end
                                --Updates treeview
                                self.set.tree.data:clear()
                                self.set.tree.data:append( { Label.MATERIAL.name, name, "" } )
                                for i = 1, #buffer do
                                    self.set.tree.data:append( buffer[ i ] )
                                end
                                self:change_element_type( self.set_element_type_combobox:get_active_text() )
                                for i = 1, self.element_type.tree.data.itens do
                                    self.set.tree.data:append( self.element_type.tree.data:get( i ) )
                                end
                                self.set.tree:update()
                                end )
end

function material:save_material( handlers )
--    --Check if there's any blank fieldl
--    for i = 1, material.set.tree.data.itens do
--        if( material.set.tree.data:get( i )[ 2 ] == "" ) then
--            local dialog = gtk.MessageDialog.new( nil, gtk.DIALOG_DESTROY_WITH_PARENT, gtk.MESSAGE_ERROR, gtk.BUTTONS_CLOSE,
--                                 Label.MATERIAL.error, nil );
--            dialog:set( "text", Label.MATERIAL.error )
--            dialog:run();
--            dialog:destroy();
--            return nil
--        end
--    end
    --Sets buttons and disconnect signals
    self.save_button:set( "sensitive", false )
    self.cancel_button:set( "sensitive", false )
    self.set_geometry_combobox:set( "sensitive", false )
    self.set_element_type_combobox:set( "sensitive", false )
    self.editable = false
    self.set_new_material:set( "sensitive", true )
    self.set_edit_material:set( "sensitive", true )
    self.set_del_material:set( "sensitive", true )
    self.set_geometry_combobox:disconnect    ( handlers[ 1 ] )
    self.set_element_type_combobox:disconnect( handlers[ 2 ] )

    --Buffers info into "data"
    local name      = self.set.tree.data:get( 1 )[ 2 ]
    local x_section = self.set_geometry_combobox:get_active_text()
    local element_type = self.set_element_type_combobox:get_active_text()
    local data = {}
    for k, v in pairs( self.x_section[ x_section ] ) do
        local K, V = k, v
        if( K ~= "name" ) and ( K ~= "image" ) then
            for i = 1, self.set.tree.data.itens do
                local row = self.set.tree.data:get( i )
                if( V == row[ 1 ] ) then
                    data[ K ] = row[ 2 ]
                end
            end
        end
    end
    for k, v in pairs( self.element_type[ element_type ] ) do
        local K, V = k, v
        for i = 1, self.set.tree.data.itens do
            local row = self.set.tree.data:get( i )
            if( self.element_type[ element_type ][ K ].var == row[ 1 ] ) then
                data[ K ] = row[ 2 ]
            end
        end
    end
    --Saves info in a MATERIAL class instance
    local file = io.open( "Material library\\"..name..".lua", "w" )
    file:write( "material.lib."..name.." = MATERIAL.new( \""..name.."\", \""..x_section.."\", \""..element_type.."\", {" )
    for k, v in pairs( data ) do
        file:write( "\n\t"..k.." = \""..v.."\", " )
    end
    file:write( "\n} )" )
    file:close()
    --Updates material library
    self:update_mat_list( name )
end

function material:cancel_material( handlers )
    --Sets buttons and disconnect signals
    self.save_button:set( "sensitive", false )
    self.cancel_button:set( "sensitive", false )
    self.set_geometry_combobox:set( "sensitive", false )
    self.set_element_type_combobox:set( "sensitive", false )
    self.editable = false
    self.set_new_material:set( "sensitive", true )
    self.set_edit_material:set( "sensitive", true )
    self.set_del_material:set( "sensitive", true )
    self.set_geometry_combobox:disconnect    ( handlers[ 1 ] )
    self.set_element_type_combobox:disconnect( handlers[ 2 ] )
    self.set.tree.data:clear()
    self.set.tree:update()
end

function material:delete_material( name )
    --Checks if it is assigned to project
    for k, v in ipairs( proj.material ) do
        if( v == name ) then
            self:remove_material_from_project( name )
        end
    end
    --Removes from library
    self.lib[ name ] = nil
    self:update_mat_list( nil )
    os.remove( config.working_directory.."\\Material library\\"..name..".lua" )
end

function material:change_material_view( name )
    --Adds name and prepare comboboxes
    local mat = self.lib[ name ]
    self.set.tree.data:clear()
    self.set.tree.data:append( { Label.MATERIAL.name, name, "" } )
    self.set_geometry_combobox:set_active( mat.geom )
    self.set_element_type_combobox:set_active( mat.element_type )
    --Adds cross section
    self:change_x_section( mat.geom )
    for k, v in pairs( self.x_section[ mat.geom ] ) do
        local K, V = k, v
        if( K ~= "name" ) and ( K ~= "image" ) then
            self.set.tree.data:append( { V, mat[ K ], "mm" } )
        end
    end
    for k, v in pairs( self.element_type[ mat.element_type ] ) do
        local K, V = k, v
        self.set.tree.data:append( { self.element_type[ mat.element_type ][ K ].var, mat[ K ], self.element_type[ mat.element_type ][ K ].unit } )
    end
    self.set.tree:update()
end

function material:load_material_lib()
    local file = loadfile( "Material library\\mat_list.lua" )
    file()
    self.manager_lib.data:clear()
    for k, v in pairs( self.lib ) do
        self.manager_lib.data:append( { k } )
    end
    self.manager_lib:update()
    self.manager_lib.view:connect( "cursor-changed", function()
                                                        if( self.manager_lib:get_selected() ~= nil ) and ( #self.manager_lib:get_selected() > 0 ) then
                                                            local mat = self.manager_lib.data:get( self.manager_lib:get_selected()[ 1 ] )[ 1 ]
                                                            self:change_material_view( mat )
                                                        end
                                                        end )
    self.manager_proj.view:connect( "cursor-changed", function()
                                                        if( self.manager_proj:get_selected() ~= nil ) and ( #self.manager_proj:get_selected() > 0 ) then
                                                            local mat = self.manager_proj.data:get( self.manager_proj:get_selected()[ 1 ] )[ 1 ]
                                                            self:change_material_view( mat )
                                                        end
                                                        end )
end

function material:add_material_to_project( name )
    --Checks if it already exists
    for i = 1, self.manager_proj.data.itens do
        local row = self.manager_proj.data:get( i )
        if( row[ 1 ] == name ) then
            return nil
        end
    end
    --Adds material
    self.manager_proj.data:append( { name } )
    self.manager_proj:update()
    update_material_list( name, "add", nil )
end

function material:remove_material_from_project( name )
    for i = 1, self.manager_proj.data.itens do
        local row = self.manager_proj.data:get( i )
        if( row[ 1 ] == name ) then
            self.manager_proj.data:remove( i )
            update_material_list( name, "del", i )
        end
    end
    self.manager_proj:update()
end

function material:update_mat_list( name )
    local file = io.open( "Material library\\mat_list.lua", "w" )
    file:write( "--Materials\n" )
    --file:write( "function mat_list_load()\n" )
    local k, v
    for k, v in pairs( material.lib ) do
        local text = "" --string.gsub( config.program_directory, "\\", "\\\\" )
        file:write( "mat_file = loadfile( \""..text.."\\\\Material library\\\\"..k..".lua\")\nmat_file()\n" )
        if( name == k ) then name = nil end
    end
    if( name ~= nil ) then
        local text = "" --string.gsub( config.program_directory, "\\", "\\\\" )
        file:write( "mat_file = loadfile( \""..text.."\\\\Material library\\\\"..name..".lua\")\nmat_file()\n" )
    end
    --file:write( "end\n" )
    file:close()
    --Reloads material library
    self:load_material_lib()
--end
end

--Callbacks
function material:change_value( row_id, new_value )
    if( self.editable == true ) then
        local row = material.set.tree.data:get( row_id + 1 )
        row[ 2 ] = new_value
        self.set.tree:update()
    end
end
function material:build()
    function settings_treeview()
        local tree
        tree = Treeview.new( false )
        tree:add_column_text( Label.MATERIAL.view_column_3, 170, material.change_value, material )
        tree:add_column_text( Label.MATERIAL.view_column_4, 75, material.change_value, material )
        tree:add_column_text( Label.MATERIAL.view_column_5, 75, material.change_value, material )

        tree.columns[1]:set( "min-width", 170 )
        tree.columns[2]:set( "min-width", 75 )
        tree.columns[3]:set( "min-width", 75 )
        return tree
    end
    --Handlers for save and cancel buttons
    self.handlers = {}
    --Material manager (to choose which materials are active inside the project)
    material.manager_frame         = gtk.Frame.new( Label.MATERIAL.manager_frame )
    material.manager_hbox          = gtk.HBox.new( false, 5 )
    material.manager_lib           = Treeview.new( true )
    material.manager_vbox          = gtk.VBox.new( false, 20 )
    material.manager_add_button    = build_button( 1, "gtk-go-forward", "", "all", std.icon_size )
    material.manager_remove_button = build_button( 1, "gtk-go-back", "", "all", std.icon_size )
        material.manager_vbox:pack_start( material.manager_add_button, false, false, 1 )
        material.manager_vbox:pack_start( material.manager_remove_button, false, false, 1 )
    material.manager_proj          = Treeview.new( true )
    --Material settings
    material.set_frame          = gtk.Frame.new( Label.MATERIAL.set_frame )
    material.set_vbox           = gtk.VBox.new( false, 5 )
    material.set_functions_hbox = gtk.HBox.new( false, 5 )
        material.set_new_material  = build_button( 1, "gtk-new", Label.MATERIAL.new_material, "all", std.icon_size )
        material.set_edit_material = build_button( 1, "gtk-edit", Label.MATERIAL.edit_material, "all", std.icon_size )
        material.set_del_material = build_button( 1, "gtk-delete", Label.MATERIAL.del_material, "all", std.icon_size )

        material.set_functions_hbox:pack_start( material.set_new_material, false, false, 1 )
        material.set_functions_hbox:pack_start( material.set_edit_material, false, false, 1 )
        material.set_functions_hbox:pack_start( material.set_del_material, false, false, 1 )
    material.set_geometry_hbox = gtk.HBox.new( false, 5 )
        --Label goes here
        material.set_geometry_combobox  = gtk.ComboBox.new_text()
        material.set_geometry_image     = gtk.Image.new()

        material.set_geometry_hbox:pack_start( Label.MATERIAL.geometry_label, false, false, 1 )
        material.set_geometry_hbox:pack_start( material.set_geometry_combobox, true, false, 1 )
        material.set_geometry_hbox:pack_start( material.set_geometry_image, false, false, 1 )
    self.set_element_type_hbox = gtk.HBox.new( false, 5 )
        self.element_type_label        = gtk.Label.new( Label.MATERIAL.element_type )
        self.set_element_type_combobox = gtk.ComboBox.new_text()

        self.set_element_type_hbox:pack_start( self.element_type_label, false, false, 1 )
        self.set_element_type_hbox:pack_start( self.set_element_type_combobox, true, false, 1 )

    --Material settings treeview
    material.set = {}
    material.set.tree = settings_treeview()
    material.save_hbox = gtk.HBox.new( false, 5 )
        material.save_button   = build_button( 1, "gtk-save", Label.MATERIAL.save_material, "all", std.icon_size )
        material.cancel_button = build_button( 1, "gtk-cancel", Label.MATERIAL.cancel, "all", std.icon_size )

        material.save_hbox:pack_start( material.save_button, false, false, 1 )
        material.save_hbox:pack_start( material.cancel_button, false, false, 1 )

    --Settings
    material.manager_lib:add_column_text( Label.MATERIAL.view_column_1, 75 )
    material.manager_proj:add_column_text( Label.MATERIAL.view_column_2, 75 )
    material.save_button:set( "sensitive", false )
    material.cancel_button:set( "sensitive", false )
    material.set_geometry_combobox:set( "sensitive", false )
    self.set_element_type_combobox:set( "sensitive", false )
    self.editable = false
    --Cross section comboboxes
    local k, v
    for k, v in pairs( material.x_section ) do
        material.set_geometry_combobox:append_text( v.name )
    end
    for k, v in pairs( fem.element_type ) do
        self.set_element_type_combobox:append_text( v )
    end

    material.manager_lib.obj      = material.manager_lib:build( { width = 200, height = 500 } )
    material.manager_proj.obj     = material.manager_proj:build( { width = 200, height = 500 } )
    material.set.tree.obj         = material.set.tree:build( { width = 350, height = 400 } )

    --Events
    self.set_new_material:connect     ( "clicked", function() self.handlers = self:create_material_dialog() end )
    material.set_edit_material:connect( "clicked", function()
                                                    if( self.set.tree.data:get( 1 ) == nil ) then
                                                        return nil
                                                    end
                                                    local mat = self.set.tree.data:get( 1 )[ 2 ]
                                                    print( mat )
                                                    if( mat ~= "" ) and ( mat ~= nil ) then
                                                        self:edit_material( mat )
                                                    end
                                                    end )
    material.set_del_material:connect ( "clicked", function()
                                                        local table = self.manager_lib:get_selected()
                                                        if( #table > 0 ) then
                                                            for i = 1, #table do
                                                                self:delete_material( material.manager_lib.data:get( table[ i ] )[ 1 ] )
                                                            end
                                                        end
                                                        end )
    material.save_button:connect( "clicked", function() self:save_material( self.handlers ) end )
    material.cancel_button:connect( "clicked", function() self:cancel_material( self.handlers ) end )
    material.manager_add_button:connect( "clicked", function()
                                                        local table = self.manager_lib:get_selected()
                                                        if( #table > 0 ) then
                                                            for i = 1, #table do
                                                                self:add_material_to_project( material.manager_lib.data:get( table[ i ] )[ 1 ] )
                                                            end
                                                        end
                                                        end )
    material.manager_remove_button:connect( "clicked", function()
                                                        local table = self.manager_proj:get_selected()
                                                        if( #table > 0 ) then
                                                            for i = 1, #table do
                                                                self:remove_material_from_project( self.manager_proj.data:get( table[ i ] )[ 1 ] )
                                                            end
                                                        end
                                                        end )

    material.manager_hbox:pack_start( material.manager_lib.obj, false, false, 1 )
    material.manager_hbox:pack_start( material.manager_vbox, false, false, 1 )
    material.manager_hbox:pack_start( material.manager_proj.obj, false, false, 1 )

    material.set_vbox:pack_start( material.set_functions_hbox, false, false, 1 )
    material.set_vbox:pack_start( material.set_geometry_hbox, false, false, 1 )
    material.set_vbox:pack_start( material.set_element_type_hbox, false, false, 1 )
    material.set_vbox:pack_start( material.set.tree.obj, false, false, 1 )
    material.set_vbox:pack_start( material.save_hbox, false, false, 1 )

    material.manager_frame:add( material.manager_hbox )
    material.set_frame:add( material.set_vbox )
    material.main_hbox:pack_start( material.manager_frame, false, false, 1 )
    material.main_hbox:pack_start( material.set_frame, false, false, 1 )
    material.set.tree:update()
    material.main_hbox:show_all()
    self:load_material_lib()
    --load_material_to_view( nil )
end
