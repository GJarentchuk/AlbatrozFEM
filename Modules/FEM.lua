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

--FEM is the class for scenarios
--fem is for fixed entities

fem = { --Buttons are built in build function, here they are declared just for reference
    main_vbox = gtk.VBox.new( false, 0 ),
    --Toolbar
    toolbar   = gtk.Toolbar.new(),
    toolbar_1 = gtk.Toolbar.new(),
    tool = { --Toolbar components
        add_scenario = nil,
        add_node     = nil,
    },
    --Scenario notebook
    notebook   = gtk.Notebook.new(),
    page_child = {},
    --Table of scenarios for a project
    sce = {},
    --Node view
    --[[node = {
        window = gtk.ScrolledWindow.new( nil, nil ),
        --view   = gtk
    },]]
    element_type = {
        "Standard",
        "Variable",
        "Spring",
    }
}

--Class fem
FEM = {}
FEM.__index = FEM

function FEM.new( scenario_name )
    self = {}
    setmetatable(self, FEM)
    self.name = scenario_name
    --GTK
    --Notebook and main vbox
    self.scroll = gtk.ScrolledWindow.new( nil, nil )
    self.scroll:set_policy( gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC )
    self.scroll:set( "height-request", 450 )
    self.main_vbox = gtk.VBox.new( false, 5 )--Inserted in notebook page
    scenario_name  = gtk.Label.new( scenario_name )
    self.scroll:add_with_viewport( self.main_vbox )
    fem.notebook:insert_page( self.scroll, scenario_name, -1 )
    --HBoxes
    self.hbox1  = gtk.HBox.new( false, 5 )
    self.hbox2  = gtk.HBox.new( false, 5 )
    self.main_vbox:pack_start( self.hbox1, false, false, 1 )
    self.main_vbox:pack_start( self.hbox2, false, false, 1 )
    --Node view
    self.node       = self:node_view_build()
    self.node.frame = gtk.Frame.new( Label.FEM.node_frame )
    self.node.obj = self.node:build( { width = 320, height = 400 } )

    self.node.frame:add( self.node.obj )
    self.hbox1:pack_start( self.node.frame, false, false, 1 )
    --Element view
    self.element              = self:element_view_build()
    self.element.frame        = gtk.Frame.new( Label.FEM.element_frame )
    self.element.obj          = self.element:build( { width = 500, height = 400 } )
    self.element.hbox         = gtk.HBox.new( false, 0 )

    self.element.hbox:pack_start( self.element.obj, false, false, 1 )
    self.element.frame:add( self.element.hbox )
    self.hbox1:pack_start( self.element.frame, false, false, 1 )
    --Loads view
    self.load       = self:load_view_build()
    self.load.frame = gtk.Frame.new( Label.FEM.load_frame )
    self.load.obj   = self.load:build( { width = 400, height = 400 } )

    self.load.frame:add( self.load.obj )
    self.hbox2:pack_start( self.load.frame, false, false, 1 )
    --Constraints view
    self.constraint = self:constraint_view_build()
    self.constraint.frame = gtk.Frame.new( Label.FEM.constraint_frame )
    self.constraint.obj   = self.constraint:build( { width = 400, height = 400 } )
    self.constraint.node = {}--Nodes with constraints

    self.constraint.frame:add( self.constraint.obj )
    self.hbox2:pack_start( self.constraint.frame, false, false, 1 )
    --Results GUI
    self.res = {}
    --GMSH
    self.GMSH_list = {}

    fem.notebook:show_all()
    fem.notebook:set_current_page( -1 )
    --Set page child name
    fem.page_child[ fem.notebook:get( "page" ) ] = self.scroll
    return self
end

--Node treeview
function FEM:node_view_build()
    local node = {}
--    node.data = {
--        --List of format [ id ] = { x, y, z }
--    }
    --Create node treeview
    node = Treeview.new( true )
    --Set columns
    node:add_column_text( "ID", 75, self.change_node_id, self )
    node:add_column_text( "X [ mm ]", 75, self.change_node_x, self )
    node:add_column_text( "Y [ mm ]", 75, self.change_node_y, self )
    node:add_column_text( "Z [ mm ]", 75, self.change_node_z, self )
    local i
    for i = 1, #node.columns do
        node.columns[i]:set( "min-width", 75 )
    end

    node.id_list = {} --Lista por ids com linhas
    node.linkage = {} --List with elements connected to a given knot
    node.view:connect( "key-press-event" , Bind.key, Main_window )

    node.view:set( "enable-grid-lines", gtk.TREE_VIEW_GRID_LINES_BOTH )

    return node
end
--Callbacks
function FEM:change_node_id( row_id, new_value )
    local row = self.node.data:get( row_id + 1 )
    --self.node.id_list[ new_value ] = self.node.id_list[ row[ 1 ] ]
    --print( self.node.id_list[ new_value ] )
    if( self.node.id_list[ new_value ] == nil ) then
        self:change_linkage( row[ 1 ], new_value )
        self.node.id_list[ row[ 1 ] ] = nil
        row[ 1 ] = new_value
        self.node.id_list[ new_value ] = 1
    end
    self.node:update()
    self.element:update()
end
function FEM:change_node_x( row_id, new_value )
    local row = self.node.data:get( row_id + 1 )
    row[ 2 ] = tonumber( new_value )
    self.node:update()
end
function FEM:change_node_y( row_id, new_value )
    local row = self.node.data:get( row_id + 1 )
    row[ 3 ] = tonumber( new_value )
    self.node:update()
end
function FEM:change_node_z( row_id, new_value )
    local row = self.node.data:get( row_id + 1 )
    row[ 4 ] = tonumber( new_value )
    self.node:update()
end

--Element treeview
function FEM:element_view_build()
    element = {}
    --Create element view
    element = Treeview.new( true )
    --Set columns
    element:add_column_text( Label.FEM.view_id, 30, self.view_change_element, { self, 1 } )
    element:add_column_text( Label.FEM.view_node1, 30 )
    element:add_column_text( Label.FEM.view_node2, 30 )
    element:add_column_text( Label.MATERIAL.material_view, 100 )
    element:add_column_text( Label.FEM.view_type, 30 )
    element:add_column_text( Label.FEM.view_length, 30 )
    element:add_column_text( Label.FEM.view_z_axis, 30, self.view_change_element, { self, 7 } )
    element:add_column_text( Label.FEM.view_mass, 30 )
    element:add_column_text( Label.FEM.view_area, 30 )
    element:add_column_text( Label.FEM.view_Iyy, 30 )
    element:add_column_text( Label.FEM.view_Izz, 30 )
    element:add_column_text( Label.FEM.view_polar, 30 )
    element:add_column_text( Label.FEM.view_E, 30 )
    element:add_column_text( Label.FEM.view_G, 30 )

    for i = 1, #element.columns do
        element.columns[i]:set( "min-width", 50 )
    end
    element.columns[1]:set( "min-width", 100 )
    element.columns[2]:set( "min-width", 100 )
    element.columns[3]:set( "min-width", 100 )

    element.id_list = {}
    element.view:set( "enable-grid-lines", gtk.TREE_VIEW_GRID_LINES_HORIZONTAL )

    return element
end
--Callbacks
function FEM.view_change_element( data, row_id, new_value )
    local self = data[1]
    local col  = data[2]
    local row = self.element.data:get( row_id + 1 )
    if( col == 1 ) then --Change id
        if( self.node.id_list[ new_value ] == nil ) then
            self.node.id_list[ row[ 1 ] ] = nil
            self.node.linkage[ row[2] ][ row[1] ] = nil
            self.node.linkage[ row[3] ][ row[1] ] = nil
            self.node.linkage[ row[2] ][ new_value ] = 1
            self.node.linkage[ row[3] ][ new_value ] = 1
            row[ 1 ] = new_value
            self.node.id_list[ new_value ] = 1
        end
    elseif( col == 7 ) then --Change z_axis
--        local v = vector.new( nil, nil, {0,0,0} )
--        v:scan( new_value )
--        print( v:print() )
        row[ 7 ] = new_value
    end
    self.element:update()
end

--Load treeview
function FEM:load_view_build()
    local load = {}
    --Creates load view
    load = Treeview.new( true )
    --Creates columns
    load:add_column_text( Label.FEM.load_id, 75, self.view_change_load_data, { self, 1 } )
    load:add_column_text( Label.FEM.load_node, 75, self.view_change_load_data, { self, 2 } )
    load:add_column_text( Label.FEM.load_value, 75, self.view_change_load_data, { self, 3 } )
    load:add_column_text( Label.FEM.load_direction, 75, self.view_change_load_data, { self, 4 } )

    load.columns[1]:set( "min-width", 75 )
    load.columns[2]:set( "min-width", 75 )
    load.columns[3]:set( "min-width", 75 )
    load.columns[4]:set( "min-width", 75 )

    load.id_list = {}
    load.view:set( "enable-grid-lines", gtk.TREE_VIEW_GRID_LINES_BOTH )

    return load
end
--Callback
function FEM.view_change_load_data( data, row_id, new_value )
    local self = data[1]
    local col  = data[2]
    local row  = self.load.data:get( row_id + 1 )
    row[ col ] = new_value
    self.load:update()
end

--Constraint view
function FEM:constraint_view_build()
    local constraint = {}
    --Creates constraint view
    constraint = Treeview.new( true )
    --Creates columns
    constraint:add_column_text( Label.FEM.constraint_node, 75 )
    constraint:add_column_toggle( Label.FEM.constraint_trans_x, 50, self.toggle_const_tx, self )
    constraint:add_column_toggle( Label.FEM.constraint_trans_y, 50, self.toggle_const_ty, self )
    constraint:add_column_toggle( Label.FEM.constraint_trans_z, 50, self.toggle_const_tz, self )
    constraint:add_column_toggle( Label.FEM.constraint_rot_x, 50, self.toggle_const_rx, self )
    constraint:add_column_toggle( Label.FEM.constraint_rot_y, 50, self.toggle_const_ry, self )
    constraint:add_column_toggle( Label.FEM.constraint_rot_z, 50, self.toggle_const_rz, self )
    constraint.view:set( "enable-grid-lines", gtk.TREE_VIEW_GRID_LINES_HORIZONTAL )

    return constraint
