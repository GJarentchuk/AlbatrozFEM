--AlbatrozFEM main file

--TO RUN: SET PATH=%CD%\\GTK2;%PATH% & lua AlbatrozFEM.lua

--Add GTK2 to lua module search folders
local curr_dir = io.popen("cd"):read('*l')
package.path  = curr_dir.."\\GTK2\\lua\\?.lua;"..curr_dir.."\\GTK2\\lua\\?\\init.lua;" .. package.path
package.cpath = curr_dir.."\\GTK2\\clibs\\?.dll;"..curr_dir.."\\Binaries\\?.dll;"..curr_dir.."\\clibs\\?\\init.dll;" .. package.cpath

--Libraries
require("lgob.gdk")
require("lgob.gtk")
require("letk") --WARNING, a modified version of letk is being used, check init file foi info
require("Libraries\\treeview")
require("Libraries\\Mathematics")
require("Libraries\\Simulation")
--require("Libraries\\Explicit_global_stiffness")
require("Libraries\\GMSH")
--Modules
require("Modules\\FEM")
require("Modules\\MeshTools")
require("Modules\\Material")
require("Material Library\\mat_list")
--Languages
require("Languages\\lang_en")
--Warning: Capital letter denotes "class" while lower case with the same name denotes main class entity (see window)

--FAZER CONFIG DA LINGUA

--Standard definitions
std = {
    file = nil,
    main_window_name = "Albatroz Parametric v2.0",
    icon_size = gtk.ICON_SIZE_SMALL_TOOLBAR, --Buttons icon size
}

--Configurations
config = {
    lang = "",
    working_directory = "",
    name = "",
}

--Main data structure
Main = {
    Window = {},
    Toolbar = {},
    Notebook = {},
}

--Class project
proj = {
    name = nil,
}

Label = {} --Strings affected by language settings

--Functions

--Builds buttons
function build_button( is_stock, icon, label, type_of_button, size )
    if( type_of_button == "icon" ) then
        button = gtk.Button.new()
        if( is_stock == 1 )then
            icon = gtk.Image.new_from_stock( stock_icon_type, size )
        else
            icon = gtk.Image.new_from_file( icon )
        end
        button:set_image( icon )
        return button
    elseif( type_of_button == "label" ) then
        button = gtk.Button.new_with_label( label )
        return button
    elseif( type_of_button == "all" ) then
        button    = gtk.Button.new()
        hbox      = gtk.HBox.new( false, 2 )
        if( is_stock == 1 )then
            icon = gtk.Image.new_from_stock( icon, size )
        else
            icon = gtk.Image.new_from_file( icon )
        end
        gtk_label = gtk.Label.new( label )
        hbox:pack_start( icon, false, false, 0 )
        hbox:pack_start( gtk_label, false, false, 0 )
        button:add     ( hbox )
        return button
    end
end

--Builds toolbar buttons
function build_toolbutton( is_stock, icon, label, type_of_button )
    if( type_of_button == "icon" ) then
        if( is_stock == 1 )then
            icon = gtk.Image.new_from_stock( icon )
        else
            icon = gtk.Image.new_from_file( icon )
        end
        button = gtk.ToolButton.new( icon, nil )
        return button
    elseif( type_of_button == "label" ) then
        button = gtk.ToolButton.new( nil, label )
        return button
    elseif( type_of_button == "all" ) then
        if( is_stock == 1 )then
            icon = gtk.Image.new_from_stock( icon )
        else
            icon = gtk.Image.new_from_file( icon )
        end
        gtk_label = gtk.Label.new( label )
        button = gtk.ToolButton.new( icon, label )
        return button
    end
end

--Load Config.cfg file
function load_config()
    local file = loadfile( "Config.lua" )
    file()
    config.lang                       = lang print( "Language = "..config.lang )
    config.program_directory          = program_directory
    config.working_directory          = working_directory
    config.start_with_default_project = start_with_default_project
    config.default_project            = default_project
    config.gmsh_folder                = gmsh_folder
    config.gmsh_model_folder          = gmsh_model_folder
    config.default_inertia_acc_x      = default_inertia_acc_x
    config.default_inertia_acc_y      = default_inertia_acc_y
    config.default_inertia_acc_z      = default_inertia_acc_z
end

