require("lgob.gdk")
require("lgob.gtk")
--require("Libraries\\STEP ISO 10303")

--[[This is MeshTools ]]
--MeshTools tab and entities
mesh = {
    main_vbox = gtk.VBox.new( false, 5 ),
    sce = {}, --Scenarios
    page_child = {},
    notebook = gtk.Notebook.new(),
    --Toolbar
    toolbar = {
        obj = gtk.Toolbar.new(),
    },
}
function mesh:build()
    --
    self.toolbar.export_step = build_toolbutton( 0, "Icons\\export-step.png", Label.MESH.export_step, "all" )

    --
    self.toolbar.obj:insert( self.toolbar.export_step, -1 )
    self.notebook:set( "enable-popup", true, "scrollable", true )

    --
    self.toolbar.export_step:connect( "clicked", function()
                                                 local scenario = mesh.notebook:get_tab_label( mesh.page_child[ mesh.notebook:get( "page" ) ] )
                                                 scenario = scenario:get_text()
                                                 self:export_dialog( scenario )
                                                 end )
    --
    self.main_vbox:pack_start( self.toolbar.obj, false, false, 1 )
    self.main_vbox:pack_start( self.notebook, false, false, 1 )
    self.main_vbox:show_all()
end

function mesh:browse_folder( window )
    local dialog = gtk.FileChooserDialog.new( "Select folder", window, gtk.FILE_CHOOSER_ACTION_SELECT_FOLDER,
                                       "gtk-cancel", gtk.RESPONSE_CANCEL, "gtk-ok", gtk.RESPONSE_OK )
    dialog:set_current_folder( config.working_directory )

    if( dialog:run() == gtk.RESPONSE_OK ) then
        local file = dialog:get_filename()
        dialog:destroy()
        return file
    elseif( dialog:run() == gtk.RESPONSE_CANCEL ) then
        dialog:destroy()
    end
end

function mesh:export_dialog( scenario )
    --
    local window    = gtk.Window.new()
    local main_vbox = gtk.VBox.new( false, 5 )
    --Line one
    local hbox1          = gtk.HBox.new( false, 5 )
    local filename_label = gtk.Label.new( Label.MESH.filename )
    local filename_entry = gtk.Entry.new()
    local browse_button  = build_button( 1, "", Label.MESH.browse, "label", std.icon_size )
    local folder_entry   = gtk.Entry.new()
    local sep1           = gtk.HSeparator.new()
    --Line two
    local hbox2                  = gtk.HBox.new( false, 5 )
    local file_description_label = gtk.Label.new( Label.MESH.file_description )
    local file_description       = gtk.Entry.new()
    local sep2                   = gtk.HSeparator.new()

    local hbox_b = gtk.HBox.new( false, 5 )
    local export = build_button( 1, "gtk-apply", Label.MESH.export_button, "all", std.icon_size )

    --FOR TESTING ONLY
    folder_entry:set_text( config.program_directory.."\\Projects\\stp" )

    ----
    window:set_title( Label.MESH.export_window )
    filename_entry:set( "width-request", 90, "text", proj.name )
    folder_entry:set( "width-request", 150 )

    --
    window:connect( "delete-event", function() window:destroy() end )
    browse_button:connect( "clicked", function()
                               folder_entry:set_text( mesh:browse_folder( window ) )
                               end )
    export:connect( "clicked", function()
                               header = {}
                               header.name        = filename_entry:get_text()
                               header.path        = folder_entry:get_text()
                               header.description = file_description:get_text()
                               if( header.name ~= "" ) then
                                   step[ header.name ] = STEP.new( header, scenario )
                               end
                               window:destroy()
                               end )

    --
    hbox1:pack_start( filename_label, false, false, 1 )
    hbox1:pack_start( filename_entry, false, false, 1 )
    hbox1:pack_start( browse_button, false, false, 1 )
    hbox1:pack_start( folder_entry, false, false, 1 )

    hbox2:pack_start( file_description_label, false, false, 1 )
    hbox2:pack_start( file_description, false, false, 1 )

    hbox_b:pack_start( export, false, false, 1 )

    main_vbox:pack_start( hbox1, false, false, 1 )
    main_vbox:pack_start( sep1, false, false, 1 )
    main_vbox:pack_start( hbox2, false, false, 1 )
    main_vbox:pack_start( sep2, false, false, 1 )
    main_vbox:pack_start( hbox_b, false, false, 1 )

    window:add( main_vbox )
    window:show_all()