end
--Callbacks
function FEM:toggle_const_tx( row_id )
    local row = self.constraint.data:get( row_id + 1 )
    if( row[ 2 ] == false ) then
        row[ 2 ] = true
    else
        row[ 2 ] = false
    end
    self.constraint:update()
end
function FEM:toggle_const_ty( row_id )
    local row = self.constraint.data:get( row_id + 1 )
    if( row[ 3 ] == false ) then
        row[ 3 ] = true
    else
        row[ 3 ] = false
    end
    self.constraint:update()
end
function FEM:toggle_const_tz( row_id )
    local row = self.constraint.data:get( row_id + 1 )
    if( row[ 4 ] == false ) then
        row[ 4 ] = true
    else
        row[ 4 ] = false
    end
    self.constraint:update()
end
function FEM:toggle_const_rx( row_id )
    local row = self.constraint.data:get( row_id + 1 )
    if( row[ 5 ] == false ) then
        row[ 5 ] = true
    else
        row[ 5 ] = false
    end
    self.constraint:update()
end
function FEM:toggle_const_ry( row_id )
    local row = self.constraint.data:get( row_id + 1 )
    if( row[ 6 ] == false ) then
        row[ 6 ] = true
    else
        row[ 6 ] = false
    end
    self.constraint:update()
end
function FEM:toggle_const_rz( row_id )
    local row = self.constraint.data:get( row_id + 1 )
    if( row[ 7 ] == false ) then
        row[ 7 ] = true
    else
        row[ 7 ] = false
    end
    self.constraint:update()
end

--Checks for unique ids
function FEM:unique_id( kind, prefix )
    local i = 1
    while( true ) do
        if( prefix == nil ) then
            if( self[ kind ].id_list[ tostring(i) ] == nil ) then
                self[ kind ].id_list[ tostring(i) ] = 1
                return tostring(i)
            end
        else
            local index = prefix.."_"..tostring(i)
            if( self[ kind ].id_list[ index ] == nil ) then
                self[ kind ].id_list[ index ] = 1
                return prefix.."_"..tostring(i)
            end
        end
        i = i + 1
    end
end