--Save Config.cfg file
function save_config()
    local file = io.open( "Config.lua", "w" )
    file:write( "--Linhas com \"--\" são comentários\n\n" )
    file:write( "lang = \""..config.lang.."\"\n" )
        local text = string.gsub( config.program_directory, "\\", "\\\\" )
    file:write( "program_directory = \""..text.."\"\n" )
        text = string.gsub( config.working_directory, "\\", "\\\\" )
    file:write( "working_directory = \""..text.."\"\n" )
    file:write( "start_with_default_project = "..tostring( config.start_with_default_project ).."\n" )
        text = string.gsub( config.default_project, "\\", "\\\\" )
    file:write( "default_project = \""..text.."\"\n" )
        text = string.gsub( config.gmsh_folder, "\\", "\\\\" )
    file:write( "gmsh_folder = \""..text.."\"\n" )
        text = string.gsub( config.gmsh_model_folder, "\\", "\\\\" )
    file:write( "gmsh_model_folder = \""..text.."\"\n" )
        text = config.default_inertia_acc_x
    file:write( "default_inertia_acc_x = \""..text.."\"\n" )
        text = config.default_inertia_acc_y
    file:write( "default_inertia_acc_y = \""..text.."\"\n" )
        text = config.default_inertia_acc_z
    file:write( "default_inertia_acc_z = \""..text.."\"\n" )
    file:close()
end

--Set language (ONLY ENGLISH HAS BEEN IMPLEMENTED)
function set_lang( lang )
    if( lang == "English" ) then
        Label = lang_en.new()
    elseif( lang == "Português BR" ) then
    end
end

--Build main notebook
function build_main_notebook()
    Main.notebook                = gtk.Notebook.new()
    Main.Notebook.FEM_page       = fem.main_vbox
    Main.Notebook.MESH_page      = mesh.main_vbox
    Main.Notebook.MATERIAL_page      = material.main_hbox

    Main.notebook:insert_page( Main.Notebook.FEM_page, Label.FEM.tab_name, -1 )
    Main.notebook:insert_page( Main.Notebook.MESH_page, Label.MESH.tab_name, -1 )
    Main.notebook:insert_page( Main.Notebook.MATERIAL_page, Label.MATERIAL.tab_name, -1 )
    Main.notebook:set        ( "enable-popup", true, "scrollable", true )

    Main.notebook:connect( "switch-page", function()
                                          for k, v in pairs( fem.sce ) do
                                            fem.sce[ k ].node:update()
                                            mesh.sce[ k ].node:update()
                                            fem.sce[ k ].element:update()
                                            mesh.sce[ k ].element:update()
                                          end
                                          end )

    Main.Window.vbox:pack_start( Main.notebook, false, false, 1 )
    Main_window:show_all       ()
end

--Callbacks
--Preferences window
function preferences_window()
    pref = {}
    pref.window            = gtk.Window.new( gtk.WINDOW_TOPLEVEL )
    pref.main_vbox         = gtk.VBox.new( false, 0 )

    pref.working_dir_frame = gtk.Frame.new( Label.pref_working_dir_frame )
        pref.working_dir_hbox    = gtk.HBox.new( false, 0 )
        --pref.working_dir_label = Label.pref_working_dir_label
        pref.working_dir_entry   = gtk.Entry.new()
        pref.working_dir_set_but = build_button( 1, "gtk-apply", "Set", "all", std.icon_size )

        pref.working_dir_hbox:pack_start( Label.pref_working_dir_label, false, false, 1 )
        pref.working_dir_hbox:pack_start( pref.working_dir_entry, false, false, 1 )
        pref.working_dir_hbox:pack_start( pref.working_dir_set_but, false, false, 1 )
        pref.working_dir_frame:add( pref.working_dir_hbox )

    pref.default_project_frame = gtk.Frame.new( Label.pref_default_project_frame )
        pref.default_project_hbox   = gtk.HBox.new( false, 0 )
        pref.default_project_button = gtk.CheckButton.new_with_label( Label.pref_default_project_but_label )
        pref.default_project_sep    = gtk.VSeparator.new()
        pref.default_project_entry  = gtk.Entry.new()

        pref.default_project_hbox:pack_start( pref.default_project_button, false, false, 1 )
        pref.default_project_hbox:pack_start( pref.default_project_sep, false, false, 1 )
        pref.default_project_hbox:pack_start( Label.pref_default_project_label, false, false, 1 )
        pref.default_project_hbox:pack_start( pref.default_project_entry, false, false, 1 )
        pref.default_project_frame:add( pref.default_project_hbox )

    pref.ok_but = build_button( 1, "gtk-ok", Label.button_ok, "all", std.icon_size )

    pref.window:set_title( Label.pref_window_name )
    pref.window:set_deletable( false )

    --Config load
    pref.working_dir_entry:set_text( config.working_directory )
    pref.default_project_button:set( "active", config.start_with_default_project )
    pref.default_project_entry:set_text ( config.default_project )


    pref.ok_but:connect             ( "clicked", function()
                                                    --config.start_with_default_project = pref.default_project_entry:get( "active" )
                                                    save_config()
                                                    pref.window:destroy() end )
    pref.working_dir_set_but:connect( "clicked", function() config.working_directory = pref.working_dir_entry:get_text() end )
    pref.default_project_button:connect( "toggled", function()
                                                        if( config.start_with_default_project == true ) then
                                                            config.start_with_default_project = false
                                                            pref.default_project_button:set( "active", config.start_with_default_project )
                                                        else
                                                            config.start_with_default_project = true
                                                            pref.default_project_button:set( "active", config.start_with_default_project )
                                                        end
                                                    end )

    pref.main_vbox:pack_start( pref.working_dir_frame, false, false, 1 )
    pref.main_vbox:pack_start( pref.default_project_frame, false, false, 1 )
    pref.main_vbox:pack_end  ( pref.ok_but, false, false, 1 )

    pref.window:add( pref.main_vbox )
    pref.window:show_all()