end

--MESH class for each scenario
MESH = {}
MESH.__index = MESH

function MESH:linear_interpolation_build()
    local linear = {}
    function visible_buttons()
        linear.v_vbox            = gtk.VBox.new( false, 5 )
        linear.v_hbox            = gtk.HBox.new( false, 5 )
        linear.v_activate_button = build_button( 0, "Icons\\linear_int.png", Label.MESH.linear_button, "all", std.icon_size )
        linear.v_apply_button    = build_button( 1, "gtk-apply", Label.MESH.apply, "all", std.icon_size )
        linear.v_ok_button       = build_button( 1, "gtk-ok", Label.MESH.ok, "all", std.icon_size )

        linear.v_hbox:pack_start( linear.v_apply_button, false, false, 1 )
        linear.v_hbox:pack_start( linear.v_ok_button, false, false, 1 )
        linear.v_vbox:pack_start( linear.v_activate_button, false, false, 1 )
        linear.v_vbox:pack_start( linear.v_hbox, false, false, 1 )
    end
    function invisible_buttons()
        linear.i_vbox1   = gtk.VBox.new( false, 10 ) --Pack 1
        linear.i_combo   = gtk.ComboBox.new_text()
        linear.i_hbox1   = gtk.HBox.new( false, 5 )
        linear.i_n_label = gtk.Label.new( Label.MESH.n_label )
        linear.i_n_entry = gtk.Entry.new()
        linear.i_vbox2   = gtk.VBox.new( false, 10 ) --Pack 2.1
        linear.i_view    = Treeview.new( false )
        linear.i_view_1  = Treeview.new( false )
        linear.i_view_2  = Treeview.new( false )
        linear.i_view_1.data:add( {"Element", ""}, linear.i_view_1.data.itens + 1 )
        linear.i_view_2.data:add( {"Node 1", ""}, linear.i_view_2.data.itens + 1 )
        linear.i_view_2.data:add( {"Node 2", ""}, linear.i_view_2.data.itens + 1 )

        linear.i_vbox1:set( "sensitive", false, "width-request", 200 )
        linear.i_combo:append_text( Label.MESH.divide )
        linear.i_combo:append_text( Label.MESH.with_node )
        linear.i_n_entry:set( "width-request", 58 )
        linear.i_combo:set( "active", 0 )
        linear.i_vbox2:set( "sensitive", false, "width-request", 150 )
        linear.i_view:add_column_text( "Property", 50 )
        linear.i_view:add_column_text( "Value", 100 )
        linear.i_view:add_column_text( "Row", 1 )

        linear.i_view.obj =  linear.i_view:build( { width = 150, height = 70 } )
        linear.i_view.obj:set_policy( gtk.POLICY_NEVER, gtk.POLICY_NEVER )

        linear.i_hbox1:pack_start( linear.i_n_label, false, false, 1 )
        linear.i_hbox1:pack_start( linear.i_n_entry, false, false, 1 )
        linear.i_vbox1:pack_start( linear.i_combo, false, false, 1 )
        linear.i_vbox1:pack_start( linear.i_hbox1, false, false, 1 )
        linear.i_vbox2:pack_start( linear.i_view.obj, false, false, 1 )
    end
    --
    linear.frame = gtk.Frame.new()
    linear.hbox  = gtk.HBox.new( false, 5 )
    visible_buttons()
    linear.sep1  = gtk.VSeparator.new()
    invisible_buttons()
    linear.handler = {}

    --

    --
    linear.v_activate_button:connect( "clicked", function()
                                                 linear.i_vbox1:set( "sensitive", true )
                                                 linear.i_vbox2:set( "sensitive", true )
                                                 if( linear.i_combo:get_active_text() == Label.MESH.divide ) then
                                                    linear.i_view.data = linear.i_view_1.data
                                                    linear.i_view:update()
                                                    self:linear_interpolation_element_set()
                                                 else
                                                    linear.i_view.data = linear.i_view_2.data
                                                    linear.i_view:update()
                                                    self:linear_interpolation_nodes_set()
                                                 end end )
    linear.v_apply_button:connect( "clicked", function()
                                                local n = tonumber( linear.i_n_entry:get_text() )
                                                local row
                                                if( linear.i_combo:get_active_text() == Label.MESH.divide ) then
                                                    row = linear.i_view.data:get( 1 )
                                                    local element_row = row[ 3 ]
                                                    row = self.element.data:get( row[ 3 ] )
                                                    local I, K
                                                    for i = 1, self.node.data.itens do
                                                        local row2 = self.node.data:get( i )
                                                        if( row2[1] == row[2] ) then
                                                            I = i
                                                        elseif( row2[1] == row[3] ) then
                                                            K = i
                                                        end
                                                    end
                                                    self:linear_interpolation( I, K, n, element_row )
                                                else
                                                    row = {}
                                                    row[1] = linear.i_view.data:get( 1 )
                                                    row[2] = linear.i_view.data:get( 2 )
                                                    self:linear_interpolation( row[1][3], row[2][3], n, nil )
                                                end
                                                end )
    linear.v_ok_button:connect( "clicked", function()
                                           linear.i_vbox1:set( "sensitive", false )
                                           linear.i_vbox2:set( "sensitive", false )
                                           if( self.linear.handler[ 1 ] ~= nil ) then self.element.view:disconnect( self.linear.handler[ 1 ] ) end
                                           if( self.linear.handler[ 2 ] ~= nil ) then self.node.selection:disconnect( self.linear.handler[ 2 ] ) end
                                           end )
    linear.i_combo:connect( "changed", function()
                                       if( linear.i_combo:get_active_text() == Label.MESH.divide ) then
                                        linear.i_view.data = linear.i_view_1.data
                                        linear.i_view:update()
                                        self:linear_interpolation_element_set()
                                       else
                                        linear.i_view.data = linear.i_view_2.data
                                        linear.i_view:update()
                                        self:linear_interpolation_nodes_set()
                                       end end )

    --
    linear.hbox:pack_start( linear.v_vbox, false, false, 1 )
    linear.hbox:pack_start( linear.sep1, false, false, 1 )
    linear.hbox:pack_start( linear.i_vbox1, false, false, 1 )
    linear.hbox:pack_start( linear.i_vbox2, false, false, 1 )
    linear.frame:add( linear.hbox )
    return linear
