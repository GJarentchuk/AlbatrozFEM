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


--File with English language version
lang_en = {
    --Common buttons
    button_ok = "OK",
    button_apply = "Apply",
    button_cancel = "Cancel",
    --Create new project window
    new_project_windowname = "Create new project",
    new_project_label      = gtk.Label.new( "Project name" ),
    --Preferences window
    pref_window_name           = "Preferences",
    pref_working_dir_frame     = "Working Directory",
    pref_working_dir_label     = gtk.Label.new( "Set working directory" ),
    pref_default_project_frame = gtk.Label.new( "Default Project" ),
    pref_default_project_but_label = "Load default project at program startup",
    pref_default_project_label = gtk.Label.new( "Default project path" ),
    FEM = {
        tab_name       = gtk.Label.new( "Finite Elements" ),
        --Toolbar buttons
        add_node         = "Add node",
        pattern_add_node = "Pattern add node",
        add_scenario     = "New scenario",
        del_scenario     = "Delete scenario",
        delete_node      = "Delete nodes",
        add_constraint   = "Add constraint",
        del_constraint   = "Delete constraint",
        view_mesh        = "View mesh on Gmsh",
        run              = "Config and run\n    simulation",
        view             = "View results",
        add_element      = "Add element",
        material_label   = gtk.Label.new( "Element material" ),
        change_material  = "Change element\n        material",
        del_element      = "Delete element",
        export_nodes     = "Export nodes to \"Excel\" (tsv)",
        import_nodes     = "Import nodes from \"Excel\" (tsv)",
        add_load         = "Add load",
        del_load         = "Delete load",
        inertia_loads    = "Add inertia loads",
        --New scenario
        new_scenario_window = "Type scenario name",
        --Pattern add
        pattern_add_info = gtk.Label.new(
[[Select the attributes you want to repeat
       and add nodes repeating them]] ),
        id_label =  gtk.Label.new("ID"),
        x_label  =  gtk.Label.new("X"),
        y_label  =  gtk.Label.new("Y"),
        z_label  =  gtk.Label.new("Z"),
        n_nodes  = gtk.Label.new( "Number of nodes" ),
        p_add_m_nodes = "Add all \"n\" nodes",
        p_add_node = "Add one node",
        --Add constraint
--        const_window  = "Add constraints",
--        const_info    = gtk.Label.new(
--[[Check the desired constraints, select the nodes to apply them
--                in the "Nodes" table and click "apply" ), ]]
--        const_block_t = gtk.Label.new( "Block translation in" ),
--        const_block_r = gtk.Label.new( "Block rotation in" ),
--        const_x       = "in X axis",
--        const_y       = "in Y axis",
--        const_z       = "in Z axis",
        --Node
        node_frame = "Nodes",
        --Element
        element_frame = "Elements",
        view_id       = "ID",
        view_node1    = "Node 1",
        view_node2    = "Node 2",
        view_length   = "Length [ mm ]",
        view_z_axis   = "Z axis or.",
        view_area     = "Sec. Area [ mm^2 ]",
        view_Iyy      = "Moment of\nInertia yy [ mm^4 ]",
        view_Izz      = "Moment of\nInertia zz [ mm^4 ]",
        view_polar    = "Polar moment\nof In. [ mm^4 ]",
        view_E        = "E [ MPa ]",
        view_G        = "G [ MPa ]",
        view_mass     = "Mass [ kg ]",
        view_type     = "Element type",
        --Load
        load_frame     = "Loads",
        load_id        = "ID",
        load_node      = "Node",
        load_value     = "Value",
        load_direction = "Direction",
        load_window    = "Add Concentrated load",
        load_id_prefix = gtk.Label.new( "Load ID prefix to selected nodes" ),
        load_2nd_prefix = "ID 2nd prefix",
        load_F_frame   = "Force [ N ]",
        load_M_frame   = "Moment [ N.m ]",
        load_Xaxis     = "X axis",
        load_Yaxis     = "Y axis",
        load_Zaxis     = "Z axis",
        load_value     = "Value",
        load_apply     = "Apply loads to selected nodes",
        acceleration_v = "Acceleration vector (x y z) in m/s^2",
        --Constraint
        constraint_frame   = "Constraints",
        constraint_id      = "ID",
        constraint_node    = "Node",
        constraint_type    = "Type",
        constraint_trans_x = "      Block\nTranslation\n  in X axis?",
        constraint_trans_y = "      Block\nTranslation\n  in Y axis?",
        constraint_trans_z = "      Block\nTranslation\n  in Z axis?",
        constraint_rot_x   = "   Block\nRotation\nin X axis?",
        constraint_rot_y   = "   Block\nRotation\nin Y axis?",
        constraint_rot_z   = "   Block\nRotation\nin Z axis?",
        --Run
        run_window  = "Pre-run check",
        run_button  = "Run simulation",
        open_script = "View calculation script",
        --Results
        res_window      = "Simulation results",
        sce_combo_label = "View results from",
        total_mass      = "Total project mass",
        save_results    = "Save results to \"Excel\" (tsv)",
        view_on_gmsh    = "View on Gmsh",
        scale           = "Scale",
        disp_label      = "Displacements",
        def_label       = "Deformed mesh",
        stress_label    = "Maximum stress",
        res_options     = "View Options",
        stress_fail     = "Show maximum equivalent stress",
        stress_normal   = "Show only normal stress",
        stress_shear    = "Show only shear stress",
        normalized      = "View stress as fraction of failure tension",
        with_buckling   = "With buckling",
        no_fail         = "Use max. stress as scale maximum value",
        with_node_id    = "With node ids",
        with_elem_id    = "With element ids",

    },
    MESH = {
        --For view
        window_name      = "STEPmesh model view",
        tab_name         = gtk.Label.new( "MeshTools" ),
        export_step      = "Export mesh to STEP",
        export_window    = "Export scenario mesh to STEP file (.stp)",
        export_button    = "Export file",
        filename         = "Filename",
        browse           = "Browse folder",
        file_description = "File description",
        --For class
        linear_button    = "      Linear\ninterpolation",
        arc_button       = "        Arc\ninterpolation",
        ok               = "OK",
        apply            = "Apply",
        n_label          = "N elements to interpolate",
        e_label          = "Selected element to divide",
        n1_label         = "Selected node 1",
        n2_label         = "Selected node 2",
        divide           = "Divide one element into N parts",
        with_node        = "Create N elements from two nodes",
        arc_label        = "Select two nodes for arc or one node\nfor circle and another for the center",
        arc_entry_label  = "Arc center point",
        z_label_1        = "Z vector:",
        z_label_2        = ",from node:",
    },
    MATERIAL = {
        --For frame
        material = "Material",
        material_view = "Material/\nComponent",
        tab_name = gtk.Label.new( "Material-component" ),
        --For material manager
        manager_frame = "Material manager",
        view_column_1 = "Material-components in library",
        view_column_2 = "Material-components in project",
        view_column_3 = "Property",
        view_column_4 = "Value",
        view_column_5 = "Unit",
        --For material settings
        set_frame      = "Material settings",
        new_material   = "New material",
            new_material_dialog = "Type new material-component name",
        edit_material  = "Edit material",
        del_material   = "Delete material",
        geometry_label = gtk.Label.new( "Cross section geometry" ),
        save_material  = "Save to library",
        cancel         = "Cancel",
        element_type   = "Element type",
        --Cross section
        rectangular = "Rectangular",
            rec_width_label = "Width (w)",
            rec_height_label = "Height (h)",
        circular = "Circular",
            cir_diameter_label = "Diameter (D)",
        tubular = "Tubular",
            tub_in_diameter_label = "Inner Diameter (Di)",
            tub_out_diameter_label = "Outer Diameter (Do)",
        --Material settings treeview
        name = "Name",
        density = "Density",
        area = "Cross section area",
        Iyy = "Area moment of inertia Iyy",
        Izz = "Area moment of inertia Izz",
        polar = "Polar moment of inertia",
        E = "Longitudinal elastic modulus [E]",
        G = "Transverse elastic modulus [G]",
        fail = "Failure tension",
        fail_type = "Fragile, Ductile or Composite?",
        f_shear_y = "Shear factor (y dir)",
        f_shear_z = "Shear factor (z dir)",
        f_torsion = "Torsion factor",
        error = "Fill all the empty fields!!!",
    }
}

lang_en.__index = lang_en

function lang_en.new()
    tbl = {}
    setmetatable(tbl, lang_en)
    return tbl
end