end

--Create new project
function new_project_window()
    project_dialog = gtk.Window.new( gtk.WINDOW_TOPLEVEL )
    project_dialog:set_title( Label.new_project_windowname )
        project_dialog:set_default_size( 100, 50 )
        project_dialog:set_position( gtk.WIN_POS_CENTER )
    vbox = gtk.VBox.new( false, 0 )
    hbox = gtk.HBox.new( false, 0 )
    text_box = gtk.Entry.new()

    text_box:connect( "activate", function() new_project( text_box:get_text() ) project_dialog:destroy() end )

    project_dialog:add( vbox )
    vbox:pack_start( hbox, false, false, 0 )
    hbox:pack_start( Label.new_project_label, false, false, 0 )
    hbox:pack_start( text_box, false, false, 0 )
    project_dialog:show_all()
end

--Create project file
function new_project( filename, save_as )
    std.file = io.open( config.working_directory.."\\"..filename..".pro", "w" )
    std.file:write( "name = ".."\""..filename.."\"\n" )
    std.file:write( "sce = {}\n" )
    std.file:write( "materials = {}\n" )
    std.file:close()
    filename = config.working_directory.."\\"..filename..".pro"
--    fem.sce  = {}
--    mesh.sce = {}
--    Res.sce  = {}
    open_project( filename )
end