end
--Callbacks
function MESH:linear_interpolation_element_set()
    if( self.linear.handler[ 2 ] ~= nil ) then
        self.node.selection:disconnect( self.linear.handler[ 2 ] )
    end
    self.linear.handler[ 1 ] = self.element.view:connect( "cursor-changed", function()
                                                                            local value = self.element.data:get( self.element:get_selected()[ 1 ] )[ 1 ]
                                                                            local row = self.linear.i_view_1.data:get( 1 )
                                                                            row[ 2 ] = value
                                                                            row[ 3 ] = self.element:get_selected()[ 1 ]
                                                                            self.linear.i_view:update()
                                                                            end )
end
function MESH:linear_interpolation_nodes_set()
    if( self.linear.handler[ 1 ] ~= nil ) then
        self.element.view:disconnect( self.linear.handler[ 1 ] )
    end
    self.linear.handler[ 2 ] = self.node.selection:connect( "changed", function()
                                                                            if( #self.node:get_selected() == 2 ) then
                                                                                local value1 = self.node.data:get( self.node:get_selected()[ 1 ] )[ 1 ]
                                                                                local value2 = self.node.data:get( self.node:get_selected()[ 2 ] )[ 1 ]
                                                                                local row = self.linear.i_view_2.data:get( 1 )
                                                                                row[ 2 ] = value1
                                                                                row[ 3 ] = self.node:get_selected()[ 1 ]
                                                                                local row = self.linear.i_view_2.data:get( 2 )
                                                                                row[ 2 ] = value2
                                                                                row[ 3 ] = self.node:get_selected()[ 2 ]
                                                                                self.linear.i_view:update()
                                                                            end
                                                                            end )
end

function MESH:arc_interpolation_build()
    local arc = {}
    function visible_buttons()
        arc.v_vbox            = gtk.VBox.new( false, 5 )
        arc.v_hbox            = gtk.HBox.new( false, 5 )
        arc.v_activate_button = build_button( 0, "Icons\\arc_int.png", Label.MESH.arc_button, "all", std.icon_size )
        arc.v_apply_button    = build_button( 1, "gtk-apply", Label.MESH.apply, "all", std.icon_size )
        arc.v_ok_button       = build_button( 1, "gtk-ok", Label.MESH.ok, "all", std.icon_size )

        arc.v_hbox:pack_start( arc.v_apply_button, false, false, 1 )
        arc.v_hbox:pack_start( arc.v_ok_button, false, false, 1 )
        arc.v_vbox:pack_start( arc.v_activate_button, false, false, 1 )
        arc.v_vbox:pack_start( arc.v_hbox, false, false, 1 )
    end
    function invisible_buttons()
        arc.i_vbox1   = gtk.VBox.new( false, 10 ) --Pack 1
        arc.i_label   = gtk.Label.new( Label.MESH.arc_label )
--        arc.i_combo   = gtk.ComboBox.new_text()
        arc.i_hbox1   = gtk.HBox.new( false, 5 )
        arc.i_radius_label = gtk.Label.new( Label.MESH.arc_entry_label )
        arc.i_radius_entry = gtk.Entry.new()
        arc.i_hbox2   = gtk.HBox.new( false, 5 )
        arc.i_n_label = gtk.Label.new( Label.MESH.n_label )
        arc.i_n_entry = gtk.Entry.new()
        arc.i_hbox3   = gtk.HBox.new( false, 5 )
        arc.i_z_label_1 = gtk.Label.new( Label.MESH.z_label_1 )
        arc.i_z_entry_1 = gtk.Entry.new()
        arc.i_z_label_2 = gtk.Label.new( Label.MESH.z_label_2 )
        arc.i_z_entry_2 = gtk.Entry.new()
        arc.i_mat_combo = gtk.ComboBox.new_text()
        arc.i_vbox2   = gtk.VBox.new( false, 10 ) --Pack 2.1
        arc.i_view    = Treeview.new( false )
--        arc.i_view_1  = Treeview.new( false )
--        arc.i_view_2  = Treeview.new( false )
--        arc.i_view.data:add( {"Element", ""}, arc.i_view_1.data.itens + 1 )
        arc.i_view.data:add( {"Node 1", ""}, arc.i_view.data.itens + 1 )
        arc.i_view.data:add( {"Node 2", ""}, arc.i_view.data.itens + 1 )
--
        arc.i_vbox1:set( "sensitive", false, "width-request", 200 )
--        arc.i_combo:append_text( Label.MESH.divide )
--        arc.i_combo:append_text( Label.MESH.with_node )
        arc.i_radius_entry:set( "width-request", 90, "text", "76.1315 91.8029 88.5573" )
        arc.i_n_entry:set( "width-request", 58, "text", "5" )
        arc.i_z_entry_1:set( "width-request", 58, "text", "0 0 1" )
        arc.i_z_entry_2:set( "width-request", 10, "text", "1" )
        arc.i_mat_combo:set( "active", 2 )
        arc.i_vbox2:set( "sensitive", false, "width-request", 150 )
        arc.i_view:add_column_text( "Property", 50 )
        arc.i_view:add_column_text( "Value", 100 )
        arc.i_view:add_column_text( "Row", 1 )
--
        arc.i_view.obj =  arc.i_view:build( { width = 150, height = 70 } )
        arc.i_view.obj:set_policy( gtk.POLICY_NEVER, gtk.POLICY_NEVER )
        arc.i_view:update()
--
        arc.i_hbox1:pack_start( arc.i_radius_label, false, false, 1 )
        arc.i_hbox1:pack_start( arc.i_radius_entry, false, false, 1 )
        arc.i_hbox2:pack_start( arc.i_n_label, false, false, 1 )
        arc.i_hbox2:pack_start( arc.i_n_entry, false, false, 1 )
        arc.i_hbox3:pack_start( arc.i_z_label_1, false, false, 1 )
        arc.i_hbox3:pack_start( arc.i_z_entry_1, false, false, 1 )
        arc.i_hbox3:pack_start( arc.i_z_label_2, false, false, 1 )
        arc.i_hbox3:pack_start( arc.i_z_entry_2, false, false, 1 )
        arc.i_vbox1:pack_start( arc.i_label, false, false, 1 )
        arc.i_vbox1:pack_start( arc.i_hbox1, false, false, 1 )
        arc.i_vbox1:pack_start( arc.i_hbox2, false, false, 1 )
        arc.i_vbox1:pack_start( arc.i_hbox3, false, false, 1 )
        arc.i_vbox1:pack_start( arc.i_mat_combo, false, false, 1 )
        arc.i_vbox2:pack_start( arc.i_view.obj, false, false, 1 )
    end
    --
    arc.frame = gtk.Frame.new()
    arc.hbox  = gtk.HBox.new( false, 5 )
    visible_buttons()
    arc.sep1  = gtk.VSeparator.new()
    invisible_buttons()
    arc.handler = {}

    --

    --
    arc.v_activate_button:connect( "clicked", function()
                                                 arc.i_vbox1:set( "sensitive", true )
                                                 arc.i_vbox2:set( "sensitive", true )
                                                 end )
    arc.v_apply_button:connect( "clicked", function()
                                                if( arc.i_vbox1:get( "sensitive" ) == false ) then
                                                    return nil
                                                else
                                                    local row = {}
                                                    row[1] = arc.i_view.data:get( 1 )
                                                    row[2] = arc.i_view.data:get( 2 )
                                                    if( row[2][2] == "" ) then
                                                        row[2][3] = nil
                                                    end
                                                    local center = vector.new( nil, nil, {1,0,0} )
                                                    center:scan( arc.i_radius_entry:get_text() )
                                                    local n = tonumber( arc.i_n_entry:get_text() )
                                                    local z = vector.new( nil, nil, {1,0,0} )
                                                    z:scan( arc.i_z_entry_1:get_text() )
                                                    z:normalize()
                                                    local mat = arc.i_mat_combo:get_active_text()
                                                    local node = tonumber( arc.i_z_entry_2:get_text() )
                                                    if( node ~= 1 ) and ( node ~= 2 ) then
                                                        print( "ERROR: Input node 1 or 2" )
                                                        return nil
                                                    end
                                                    self:arc_interpolation( row[1][3], row[2][3], center, n, z, node, mat )
                                                end
                                                end )
    arc.v_ok_button:connect( "clicked", function()
                                           arc.i_vbox1:set( "sensitive", false )
                                           arc.i_vbox2:set( "sensitive", false )
                                           end )

    arc.hbox:pack_start( arc.v_vbox, false, false, 1 )
    arc.hbox:pack_start( arc.sep1, false, false, 1 )
    arc.hbox:pack_start( arc.i_vbox1, false, false, 1 )
    arc.hbox:pack_start( arc.i_vbox2, false, false, 1 )
    arc.frame:add( arc.hbox )
    return arc
end

function MESH:linear_interpolation( node1, node2, n, element_row ) --node1 and node2 are the row positions, not ids
    if( node1 == nil ) or ( node2 == nil ) or ( n == nil ) then
        return nil
    else
        local row1 = self.node.data:get( node1 )
        local row2 = self.node.data:get( node2 )
        local pnt1 = point.new( { tonumber( row1[2] ), tonumber( row1[3] ), tonumber( row1[4] ) } )
        local pnt2 = point.new( { tonumber( row2[2] ), tonumber( row2[3] ), tonumber( row2[4] ) } )
        local vet  = vector.new( pnt1, pnt2 )
        local len = (vet.abs/n)
        if( len >= 1 ) then
            local pnti, pntf
            local unit = vector.new( {0,0,0}, vet.unit )
            local data = {}
            local mat --For material
            local prefix
            local z_axis
            if( element_row == nil ) then
                mat = ""
                prefix = nil
                z_axis = "0 0 1"
            else
                mat = self.element.data:get( element_row )[ 4 ]
                prefix = self.element.data:get( element_row )[ 1 ]
                z_axis = self.element.data:get( element_row )[ 7 ]
            end
            local id_n0
            for i = 1, n do
                local id_n = fem.sce[ self.name ]:unique_id( "node", nil )
                local id_e = fem.sce[ self.name ]:unique_id( "element", prefix )
                if( i == 1 ) then
                    pnti = pnt1
                    pntf = pnti + len*unit
                    id_n0 = row1[ 1 ]
                    fem.sce[ self.name ]:add_node( { id_n, pntf[1], pntf[2], pntf[3] } )
                    fem.sce[ self.name ]:add_element( true, { id_e, id_n0, id_n, mat, z_axis }, false )
                    id_n0 = id_n
                elseif( i == n ) then
                    pnti = pntf
                    pntf = pnt2
                    id_n = row2[ 1 ]
                    fem.sce[ self.name ]:add_element( true, { id_e, id_n0, id_n, mat, z_axis }, false )
                else
                    pnti = pntf
                    pntf = pnti + len*unit
                    fem.sce[ self.name ]:add_node( { id_n, pntf[1], pntf[2], pntf[3] } )
                    fem.sce[ self.name ]:add_element( true, { id_e, id_n0, id_n, mat, z_axis }, false )
                    id_n0 = id_n
                end
                print( pntf[1], pntf[2], pntf[3] )
            end
            --Erases old element (if there is) and update
            if( element_row ~= nil ) then
                fem.sce[ self.name ]:delete_element( { element_row } )
            end
            fem.sce[ self.name ].node:update()
            fem.sce[ self.name ].element:update()
            self.node:update()
            self.element:update()
        end
    end
end

function MESH:arc_interpolation( node1, node2, center, n, z, z_from_node, mat ) --node1 and node2 are the row positions, not ids
    local C, U, N, R, V, angle
    local row1 = self.node.data:get( node1 )
    local row2 = self.node.data:get( node2 )
    local point_list = {}
    C = { center[1], center[2], center[3] }
    R = vector.new( {row1[2], row1[3], row1[4]}, {center[1], center[2], center[3]} )
    R = R.abs
    U = vector.new( C, {row1[2], row1[3], row1[4]} )
    U:normalize()
    U  = vector.new( nil, nil, U.unit )
    v1 = vector.new( C, {row2[2], row2[3], row2[4]}, nil )
    N  = vector.new( nil, nil, v1:cross( U ) )
    N:normalize()
    N = vector.new( nil, nil, N.unit )
    V = vector.new( nil, nil, U:cross( N ) )
    V:normalize()
    V = vector.new( nil, nil, V.unit )
    v1:normalize()
    v1 = vector.new( nil, nil, v1.unit )
    angle = math.acos( U:dot( v1 ) )
    print( 'R = '..R )
    print( 'C = '..C[1]..' '..C[2]..' '..C[3] )
    print( 'U = '..U[1]..' '..U[2]..' '..U[3] )
    print( 'V = '..V[1]..' '..V[2]..' '..V[3] )
    print( 'N = '..N[1]..' '..N[2]..' '..N[3] )
    print( 'angle = '..angle )

    local z_list = {}
    point_list[1] = { {row1[2], row1[3], row1[4]} }
    local div = 1/n
    for i = 1, n - 1 do
        point_list[ i + 1 ] = {}
        for j = 1, 3 do
            point_list[i + 1][j] = (C[j] + R*U[j]*math.cos( angle*(div*i) ) + R*V[j]*math.sin( angle*(div*i)))
        end
        print( angle*(div*i) )
    end
    point_list[ #point_list + 1 ] = row2[1]
    point_list[ 1 ] = row1[1]
    for k, v in ipairs( point_list ) do
        if( k ~= 1 ) and ( k ~= #point_list ) then
            local id_n = fem.sce[ self.name ]:unique_id( "node", nil )
            fem.sce[ self.name ]:add_node( { id_n, v[1], v[2], v[3] } )
            point_list[ k ] = id_n
        end
        if( N:dot( z ) < 1 ) then
--            local u = { ((row1[2]+row2[2])/2), ((row1[3]+row2[3])/2), ((row1[4]+row2[4])/2) }
--            u  = vector.new( u, C )
--            local z1 = z:proj_to( N )
--            local z2 = z:proj_to( u )
--            z_list[k] = vector.new( nil, nil, (z1+z2) )
--            z_list[k]:normalize()
--            z_list[k] = vector.new( nil, nil, z_list[k].unit )

            z_list[ k ] = z --TEMPORARY
        else
            z_list[ k ] = z
        end
    end
    for i = 1, n do
        local id_e = fem.sce[ self.name ]:unique_id( "element", prefix )
        --print( point_list[i], point_list[(i+1)] )
        fem.sce[ self.name ]:add_element( true, { id_e, point_list[i], point_list[(i+1)], mat, z_list[i][1]..z_list[i][2]..z_list[i][3] }, false )
    end
    fem.sce[ self.name ].node:update()
end

function MESH:node_element_view()
    local node    = Treeview.new( true )
    local element = Treeview.new( true )

    node:add_column_text( "ID", 75, self.change_node_id, self )
    node:add_column_text( "X [ mm ]", 75, self.change_node_x, self )
    node:add_column_text( "Y [ mm ]", 75, self.change_node_y, self )
    node:add_column_text( "Z [ mm ]", 75, self.change_node_z, self )
    local i
    for i = 1, #node.columns do
        node.columns[i]:set( "min-width", 75 )
    end
    element:add_column_text( Label.FEM.view_id, 30, self.change_element_id, self )
    element:add_column_text( Label.FEM.view_node1, 30 )
    element:add_column_text( Label.FEM.view_node2, 30 )
    element:add_column_text( Label.MATERIAL.material_view, 30 )
    element:add_column_text( Label.FEM.view_type, 30 )
    element:add_column_text( Label.FEM.view_length, 30 )
    element:add_column_text( Label.FEM.view_z_axis, 30, self.change_element_mass, self )
    element:add_column_text( Label.FEM.view_mass, 30, self.change_element_mass, self )
    element:add_column_text( Label.FEM.view_area, 30, self.change_element_area, self )
    element:add_column_text( Label.FEM.view_Iyy, 30, self.change_element_Iyy, self )
    element:add_column_text( Label.FEM.view_Izz, 30, self.change_element_Izz, self )
    element:add_column_text( Label.FEM.view_polar, 30, self.change_element_polar, self )
    element:add_column_text( Label.FEM.view_E, 30, self.change_element_E, self )
    element:add_column_text( Label.FEM.view_G, 30, self.change_element_G, self )
    for i = 1, #element.columns do
        element.columns[i]:set( "min-width", 50 )
    end

    return node, element
end

function MESH.new( scenario_name )
    local self = {}
    setmetatable(self, MESH)
    self.name = scenario_name
    --Notebook and main vbox
    self.scroll = gtk.ScrolledWindow.new( nil, nil )
    self.scroll:set_policy( gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC )
    self.scroll:set( "height-request", 450 )
    self.main_hbox = gtk.HBox.new( false, 5 )
    self.main_vbox = gtk.VBox.new( false, 5 )
    self.scenario_name  = gtk.Label.new( scenario_name )
    self.scroll:add_with_viewport( self.main_hbox )

    self.main_vbox:set( "width-request", 500 )

    self.main_hbox:pack_start( self.main_vbox, false, false, 1 )
    --Linear interpolation
    self.linear = self:linear_interpolation_build()
    self.main_vbox:pack_start( self.linear.frame, false, false, 1 )

    --Arc interpolation
    self.arc = self:arc_interpolation_build()
    self.main_vbox:pack_start( self.arc.frame, false, false, 1 )

    --Separator
    self.main_sep = gtk.VSeparator.new()
    self.main_hbox:pack_start( self.main_sep, false, false, 1 )

    --Element and node view (again, its the same from FEM)
    self.view_vbox    = gtk.VBox.new( false, 5 )
    self.node, self.element = self:node_element_view()
    self.node.data    = fem.sce[ scenario_name ].node.data
    self.element.data = fem.sce[ scenario_name ].element.data
    self.node.obj     = self.node:build( { width = 350, height = 250 } )
    self.element.obj  = self.element:build( { width = 350, height = 250 } )
    self.node:update()
    self.element:update()

    self.view_vbox:pack_start( self.element.obj, false, false, 1 )
    self.view_vbox:pack_start( self.node.obj, false, false, 1 )
    self.main_hbox:pack_start( self.view_vbox, false, false, 1 )

    self.scroll:show_all()
    mesh.notebook:insert_page( self.scroll, self.scenario_name, -1 )

    self.node.selection:connect( "changed", function()
                                            if( #self.node:get_selected() == 2 ) then
                                                local value1 = self.node.data:get( self.node:get_selected()[ 1 ] )[ 1 ]
                                                local value2 = self.node.data:get( self.node:get_selected()[ 2 ] )[ 1 ]
                                                local row = self.arc.i_view.data:get( 1 )
                                                row[ 2 ] = value1
                                                row[ 3 ] = self.node:get_selected()[ 1 ]
                                                local row = self.arc.i_view.data:get( 2 )
                                                row[ 2 ] = value2
                                                row[ 3 ] = self.node:get_selected()[ 2 ]
                                                self.arc.i_view:update()
                                            end
                                            end )

    mesh.notebook:show_all()
    fem.notebook:set_current_page( -1 )
    --Set page child name
    mesh.page_child[ mesh.notebook:get( "page" ) ] = self.scroll
    return self
end

--For STEP file handling
step = {}--Keeps STEP instances
STEP = {}
STEP.__index = STEP

function STEP.new( header, scenario )
    local self = {}
    setmetatable(self, STEP)
    self.header = header
    --filename
    local file = header.path.."\\"..header.name
    --Command lines table --> [ program entity ] = STEP line. example: [ node1 ] = { 1, "#1=CARTESIAN_POINT('node1',(0,0,0));" }
    self.node_lines = {}
    self.used_lines = {} --
    self:set_cartesian_points( scenario )
    self:set_lines( scenario )

    self:write( file )
    return self
end

function STEP:write( filepath )
    local file = io.open( filepath..".stp", "w" )
    file:write( "ISO-10303-21;\n" )
    file:write( "HEADER;\n" )
    file:write( "FILE_DESCRIPTION(('"..self.header.description.."\'),'2;1');\n" )
    file:write( "FILE_NAME('"..self.header.name.."',,,,,, )\n" ) --ADD OTHERS
    file:write( "FILE_SCHEMA(('CONFIG_CONTROL_DESIGN'));\n" )
    file:write( "ENDSEC;\n" )
    file:write( "DATA;\n" )
    --Add stuff
    local i
    for i = 1, #self.used_lines do
        file:write( self.used_lines[ i ][ 3 ].."\n" )
    end
    file:close()
end

function STEP:get_id()
    local i
    for i = 1, #self.used_lines + 1 do
        if( self.used_lines[ i ] == nil ) then
            return i
        end
    end
end

function STEP:set_cartesian_points( scenario )
    --CARTESIAN_POINT( 'node_id', ( x, y, z ));
    --Get scenario
    scenario = fem.sce[ scenario ]
    --Convert nodes into cartesian points
    local i
    for i = 1, scenario.node.data.itens do
        local row = scenario.node.data:get( i )
        local line = self:get_id()
        self.used_lines[ line ] = { "CARTESIAN_POINT", tostring(row[ 1 ]), "#"..line.."=CARTESIAN_POINT('"..tostring( row[ 1 ] ).."',("..row[2]..","..row[3]..","..row[4].."));" }
        self.node_lines[ row[ 1 ] ] = { line, row[2], row[3], row[4] }
    end
end

function STEP:set_lines( scenario )
    --LINE( 'element_id', node1, VECTOR );
    --VECTOR( 'element_id', DIRECTION, element_length );
    --DIRECTION( 'element_id', ( normalized_vector_with_node2 ) );
    --Get scenario
    scenario = fem.sce[ scenario ]
    --Set directions
    local i, k, v
    for i = 1, scenario.element.data.itens do
        local row = scenario.element.data:get( i )
        local line = self:get_id()
        local pnt1 = {}
        local pnt2 = {}
        for i = 1, 3 do
            pnt1[ i ] = self.node_lines[ row[2] ][ i + 1 ]
            pnt2[ i ] = self.node_lines[ row[3] ][ i + 1 ]
        end
        local direction = vector.new( pnt1, pnt2 )
        self.used_lines[ line ] = { "DIRECTION", tostring( row[ 1 ] ), "#"..line.."=DIRECTION('"..row[ 1 ].."',("..direction.normalized[1]..","..direction.normalized[2]..","..direction.normalized[3].."));" }
    end
    --Set vectors
    for i = 1, scenario.element.data.itens do
        local row = scenario.element.data:get( i )
        local line = self:get_id()
        local DIRECTION
        for k, v in pairs( self.used_lines ) do
            if( v[1] == "DIRECTION" ) and ( v[2] == row[1] ) then DIRECTION = k break end
        end
        self.used_lines[ line ] = { "VECTOR", tostring( row[ 1 ] ), "#"..line.."=VECTOR('"..row[ 1 ].."',#"..DIRECTION..","..row[6]..");" }
    end
    --Set lines
    for i = 1, scenario.element.data.itens do
        local row = scenario.element.data:get( i )
        local line = self:get_id()
        local VECTOR
        local CARTESIAN_POINT
        for k, v in pairs( self.used_lines ) do
            if( v[1] == "CARTESIAN_POINT" ) and ( v[2] == row[2] ) then CARTESIAN_POINT = k end
            if( v[1] == "VECTOR" ) and ( v[2] == row[1] ) then VECTOR = k break end
        end
        self.used_lines[ line ] = { "LINE", tostring( row[ 1 ] ), "#"..line.."=LINE('"..row[ 1 ].."',#"..CARTESIAN_POINT..",#"..VECTOR..");" }
    end
end

--[[step = {--Fixed entities
    main_vbox = gtk.VBox.new( false, 0 ),
    view = { --Mesh view window
        window = gtk.Window.new( gtk.WINDOW_TOPLEVEL ),
    },
    sce = {},--Table for all scenario STEPview instances
}

function mesh:build()
    self.view.window:set_title( Label.MESH.window_name )

    --self.view.window:show_all()
end]]