--Change knots linkage
function FEM:change_linkage( old, new )
    local k, v
    self.node.linkage[ new ] = {}
    --print( 'old', tostring(old),  )
    if( #self.node.linkage[ tostring(old) ] > 0 ) then
        for k, v in pairs( self.node.linkage[ tostring(old) ] ) do
            self.node.linkage[ new ] = self.node.linkage[ old ]
        end
    end
    self.node.linkage[ tostring(old) ] = nil
    --Updates element treeview
    for k = 1, self.element.data.itens do
        if( self.element.data:get( k )[ 2 ] == tostring(old) ) then
            self.element.data:get( k )[ 2 ] = new
        elseif( self.element.data:get( k )[ 3 ] == tostring(old) ) then
            self.element.data:get( k )[ 3 ] = new
        end
    end
    self.element:update()
    --Updates constraints treeview
    for k = 1, self.constraint.data.itens do
        if( self.constraint.data:get( k )[ 1 ] == tostring(old) ) then
            self.constraint.data:get( k )[ 1 ] = new
        end
    end
    self.constraint:update()
end

function FEM:add_similar_node( n_nodes, table )
    if( table[2] == "" )then table[2] = 0 else table[2] = tonumber( table[2] ) end
    if( table[3] == "" )then table[3] = 0 else table[3] = tonumber( table[3] ) end
    if( table[4] == "" )then table[4] = 0 else table[4] = tonumber( table[4] ) end
    local i
    for i = 1, n_nodes do
        --ID
        local id = self:unique_id( "node", table[1] )
        fem.sce[ scenario ].node:add_row( { id , table[2], table[3], table[4] } )
        fem.sce[ scenario ].node.linkage[ id ] = {}
        fem.sce[ scenario ].node:update()
    end
end

function FEM:change_element_id( row_id, new_value )
end

function FEM:change_element_area( row_id, new_value )
end

function FEM:change_element_Iyy( row_id, new_value )
end

function FEM:change_element_Izz( row_id, new_value )
end

function FEM:change_element_polar( row_id, new_value )
end

function FEM:change_element_E( row_id, new_value )
end

function FEM:change_element_G( row_id, new_value )
end

function FEM:change_element_mass( row_id, new_value )
end

--function FEM:change_constraint_id( row_id, new_value )
--end

--TOOLBAR BUTTONS
--Scenario dialog
function new_scenario_dialog()
    local window = gtk.Window.new( gtk.WINDOW_TOPLEVEL )
    local entry  = gtk.Entry.new()

    window:set_title( Label.FEM.new_scenario_window )
    window:set( "width-request", 250 )

    window:connect( "delete-event", function() window:destroy() end )
    entry:connect( "activate", function()
                                    local name = entry:get_text()
                                    fem.sce[ name ] = FEM.new( name )
                                    mesh.sce[ name ] = MESH.new( name )
                                    window:destroy() end )

    window:add( entry )
    window:show_all()
end

function FEM:add_node( data )
    self.node:add_row( { data[1] , data[2], data[3], data[4] } )
    self.node.linkage[ data[1] ] = {}
    self.node:update()
end

--Add node dialog
function add_node( scenario )
    --print( scenario:get_text() )
    local id = fem.sce[ scenario ]:unique_id( "node", nil )
    fem.sce[ scenario ].node:add_row( { id , 0, 0, 0} )
    fem.sce[ scenario ].node.linkage[ id ] = {}
    fem.sce[ scenario ].node:update()
end

--Pattern add node
function pattern_add_node( scenario )
    print( scenario )
    local window   = gtk.Window.new( gtk.WINDOW_TOPLEVEL )
    local vbox     = gtk.VBox.new( false, 0 )
    local info     = Label.FEM.pattern_add_info
    local hbox1    = gtk.HBox.new( false, 0 )
--    local id_check = gtk.CheckButton.new_with_label( Label.FEM.id_check )
--    local x_check  = gtk.CheckButton.new_with_label( Label.FEM.x_check )
--    local y_check  = gtk.CheckButton.new_with_label( Label.FEM.y_check )
--    local z_check  = gtk.CheckButton.new_with_label( Label.FEM.z_check )
    local id_entry = gtk.Entry.new()
    local x_entry  = gtk.Entry.new()
    local y_entry  = gtk.Entry.new()
    local z_entry  = gtk.Entry.new()
    local hbox2    = gtk.HBox.new( false, 0 )
    local add_n    = build_button( 0, "", Label.FEM.p_add_m_nodes, "label", std.icon_size )
    local add      = build_button( 0, "", Label.FEM.p_add_node, "label", std.icon_size )
    local ok       = build_button( 1, "gtk-ok", Label.button_ok, "all", std.icon_size )
    local n_entry  = gtk.Entry.new()
    --local label  = Label.FEM.n_nodes

    window:set_title( Label.FEM.pattern_add_node )
    window:set( "width-request", 400 )

    id_entry:set( "width-request", 40)
    x_entry:set( "width-request", 50)
    y_entry:set( "width-request", 50)
    z_entry:set( "width-request", 50)
    n_entry:set( "width-request", 50 )

    window:connect  ( "delete-event", function() window:destroy() end )
--    id_check:connect( "toggled", function() if(id_check:get( "active" ) == true) then id_entry:set( "editable", true )
--                                            else id_entry:set( "editable", false ) end end )
--    x_check:connect( "toggled", function() if(x_check:get( "active" ) == true) then x_entry:set( "editable", true )
--                                            else x_entry:set( "editable", false ) end end )
--    y_check:connect( "toggled", function() if(y_check:get( "active" ) == true) then y_entry:set( "editable", true )
--                                            else y_entry:set( "editable", false ) end end )
--    z_check:connect( "toggled", function() if(z_check:get( "active" ) == true) then z_entry:set( "editable", true )
--                                            else z_entry:set( "editable", false ) end end )
    add_n:connect  ( "clicked", function()
                                fem.sce[ scenario ]:add_similar_node( n_entry:get_text(), { id_entry:get_text(),x_entry:get_text(),y_entry:get_text(),z_entry:get_text() } ) end )
    add:connect    ( "clicked", function()
                                fem.sce[ scenario ]:add_similar_node( 1, { id_entry:get_text(),x_entry:get_text(),y_entry:get_text(),z_entry:get_text() } ) end )
    ok:connect     ( "clicked", function() window:destroy() end )

    hbox2:pack_start( Label.FEM.n_nodes, false, false, 1 )
    hbox2:pack_start( n_entry, false, false, 1 )
    hbox2:pack_start( add_n, false, false, 1 )
    hbox2:pack_start( add, false, false, 1 )
    hbox2:pack_start( ok, false, false, 1 )

    hbox1:pack_start( Label.FEM.id_label, false, false, 1 )
    hbox1:pack_start( id_entry, false, false, 1 )
    hbox1:pack_start( Label.FEM.x_label, false, false, 1 )
    hbox1:pack_start( x_entry, false, false, 1 )
    hbox1:pack_start( Label.FEM.y_label, false, false, 1 )
    hbox1:pack_start( y_entry, false, false, 1 )
    hbox1:pack_start( Label.FEM.z_label, false, false, 1 )
    hbox1:pack_start( z_entry, false, false, 1 )

    vbox:pack_start( info, false, false, 1 )
    vbox:pack_start( hbox1, false, false, 1 )
    vbox:pack_start( hbox2, false, false, 1 )
    window:add( vbox )
    window:show_all()
end

--Delete nodes by selection
function delete_node( scenario )
    --fem.sce[ scenario ].node = fem.sce[ scenario ].node:remove_selected()
    local i
    table = fem.sce[ scenario ].node:get_selected()
    for i = 1, #table do
        print( fem.sce[ scenario ].node.id_list[ tostring( fem.sce[ scenario ].node.data:get( table[ i ] )[ 1 ] ) ] )
        fem.sce[ scenario ].node.id_list[ tostring( fem.sce[ scenario ].node.data:get( table[ i ] )[ 1 ] ) ] = nil
        fem.sce[ scenario ].node.data:remove( table[ i ] )
    end
    fem.sce[ scenario ].node:update()
    --Delete elements related using linkage table
end

--Delete scenario
function del_scenario( scenario )
    fem.notebook:remove_page( fem.notebook:get_current_page() )
    fem.sce[ scenario ] = nil
end

--Update combobox
function update_material_list( name, action, row )
    if( action == "add" ) then
        fem.tool.material_combobox:append_text( name )
        for k, v in pairs( mesh.sce ) do
            v.arc.i_mat_combo:append_text( name )
        end
        proj.material[ #proj.material + 1 ] = name
    elseif( action == "del" ) then
        fem.tool.material_combobox:remove_text( row - 1 )
        for k, v in pairs( mesh.sce ) do
            v.arc.i_mat_combo:remove_text( row - 1 )
        end
        proj.material[ row ] = nil
    end
end


--Functions using class (fix the others later)
--NOT REALLY EXCEL, BUT TAB SEPARATED VALUES FILE
function FEM:node_export_to_excel()
    dialog = gtk.FileChooserDialog.new( "Export nodes to tab seprated values (tsv) file", Main_window, gtk.FILE_CHOOSER_ACTION_SAVE,
                                       "gtk-cancel", gtk.RESPONSE_CANCEL, "gtk-ok", gtk.RESPONSE_OK )
--    filter_pro = gtk.FileFilter.new()
--    filter_all = gtk.FileFilter.new()
--    filter_pro:add_pattern( "*.pro" )
--    filter_pro:set_name( "Project files" )
--    filter_all:add_pattern( "*" )
--    filter_all:set_name( "All files" )
--    dialog:add_filter( filter_pro )
--    dialog:add_filter( filter_all )
    dialog:set_current_folder( config.working_directory )

    if( dialog:run() == gtk.RESPONSE_OK ) then
        local filename = dialog:get_filename()..".tsv"
        local f = io.open( filename, 'w' )
        local node = self.node.data
        for i = 1, node.itens do
            local row = node:get( i )
            f:write( row[1].."\t"..row[2].."\t"..row[3].."\t"..row[4].."\n" )
        end
        f:close()
        dialog:destroy()
    elseif( dialog:run() == gtk.RESPONSE_CANCEL ) then
        dialog:destroy()
    end
end

--NOT REALLY EXCEL, BUT TAB SEPARATED VALUES FILE
function FEM:node_import_from_excel()
    dialog = gtk.FileChooserDialog.new( "Import nodes from tab separated values (tsv) file", Main_window, gtk.FILE_CHOOSER_ACTION_OPEN,
                                       "gtk-cancel", gtk.RESPONSE_CANCEL, "gtk-ok", gtk.RESPONSE_OK )
--    filter_pro = gtk.FileFilter.new()
--    filter_all = gtk.FileFilter.new()
--    filter_pro:add_pattern( "*.pro" )
--    filter_pro:set_name( "Project files" )
--    filter_all:add_pattern( "*" )
--    filter_all:set_name( "All files" )
--    dialog:add_filter( filter_pro )
--    dialog:add_filter( filter_all )
    dialog:set_current_folder( config.working_directory )

    if( dialog:run() == gtk.RESPONSE_OK ) then
        local filename = dialog:get_filename()
        --Reads file
        local f = io.open( filename, 'r' )
        local node    = {}
        local id_list = {}
        for l in f:lines() do
            local i = 1
            node[ #node + 1 ] = {}
            for l in string.gmatch( l, '(%S+)' ) do
                node[ #node ][ i ] = tostring(l)
                i = i + 1
            end
            print( node[#node][1], node[#node][2], node[#node][3], node[#node][4] )
        end
        if( #node > 0 ) then
            for i = 1, #node do
                id_list[ node[i][1] ] = i
            end
        end
        f:close()
        --Update nodes
        for i = 1, #node do
            if( self.node.id_list[ node[i][1] ] ~= 1 ) then
                --Creates
                self.node:add_row( { tostring( node[i][1] ), node[i][2], node[i][3], node[i][4] } )
                self.node.id_list[ node[i][1] ] = 1
                self.node.linkage[ node[i][1] ] = {}
                self.node:update()
            else
                --Updates
                for i = 1, self.node.data.itens do
                    local row = self.node.data:get( i )
                    if( node[i] ~= nil ) then
                        if( row[1] == tostring( node[i][1] ) ) then
                            row[2] = node[i][2]
                            row[3] = node[i][3]
                            row[4] = node[i][4]
                        end
                    end
                end
            end
        end
        self.node:update()
        --Update elements
        self:update_elemente_data()
        dialog:destroy()
    elseif( dialog:run() == gtk.RESPONSE_CANCEL ) then
        dialog:destroy()
    end
end

--Add element
function FEM:add_element( indirect, data, explicit )
    --Indirect mode, for importing data, interpolations, etc
    --data = { id, node1_id, node2_id, material, z_axis }
    if( indirect == true ) then
        local id
        if( data[ 1 ] == nil ) or ( data[ 1 ] == "" ) then
            id = self:unique_id( "element", nil )
        else
            id = tostring( data[ 1 ] )
            self.element.id_list[ id ] = 1
        end
        local node1_id = data[ 2 ]
        local node2_id = data[ 3 ]
        local node1, node2
        for i = 1, self.node.data.itens do
            local row = self.node.data:get( i )
            if( row[ 1 ] == node1_id ) then
                node1 = { row[ 2 ], row[ 3 ], row[ 4 ] }
            elseif( row[ 1 ] == node2_id ) then
                node2 = { row[ 2 ], row[ 3 ], row[ 4 ] }
            end
        end
        self.node.linkage[ node1_id ][ id ] = 1
        self.node.linkage[ node2_id ][ id ] = 1
        local vet    = vector.new( node1, node2 )
        local length = vet.abs
        local z_axis = vector.new( nil, nil, {0,0,0} )
        z_axis:scan( data[ 5 ] )
        if( z_axis == nil ) then
            z_axis = vector.new( nil, nil, { 0,0,1 } )
        end
        if( data[ 4 ] ~= "" ) and ( data[ 4 ] ~= nil ) then
            local material_name = data[ 4 ]
            local mat           = material.lib[ material_name ]
            local element_type  = mat.element_type
            if( element_type == "Standard" ) then
                local mass          = (( mat.area/1000000 )*( length/1000 ))*mat.density
                self.element:add_row( { id, node1_id, node2_id, material_name, element_type, length, z_axis:print(), mass, mat.area, mat.Iyy, mat.Izz, mat.polar, mat.E, mat.G } )
                --print( OI ,self.element:update() )
            end
        else
            self.element:add_row( { id, node1_id, node2_id, "", "", length, z_axis:print(), "", "", "", "", "", "", "" } )
        end
        --self.element:update()
        return nil
    end
    --Checks if there's two nodes selected
    local table = self.node:get_selected()
    if( #table == 2 ) then
        --Adds material name
        local mat = fem.tool.material_combobox:get_active_text()
        --For element type
        local type
        if( material.lib[ mat ].type == "Spring" ) then type = "Spring"
        elseif( material.lib[ mat ].variable == true ) then type = "Variable Section"
        else type = "Standard" end
        --Adds id
        local id = self:unique_id( "element", nil )
        --Adds node 1 and 2 and updates node.linkage table
        local node1 = self.node.data:get( table[ 1 ] )[ 1 ]
        local node2 = self.node.data:get( table[ 2 ] )[ 1 ]
        self.node.linkage[ node1 ][ id ] = 1
        self.node.linkage[ node2 ][ id ] = 1
        --Adds length (Implement element as a vector class for calculations)
        local pnt1 = {}
        local i
        local pnt2 = {}
        for i = 1, 3 do
            pnt1[ i ] = self.node.data:get( table[ 1 ] )[ i + 1 ]
            pnt2[ i ] = self.node.data:get( table[ 2 ] )[ i + 1 ]
        end
        local vet = vector.new( pnt1, pnt2 )
        length = vet.abs
        local z_axis = vector.new( nil, nil, { 0,0,1 } )
        --Adds mass
        local mass = (( material.lib[ mat ].area/1000000 )*( length/1000 ))*material.lib[ mat ].density
        self.element:add_row( { id, node1, node2, mat, type, length, z_axis:print(), mass, material.lib[ mat ].area, material.lib[ mat ].Iyy, material.lib[ mat ].Izz, material.lib[ mat ].polar, material.lib[ mat ].E, material.lib[ mat ].G } )
        self.element:update()
        return nil
    end
end

function FEM:change_material( selection, mat )
    --If input is by selection
    if( #selection > 0 ) then
        for i = 1, #selection do
            local row = self.element.data:get( selection[ i ] )
            local length = row[ 6 ]
            row[ 4 ] = mat --Material name
            mat = material.lib[ mat ]
            if( mat.element_type == "Standard" ) then --For Standard elements
                row[ 5 ] = "Standard"
                row[ 7 ] = (( mat.area/1000000 )*( length/1000 ))*mat.density -- Mass
                --Other properties
                row[ 8 ] = mat.area
                row[ 9 ] = mat.Iyy
                row[ 10 ] = mat.Izz
                row[ 11 ] = mat.polar
                row[ 12 ] = mat.E
                row[ 13 ] = mat.G
            end
        end
    end
    self.element:update()
end

function FEM:delete_element( selection )
    if( #selection > 0 ) then
        local i
        for i = 1, #selection do
            local row = self.element.data:get( selection[ i ] )
            self.element.id_list[ tostring( row[ 1 ] ) ] = nil --Clears id
            self.node.linkage[ row[ 2 ] ][ row[ 1 ] ] = nil --Clears node 1 link
            self.node.linkage[ row[ 3 ] ][ row[ 1 ] ] = nil --Clears node 2 link
            self.element.data:remove( selection[ i ] )
        end
    end
    self.element:update()
end

function FEM:update_elemente_data() --Recalculates all elemente data when nodes are changed
    local element = self.element.data
    for i = 1, element.itens do
        local row = element:get( i )
        local id = row[1]
        local node1_id = row[ 2 ]
        local node2_id = row[ 3 ]
        local node1, node2
        for i = 1, self.node.data.itens do
            local row = self.node.data:get( i )
            if( row[ 1 ] == node1_id ) then
                node1 = { row[ 2 ], row[ 3 ], row[ 4 ] }
            elseif( row[ 1 ] == node2_id ) then
                node2 = { row[ 2 ], row[ 3 ], row[ 4 ] }
            end
        end
        local vet    = vector.new( node1, node2 )
        local length = vet.abs
        local material_name = row[ 4 ]
        local mat           = material.lib[ material_name ]
        local element_type  = mat.element_type
        if( element_type == "Standard" ) then
            local mass          = (( mat.area/1000000 )*( length/1000 ))*mat.density
            row[ 6 ] = length
            row[ 8 ] = mass
        end
    end
end

function FEM:add_constraint( selected, direct )
    --Constraint input by GUI
    if( direct == false ) then
    local i
        for i = 1, #selected do
            local row = self.node.data:get( selected[ i ] )
            if( self.constraint.node[ row[ 1 ] ] == nil ) then
                self.constraint.node[ row[ 1 ] ] = 1
                self.constraint:add_row( { row[ 1 ], false, false, false, false, false, false } )
            end
        end
    else
        local row = selected --Just one at a time
        self.constraint:add_row( { row[ 1 ], row[ 2 ], row[ 3 ], row[ 4 ], row[ 5 ], row[ 6 ], row[ 7 ] } )
    end
    self.constraint:update()
end

function FEM:delete_constraint( selected, direct )
    --Constraint input by GUI
    if( direct == false ) then
    local i
        for i = 1, #selected do
            local row = self.constraint.data:get( selected[ i ] )
            self.constraint.node[ row[ 1 ] ] = nil
            self.constraint.data:remove( selected[ i ] )
        end
    end
    self.constraint:update()
end

function FEM:add_load( data )
    --data = { id, node, value, direction }
    self.load:add_row( { data[1] , data[2], data[3], data[4]} )
    self.load:update()
end

function FEM:add_inertia_loads( a ) --a is a vector, but not the Class vector
    local elem = self.element.data
    for i = 1, elem.itens do
        local data = {}
        local row = elem:get( i )
        local node1 = row[2]
        local node2 = row[3]
--        for i = 1, self.node.data.itens do
--            local row2 = self.node.data:get( i )
--            if( row2[ 1 ] == row[2] ) then
--                node1 = { row2[ 2 ], row2[ 3 ], row2[ 4 ] }
--            elseif( row2[ 1 ] == row[3] ) then
--                node2 = { row2[ 2 ], row2[ 3 ], row2[ 4 ] }
--            end
--        end
        local mass = row[8]/2
        for i = 1, 3 do
            local dir
            if( i == 1 ) then dir = "x (translation)" elseif( i == 2 ) then dir = "y (translation)"  else dir = "z (translation)" end
            if( a[i] ~= 0 ) then
                self:add_load( {"G_"..node1, node1, mass*a[i], dir} )
                self:add_load( {"G_"..node2, node2, mass*a[i], dir} )
            end
        end
    end
    --local f = io.open( config.program_directory.."\\Load.xls", 'w' )
    --local node = self.load.data
    --for i = 1, node.itens do
    --    local row = node:get( i )
    --    f:write( row[1].."\t"..row[2].."\t"..row[3].."\t"..row[4].."\n" )
    --end
    --f:close()
end

function FEM:delete_load( selected )
    local i
    for i = 1, #selected do
        local row = self.load.data:get( selected[ i ] )
        self.load.id_list[ tostring( row[ 1 ] ) ] = nil --Clears id
        self.load.data:remove( selected[ i ] )
    end
    self.load:update()
end

function FEM:load_dialog()
    function build_F_M( type )
        local self = {}
        self.vbox  = gtk.VBox.new( false, 5 )
        self.hbox1 = gtk.HBox.new( false, 5 )
        self.hbox2 = gtk.HBox.new( false, 5 )
        self.hbox3 = gtk.HBox.new( false, 5 )
        self.x_label = gtk.Label.new( Label.FEM.load_Xaxis )
        self.y_label = gtk.Label.new( Label.FEM.load_Yaxis )
        self.z_label = gtk.Label.new( Label.FEM.load_Zaxis )
        self.x_sep = gtk.VSeparator.new()
        self.y_sep = gtk.VSeparator.new()
        self.z_sep = gtk.VSeparator.new()
        self.x_lab = gtk.Label.new( Label.FEM.load_2nd_prefix )
        self.y_lab = gtk.Label.new( Label.FEM.load_2nd_prefix )
        self.z_lab = gtk.Label.new( Label.FEM.load_2nd_prefix )
        self.x_id = gtk.Entry.new()
        self.y_id = gtk.Entry.new()
        self.z_id = gtk.Entry.new()
        self.x_v = gtk.Label.new( Label.FEM.load_value )
        self.y_v = gtk.Label.new( Label.FEM.load_value )
        self.z_v = gtk.Label.new( Label.FEM.load_value )
        self.x = gtk.Entry.new()
        self.y = gtk.Entry.new()
        self.z = gtk.Entry.new()

        self.x_id:set( "width-request", 30, "text", type.."x" )
        self.y_id:set( "width-request", 30, "text", type.."y" )
        self.z_id:set( "width-request", 30, "text", type.."z" )
        self.x:set( "width-request", 60, "text", "0" )
        self.y:set( "width-request", 60, "text", "0" )
        self.z:set( "width-request", 60, "text", "0" )

        self.hbox1:pack_start( self.x_label, false, false, 1 )
        self.hbox1:pack_start( self.x_sep, false, false, 1 )
        self.hbox1:pack_start( self.x_lab, false, false, 1 )
        self.hbox1:pack_start( self.x_id, false, false, 1 )
        self.hbox1:pack_start( self.x_v, false, false, 1 )
        self.hbox1:pack_start( self.x, false, false, 1 )
        self.hbox2:pack_start( self.y_label, false, false, 1 )
        self.hbox2:pack_start( self.y_sep, false, false, 1 )
        self.hbox2:pack_start( self.y_lab, false, false, 1 )
        self.hbox2:pack_start( self.y_id, false, false, 1 )
        self.hbox2:pack_start( self.y_v, false, false, 1 )
        self.hbox2:pack_start( self.y, false, false, 1 )
        self.hbox3:pack_start( self.z_label, false, false, 1 )
        self.hbox3:pack_start( self.z_sep, false, false, 1 )
        self.hbox3:pack_start( self.z_lab, false, false, 1 )
        self.hbox3:pack_start( self.z_id, false, false, 1 )
        self.hbox3:pack_start( self.z_v, false, false, 1 )
        self.hbox3:pack_start( self.z, false, false, 1 )


        self.vbox:pack_start( self.hbox1, false, false, 1 )
        self.vbox:pack_start( self.hbox2, false, false, 1 )
        self.vbox:pack_start( self.hbox3, false, false, 1 )
        return self
    end
    --
    local window    = gtk.Window.new()
    local main_vbox = gtk.VBox.new( false, 5 )
    --First line
    local hbox1     = gtk.HBox.new( false, 5 )
    local id_prefix = gtk.Entry.new()
    local sep1      = gtk.HSeparator.new()

    --Frame line
    local hbox_frame = gtk.HBox.new( false, 5 )
    local F_frame    = gtk.Frame.new( Label.FEM.load_F_frame )
    local F_vbox     = gtk.VBox.new( false, 5 )

    local M_frame    = gtk.Frame.new( Label.FEM.load_M_frame )
    local M_vbox     = gtk.VBox.new( false, 5 )
    local sep2       = gtk.HSeparator.new()

    --Forces and moment
    local force  = build_F_M( "F" )
    F_frame:add( force.vbox )
    local moment = build_F_M( "M" )
    M_frame:add( moment.vbox )

    --Button
    local hbox_b = gtk.HBox.new( false, 5 )
    local apply  = build_button( 1, "gtk-apply", Label.FEM.load_apply, "all", std.icon_size )
    hbox_b:pack_start( apply, false, false, 1 )

    --
    window:set_title( Label.FEM.load_window )
    id_prefix:set( "width-request", 100 )

    --
    window:connect( "delete-event", function() window:destroy() end )
    apply:connect ( "clicked", function()
                               local prefix = id_prefix:get_text()
                               local type = "x"
                               local node
                               local selected = self.node:get_selected()
                               if( selected ~= nil ) then
                                for i = 1, #selected do
                                    node = self.node.data:get( selected[ i ] )[ 1 ]
                                    while( true ) do
                                        if( force[ type ]:get_text() ~= "0" ) then
                                            local id = prefix.."_"..force[ type.."_id" ]:get_text()
                                            id = self:unique_id( "load", id )
                                            self:add_load( { id, node, force[ type ]:get_text(), type.." (translation)" } )
                                        end
                                        if( type == "x" ) then type = "y"
                                        elseif( type == "y" ) then type = "z"
                                        else type = "x" break end
                                    end
                                    while( true ) do
                                        if( moment[ type ]:get_text() ~= "0" ) then
                                            local id = prefix.."_"..moment[ type.."_id" ]:get_text()
                                            id = self:unique_id( "load", id )
                                            self:add_load( { id, node, moment[ type ]:get_text(), type.." (rotation)" } )
                                        end
                                        if( type == "x" ) then type = "y"
                                        elseif( type == "y" ) then type = "z"
                                        else type = "x" break end
                                    end
                                end
                               end
                               end )

    --
    hbox1:pack_start( Label.FEM.load_id_prefix, false, false, 1 )
    hbox1:pack_start( id_prefix, false, false, 1 )
    hbox_frame:pack_start( F_frame, false, false, 1 )
    hbox_frame:pack_start( M_frame, false, false, 1 )

    main_vbox:pack_start( hbox1, false, false, 1 )
    main_vbox:pack_start( sep1, false, false, 1 )
    main_vbox:pack_start( hbox_frame, false, false, 1 )
    main_vbox:pack_start( sep2, false, false, 1 )
    main_vbox:pack_start( hbox_b, false, false, 1 )
    window:add( main_vbox )
    window:show_all()
end

function FEM:inertia_loads_dialog()
    local window    = gtk.Window.new()
    local main_hbox = gtk.HBox.new( false, 5 )
    local label     = gtk.Label.new( Label.FEM.acceleration_v )
    local x         = gtk.Entry.new()
    local y         = gtk.Entry.new()
    local z         = gtk.Entry.new()
    local ok        = build_button( 1, "gtk-apply", Label.button_ok, "all", std.icon_size )

    window:set_title( Label.FEM.inertia_loads )
    x:set( "width-request", 50, "text", config.default_inertia_acc_x )
    y:set( "width-request", 50, "text", config.default_inertia_acc_y )
    z:set( "width-request", 50, "text", config.default_inertia_acc_z )

    window:connect( "delete-event", function() window:destroy() end )
    ok:connect( "clicked", function()
                                self:add_inertia_loads( { tonumber(x:get_text()), tonumber(y:get_text()), tonumber(z:get_text()) } )
                                window:destroy()
                           end )

    main_hbox:pack_start( label, false, false, 1 )
    main_hbox:pack_start( x, false, false, 1 )
    main_hbox:pack_start( y, false, false, 1 )
    main_hbox:pack_start( z, false, false, 1 )
    main_hbox:pack_start( ok, false, false, 1 )
    window:add( main_hbox )
    window:show_all()
end

function FEM:build_ElementType_objects()--Does what pre_check does, but for results loading
    Element[ self.name ] = {}
    local elements = self.element.data
    local id_list = {}
    for i = 1, elements.itens do
        local row = elements:get( i )
        if( id_list[ row[1] ] == nil ) then
            id_list[ row[1] ] = i
        else
            print( "ElementType objects aborted! Same id elements found" )
            return nil
        end
    end
    print( "\nElements loading" )
    for i = 1, elements.itens do
        local row = elements:get( i )
        local node1, node2
        local data = {}
        for i = 1, self.node.data.itens do
            local row2 = self.node.data:get( i )
            if( row2[ 1 ] == row[2] ) then
                node1 = { row2[ 2 ], row2[ 3 ], row2[ 4 ] }
                data.node1_id = row2[ 1 ]
                data.node1 = { row2[ 2 ], row2[ 3 ], row2[ 4 ] }
            elseif( row2[ 1 ] == row[3] ) then
                node2 = { row2[ 2 ], row2[ 3 ], row2[ 4 ] }
                data.node2_id = row2[ 1 ]
                data.node2 = { row2[ 2 ], row2[ 3 ], row2[ 4 ] }
            end
        end
        local direction = vector.new( node1, node2 )
        local z_dir     = vector.new( {0,0,0}, {0,0,1} )
        direction:normalize()
        direction = vector.new( nil, nil, direction.unit )
        z_dir:scan( row[ 7 ] )
        z_dir:normalize()
        z_dir = vector.new( nil, nil, z_dir.unit )
        --print( direction:print(), z_dir:print() )
        if( z_dir:dot( direction ) ~= 0 ) then
            print( "------WARNING: Element "..row[1].." x and z vectors aren't orthogonal!\n" )
            ortho_error = 1
        end
        --print( z_dir.unit[1],z_dir.unit[2],z_dir.unit[3]  )-- ,z_dir:scan( row[ 7 ] )[2],z_dir:scan( row[ 7 ][3] ) )
        --Directions
        data.x_axis = direction
        data.z_axis = z_dir
        --Element info
        local mat          = material.lib[ row[ 4 ] ]
        local element_type = row[ 5 ]
        if( element_type == "Standard" ) then
            data.E   = mat.E
            data.A   = mat.area
            data.L   = row[6]
            data.G   = mat.G
            data.fsy = mat.f_shear_y
            data.fsz = mat.f_shear_z
            data.Izz = mat.Izz
            data.Iyy = mat.Iyy
            data.J   = mat.polar
            data.ft  = mat.f_torsion
            data.geom = mat.geom
            data.fail = tonumber( mat.fail )
            data.fail_type = mat.fail_type
            if( data.geom == "Rectangular" ) then
                data.width  = mat.width
                data.height = mat.height
            elseif( data.geom == "Circular" ) then
                data.diameter = mat.diameter
            elseif( data.geom == "Tubular" ) then
                data.in_diameter  = mat.in_diameter
                data.out_diameter = mat.out_diameter
            end
        end
        Element[ self.name ][ row[1] ] = ElementType[ element_type ]:new( data )
    end
end

function FEM:pre_check( view, buffer, iter ) --View is a text view
    function gtk.TextView:print( text )
        local buffer = self:get( "buffer" )
        local iter   = gtk.TextIter.new()
        buffer:get_end_iter( iter )
        return buffer:insert( iter, text, -1 )
    end
    local ortho_error = 0
    view:print( "Checking for data entry errors and building simulation variables...\n" )
    local id_list = {}
    --Node verification
    local nodes = self.node.data
    for i = 1, nodes.itens do
        local row = nodes:get( i )
        if( id_list[ row[1] ] == nil ) then
            id_list[ row[1] ] = i
        else
            --Failure
            view:print( "---Simulation Aborted!\n" )
            view:print( "!!!Node with same id found! Make sure all node IDs are unique\n" )
            return nil
        end
    end
    Stiff[ self.name ] = STIFF:new( { rows = nodes.itens*6,
                                      columns = nodes.itens*6,
                                      id = id_list,
                                    } )
    view:print( "---Stiffness matrix successfully allocated with "..nodes.itens.." nodes\n")
    --I know it's a square matrix
    view:print( "---Stiffness matrix size = "..Stiff[ self.name ].rows.." x "..Stiff[ self.name ].columns.."\n" )
    --Element verification
    Element[ self.name ] = {}
    local elements = self.element.data
    local id_list = {}
    for i = 1, elements.itens do
        local row = elements:get( i )
        if( id_list[ row[1] ] == nil ) then
            id_list[ row[1] ] = i
        else
            --Failure
            view:print( "---Simulation Aborted!\n" )
            view:print( "!!!Element with same id found! Make sure all elements IDs are unique\n" )
            return nil
        end
    end
    view:print( "---Creating elements\n" )
    --print( "\n\nElements\n" )
    for i = 1, elements.itens do
        local row = elements:get( i )
        local node1, node2
        local data = {}
        for i = 1, self.node.data.itens do
            local row2 = self.node.data:get( i )
            if( row2[ 1 ] == row[2] ) then
                node1 = { row2[ 2 ], row2[ 3 ], row2[ 4 ] }
                data.node1_id = row2[ 1 ]
                data.node1 = { row2[ 2 ], row2[ 3 ], row2[ 4 ] }
            elseif( row2[ 1 ] == row[3] ) then
                node2 = { row2[ 2 ], row2[ 3 ], row2[ 4 ] }
                data.node2_id = row2[ 1 ]
                data.node2 = { row2[ 2 ], row2[ 3 ], row2[ 4 ] }
            end
        end
        local direction = vector.new( node1, node2 )
--        print( 'direction', direction:print() )
        local z_dir     = vector.new( {0,0,0}, {0,0,1} )
        direction:normalize()
        direction = vector.new( nil, nil, direction.unit )
        z_dir:scan( row[ 7 ] )
        z_dir:normalize()
        z_dir = vector.new( nil, nil, z_dir.unit )
--        print( 'angle', math.acos( z_dir:dot( direction ) ) )
        --print( direction:print(), z_dir:print() )
--        print( 'z_vector', z_dir:dot( direction ) )
        if( z_dir:dot( direction ) > 0.005 ) or ( z_dir:dot( direction ) < -0.005 ) then
            view:print( "------WARNING: Element "..row[1].." x and z vectors aren't orthogonal! ".."dotValue = "..z_dir:dot( direction ).."\n" )
            ortho_error = 1
        end
        --print( z_dir.unit[1],z_dir.unit[2],z_dir.unit[3]  )-- ,z_dir:scan( row[ 7 ] )[2],z_dir:scan( row[ 7 ][3] ) )
        --Directions
        data.x_axis = direction
        data.z_axis = z_dir
        --Element info
        local mat          = material.lib[ row[ 4 ] ]
        local element_type = row[ 5 ]
        if( element_type == "Standard" ) then
            data.E   = mat.E
            data.A   = mat.area
            data.L   = row[6]
            data.G   = mat.G
            data.fsy = mat.f_shear_y
            data.fsz = mat.f_shear_z
            data.Izz = mat.Izz
            data.Iyy = mat.Iyy
            data.J   = mat.polar
            data.ft  = mat.f_torsion
            data.fail = tonumber( mat.fail )
            data.fail_type = mat.fail_type
            data.geom = mat.geom
            if( data.geom == "Rectangular" ) then
                data.width  = mat.width
                data.height = mat.height
            elseif( data.geom == "Circular" ) then
                data.diameter = mat.diameter
            elseif( data.geom == "Tubular" ) then
                data.in_diameter  = mat.in_diameter
                data.out_diameter = mat.out_diameter
            end
        end
        Element[ self.name ][ row[1] ] = ElementType[ element_type ]:new( data )
    end
    view:print( "---Elements local and global stiffness matrices created\n" )
    view:print( "---Generating scenario global stiffness matrix\n" )
    Stiff[ self.name ]:build( Element[ self.name ] )
    view:print( "---Global stiffness matrix successfully generated!\n" )
--    Stiff[ self.name ]:export_to_Excel( "Stiff" )
    view:print( "---Creating load vector\n" )
    local loads = self.load.data
    local data_list = {}
    for i = 1, loads.itens do
        data_list[ i ] = loads:get( i )
    end
    Load[ self.name ] = LOAD:new( { rows = Stiff[ self.name ].rows, columns = 1 }  )
    Load[ self.name ]:build( data_list, Stiff[ self.name ].id )
    view:print( "---Load vector created\n" )
    view:print( "---Applying constraints\n" )
    nodes = {}
    local dof = {}
    local constraints = self.constraint.data
    local const_type = {}
    for i = 1, constraints.itens do
        local row = constraints:get( i )
        nodes[ i ] = row[1]
        dof[ i ] = {}
        for j = 1, 6 do
            dof[ i ][ j ] = row[ j + 1 ]
        end
        const_type[ i ] = "zero"
    end
    Stiff[ self.name ]:apply_constraints( nodes, dof, const_type, Load[ self.name ] )
    view:print( "\nSimulation pre-check completed!\n" )
    if( ortho_error == 1 ) then
        view:print( "!!!Non-orthogonal x and z vectors were found in one or more elements!\n" )
        view:print( "Simulation aborted\n" )
        return false
    else
        view:print( "Ready to run simulation\n" )
        return true
    end
end

function FEM:run_dialog()
    --
    local window      = gtk.Window.new()
    local vbox        = gtk.VBox.new( false, 5 )
    local frame_view  = gtk.Frame.new( "Run setup info" )
    local view        = gtk.TextView.new()
    local buffer      = view:get( "buffer" )
    local iter        = gtk.TextIter.new()
    local sep         = gtk.HSeparator.new()
    local hbox        = gtk.HBox.new( false, 5 )
    local run         = build_button( 1, "gtk-execute", Label.FEM.run_button, "all", std.icon_size )
    local cancel      = build_button( 1, "gtk-cancel", Label.button_cancel, "all", std.icon_size )
    local open_script = build_button( 1, "gtk-open", Label.FEM.open_script, "all", std.icon_size )

    --
    window:set_title( Label.FEM.run_window )
    view:set( "width-request", 400, "height-request", 300, "editable", false )
    run:set( "sensitive", false )

    --
    window:connect( "delete-event", function() window:destroy() end )
    run:connect( "clicked", function()
                                window:destroy()
                                Sim[ self.name ] = SIM:new( { name = self.name } )
                                Sim[ self.name ]:run()
                                fem.tool.view:set( "sensitive", true )
                            end )
    cancel:connect( "clicked", function() window:destroy() end )

    --
    frame_view:add( view )

    hbox:pack_start( run, false, false, 1 )
    hbox:pack_start( cancel, false, false, 1 )
    hbox:pack_start( open_script, false, false, 1 )

    vbox:pack_start( frame_view, false, false, 1 )
    vbox:pack_start( sep, false, false, 1 )
    vbox:pack_start( hbox, false, false, 1 )
    window:add( vbox )
    window:show_all()

    local bool = self:pre_check( view, buffer, iter )
    run:set( "sensitive", bool )
end

function FEM:get_scenarios_with_results()
    local names = {}
    for k, v in pairs( Res ) do
        names[ #names + 1 ] = k
    end
    return names
end

--NOT REALLY EXCEL, BUT TAB SEPARATED VALUES FILE
function FEM:export_results_txt_excel( filename )
    local f = io.open( filename, 'w' )
    f:write( "Element\tNode 1\tNode 2\tFailed ?\tMax Stress [MPa]\tPercentage of failure stress\tBuckling? (-1 is no)\tMass [kg]\tAxial stress [MPa]\tShear stress [MPa]\tTorsion stress [MPa]\tFlexion stress [MPa]\tMax Pure shear [MPa]\t\tNx node 1\tVy node 1\tVz node 1\tTx node 1\tMy node 1\tMz node 1\tNx node 2\tVy node 2\tVz node 2\tTx node 2\tMy node 2\tMz node 2\n" )
    for i = 1, self.element.data.itens do
        local row = self.element.data:get( i )
        f:write( ""..row[1].."\t"..row[2].."\t"..row[3].."\t"..tostring(Element[ self.name ][ row[1]].has_failed).."\t"..Element[ self.name ][row[1]].max_stress.."\t"..Element[ self.name ][row[1]].normalized_stress.."\t"
                   ..Element[ self.name ][row[1]].buckling_stress.."\t"..row[8].."\t"..Element[ self.name ][row[1]].critical[1].."\t"..Element[ self.name ][ row[1] ].critical[2].."\t"
                   ..Element[ self.name ][ row[1] ].critical[3].."\t"..Element[ self.name ][ row[1] ].critical[4].."\t"..Element[ self.name ][ row[1] ].max_shear.."\t\t"
                   ..Element[ self.name ][ row[1] ].internal_loads[1][1].."\t"..Element[ self.name ][ row[1] ].internal_loads[2][1].."\t"..Element[ self.name ][ row[1] ].internal_loads[3][1].."\t"
                   ..Element[ self.name ][ row[1] ].internal_loads[4][1].."\t"..Element[ self.name ][ row[1] ].internal_loads[5][1].."\t"..Element[ self.name ][ row[1] ].internal_loads[6][1].."\t"
                   ..Element[ self.name ][ row[1] ].internal_loads[7][1].."\t"..Element[ self.name ][ row[1] ].internal_loads[8][1].."\t"..Element[ self.name ][ row[1] ].internal_loads[9][1].."\t"
                   ..Element[ self.name ][ row[1] ].internal_loads[10][1].."\t"..Element[ self.name ][ row[1] ].internal_loads[11][1].."\t"..Element[ self.name ][ row[1] ].internal_loads[12][1]..
                   "\n" )
    end
    f:write( "\n\n" )
    f:write( "Node\tx (disp)\ty (disp)\tz (disp)\trotx (disp)\troty (disp)\trotz (disp)\n" )
    for i = 1, self.node.data.itens do
        local row  = self.node.data:get( i )
        local n_id = i
        f:write( ""..row[1].."\t"..Res[self.name].disp[ (n_id*6 - 5) ][1].."\t"..Res[self.name].disp[ (n_id*6 - 4) ][1].."\t"..Res[self.name].disp[ (n_id*6 - 3) ][1].."\t"
                   ..Res[self.name].disp[ (n_id*6 - 2) ][1].."\t"..Res[self.name].disp[ (n_id*6 - 1) ][1].."\t"..Res[self.name].disp[ n_id*6 ][1].."\n" )
    end
    f:close()
end

function FEM:view_results_dialog()
    self.res.window    = gtk.Window.new()
    self.res.main_vbox = gtk.VBox.new( false, 5 )
    --Scenario line (1)
    self.res.hbox1           = gtk.HBox.new( false, 5 )
    self.res.sce_combo_label = gtk.Label.new( Label.FEM.sce_combo_label )
    self.res.sce_combobox    = gtk.ComboBox.new_text()
    local names              = self.get_scenarios_with_results()
    self.res.sep1            = gtk.HSeparator.new()
    self.res.mass_label      = gtk.Label.new( Label.FEM.total_mass )
    self.res.mass_entry      = gtk.Entry.new()
    self.res.save_results    = build_button( 0, "Icons\\Export-20.png", Label.FEM.save_results, "all", std.icon_size )
    --Displacement results
    self.res.hbox2      = gtk.HBox.new( false, 5 )
    self.res.disp_label = gtk.Label.new( Label.FEM.disp_label )
    self.res.sep2            = gtk.HSeparator.new()
    --Deformed mesh
    self.res.hbox3           = gtk.HBox.new( false, 5 )
    self.res.def_label       = gtk.Label.new( Label.FEM.def_label )
    self.res.def_gmsh        = build_button( 1, "gtk-convert", Label.FEM.view_on_gmsh, "all", std.icon_size )
    self.res.def_scale_label = gtk.Label.new( Label.FEM.scale )
    self.res.def_scale_entry = gtk.Entry.new()
    self.res.sep3            = gtk.HSeparator.new()
    --Stresses
    self.res.hbox4        = gtk.HBox.new( false, 5 )
    self.res.stress_label = gtk.Label.new( Label.FEM.stress_label )
    self.res.stress_gmsh  = build_button( 1, "gtk-convert", Label.FEM.view_on_gmsh, "all", std.icon_size )
    self.res.stress_frame = gtk.Frame.new( Label.FEM.res_options )
    self.res.opt_hbox     = gtk.HBox.new( false, 5 )
    self.res.opt_vbox1     = gtk.VBox.new( false, 5 )
    self.res.opt_vbox2     = gtk.VBox.new( false, 5 )
    self.res.opt_vbox3     = gtk.VBox.new( false, 5 )
    self.res.opt_vbox4     = gtk.VBox.new( false, 5 )
        self.res.stress_frame:add   ( self.res.opt_hbox )
        self.res.opt_hbox:pack_start( self.res.opt_vbox1, false, false, 1 )
        self.res.opt_hbox:pack_start( self.res.opt_vbox2, false, false, 1 )
        self.res.opt_hbox:pack_start( self.res.opt_vbox3, false, false, 1 )
        self.res.opt_hbox:pack_start( self.res.opt_vbox4, false, false, 1 )
    self.res.stress_fail   = gtk.RadioButton.new_with_label( nil, Label.FEM.stress_fail )
    self.res.stress_normal = self.res.stress_fail:new_with_label_from_widget( Label.FEM.stress_normal )
    self.res.stress_shear  = self.res.stress_fail:new_with_label_from_widget( Label.FEM.stress_shear )
        self.res.opt_vbox1:pack_start( self.res.stress_fail, false, false, 1 )
        self.res.opt_vbox1:pack_start( self.res.stress_normal, false, false, 1 )
        self.res.opt_vbox1:pack_start( self.res.stress_shear, false, false, 1 )
    self.res.normalized    = gtk.CheckButton.new_with_label( Label.FEM.normalized )
    self.res.with_buckling = gtk.CheckButton.new_with_label( Label.FEM.with_buckling )
    self.res.no_fail       = gtk.CheckButton.new_with_label( Label.FEM.no_fail )
        self.res.opt_vbox2:pack_start( self.res.normalized, false, false, 1 )
        self.res.opt_vbox2:pack_start( self.res.with_buckling, false, false, 1 )
        self.res.opt_vbox2:pack_start( self.res.no_fail, false, false, 1 )
    self.res.stress_deformed = gtk.CheckButton.new_with_label( Label.FEM.def_label )
    self.res.stress_scale_hbox  = gtk.HBox.new( false, 5 )
    self.res.stress_scale_label = gtk.Label.new( Label.FEM.scale )
    self.res.stress_scale_entry = gtk.Entry.new()
    self.res.stress_scale_hbox:pack_start( self.res.stress_scale_label, false, false, 1 )
    self.res.stress_scale_hbox:pack_start( self.res.stress_scale_entry, false, false, 1 )
        self.res.opt_vbox3:pack_start( self.res.stress_deformed, false, false, 1 )
        self.res.opt_vbox3:pack_start( self.res.stress_scale_hbox, false, false, 1 )
    self.res.with_node_id  = gtk.CheckButton.new_with_label( Label.FEM.with_node_id )
    self.res.with_elem_id  = gtk.CheckButton.new_with_label( Label.FEM.with_elem_id )
        self.res.opt_vbox4:pack_start( self.res.with_node_id, false, false, 1 )
        self.res.opt_vbox4:pack_start( self.res.with_elem_id, false, false, 1 )
    self.res.sep4          = gtk.HSeparator.new()


    local Mass = 0
    for i = 1, self.element.data.itens do
        local row = self.element.data:get( i )
        Mass = Mass + tonumber( row[8] )
    end
    self.res.mass_entry:set( "text", string.format( "%.6f kg", Mass ), "editable", false )
    self.res.window:set_title( Label.FEM.res_window )
    for k, v in ipairs( names ) do
        self.res.sce_combobox:append_text( v )
    end
    self.res.sce_combobox:set( "active", fem.notebook:get( "page" ) )
    self.res.def_scale_entry:set( "text", "1", "width-request", 25 )
    self.res.stress_scale_entry:set( "text", "1", "width-request", 25 )
    self.res.normalized:set( "active", false )
    self.res.with_buckling:set( "active", false )
    self.res.no_fail:set( "active", true )
    self.res.stress_deformed:set( "active", false )
    self.res.with_node_id:set( "active", true )
    self.res.with_elem_id:set( "active", true )

    self.res.window:connect( "delete-event", function() self.res.window:destroy() end )
    self.res.save_results:connect( "clicked",   function()
                                                    dialog = gtk.FileChooserDialog.new( "Export nodes", Main_window, gtk.FILE_CHOOSER_ACTION_SAVE,
                                                                                           "gtk-cancel", gtk.RESPONSE_CANCEL, "gtk-ok", gtk.RESPONSE_OK )
                                                        dialog:set_current_folder( config.working_directory )
                                                        if( dialog:run() == gtk.RESPONSE_OK ) then
                                                            local filename = dialog:get_filename()
                                                            self:export_results_txt_excel( filename )
                                                            dialog:destroy()
                                                        elseif( dialog:run() == gtk.RESPONSE_CANCEL ) then
                                                            dialog:destroy()
                                                        end
                                                end )
    self.res.def_gmsh:connect( "clicked", function()
                                            local scale = self.res.def_scale_entry:get_text()
                                            Res[ self.name ].scaled_nodes = Res[ self.name ]:build_displaced_nodes( scale )
                                            Res[ self.name ]:GMSH_view_plain_mesh( Res[ self.name ].scaled_nodes )
                                          end )
    self.res.stress_gmsh:connect( "clicked", function()
                                                local opt1 = self.res.stress_fail:get_active()
                                                local opt2 = {}
                                                local opt3 = {}
                                                local opt4 = {}
                                                local scale
                                                if( self.res.stress_fail:get_active() ) then opt1 = 1
                                                    elseif( self.res.stress_normal:get_active() ) then opt1 = 2
                                                    elseif( self.res.stress_shear:get_active() ) then opt1 = 3
                                                end
                                                opt2[1] = self.res.normalized:get_active()
                                                opt2[2] = self.res.with_buckling:get_active()
                                                opt2[3] = self.res.no_fail:get_active()
                                                opt3[1] = self.res.stress_deformed:get_active()
                                                opt3[2] = self.res.stress_scale_entry:get_text()
                                                opt4[1] = self.res.with_node_id:get_active()
                                                opt4[2] = self.res.with_elem_id:get_active()
                                                self:GMSH_view_stresses( opt1, opt2, opt3, opt4 )
                                             end )

    self.res.hbox1:pack_start( self.res.sce_combo_label, false, false, 1 )--
    self.res.hbox1:pack_start( self.res.sce_combobox, false, false, 1 )
    self.res.hbox1:pack_start( self.res.mass_label, false, false, 1 )
    self.res.hbox1:pack_start( self.res.mass_entry, false, false, 1 )
    self.res.hbox1:pack_start( self.res.save_results, false, false, 1 )
    self.res.hbox2:pack_start( self.res.disp_label, false, false, 1 )--
    self.res.hbox3:pack_start( self.res.def_label, false, false, 1 )--
    self.res.hbox3:pack_start( self.res.def_gmsh, false, false, 1 )
    self.res.hbox3:pack_start( self.res.def_scale_label, false, false, 1 )
    self.res.hbox3:pack_start( self.res.def_scale_entry, false, false, 1 )
    self.res.hbox4:pack_start( self.res.stress_label, false, false, 1 )--
    self.res.hbox4:pack_start( self.res.stress_gmsh, false, false, 1 )
    self.res.hbox4:pack_start( self.res.stress_frame, false, false, 1 )

    self.res.main_vbox:pack_start( self.res.hbox1, false, false, 1 )
    self.res.main_vbox:pack_start( self.res.sep1, false, false, 1 )
    self.res.main_vbox:pack_start( self.res.hbox2, false, false, 1 )
    self.res.main_vbox:pack_start( self.res.sep2, false, false, 1 )
    self.res.main_vbox:pack_start( self.res.hbox3, false, false, 1 )
    self.res.main_vbox:pack_start( self.res.sep3, false, false, 1 )
    self.res.main_vbox:pack_start( self.res.hbox4, false, false, 1 )
    self.res.main_vbox:pack_start( self.res.sep4, false, false, 1 )
    self.res.window:add( self.res.main_vbox )
    self.res.window:show_all()
end

--GMSH FUNCTIONS
function FEM:GMSH_view_mesh()
    if( self.GMSH_list.mesh == nil ) then
        self.GMSH_list.mesh = GMSH:new( {
                                        name         = self.name,
                                        node_data    = self.node.data,
                                        element_data = self.element.data,
                                        lc           = 0.009, --Point "thickness"
                                        load_data    = self.load.data,
                                        } )
    end
    self.GMSH_list.mesh:update()
    self.GMSH_list.mesh:export_and_view( "geometry" )
end

function FEM:GMSH_view_stresses( opt1, opt2, opt3, opt4 )
    local data = {}
    for k, v in pairs( Element[ self.name ] ) do
        data[k] ={}
        if( opt4 == true ) then --Deformed still doesn't deforms
            data[k][1] = v.node1[1]
            data[k][2] = v.node1[2]
            data[k][3] = v.node1[3]
            data[k][4] = v.node2[1]
            data[k][5] = v.node2[2]
            data[k][6] = v.node2[3]
        else
            data[k][1] = v.node1[1]
            data[k][2] = v.node1[2]
            data[k][3] = v.node1[3]
            data[k][4] = v.node2[1]
            data[k][5] = v.node2[2]
            data[k][6] = v.node2[3]
        end
        data[k][7] = k
        --Get value
        if( opt1 == 1 ) then data[k][8] = v.max_stress
        elseif( opt1 == 2  ) then data[k][8] = (v.critical[1] + v.critical[4])
        else data[k][8] = (v.critical[2] + v.critical[3])
        end
        --Modify value
        if( opt2[1] == true ) and ( opt2[3] == true ) then --Normalized with max_stress
            data[k][8] = data[k][8]/v.fail
            if( opt2[2] == true ) then
                if( v.buckling_stress <= v.fail ) and ( v.buckling_stress > 0 ) then
                    data[k][8] = -1
                    data[k][7] = data[k][7].."(F: buckling)"
                end
            end
            if( data[k][8] >= 1 ) then
                data[k][7] = data[k][7].."(F: "..data[k][8]..")"
            end
        elseif( opt2[1] == true ) then --Normalized only
            if( opt1 == 1 ) then data[k][8] = v.normalized_stress
                else data[k][8] = data[k][8]/v.fail
            end
            if( opt2[2] == true ) then
                if( v.buckling_stress <= v.fail ) and ( v.buckling_stress > 0 ) and ( v.max_stress >= v.buckling_stress ) then
                    print( ( v.buckling_stress <= v.fail ) and ( v.buckling_stress > 0 ) )
                    data[k][8] = -1
                    data[k][7] = data[k][7].."(F: buckling)"
                end
            end
            if( data[k][8] >= 1 ) then
                data[k][7] = data[k][7].."(F: "..data[k][8]..")"
                data[k][8] = 1
            end
        print( data[k][8] )
        elseif( opt2[3] == true ) and ( opt2[1] == false ) then --Plain result
            if( opt2[2] == true ) then
                if( v.buckling_stress <= v.fail ) and ( v.buckling_stress > 0 ) then
                    data[k][7] = data[k][7].."(F: buckling)"
                end
            end
            if( data[k][8] >= v.fail ) then
                data[k][7] = data[k][7].."(F: "..data[k][8]..")"
            end
        else
            print( "ERROR: scale not set" )
            return nil
        end
    end
    if( self.GMSH_list.stress == nil ) then
        self.GMSH_list.stress = GMSH:new( {
                                        name         = self.name,
                                        node_data    = self.node.data,
                                        element_data = self.element.data,
                                        lc           = 1, --Point "thickness"
                                        load_data    = self.load.data,
                                        } )
    end
    self.GMSH_list.stress:update()
    self.GMSH_list.stress:export_and_view( "post", data )
    --Will generate table = { node1x, node1y, node1z, node2x, node2y, node2z, element_id, value }
end

function fem.build()
    --Entities that are built by other functions, declared for reference above
    --toolbar
    fem.tool.add_scenario     = build_toolbutton( 0, "Icons\\tab_new_raised.png", Label.FEM.add_scenario, "all" )
    fem.tool.del_scenario     = build_toolbutton( 0, "Icons\\tab_remove.png", Label.FEM.del_scenario, "all" )
    --
    fem.tool.add_scenario:set_sensitive(false)
    fem.tool.del_scenario:set_sensitive(false)
    --
    fem.tool.add_node         = build_toolbutton( 1, "gtk-add", Label.FEM.add_node, "all" )
    fem.tool.pattern_add_node = build_toolbutton( 0, "Icons\\pattern_node_add.png", Label.FEM.pattern_add_node, "all" )
    fem.tool.delete_node      = build_toolbutton( 1, "gtk-cancel", Label.FEM.delete_node, "all" )
    fem.tool.add_constraint   = build_toolbutton( 0, "Icons\\constraint-add.png", Label.FEM.add_constraint, "all" )
    fem.tool.del_constraint   = build_toolbutton( 0, "Icons\\constraint-del.png", Label.FEM.del_constraint, "all" )
    fem.tool.view_mesh        = build_toolbutton( 1, "gtk-zoom-fit", Label.FEM.view_mesh, "all" )
    fem.tool.run              = build_toolbutton( 1, "gtk-execute", Label.FEM.run, "all" )
    fem.tool.view             = build_toolbutton( 1, "gtk-index", Label.FEM.view, "all" )
    --toolbar_1
    fem.tool.add_element_toogle = gtk.ToggleToolButton.new()
    fem.tool.material_set       = gtk.ToolItem.new()
    fem.tool.material_vbox      = gtk.VBox.new( false, 0 )
    --fem.tool.material_label     = Label.FEM.material_label
    fem.tool.material_combobox  = gtk.ComboBox.new_text()
    fem.tool.change_material    = build_toolbutton( 1, "gtk-convert", Label.FEM.change_material, "all" )
    fem.tool.del_element        = build_toolbutton( 1, "gtk-cancel", Label.FEM.del_element, "all" )
    fem.tool.import_export      = gtk.ToolItem.new()
    fem.tool.import_export_box  = gtk.VBox.new( false, 0 )
    fem.tool.import_nodes       = build_button( 0, "Icons\\Import-20.png", Label.FEM.import_nodes, "all", std.icon_size )
    fem.tool.export_nodes       = build_button( 0, "Icons\\Export-20.png", Label.FEM.export_nodes, "all", std.icon_size )
    fem.tool.add_load           = build_toolbutton( 0, "Icons\\load-add.png", Label.FEM.add_load, "all" )
    fem.tool.del_load           = build_toolbutton( 0, "Icons\\load-del.png", Label.FEM.del_load, "all" )
    fem.tool.inertia_loads      = build_toolbutton( 0, "Icons\\load-inertia.png", Label.FEM.inertia_loads, "all" )

    --Toggle buttons settings
    local add_element_icon = gtk.Image.new_from_file( "Icons\\element_add.png" )
    fem.tool.add_element_toogle:set_icon_widget( add_element_icon )
    fem.tool.add_element_toogle:set_label( Label.FEM.add_element )
    --Material combobox settings
    fem.tool.material_vbox:pack_start( Label.FEM.material_label, false, false, 1 )
    fem.tool.material_vbox:pack_start( fem.tool.material_combobox, false, false, 1 )
    fem.tool.material_set:add( fem.tool.material_vbox )
    --Export buttons box
    fem.tool.import_export_box:pack_start( fem.tool.import_nodes, false, false, 1 )
    fem.tool.import_export_box:pack_start( fem.tool.export_nodes, false, false, 1 )
    fem.tool.import_export:add( fem.tool.import_export_box )

    --Toolbar mount
    fem.toolbar:insert( fem.tool.add_scenario, -1 )
    fem.toolbar:insert( fem.tool.del_scenario, -1 )
    fem.toolbar:insert( fem.tool.add_node, -1 )
    fem.toolbar:insert( fem.tool.pattern_add_node, -1 )
    fem.toolbar:insert( fem.tool.delete_node, -1 )
    fem.toolbar:insert( fem.tool.add_constraint, -1 )
    fem.toolbar:insert( fem.tool.del_constraint, -1 )
    fem.toolbar:insert( fem.tool.view_mesh, -1 )
    fem.toolbar:insert( fem.tool.run, -1 )
    fem.toolbar:insert( fem.tool.view, -1 )
    --Toolbar_1 mount
    fem.toolbar_1:insert( fem.tool.add_element_toogle, -1 )
    fem.toolbar_1:insert( fem.tool.material_set, -1 )
    fem.toolbar_1:insert( fem.tool.change_material, -1 )
    fem.toolbar_1:insert( fem.tool.del_element, -1 )
    fem.toolbar_1:insert( fem.tool.import_export, -1 )
    fem.toolbar_1:insert( fem.tool.add_load, -1 )
    fem.toolbar_1:insert( fem.tool.del_load, -1 )
    fem.toolbar_1:insert( fem.tool.inertia_loads, -1 )


    --Notebook mount
    fem.notebook:set ( "enable-popup", true, "scrollable", true )
    --fem.tool.view:set( "sensitive", false )

    --Events
    fem.tool.add_scenario:connect( "clicked", function() new_scenario_dialog() end )
    fem.tool.del_scenario:connect( "clicked", function()
                                            scenario = fem.notebook:get_tab_label( fem.page_child[ fem.notebook:get( "page" ) ] )
                                            scenario = scenario:get_text()
                                            del_scenario( scenario ) end )
    fem.tool.add_node:connect( "clicked", function()
                                            scenario = fem.notebook:get_tab_label( fem.page_child[ fem.notebook:get( "page" ) ] )
                                            scenario = scenario:get_text()
                                            add_node( scenario ) end )
    fem.tool.pattern_add_node:connect( "clicked", function()
                                            scenario = fem.notebook:get_tab_label( fem.page_child[ fem.notebook:get( "page" ) ] )
                                            scenario = scenario:get_text()
                                            pattern_add_node( scenario ) end )
    fem.tool.delete_node:connect( "clicked", function()
                                                local scenario = fem.notebook:get_tab_label( fem.page_child[ fem.notebook:get( "page" ) ] )
                                                scenario = scenario:get_text()
                                                delete_node( scenario ) end )
    fem.tool.change_material:connect( "clicked", function()
                                                 local scenario = fem.notebook:get_tab_label( fem.page_child[ fem.notebook:get( "page" ) ] )
                                                scenario = scenario:get_text()
                                                fem.sce[ scenario ]:change_material( fem.sce[ scenario ].element:get_selected(), fem.tool.material_combobox:get_active_text() )
                                                end )
    fem.tool.del_element:connect( "clicked", function()
                                             local scenario = fem.notebook:get_tab_label( fem.page_child[ fem.notebook:get( "page" ) ] )
                                             scenario = scenario:get_text()
                                             fem.sce[ scenario ]:delete_element( fem.sce[ scenario ].element:get_selected() )
                                             end )
    fem.tool.add_constraint:connect( "clicked", function()
                                                local scenario = fem.notebook:get_tab_label( fem.page_child[ fem.notebook:get( "page" ) ] )
                                                scenario = scenario:get_text()
                                                local selected = fem.sce[ scenario ].node:get_selected()
                                                if( #selected > 0 ) then fem.sce[ scenario ]:add_constraint( selected, false ) end
                                                end )
    fem.tool.del_constraint:connect( "clicked", function()
                                                local scenario = fem.notebook:get_tab_label( fem.page_child[ fem.notebook:get( "page" ) ] )
                                                scenario = scenario:get_text()
                                                local selected = fem.sce[ scenario ].constraint:get_selected()
                                                if( #selected > 0 ) then fem.sce[ scenario ]:delete_constraint( selected, false ) end
                                                end )
    fem.tool.add_load:connect( "clicked", function()
                                                local scenario = fem.notebook:get_tab_label( fem.page_child[ fem.notebook:get( "page" ) ] )
                                                scenario = scenario:get_text()
                                                fem.sce[ scenario ]:load_dialog()
                                                end )
    fem.tool.del_load:connect( "clicked", function()
                                                local scenario = fem.notebook:get_tab_label( fem.page_child[ fem.notebook:get( "page" ) ] )
                                                scenario = scenario:get_text()
                                                local selected = fem.sce[ scenario ].load:get_selected()
                                                fem.sce[ scenario ]:delete_load( selected )
                                                end )
    fem.tool.inertia_loads:connect( "clicked", function()
                                                local scenario = fem.notebook:get_tab_label( fem.page_child[ fem.notebook:get( "page" ) ] )
                                                scenario = scenario:get_text()
                                                fem.sce[ scenario ]:inertia_loads_dialog()
                                                end )
    fem.tool.run:connect( "clicked", function()
                                        local scenario = fem.notebook:get_tab_label( fem.page_child[ fem.notebook:get( "page" ) ] )
                                        scenario = scenario:get_text()
                                        fem.sce[ scenario ]:run_dialog()
                                     end )
    fem.tool.view:connect( "clicked", function()
                                        local scenario = fem.notebook:get_tab_label( fem.page_child[ fem.notebook:get( "page" ) ] )
                                        scenario = scenario:get_text()
                                        fem.sce[ scenario ]:view_results_dialog()
                                     end )
    fem.tool.view_mesh:connect( "clicked", function()
                                            local scenario = fem.notebook:get_tab_label( fem.page_child[ fem.notebook:get( "page" ) ] )
                                            scenario = scenario:get_text()
                                            fem.sce[ scenario ]:GMSH_view_mesh()
                                           end )
    fem.tool.export_nodes:connect( "clicked", function()
                                            local scenario = fem.notebook:get_tab_label( fem.page_child[ fem.notebook:get( "page" ) ] )
                                            scenario = scenario:get_text()
                                            fem.sce[ scenario ]:node_export_to_excel()
                                           end )
    fem.tool.import_nodes:connect( "clicked", function()
                                            local scenario = fem.notebook:get_tab_label( fem.page_child[ fem.notebook:get( "page" ) ] )
                                            scenario = scenario:get_text()
                                            fem.sce[ scenario ]:node_import_from_excel()
                                           end )

    fem.main_vbox:pack_start( fem.toolbar, false, false, 1 )
    fem.main_vbox:pack_start( fem.toolbar_1, false, false, 1 )
    fem.main_vbox:pack_start( fem.notebook, false, false, 1 )
    fem.main_vbox:show_all()
end