--Save project file
function save_project( filename, new_name )
    std.file = io.open( filename, "w" )
    --Project atributtes
    if( new_name == nil ) then
        std.file:write( "name = ".."\""..proj.name.."\"\n" )
    else
        std.file:write( "name = ".."\""..new_name.."\"\n" )
    end
    --FEM
    --Scenarios
    std.file:write( "fem.sce = {}\n" )
    local k, v
    local i
    for k, v in pairs( fem.sce ) do
        std.file:write( "fem.sce."..k.." = FEM.new( \""..k.."\" )\n" )
        std.file:write( "mesh.sce."..k.." = MESH.new( \""..k.."\" )\n" )
        --Save node data
        for i = 1, ( fem.sce[ k ].node.data:len() ) do
            std.file:write( "fem.sce."..k..".node:add_row( { ".."\""..fem.sce[ k ].node.data:get( i )[ 1 ].."\""..", "..
                                                                   fem.sce[ k ].node.data:get( i )[ 2 ]..", "..
                                                                   fem.sce[ k ].node.data:get( i )[ 3 ]..", "..
                                                                   fem.sce[ k ].node.data:get( i )[ 4 ].." } )\n" )
            if( tonumber( fem.sce[ k ].node.data:get( i )[ 1 ] ) == nil ) then
                std.file:write( "fem.sce."..k..".node.id_list."..fem.sce[ k ].node.data:get( i )[ 1 ].." = 1\n" )
                std.file:write( "fem.sce."..k..".node.linkage."..fem.sce[ k ].node.data:get( i )[ 1 ].." = {}\n" )
            else
                std.file:write( "fem.sce."..k..".node.id_list[ \""..fem.sce[ k ].node.data:get( i )[ 1 ].."\" ] = 1\n" )
                std.file:write( "fem.sce."..k..".node.linkage[ \""..fem.sce[ k ].node.data:get( i )[ 1 ].."\" ] = {}\n" )
            end
        end
        std.file:write( "fem.sce."..k..".node:update()\n\n" )
        --Save element data
        --std.file:write( "sce."..k..".element
    end

    --Materials
    std.file:write( "\n" )
    std.file:write( "materials = {}\n")
    i = 1
    for k, v in pairs( proj.material ) do
        std.file:write( "materials[ "..i.." ] = \""..v.."\"\n" )
        i = i + 1
    end

    std.file:write( "\n" )
    --Save element data for scenarios
    for k, v in pairs( fem.sce ) do
        for i = 1, ( fem.sce[ k ].element.data:len() ) do
            std.file:write( "fem.sce."..k..":add_element( true, { ".."\""..fem.sce[ k ].element.data:get( i )[ 1 ].."\", "..
                                                                 "\""..fem.sce[ k ].element.data:get( i )[ 2 ].."\", "..
                                                                 "\""..fem.sce[ k ].element.data:get( i )[ 3 ].."\", "..
                                                                 "\""..fem.sce[ k ].element.data:get( i )[ 4 ].."\", "..
                                                                 "\""..fem.sce[ k ].element.data:get( i )[ 7 ].."\" }, false )\n" )
        end
        std.file:write( "fem.sce."..k..".element:update()\n\n" )
    end
    --Save node constranits
    for k, v in pairs( fem.sce ) do
        for i = 1, ( fem.sce[ k ].constraint.data:len() ) do
            std.file:write( "fem.sce."..k..":add_constraint( { "..
                                            "\""..fem.sce[ k ].constraint.data:get( i )[ 1 ].."\", "..
                                            ""..tostring( fem.sce[ k ].constraint.data:get( i )[ 2 ] )..", "..
                                            ""..tostring( fem.sce[ k ].constraint.data:get( i )[ 3 ] )..", "..
                                            ""..tostring( fem.sce[ k ].constraint.data:get( i )[ 4 ] )..", "..
                                            ""..tostring( fem.sce[ k ].constraint.data:get( i )[ 5 ] )..", "..
                                            ""..tostring( fem.sce[ k ].constraint.data:get( i )[ 6 ] )..", "..
                                            ""..tostring( fem.sce[ k ].constraint.data:get( i )[ 7 ] )..", "..
                                            "}, true )\n" )
        end
        std.file:write( "fem.sce."..k..".constraint:update()\n\n" )
    end
    --Save loads
    for k, v in pairs( fem.sce ) do
        for i = 1, ( fem.sce[ k ].load.data:len() ) do
            std.file:write( "fem.sce."..k..":add_load( { "..
                                            "\""..fem.sce[ k ].load.data:get( i )[ 1 ].."\", "..
                                            "\""..fem.sce[ k ].load.data:get( i )[ 2 ].."\", "..
                                            "\""..fem.sce[ k ].load.data:get( i )[ 3 ].."\", "..
                                            "\""..fem.sce[ k ].load.data:get( i )[ 4 ].."\" } )\n" )
        end
        std.file:write( "fem.sce."..k..".load:update()\n\n" )
    end

    --Save results
    for k, v in pairs( Res ) do
        v:save_results( std.file )
    end

    std.file:close()
    --Keeps the filename
    std.file = filename
end

--Clone project (save as)
function save_as( filename )
    new_name = string.gsub( filename, ".pro", "" )
    new_name = string.gsub( new_name, config.working_directory.."\\", "" )
    save_project( filename, new_name )
--    open_project( filename )
end

--Save as dialog
function save_as_dialog()
    dialog = gtk.FileChooserDialog.new( "Save project as", Main_window, gtk.FILE_CHOOSER_ACTION_SAVE,
                                       "gtk-cancel", gtk.RESPONSE_CANCEL, "gtk-ok", gtk.RESPONSE_OK )
    filter_pro = gtk.FileFilter.new()
    filter_all = gtk.FileFilter.new()
    filter_pro:add_pattern( "*.pro" )
    filter_pro:set_name( "Project files" )
    filter_all:add_pattern( "*" )
    filter_all:set_name( "All files" )
    dialog:add_filter( filter_pro )
    dialog:add_filter( filter_all )
    dialog:set_current_folder( config.working_directory )
    if( dialog:run() == gtk.RESPONSE_OK ) then
        local filename = dialog:get_filename()
        save_as( filename )
        dialog:destroy()
    elseif( dialog:run() == gtk.RESPONSE_CANCEL ) then
        dialog:destroy()
    end
end

--Create open dialog
function open_dialog()
    dialog = gtk.FileChooserDialog.new( "Open File", Main_window, gtk.FILE_CHOOSER_ACTION_OPEN,
                                       "gtk-cancel", gtk.RESPONSE_CANCEL, "gtk-ok", gtk.RESPONSE_OK )
    filter_pro = gtk.FileFilter.new()
    filter_all = gtk.FileFilter.new()
    filter_pro:add_pattern( "*.pro" )
    filter_pro:set_name( "Project files" )
    filter_all:add_pattern( "*" )
    filter_all:set_name( "All files" )
    dialog:add_filter( filter_pro )
    dialog:add_filter( filter_all )
    dialog:set_current_folder( config.working_directory )

    if( dialog:run() == gtk.RESPONSE_OK ) then
        filename = dialog:get_filename()
        open_project( filename )
        dialog:destroy()
    elseif( dialog:run() == gtk.RESPONSE_CANCEL ) then
        dialog:destroy()
    end
end

--Open project file
function open_project( filename )
    Res = {}
    fem.sce = {}
    materials = {}
    if( proj.name ~= nil )then
        Main.notebook:destroy()
        --fem.main_vbox:destroy()
        std.main_window_name = "Albatroz Parametric v2.0"
        --Empty data
        materials = {}
        proj.material = {}
        material.manager_proj:update()
    end
    std.file = loadfile( filename )
    print( std.file, filename, loadfile( filename ) )
    std.file()
    --Project name and material
    proj.name = name
    proj.material = {}
    std.main_window_name = std.main_window_name.." - "..name..".pro"
    Main_window:set_title( std.main_window_name )
    --Material settings
    material:build()
    --Toolbar settings
    build_main_notebook()
    fem.build()
    mesh:build()
    --FEM scenarios
    --fem.sce = sce
    --MATERIALs
    local i
    if( #materials > 0 ) then
        for i = 1, #materials do
            --print( materials[i] )
            material:add_material_to_project( materials[i] )
        end
        fem.tool.material_combobox:set_active( 0 )
    end
    --Load previous results
    for k, v in pairs( Res ) do
        v:import_results_from_project()
    end

    --Updates MeshTools
    for k, v in pairs( fem.sce ) do
        mesh.sce[ k ].node:update()
        mesh.sce[ k ].element:update()
    end
    --Finish keeping the filename
    std.file = filename
    Main.notebook:set_current_page( 0 )
end

function set_this_as_start_project()
    config.default_project = std.file
    save_config()
end

Bind = {}

--Space key binding function
function Bind.key( widget, event, param )
    local a,b,c,d,key = gdk.event_key_get( event )
    if( key == 65 ) then --"shift" key
        if( fem.tool.add_element_toogle:get( "active" ) == true ) then
            local scenario = fem.notebook:get_tab_label( fem.page_child[ fem.notebook:get( "page" ) ] )
            scenario = scenario:get_text()
            fem.sce[ scenario ]:add_element( false, nil, false )
        end
    end
end

--Main execution function: creates the base window and calls all initialization functions
function main()
    --Configurations
    load_config()
    set_lang( config.lang )

    --Creation of entities
    --Main.window                  = gtk.Window.new( gtk.WINDOW_TOPLEVEL )
    Main_window                  = gtk.Window.new( gtk.WINDOW_TOPLEVEL )
    --Main.window                  = gtk.ScrolledWindow.new( nil, nil )
    Main.Window.vbox             = gtk.VBox.new( false, 0 )
    Main.toolbar                 = gtk.Toolbar.new()
        Main.Toolbar.new_file_icon = gtk.Image.new_from_stock( "gtk-new" )
    Main.Toolbar.new_file        = gtk.ToolButton.new( Main.Toolbar.new_file_icon, nil )
        Main.Toolbar.open_project_icon    = gtk.Image.new_from_stock( "gtk-open" )
    Main.Toolbar.open_project    = gtk.ToolButton.new( Main.Toolbar.open_project_icon, nil )
        Main.Toolbar.save_project_icon    = gtk.Image.new_from_stock( "gtk-save" )
    Main.Toolbar.save_project    = gtk.ToolButton.new( Main.Toolbar.save_project_icon, nil )
        Main.Toolbar.save_as_project_icon = gtk.Image.new_from_stock( "gtk-save-as" )
    Main.Toolbar.save_as_project = gtk.ToolButton.new( Main.Toolbar.save_as_project_icon, nil )
        Main.Toolbar.startup_icon         = gtk.Image.new_from_stock( "gtk-goto-bottom" )
    Main.Toolbar.startup         = gtk.ToolButton.new( Main.Toolbar.startup_icon, nil )
        Main.Toolbar.preferences_icon     = gtk.Image.new_from_stock( "gtk-preferences" )
    Main.Toolbar.preferences     = gtk.ToolButton.new( Main.Toolbar.preferences_icon, nil )
        Main.Toolbar.about_icon           = gtk.Image.new_from_stock( "gtk-about" )
    Main.Toolbar.about           = gtk.ToolButton.new( Main.Toolbar.about_icon, nil )

    --Settings
    --Main window
    --Main.window:set_policy( gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC )
    Main_window:set_title( std.main_window_name )
    --Main.window:set_position( gtk.WIN_POS_CENTER )
    Main_window:set_icon_from_file( "Icons\\Albatroz.png" )
    Main_window:set_default_size( 900, 650 )
    --Toolbar
    Main.toolbar:set_style( gtk.TOOLBAR_ICONS )
    Main.toolbar:insert   ( Main.Toolbar.new_file, -1 )
    Main.toolbar:insert   ( Main.Toolbar.open_project, -1 )
    Main.toolbar:insert   ( Main.Toolbar.save_project, -1 )
    Main.toolbar:insert   ( Main.Toolbar.save_as_project, -1 )
    Main.toolbar:insert   ( Main.Toolbar.startup, -1 ) --For setting current project as starting project
    Main.toolbar:insert   ( Main.Toolbar.preferences, -1 )
    Main.toolbar:insert   ( Main.Toolbar.about, -1 )

    --Events
    Main_window:connect              ( "delete-event", gtk.main_quit )
    Main.Toolbar.new_file:connect    ( "clicked", function() new_project_window() end )
    Main.Toolbar.save_project:connect( "clicked", function() save_project( std.file ) end )
    Main.Toolbar.save_as_project:connect( "clicked", function() save_as_dialog() end )
    Main.Toolbar.open_project:connect( "clicked", function() open_dialog() end )
    Main.Toolbar.startup:connect ( "clicked", function() set_this_as_start_project( std.file ) end )
    Main.Toolbar.preferences:connect ( "clicked", function() preferences_window() end )
    --Press space key event
    --Main_window:connect( "key-press-event" , Bind.key, Main_window )

    --Boxing
    Main.Window.vbox:pack_start( Main.toolbar, false, false, 1 )
    --Main.window:add_with_viewport( Main.Window.vbox )
    Main_window:add            ( Main.Window.vbox )
    Main_window:show_all       ()

    if( config.start_with_default_project == true ) then
        open_project( config.default_project )
    end

    --Cholesky test
--    local A = Matrix:new( { {4,2,-2}, {2,10,2}, {-2,2,5} } )
--    local B, Bt = A:Cholesky_decompostion()
--    B:print()
--    Bt:print()
    --Solve_linsys_with_Cholesky test
--    local B = Matrix:new( { {-2},{4},{3},{-5},{1} } )
--    local A = Matrix:new( { {2,1,1,3,2}, {1,2,2,1,1}, {1,2,9,1,5}, {3,1,1,7,1}, {2,1,5,1,8} } )
--    local x = A:Solve_linsys_with_Cholesky( B )
--    x:print()

--    local A = Matrix:new( {{2,1}, {1,2}} )
--    local B = Matrix:new( {{5},{4}} )
--    x = A:Solve_linsys_with_iterative_method( nil, B, 1e-12, "no" )

    gtk.main()
end

main()
