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


--This file contains the operations for the simulation run. For details on  more basic math operations, like cross product
--and LU factorization, please check "Mathematic.lua" file
ElementType = { --Elements types list
    Standard = {
        x_axis = vector.new( {0,0,0}, {1,0,0} ),
        z_axis = vector.new( {0,0,0}, {0,0,1} ),
        E   = 1,
        A   = 1,
        L   = 1,
        G   = 1,
        fsy = 1,
        fsz = 1,
        Izz = 1,
        Iyy = 1,
        J   = 1,
        ft  = 1,
        C1  = {
            [1.0]  = 0.208,
            [1.2]  = 0.219,
            [1.5]  = 0.231,
            [2.0]  = 0.246,
            [2.5]  = 0.258,
            [3.0]  = 0.267,
            [4.0]  = 0.282,
            [5.0]  = 0.291,
            [10.0] = 0.312,
            inf    = 0.333,
        },
        Q_rectangular = function( base, height, y ) return base*0.5*( ((height^2)/4) - y^2 ) end,
        Q_circular    = function( r, theta ) return ((2*(r^3)*(math.sin(theta)^3))/3) end,
        Q_tubular     = function() return 1 end,--Doesn't need this function
    },
    Variable = {},
    Spring   = {},
}
--Element type script
--Standard element
function ElementType.Standard:stiffness_build( only )
    --Creates a blank 12x12 matrix
    local stiff = Matrix:new( { rows = 12, columns = 12 } )
    local E   = self.E*1e6    --Young modulus [MPa to Pa]
    local A   = self.A/1e6    --Cross section area [mm^2 to m^2]
    local L   = self.L/1000   --Element length [mm to m]
    local G   = self.G*1e6    --Shear modulus [MPa to Pa]
    local fsy = self.fsy      --Shear factor in y direction
    local fsz = self.fsz      --Shear factor in z direction
    local Izz = self.Izz/1e12 --Moment of inertia, z axis [mm^4 to m^4]
    local Iyy = self.Iyy/1e12 --Moment of inertia, y axis [mm^4 to m^4]
    local J   = self.J/1e12   --Polar moment of inertia [mm^4 to m^4]
    local ft  = self.ft       --Torsion factor
    --print( E, L, Izz, ((12*E*Izz)/(L^3)) )
    if( only == "all" ) or ( only == "truss" ) or ( only == "no_shear" ) then
    --Axial stiffness ("Truss") -> x direction
    stiff[1][1] = (E*A)/L
    stiff[7][7] = stiff[1][1]
    stiff[1][7], stiff[7][1] = -stiff[1][1], -stiff[1][1]
--    stiff[1][1], stiff[7][7] = "EA/L", "EA/L"
--    stiff[1][7], stiff[7][1] = "-EA/L", "-EA/L"
    end
    if( only == "all" ) or ( only == "shear" ) then
    --Translation in y
    stiff[2][2], stiff[8][8]  = (((12*E*Izz)/(L^3))*((G*A*L^2)/((L^2)*G*A + 12*E*Izz*fsy))), (((12*E*Izz)/(L^3))*((G*A*L^2)/((L^2)*G*A + 12*E*Izz*fsy)))
    stiff[2][8], stiff[8][2]  = (-((12*E*Izz)/(L^3))*((G*A*L^2)/((L^2)*G*A + 12*E*Izz*fsy))), (-((12*E*Izz)/(L^3))*((G*A*L^2)/((L^2)*G*A + 12*E*Izz*fsy)))
    stiff[6][8], stiff[12][8] = (-((6*E*Izz)/(L^2))*((G*A*L^2)/((L^2)*G*A + 12*E*Izz*fsy))), (-((6*E*Izz)/(L^2))*((G*A*L^2)/((L^2)*G*A + 12*E*Izz*fsy)))
    stiff[6][2], stiff[12][2] = (((6*E*Izz)/(L^2))*((G*A*L^2)/((L^2)*G*A + 12*E*Izz*fsy))), (((6*E*Izz)/(L^2))*((G*A*L^2)/((L^2)*G*A + 12*E*Izz*fsy)))
    --Rotation in z
    stiff[2][6], stiff[2][12] = (((6*E*Izz)/(L^2))*((G*A*L^2)/((L^2)*G*A + 12*E*Izz*fsy))), (((6*E*Izz)/(L^2))*((G*A*L^2)/((L^2)*G*A + 12*E*Izz*fsy)))
    stiff[8][6], stiff[8][12] = (-((6*E*Izz)/(L^2))*((G*A*L^2)/((L^2)*G*A + 12*E*Izz*fsy))), (-((6*E*Izz)/(L^2))*((G*A*L^2)/((L^2)*G*A + 12*E*Izz*fsy)))
    local alpha = (12*fsy*E*Izz)/(G*A*L^2)
    stiff[6][6], stiff[12][12] = ((4*E*Izz)/L)*((4+alpha)/(4+4*alpha)), ((4*E*Izz)/L)*((4+alpha)/(4+4*alpha))
    stiff[6][12], stiff[12][6] = ((2*E*Izz)/L)*((2-alpha)/(2+2*alpha)), ((2*E*Izz)/L)*((2-alpha)/(2+2*alpha))

    --Translation in z
    stiff[3][3], stiff[9][9]  = (((12*E*Iyy)/(L^3))*((G*A*L^2)/((L^2)*G*A + 12*E*Iyy*fsz))), (((12*E*Iyy)/(L^3))*((G*A*L^2)/((L^2)*G*A + 12*E*Iyy*fsz)))
    stiff[3][9], stiff[9][3]  = (-((12*E*Iyy)/(L^3))*((G*A*L^2)/((L^2)*G*A + 12*E*Iyy*fsz))), (-((12*E*Iyy)/(L^3))*((G*A*L^2)/((L^2)*G*A + 12*E*Iyy*fsz)))
    stiff[5][3], stiff[11][3] = (-((6*E*Iyy)/(L^2))*((G*A*L^2)/((L^2)*G*A + 12*E*Iyy*fsz))), (-((6*E*Iyy)/(L^2))*((G*A*L^2)/((L^2)*G*A + 12*E*Iyy*fsz)))
    stiff[5][9], stiff[11][9] = (((6*E*Iyy)/(L^2))*((G*A*L^2)/((L^2)*G*A + 12*E*Iyy*fsz))), (((6*E*Iyy)/(L^2))*((G*A*L^2)/((L^2)*G*A + 12*E*Iyy*fsz)))
    --Rotation in y
    stiff[9][5], stiff[9][11] = (((6*E*Iyy)/(L^2))*((G*A*L^2)/((L^2)*G*A + 12*E*Iyy*fsz))), (((6*E*Iyy)/(L^2))*((G*A*L^2)/((L^2)*G*A + 12*E*Iyy*fsz)))
    stiff[3][5], stiff[3][11] = (-((6*E*Iyy)/(L^2))*((G*A*L^2)/((L^2)*G*A + 12*E*Iyy*fsz))), (-((6*E*Iyy)/(L^2))*((G*A*L^2)/((L^2)*G*A + 12*E*Iyy*fsz)))
    local alpha = (12*fsz*E*Iyy)/(G*A*L^2)
    stiff[5][5], stiff[11][11] = ((4*E*Iyy)/L)*((4+alpha)/(4+4*alpha)), ((4*E*Iyy)/L)*((4+alpha)/(4+4*alpha))
    stiff[5][11], stiff[11][5] = ((2*E*Iyy)/L)*((2-alpha)/(2+2*alpha)), ((2*E*Iyy)/L)*((2-alpha)/(2+2*alpha))
--    print( "Debug", stiff[3][5], stiff[5][3] )
    end
    if( only == "bean" ) or ( only == "no_shear" ) then
    --Bending stiffness ("Beam") -> y, z, rot_y and rot_z directions
    stiff[2][2], stiff[8][8] = stiff[2][2] + (12*E*Izz)/(L^3), stiff[8][8] + (12*E*Izz)/(L^3)
    stiff[2][8], stiff[8][2] = stiff[2][8] - (12*E*Izz)/(L^3), stiff[8][2] - (12*E*Izz)/(L^3)
    stiff[6][2], stiff[12][2] = (6*E*Izz)/(L^2), (6*E*Izz)/(L^2)
    stiff[6][8], stiff[12][8] = -(6*E*Izz)/(L^2), -(6*E*Izz)/(L^2)
----    stiff[2][2], stiff[8][8] = stiff[2][2].." + 12EIzz/L^3", stiff[8][8].." + 12EIzz/L^3"
----    stiff[2][8], stiff[8][2] = stiff[2][8].." + -12EIzz/L^3", stiff[8][2].." + -12EIzz/L^3"
----    stiff[6][2], stiff[12][2] = "6EIzz/L^2", "6EIzz/L^2"
----    stiff[6][8], stiff[12][8] = "-6EIzz/L^2", "-6EIzz/L^2"

    stiff[3][3], stiff[9][9] = stiff[3][3] + (12*E*Iyy)/(L^3), stiff[9][9] + (12*E*Iyy)/(L^3)
    stiff[3][9], stiff[9][3] = stiff[3][9] - (12*E*Iyy)/(L^3), stiff[9][3] - (12*E*Iyy)/(L^3)
    stiff[5][3], stiff[11][3] = (-6*E*Iyy)/(L^2), (-6*E*Iyy)/(L^2)
    stiff[5][9], stiff[11][9] = (6*E*Iyy)/(L^2), (6*E*Iyy)/(L^2)
----    stiff[3][3], stiff[9][9] = stiff[2][2].." + 12EIyy/L^3", stiff[8][8].." + 12EIyy/L^3"
----    stiff[3][9], stiff[9][3] = stiff[2][8].." + -12EIyy/L^3", stiff[8][2].." + -12EIyy/L^3"
----    stiff[5][3], stiff[11][3] = "-6EIyy/L^2", "-6EIyy/L^2"
----    stiff[5][9], stiff[11][9] = "6EIyy/L^2", "6EIyy/L^2"

    stiff[3][5], stiff[3][11] = (-6*E*Iyy)/(L^2), (-6*E*Iyy)/(L^2)
    stiff[9][5], stiff[9][11] = (6*E*Iyy)/(L^2), (6*E*Iyy)/(L^2)
    stiff[5][5], stiff[11][11] = (4*E*Iyy)/(L), (4*E*Iyy)/(L)
    stiff[11][5], stiff[5][11] = (2*E*Iyy)/(L), (2*E*Iyy)/(L)
----    stiff[3][5], stiff[3][11] = "-6EIyy/L^2", "-6EIyy/L^2"
----    stiff[9][5], stiff[9][11] = "6EIyy/L^2", "6EIyy/L^2"
----    stiff[5][5], stiff[11][11] = "4EI/L", "4EI/L"
----    stiff[11][5], stiff[5][11] = "2EI/L", "2EI/L"

    stiff[2][6], stiff[2][12] = (6*E*Iyy)/(L^2), (6*E*Iyy)/(L^2)
    stiff[8][6], stiff[8][12] = (-6*E*Iyy)/(L^2), (-6*E*Iyy)/(L^2)
    stiff[6][6], stiff[12][12] = (4*E*Izz)/(L), (4*E*Izz)/(L)
    stiff[6][12], stiff[12][6] = (2*E*Izz)/(L), (2*E*Izz)/(L)
----    stiff[2][6], stiff[2][12] = "6EI/L^2", "6EI/L^2"
----    stiff[8][6], stiff[8][12] = "-6EI/L^2", "-6EI/L^2"
----    stiff[6][6], stiff[12][12] = "4EI/L", "4EI/L"
----    stiff[6][12], stiff[12][6] = "2EI/L", "2EI/L"
    end
    if( only == "all" ) or ( only == "shaft" ) or ( only == "no_shear" ) then
    --Torsional stiffness
    if( self.geom == "Tubular" ) then
        local ri = (self.in_diameter/2)/1000
        local ro = (self.out_diameter/2)/1000
        local t  = ro - ri
        local Am = (( math.pi*( ri + (t/2) )^2 ))
        local S  = (((ro + ri)/2)*math.pi*2)
        stiff[4][4], stiff[10][10] = (4*G*Am*t)/(L*S), (4*G*Am*t)/(L*S)
        stiff[4][10], stiff[10][4] = (-4*G*Am*t)/(L*S), (-4*G*Am*t)/(L*S)
    else
        stiff[4][4], stiff[10][10] = (G*J)/(ft*L), (G*J)/(ft*L)
        stiff[4][10], stiff[10][4] = (-G*J)/(ft*L), (-G*J)/(ft*L)
    ----    stiff[4][4], stiff[10][10] = "GJ/ftL", "GJ/ftL"
    ----    stiff[4][10], stiff[10][4] = "-GJ/ftL", "-GJ/ftL"
    end
    end
--    stiff:print()
    return stiff
end

function ElementType.Standard:internal_loads_build( global_disp, node_id ) --node_id number from global stiffness
    local loads = {}
    local disp  = Matrix:new( { rows = 12, columns = 1 } )
    local id1,id2
    id1 = node_id[ self.node1_id ]
    id2 = node_id[ self.node2_id ]
    for i = 1, 6 do
        disp[i][1]         = global_disp[ (id1*6 - (6 - i)) ][1]
        disp[ (i + 6) ][1] = global_disp[ (id2*6 - (6 - i)) ][1]
    end
    local local_disp = self.rot*disp
    local_disp = Matrix:new( local_disp )
    loads = self.stiffness*local_disp
    loads = Matrix:new( loads )
    return loads
end

function ElementType.Standard:get_rectangular_torsion_stress_factor( ratio )
    if( ratio > 10 ) then
        return self.C1.inf
    end
    local y1, y0, x1, x0
    x0 = 1
    for k, v in pairs( self.C1 ) do
        if( k ~= "inf" ) then
            if( ratio == k ) then
                return v
            elseif( ratio > k ) then
                x0 = k
            else
                x1 = k
                break
            end
        end
    end
    y0 = self.C1[ x0 ]
    y1 = self.C1[ x1 ]
    return (((y1-y0)/(x1-x0))*ratio + y1*x1*((y1-y0)/(x1-x0)))
end

function ElementType.Standard:get_axial_stress( Fx, node ) --node = 1 or 2
    local t_ax, N
    if( node == 2 ) then N = -Fx else N = Fx end
    local A = self.A
    t_ax = N/A
    return t_ax --Stress in MPa, constant over all the element
end

function ElementType.Standard:get_shearload_stress( Fy, Fz, node, xsec_z, xsec_y, args ) --args list for Q
    local t_sh, ty, tz, Vy, Vz, Izz, Iyy, Qy, Qz
    Vy = -Fy
    Vz = -Fz
    Iyy = self.Iyy
    Izz = self.Izz
    if( self.geom == "Rectangular" ) then
        Qy = self.Q_rectangular( self.width, self.height, xsec_y )
        Qz = self.Q_rectangular( self.height, self.width, xsec_z )
        ty = ((Vy*Qy)/(Izz*self.width))
        tz = ((Vz*Qz)/(Iyy*self.height))
        if( ty >= tz ) then t_sh = ty
        else t_sh = tz end
    elseif( self.geom == "Circular" ) then
        local theta_y, theta_z
        if( xsec_z == 0 ) and ( xsec_y == 0 ) then
            theta_y = 0
            theta_z = 0
        elseif( xsec_y == 0 ) then
            theta_y = 0
            theta_z = math.atan2( xsec_y,xsec_z )
        elseif( xsec_z == 0 ) then
            theta_z = 0
            theta_y = math.atan2( xsec_z,xsec_y )
        else
            theta_y = math.atan2( xsec_z,xsec_y )
            theta_z = math.atan2( xsec_y,xsec_z )
        end
        Qy = self.Q_circular( (self.diameter/2), theta_y )
        Qz = self.Q_circular( (self.diameter/2), theta_z )
        ty = ((Vy*Qy)/(Izz*self.diameter))
        tz = ((Vz*Qz)/(Iyy*self.diameter))
        if( ty >= tz ) then t_sh = ty
        else t_sh = tz end
    elseif( self.geom == "Tubular" ) then
        --Not accurate, but favors safety
        local A = self.A
        ty = ((2*Vy)/(A))
        tz = ((2*Vz)/(A))
        t_sh = ((ty^2 + tz^2)*0.5)
    end
    return t_sh
end

function ElementType.Standard:get_torsional_stress( Mx, node )
    local t_tor, T, ratio, a, b, r, J, ri, ro, t, Am
    T = -Mx*1000 --N.mm
    if( self.geom == "Rectangular" ) then
        if( tonumber(self.width) > tonumber(self.height) ) then
            ratio = self.width/self.height
            a = self.width
            b = self.height
        else
            ratio = self.height/self.width
            a = self.height
            b = self.width
        end
        local C1 = self:get_rectangular_torsion_stress_factor( ratio )
        t_tor = (T/(C1*a*(b^2)))
    elseif( self.geom == "Circular" ) then
        r = self.diameter/2
        J = self.J
        t_tor = ((T*r)/J)
    elseif( self.geom == "Tubular" ) then
        ri = self.in_diameter/2
        ro = self.out_diameter/2
        t  = ro - ri
        Am = (math.pi*( ri + (t/2) )^2 )
        t_tor = (T/(2*t*Am))
    end
    return t_tor --Stress in MPa, evaluated at the element surface (see documentation)
end

function ElementType.Standard:get_flexion_stress( My, Mz, node, xsec_z, xsec_y )
    local t_fl, Iyy, Izz, cy, cz
    My = -My*1000 --N.mm
    Mz = -Mz*1000 --N.mm
    cy = xsec_y
    cz = xsec_z
    Iyy = self.Iyy
    Izz = self.Izz
    t_fl = ((-(Mz*cy)/Izz) + ((My*cz)/Iyy))
    return t_fl
end

function ElementType.Standard:buckling_critical_stress( Fx1, Fx2, Mz, My ) --Check this
    if( Fx1 <= 0 ) and ( Fx2 >= 0 ) then --If tension, breaks
        return -1
    else
        local ey, ez
        if( self.geom == "Rectangular" ) then
            ey, ez = (self.height/2), (self.width/2)
        elseif( self.geom == "Circular" ) then
            ey, ez = (self.diameter/2), (self.diameter/2)
        elseif( self.geom == "Tubular" ) then
            ey, ez = (self.out_diameter/2), (self.out_diameter/2)
        end
        local cy, cz = ez, ey
        --local Py, Pz = (Fx1 + (Mz/ey)), (Fx1 + (My/ez))
        local Py, Pz = Fx1, Fx1
        local A = self.A
        local L = self.L
        local E = self.E
        local Izz, Iyy = self.Izz, self.Iyy
        local ryy = (Iyy/A)^0.5
        local rzz = (Izz/A)^0.5
--        local tzz_buck = ((Py/A)*(1 + ((ey*cy)/(rzz^2))*(1/(math.cos(((L/(2*rzz))*(Py/(A*E))^0.5))))))
--        local tyy_buck = ((Pz/A)*(1 + ((ez*cz)/(ryy^2))*(1/(math.cos(((L/(2*ryy))*(Pz/(A*E))^0.5))))))
        local tzz_buck = (self.fail)/(1 + ((ey*cy)/(rzz^2))*(1/(math.cos(((L/(2*rzz))*(Py/(A*E))^0.5)))))
        local tyy_buck = (self.fail)/((1 + ((ez*cz)/(ryy^2))*(1/(math.cos(((L/(2*ryy))*(Pz/(A*E))^0.5))))))
        if( tzz_buck >= tyy_buck ) then
            return tzz_buck
        else
            return tyy_buck
        end
    end
end

function ElementType.Standard:eval_critial_points_stresses()
    local points = {}--points[ index ] = { [1] = axial, [2] = shearload, [3] = torsional, [4] = flexion }
    if( self.geom == "Rectangular" ) then --18 points: edges, midpoints and center for each node
        for i = 1, 2 do --IT IS A LITTLE INEFFICIENT
            local Fx, Fy, Fz, Mx, My, Mz = self.internal_loads[(6*i - 5)][1], self.internal_loads[(6*i - 4)][1], self.internal_loads[(6*i - 3)][1], self.internal_loads[(6*i - 2)][1], self.internal_loads[(6*i - 1)][1], self.internal_loads[(6*i)][1]
            local axial   = self:get_axial_stress( Fx, i )
            local torsion = self:get_torsional_stress( Mx, node )
            points[1 + (i-1)*9] = { axial, self:get_shearload_stress( Fy, Fz, i, 0, 0, nil ), torsion, self:get_flexion_stress( My, Mz, i, 0, 0 ) }
            points[2 + (i-1)*9] = { axial, self:get_shearload_stress( Fy, Fz, i, (self.width/2), 0, nil ), torsion, self:get_flexion_stress( My, Mz, i, (self.width/2), 0 ) }
            points[3 + (i-1)*9] = { axial, self:get_shearload_stress( Fy, Fz, i, -(self.width/2), 0, nil ), torsion, self:get_flexion_stress( My, Mz, i, -(self.width/2), 0 ) }
            points[4 + (i-1)*9] = { axial, self:get_shearload_stress( Fy, Fz, i, 0, (self.height/2), nil ), torsion, self:get_flexion_stress( My, Mz, i, 0, (self.height/2) ) }
            points[5 + (i-1)*9] = { axial, self:get_shearload_stress( Fy, Fz, i, 0, -(self.height/2), nil ), torsion, self:get_flexion_stress( My, Mz, i, 0, -(self.height/2) ) }
            points[6 + (i-1)*9] = { axial, self:get_shearload_stress( Fy, Fz, i, (self.width/2), (self.height/2), nil ), torsion, self:get_flexion_stress( My, Mz, i, (self.width/2), (self.height/2) ) }
            points[7 + (i-1)*9] = { axial, self:get_shearload_stress( Fy, Fz, i, -(self.width/2), (self.height/2), nil ), torsion, self:get_flexion_stress( My, Mz, i, -(self.width/2), (self.height/2) ) }
            points[8 + (i-1)*9] = { axial, self:get_shearload_stress( Fy, Fz, i, (self.width/2), -(self.height/2), nil ), torsion, self:get_flexion_stress( My, Mz, i, (self.width/2), -(self.height/2) ) }
            points[9 + (i-1)*9] = { axial, self:get_shearload_stress( Fy, Fz, i, -(self.width/2), -(self.height/2), nil ), torsion, self:get_flexion_stress( My, Mz, i, -(self.width/2), -(self.height/2) ) }
        end
    elseif( self.geom == "Circular" ) then --14 points
        for i = 1, 2 do
            local Fx, Fy, Fz, Mx, My, Mz = self.internal_loads[(6*i - 5)][1], self.internal_loads[(6*i - 4)][1], self.internal_loads[(6*i - 3)][1], self.internal_loads[(6*i - 2)][1], self.internal_loads[(6*i - 1)][1], self.internal_loads[(6*i)][1]
            local axial   = self:get_axial_stress( Fx, i )
            local torsion = self:get_torsional_stress( Mx, node )
            local z_norm, y_norm = (Mz/((Mz^2 + My^2)^0.5)), (My/((Mz^2 + My^2)^0.5))
            points[1 + (i-1)*7] = { axial, self:get_shearload_stress( Fy, Fz, i, 0, 0, nil ), torsion, self:get_flexion_stress( My, Mz, i, 0, 0 ) }
            points[2 + (i-1)*7] = { axial, self:get_shearload_stress( Fy, Fz, i, (self.diameter/2), 0, nil ), torsion, self:get_flexion_stress( My, Mz, i, (self.diameter/2), 0 ) }
            points[3 + (i-1)*7] = { axial, self:get_shearload_stress( Fy, Fz, i, -(self.diameter/2), 0, nil ), torsion, self:get_flexion_stress( My, Mz, i, -(self.diameter/2), 0 ) }
            points[4 + (i-1)*7] = { axial, self:get_shearload_stress( Fy, Fz, i, 0, (self.diameter/2), nil ), torsion, self:get_flexion_stress( My, Mz, i, 0, (self.diameter/2) ) }
            points[5 + (i-1)*7] = { axial, self:get_shearload_stress( Fy, Fz, i, 0, -(self.diameter/2), nil ), torsion, self:get_flexion_stress( My, Mz, i, 0, -(self.diameter/2) ) }
            points[6 + (i-1)*7] = { axial, self:get_shearload_stress( Fy, Fz, i, (self.diameter/2)*z_norm, (self.diameter/2)*y_norm, nil ), torsion, self:get_flexion_stress( My, Mz, i, (self.diameter/2)*z_norm, (self.diameter/2)*y_norm ) }
            points[7 + (i-1)*7] = { axial, self:get_shearload_stress( Fy, Fz, i, -(self.diameter/2)*z_norm, -(self.diameter/2)*y_norm, nil ), torsion, self:get_flexion_stress( My, Mz, i, -(self.diameter/2)*z_norm, -(self.diameter/2)*y_norm ) }
        end
    elseif( self.geom == "Tubular" ) then --4 points
        for i = 1, 2 do
            local Fx, Fy, Fz, Mx, My, Mz = self.internal_loads[(6*i - 5)][1], self.internal_loads[(6*i - 4)][1], self.internal_loads[(6*i - 3)][1], self.internal_loads[(6*i - 2)][1], self.internal_loads[(6*i - 1)][1], self.internal_loads[(6*i)][1]
            local axial   = self:get_axial_stress( Fx, i )
            local torsion = self:get_torsional_stress( Mx, node )
            local z_norm, y_norm = (Mz/((Mz^2 + My^2)^0.5)), (My/((Mz^2 + My^2)^0.5))
            points[1 + (i-1)*2] = { axial, self:get_shearload_stress( Fy, Fz, i, 0, 0, nil ), torsion, self:get_flexion_stress( My, Mz, i, -(self.out_diameter/2)*z_norm, (self.out_diameter/2)*y_norm ) }
            points[2 + (i-1)*2] = { axial, self:get_shearload_stress( Fy, Fz, i, 0, 0, nil ), torsion, self:get_flexion_stress( My, Mz, i, (self.out_diameter/2)*z_norm, -(self.out_diameter/2)*y_norm ) }
        end
    end
    return points
end

function ElementType.Standard:ductile_failure( c_points, buckling_stress ) --von Mises
    local max_stress, fail, c_p
    self.critical = {}
    max_stress = 0
    self.max_shear = 0
    for i = 1, #c_points do
--        print( #c_points, i, c_points[i] )
        local normal = c_points[i][1] + c_points[i][4]
        local shear  = c_points[i][2] + c_points[i][3] --This may look misleading if documentation is not checked!
        local von_mises = (( normal^2 + 3*(shear)^2 )^(0.5))
        if( von_mises > max_stress ) then
            max_stress = von_mises
            c_p = i
        end
        if( math.abs( self.max_shear ) < math.abs( c_points[i][2] ) ) then
            self.max_shear = c_points[i][2]
        end
    end
    for i = 1, 4 do
        self.critical[i] = c_points[ c_p ][i]
    end
    if(( max_stress < self.fail ) and ( math.abs(self.critical[1]) < buckling_stress )) or (( max_stress < self.fail ) and ( buckling_stress == -1 )) then
        fail = false
        self.buckling_stress = -1
    else
        fail = true
    end
    local norm = max_stress/self.fail
    return max_stress, fail, norm
end

function ElementType.Standard:brittle_failure( c_points, buckling_stress ) --Rankine (have to check this out later)
    local max_stress, fail, c_p , norm
    self.critical = {}
    norm = 0
    max_stress = 0
    self.max_shear = 0
    c_p = 1
    for i = 1, #c_points do
        local normal = c_points[i][1] + c_points[i][4]
        local shear  = c_points[i][2] + c_points[i][3]
        local main_stress = ((normal/2)+(((normal/2)^2) + shear^2)^0.5)
        --print( 'brittle', c_points, c_p, i, main_stress )
        if( main_stress > max_stress ) then
            max_stress = main_stress
            c_p = i
        end
        if( math.abs( self.max_shear ) < math.abs( c_points[i][2] ) ) then
            self.max_shear = c_points[i][2]
        end
    end
    --print( 'brittle', c_points, c_p, #c_points )
    for i = 1, 4 do
        self.critical[i] = c_points[ c_p ][i]
    end
    local norm = max_stress/self.fail
    if(( norm < self.fail ) and ( math.abs(self.critical[1]) < buckling_stress )) or (( norm < self.fail ) and ( buckling_stress == -1 )) then
        fail = false
        self.buckling_stress = -1
    else
        fail = true
    end
    return max_stress, fail, norm
end

function ElementType.Standard:composite_uni_dir_rod_failure( c_points ) --Simplified Tsai-Hill criteria for uni. dir. rods
    --WARNING: AS BUCKLING IS NOT WORKING, IT WASN'T IMPLEMENTED HERE PROPERLY
    --Equation: (sigma_1/sigma_1_fail)^2 + (sigma_2/sigma_2_fail)^2 + (sigma_12/sigma_12_fail)^2 >= 1
    --Assumptions:
    --  All elements are assumed to have 0° of fibre orientation
    --  Elements don't have sigma_2
    --  Shear strenght is assumed to be 20 times lower then failure (should be tensile strength)
    local c_p
    local max_tsai_hill = 0
    self.critical = {}
    for i = 1, #c_points do
        local normal = c_points[i][1] + c_points[i][4]
        local shear  = c_points[i][2] + c_points[i][3]
        local tsai_hill = (normal/self.fail)^2 + (shear/(self.fail/20))^2
        if( tsai_hill > max_tsai_hill ) then
            max_tsai_hill = tsai_hill
            c_p = i
        end
    end
    for i = 1, 4 do
        self.critical[i] = c_points[ c_p ][i]
    end
    if(( max_tsai_hill < 1 )) then
        fail = false
        self.buckling_stress = -1
    else
        fail = true
        self.buckling_stress = -1 --BUCKLING NOT IMPLEMENTED
    end
    local norm = max_tsai_hill
    local max_stress = (max_tsai_hill^0.5)*self.fail --WARNING: RESERVE FACTOR R = sqrt( 1/max_tsai_hill )
    return max_stress, fail, norm
end

Element = {} --List of all elements
ELEMENT = {} --Unidimensional element base class

function ELEMENT:create_rotation_matrix()
    local rotation = {}
    local mult = 0
    for i = 1, 12 do
        rotation[ i ] = {}
        for j = 1, 12 do
            rotation[ i ][ j ] = 0
        end
    end
    for i = 1, 3 do --Access vector
        for j = 0, 3 do
        --OLD
--            rotation[ j*3 + i ][ j*3 + 1 ] = self.x_axis[i]
--            rotation[ j*3 + i ][ j*3 + 2 ] = self.y_axis[i]
--            rotation[ j*3 + i ][ j*3 + 3 ] = self.z_axis[i]
        --BUG FIX
            rotation[ j*3 + 1 ][ j*3 + i ] = self.x_axis[i]
            rotation[ j*3 + 2 ][ j*3 + i ] = self.y_axis[i]
            rotation[ j*3 + 3 ][ j*3 + i ] = self.z_axis[i]
        end
    end

    return Matrix:new( rotation )
end

function ELEMENT:explicit_global_stiffness()
    local ex = {}
    local ey = {}
    local ez = {}
    local X,Y1,Y2,Y3,Y4,Y5,Y6,Y7,Y8,Z1,Z2,Z3,Z4,Z5,Z6,Z7,Z8
    local TX,MY1,MY2,MY3,MY4,MY5,MY6,MY7,M8,MZ1,MZ2,MZ3,MZ4,MZ5,MZ6,MZ7,MZ8
    local K = self.stiffness
    for i = 1, 3 do
        ex[i] = self.x_axis[i]
        ey[i] = self.y_axis[i]
        ez[i] = self.z_axis[i]
    end
    X   = math.abs( K[1][1] )
    TX  = math.abs( K[4][4] )
    Y1  = math.abs( K[2][2] )
    Y2  = math.abs( K[6][2] )
    Y3  = math.abs( K[8][2] )
    Y4  = math.abs( K[12][2] )
    Y5  = math.abs( K[2][8] )
    Y6  = math.abs( K[6][8] )
    Y7  = math.abs( K[8][8] )
    Y8  = math.abs( K[12][8] )
    Z1  = math.abs( K[3][3] )
    Z2  = math.abs( K[5][3] )
    Z3  = math.abs( K[9][3] )
    Z4  = math.abs( K[11][3] )
    Z5  = math.abs( K[3][9] )
    Z6  = math.abs( K[5][9] )
    Z7  = math.abs( K[9][9] )
    Z8  = math.abs( K[11][9] )
    MY1 = math.abs( K[3][5] )
    MY2 = math.abs( K[5][5] )
    MY3 = math.abs( K[9][5] )
    MY4 = math.abs( K[11][5] )
    MY5 = math.abs( K[3][11] )
    MY6 = math.abs( K[5][11] )
    MY7 = math.abs( K[9][11] )
    M8  = math.abs( K[11][11] )
    MZ1 = math.abs( K[2][6] )
    MZ2 = math.abs( K[6][6] )
    MZ3 = math.abs( K[8][6] )
    MZ4 = math.abs( K[12][6] )
    MZ5 = math.abs( K[2][12] )
    MZ6 = math.abs( K[6][12] )
    MZ7 = math.abs( K[8][12] )
    MZ8 = math.abs( K[12][12] )
    local oi = Matrix:new(
    { {ez[1]^2*Z1+ey[1]^2*Y1+ex[1]^2*X , ez[1]*ez[2]*Z1+ey[1]*ey[2]*Y1+ex[1]*ex[2]*X , ez[1]*ez[3]*Z1+ey[1]*ey[3]*Y1+ex[1]*ex[3]*X , ey[1]*ez[1]*MZ1-ey[1]*ez[1]*MY1 , ey[1]*ez[2]*MZ1-ez[1]*ey[2]*MY1 , ey[1]*ez[3]*MZ1-ez[1]*ey[3]*MY1 , -ez[1]^2*Z5-ey[1]^2*Y5-ex[1]^2*X , -ez[1]*ez[2]*Z5-ey[1]*ey[2]*Y5-ex[1]*ex[2]*X , -ez[1]*ez[3]*Z5-ey[1]*ey[3]*Y5-ex[1]*ex[3]*X , ey[1]*ez[1]*MZ5-ey[1]*ez[1]*MY5 , ey[1]*ez[2]*MZ5-ez[1]*ey[2]*MY5 , ey[1]*ez[3]*MZ5-ez[1]*ey[3]*MY5} ,
    {ez[1]*ez[2]*Z1+ey[1]*ey[2]*Y1+ex[1]*ex[2]*X , ez[2]^2*Z1+ey[2]^2*Y1+ex[2]^2*X , ez[2]*ez[3]*Z1+ey[2]*ey[3]*Y1+ex[2]*ex[3]*X , ez[1]*ey[2]*MZ1-ey[1]*ez[2]*MY1 , ey[2]*ez[2]*MZ1-ey[2]*ez[2]*MY1 , ey[2]*ez[3]*MZ1-ez[2]*ey[3]*MY1 , -ez[1]*ez[2]*Z5-ey[1]*ey[2]*Y5-ex[1]*ex[2]*X , -ez[2]^2*Z5-ey[2]^2*Y5-ex[2]^2*X , -ez[2]*ez[3]*Z5-ey[2]*ey[3]*Y5-ex[2]*ex[3]*X , ez[1]*ey[2]*MZ5-ey[1]*ez[2]*MY5 , ey[2]*ez[2]*MZ5-ey[2]*ez[2]*MY5 , ey[2]*ez[3]*MZ5-ez[2]*ey[3]*MY5} ,
    {ez[1]*ez[3]*Z1+ey[1]*ey[3]*Y1+ex[1]*ex[3]*X , ez[2]*ez[3]*Z1+ey[2]*ey[3]*Y1+ex[2]*ex[3]*X , ez[3]^2*Z1+ey[3]^2*Y1+ex[3]^2*X , ez[1]*ey[3]*MZ1-ey[1]*ez[3]*MY1 , ez[2]*ey[3]*MZ1-ey[2]*ez[3]*MY1 , ey[3]*ez[3]*MZ1-ey[3]*ez[3]*MY1 , -ez[1]*ez[3]*Z5-ey[1]*ey[3]*Y5-ex[1]*ex[3]*X , -ez[2]*ez[3]*Z5-ey[2]*ey[3]*Y5-ex[2]*ex[3]*X , -ez[3]^2*Z5-ey[3]^2*Y5-ex[3]^2*X , ez[1]*ey[3]*MZ5-ey[1]*ez[3]*MY5 , ez[2]*ey[3]*MZ5-ey[2]*ez[3]*MY5 , ey[3]*ez[3]*MZ5-ey[3]*ez[3]*MY5} ,
    {ey[1]*ez[1]*Y2-ey[1]*ez[1]*Z2 , ez[1]*ey[2]*Y2-ey[1]*ez[2]*Z2 , ez[1]*ey[3]*Y2-ey[1]*ez[3]*Z2 , ex[1]^2*TX+ez[1]^2*MZ2+ey[1]^2*MY2 , ex[1]*ex[2]*TX+ez[1]*ez[2]*MZ2+ey[1]*ey[2]*MY2 , ex[1]*ex[3]*TX+ez[1]*ez[3]*MZ2+ey[1]*ey[3]*MY2 , ey[1]*ez[1]*Z6-ey[1]*ez[1]*Y6 , ey[1]*ez[2]*Z6-ez[1]*ey[2]*Y6 , ey[1]*ez[3]*Z6-ez[1]*ey[3]*Y6 , -ex[1]^2*TX+ez[1]^2*MZ6+ey[1]^2*MY6 , -ex[1]*ex[2]*TX+ez[1]*ez[2]*MZ6+ey[1]*ey[2]*MY6 , -ex[1]*ex[3]*TX+ez[1]*ez[3]*MZ6+ey[1]*ey[3]*MY6} ,
    {ey[1]*ez[2]*Y2-ez[1]*ey[2]*Z2 , ey[2]*ez[2]*Y2-ey[2]*ez[2]*Z2 , ez[2]*ey[3]*Y2-ey[2]*ez[3]*Z2 , ex[1]*ex[2]*TX+ez[1]*ez[2]*MZ2+ey[1]*ey[2]*MY2 , ex[2]^2*TX+ez[2]^2*MZ2+ey[2]^2*MY2 , ex[2]*ex[3]*TX+ez[2]*ez[3]*MZ2+ey[2]*ey[3]*MY2 , ez[1]*ey[2]*Z6-ey[1]*ez[2]*Y6 , ey[2]*ez[2]*Z6-ey[2]*ez[2]*Y6 , ey[2]*ez[3]*Z6-ez[2]*ey[3]*Y6 , -ex[1]*ex[2]*TX+ez[1]*ez[2]*MZ6+ey[1]*ey[2]*MY6 , -ex[2]^2*TX+ez[2]^2*MZ6+ey[2]^2*MY6 , -ex[2]*ex[3]*TX+ez[2]*ez[3]*MZ6+ey[2]*ey[3]*MY6} ,
    {ey[1]*ez[3]*Y2-ez[1]*ey[3]*Z2 , ey[2]*ez[3]*Y2-ez[2]*ey[3]*Z2 , ey[3]*ez[3]*Y2-ey[3]*ez[3]*Z2 , ex[1]*ex[3]*TX+ez[1]*ez[3]*MZ2+ey[1]*ey[3]*MY2 , ex[2]*ex[3]*TX+ez[2]*ez[3]*MZ2+ey[2]*ey[3]*MY2 , ex[3]^2*TX+ez[3]^2*MZ2+ey[3]^2*MY2 , ez[1]*ey[3]*Z6-ey[1]*ez[3]*Y6 , ez[2]*ey[3]*Z6-ey[2]*ez[3]*Y6 , ey[3]*ez[3]*Z6-ey[3]*ez[3]*Y6 , -ex[1]*ex[3]*TX+ez[1]*ez[3]*MZ6+ey[1]*ey[3]*MY6 , -ex[2]*ex[3]*TX+ez[2]*ez[3]*MZ6+ey[2]*ey[3]*MY6 , -ex[3]^2*TX+ez[3]^2*MZ6+ey[3]^2*MY6} ,
    {-ez[1]^2*Z3-ey[1]^2*Y3-ex[1]^2*X , -ez[1]*ez[2]*Z3-ey[1]*ey[2]*Y3-ex[1]*ex[2]*X , -ez[1]*ez[3]*Z3-ey[1]*ey[3]*Y3-ex[1]*ex[3]*X , ey[1]*ez[1]*MY3-ey[1]*ez[1]*MZ3 , ez[1]*ey[2]*MY3-ey[1]*ez[2]*MZ3 , ez[1]*ey[3]*MY3-ey[1]*ez[3]*MZ3 , ez[1]^2*Z7+ey[1]^2*Y7+ex[1]^2*X , ez[1]*ez[2]*Z7+ey[1]*ey[2]*Y7+ex[1]*ex[2]*X , ez[1]*ez[3]*Z7+ey[1]*ey[3]*Y7+ex[1]*ex[3]*X , ey[1]*ez[1]*MY7-ey[1]*ez[1]*MZ7 , ez[1]*ey[2]*MY7-ey[1]*ez[2]*MZ7 , ez[1]*ey[3]*MY7-ey[1]*ez[3]*MZ7} ,
    {-ez[1]*ez[2]*Z3-ey[1]*ey[2]*Y3-ex[1]*ex[2]*X , -ez[2]^2*Z3-ey[2]^2*Y3-ex[2]^2*X , -ez[2]*ez[3]*Z3-ey[2]*ey[3]*Y3-ex[2]*ex[3]*X , ey[1]*ez[2]*MY3-ez[1]*ey[2]*MZ3 , ey[2]*ez[2]*MY3-ey[2]*ez[2]*MZ3 , ez[2]*ey[3]*MY3-ey[2]*ez[3]*MZ3 , ez[1]*ez[2]*Z7+ey[1]*ey[2]*Y7+ex[1]*ex[2]*X , ez[2]^2*Z7+ey[2]^2*Y7+ex[2]^2*X , ez[2]*ez[3]*Z7+ey[2]*ey[3]*Y7+ex[2]*ex[3]*X , ey[1]*ez[2]*MY7-ez[1]*ey[2]*MZ7 , ey[2]*ez[2]*MY7-ey[2]*ez[2]*MZ7 , ez[2]*ey[3]*MY7-ey[2]*ez[3]*MZ7} ,
    {-ez[1]*ez[3]*Z3-ey[1]*ey[3]*Y3-ex[1]*ex[3]*X , -ez[2]*ez[3]*Z3-ey[2]*ey[3]*Y3-ex[2]*ex[3]*X , -ez[3]^2*Z3-ey[3]^2*Y3-ex[3]^2*X , ey[1]*ez[3]*MY3-ez[1]*ey[3]*MZ3 , ey[2]*ez[3]*MY3-ez[2]*ey[3]*MZ3 , ey[3]*ez[3]*MY3-ey[3]*ez[3]*MZ3 , ez[1]*ez[3]*Z7+ey[1]*ey[3]*Y7+ex[1]*ex[3]*X , ez[2]*ez[3]*Z7+ey[2]*ey[3]*Y7+ex[2]*ex[3]*X , ez[3]^2*Z7+ey[3]^2*Y7+ex[3]^2*X , ey[1]*ez[3]*MY7-ez[1]*ey[3]*MZ7 , ey[2]*ez[3]*MY7-ez[2]*ey[3]*MZ7 , ey[3]*ez[3]*MY7-ey[3]*ez[3]*MZ7} ,
    {ey[1]*ez[1]*Y4-ey[1]*ez[1]*Z4 , ez[1]*ey[2]*Y4-ey[1]*ez[2]*Z4 , ez[1]*ey[3]*Y4-ey[1]*ez[3]*Z4 , -ex[1]^2*TX+ez[1]^2*MZ4+ey[1]^2*MY4 , -ex[1]*ex[2]*TX+ez[1]*ez[2]*MZ4+ey[1]*ey[2]*MY4 , -ex[1]*ex[3]*TX+ez[1]*ez[3]*MZ4+ey[1]*ey[3]*MY4 , ey[1]*ez[1]*Z8-ey[1]*ez[1]*Y8 , ey[1]*ez[2]*Z8-ez[1]*ey[2]*Y8 , ey[1]*ez[3]*Z8-ez[1]*ey[3]*Y8 , ex[1]^2*TX+ez[1]^2*MZ8+ey[1]^2*M8 , ex[1]*ex[2]*TX+ez[1]*ez[2]*MZ8+ey[1]*ey[2]*M8 , ex[1]*ex[3]*TX+ez[1]*ez[3]*MZ8+ey[1]*ey[3]*M8} ,
    {ey[1]*ez[2]*Y4-ez[1]*ey[2]*Z4 , ey[2]*ez[2]*Y4-ey[2]*ez[2]*Z4 , ez[2]*ey[3]*Y4-ey[2]*ez[3]*Z4 , -ex[1]*ex[2]*TX+ez[1]*ez[2]*MZ4+ey[1]*ey[2]*MY4 , -ex[2]^2*TX+ez[2]^2*MZ4+ey[2]^2*MY4 , -ex[2]*ex[3]*TX+ez[2]*ez[3]*MZ4+ey[2]*ey[3]*MY4 , ez[1]*ey[2]*Z8-ey[1]*ez[2]*Y8 , ey[2]*ez[2]*Z8-ey[2]*ez[2]*Y8 , ey[2]*ez[3]*Z8-ez[2]*ey[3]*Y8 , ex[1]*ex[2]*TX+ez[1]*ez[2]*MZ8+ey[1]*ey[2]*M8 , ex[2]^2*TX+ez[2]^2*MZ8+ey[2]^2*M8 , ex[2]*ex[3]*TX+ez[2]*ez[3]*MZ8+ey[2]*ey[3]*M8} ,
    {ey[1]*ez[3]*Y4-ez[1]*ey[3]*Z4 , ey[2]*ez[3]*Y4-ez[2]*ey[3]*Z4 , ey[3]*ez[3]*Y4-ey[3]*ez[3]*Z4 , -ex[1]*ex[3]*TX+ez[1]*ez[3]*MZ4+ey[1]*ey[3]*MY4 , -ex[2]*ex[3]*TX+ez[2]*ez[3]*MZ4+ey[2]*ey[3]*MY4 , -ex[3]^2*TX+ez[3]^2*MZ4+ey[3]^2*MY4 , ez[1]*ey[3]*Z8-ey[1]*ez[3]*Y8 , ez[2]*ey[3]*Z8-ey[2]*ez[3]*Y8 , ey[3]*ez[3]*Z8-ey[3]*ez[3]*Y8 , ex[1]*ex[3]*TX+ez[1]*ez[3]*MZ8+ey[1]*ey[3]*M8 , ex[2]*ex[3]*TX+ez[2]*ez[3]*MZ8+ey[2]*ey[3]*M8 , ex[3]^2*TX+ez[3]^2*MZ8+ey[3]^2*M8} }
    )
    return oi
end

function ELEMENT:new( new_att ) --Here, new_att = { x_axis = vector.new(), z_axis = vector.new() }
    local SELF = new_att or {}
    setmetatable( SELF, self )
    self.__index = self
    SELF.x_axis = vector.new( nil, nil, SELF.x_axis.unit )
    SELF.z_axis = vector.new( nil, nil, SELF.z_axis.unit )
    SELF.y_axis = vector.new( nil, nil, SELF.z_axis:cross( SELF.x_axis ) ).unit
    --print( SELF.x_axis[1].." "..SELF.x_axis[2].." "..SELF.x_axis[3], SELF.y_axis[1].." "..SELF.y_axis[2].." "..SELF.y_axis[3], SELF.z_axis[1].." "..SELF.z_axis[2].." "..SELF.z_axis[3] )
    local explicit = false
    if( explicit ) then
        SELF.stiffness = SELF:stiffness_build( "all" )
        SELF.G_stiffness = SELF:explicit_global_stiffness()
        SELF.rot = SELF:create_rotation_matrix()
    else
        SELF.rot = SELF:create_rotation_matrix()
        --SELF.rot:print()
        SELF.stiffness = SELF:stiffness_build( "all" )
    --    SELF.stiffness:print()
        SELF.G_stiffness = (SELF.rot:transpose()*SELF.stiffness)*SELF.rot
    end
    --SELF.G_stiffness:print()
    --Test
--    local a = Matrix:new( { {2,3,4},{1,2,3} } )
--    local b = Matrix:new( { {5,4},{2,7},{3,2} } )
--    local c = a*b
--    c:print()
    return SELF
end
ElementType.Standard = ELEMENT:new( ElementType.Standard )


Stiff = {} --List of all stiffness matrices
STIFF = {} --Class for stiffnes matrices function list
STIFF.zero_constrained = {}

function STIFF:apply_constraints( nodes, dof, type, load_vector ) --load_vector is Matrix: object
    self.x0 = Matrix:new( { rows = self.rows, columns = 1 } )
    for i = 1, self.rows do
        self.x0[ i ][1] = 0
    end
    for i = 1, #nodes do
        local node_n = self.id[ nodes[ i ] ]
        for j = 1, 6 do --DOF type
            if( type[i] == "zero" ) then
                if( dof[ i ][ j ] == true ) then
                    for I = 1, self.rows do --Zero columns and lines
                        self[ I ][ ((node_n - 1)*6 + j) ] = 0
                        self[ ((node_n - 1)*6 + j) ][ I ] = 0
                    end
                    self[ ((node_n - 1)*6 + j) ][ ((node_n - 1)*6 + j) ] = 1
                    load_vector[ ((node_n - 1)*6 + j) ][1] = 0 --Zero the load
                    self.x0[ ((node_n - 1)*6 + j) ][1] = 0
                    self.zero_constrained[ ((node_n - 1)*6 + j) ] = 1
                end
            end
        end
    end
end

function STIFF:build( elements ) --Builds global stiffness matrix
    --self.id = table[ node_id ] = node_position_in_matrix
    for k, v in pairs( elements ) do --For each element
        local node1 = self.id[ elements[ k ].node1_id ]
        local node2 = self.id[ elements[ k ].node2_id ]
        --print( node1, node2, (6*(node1 - 1)), (6*(node2 - 1)) )
        local dof = {}
        dof[1]= 6*(node1-1)+1
        dof[2]= 6*(node1-1)+2
        dof[3]= 6*(node1-1)+3
        dof[4]= 6*(node1-1)+4
        dof[5]= 6*(node1-1)+5
        dof[6]= 6*(node1-1)+6
        dof[7]= 6*(node2-1)+1
        dof[8]= 6*(node2-1)+2
        dof[9]= 6*(node2-1)+3
        dof[10]= 6*(node2-1)+4
        dof[11]=6*(node2-1)+5
        dof[12]=6*(node2-1)+6

        for i = 1, 12 do
            for j = 1, 12 do
                self[dof[i]][dof[j]] = self[dof[i]][dof[j]] + elements[ k ].G_stiffness[i][j];
            end
        end
--        if( node1 == 1 ) or ( node2 == 1 ) then
--            elements[ k ].G_stiffness:export_to_Excel( "Stiff_g2" )
--            local tr = elements[ k ].rot:transpose()
--            tr:export_to_Excel( "Stiff_tr2" )
--            elements[ k ].rot:export_to_Excel( "Stiff_r2" )
--            self:export_to_Excel( "Stiff_new_"..k )
--            os.execute("pause")
--        end
--        for i = 1, 6 do
--            for j = 1, 6 do
--                self[ ((6*(node1 - 1)) + i) ][ ((6*(node1 - 1)) + j) ] = self[ ((6*(node1 - 1)) + i) ][ ((6*(node1 - 1)) + j) ] + elements[ k ].G_stiffness[ i ][ j ]
--                self[ ((6*(node2 - 1)) + i) ][ ((6*(node1 - 1)) + j) ] = self[ ((6*(node2 - 1)) + i) ][ ((6*(node1 - 1)) + j) ] + elements[ k ].G_stiffness[ i + 6 ][ j ]
----                self[ ((6*(node1 - 1)) + i) ][ ((6*(node2 - 1)) + j) ] = self[ ((6*(node1 - 1)) + i) ][ ((6*(node2 - 1)) + j) ] + elements[ k ].G_stiffness[ i ][ j + 6 ]
----                self[ ((6*(node2 - 1)) + i) ][ ((6*(node2 - 1)) + j) ] = self[ ((6*(node2 - 1)) + i) ][ ((6*(node2 - 1)) + j) ] + elements[ k ].G_stiffness[ i + 6 ][ j + 6 ]
--            end
--        end
    end
--    self:print()
end

STIFF = Matrix:new( STIFF ) --Creates STIFF class
--STIFF.id[ node_id ] = node matrix number

Load = {} --List of all load vectors
LOAD = {} --Class for load vector

function LOAD:build( data_list, node_id_list ) --data_mat = List from load treeview, id_list = list with nodes id and number
    self.id = {}
    for i = 1, #data_list do
        local row = node_id_list[ data_list[i][2] ]
        row = row*6
        if( data_list[i][4] == "x (translation)" ) then row = row - 5
        elseif( data_list[i][4] == "y (translation)" ) then row = row - 4
        elseif( data_list[i][4] == "z (translation)" ) then row = row - 3
        elseif( data_list[i][4] == "x (rotation)" ) then row = row - 2
        elseif( data_list[i][4] == "y (rotation)" ) then row = row - 1
        elseif( data_list[i][4] == "z (rotation)" ) then row = row
        end
        self.id[ data_list[i][1] ] = row
        self[ row ][1] = self[ row ][1] + data_list[i][ 3 ]
    end
end

LOAD = Matrix:new( LOAD )

Sim = {} --List that contains all simulation data
SIM = {} --Simulation class

function SIM:new( new_att )
    local SELF = new_att or {}
    setmetatable( SELF, self )
    self.__index = self
    --Creates "pointer" to other scenario classes
    SELF.stiff    = Stiff[ SELF.name ]
    SELF.load     = Load[ SELF.name ]
    SELF.elements = Element[ SELF.name ]

    --SELF.stiff:export_to_Excel()

    return SELF
end

--Calculations are done here
function SIM:run()
    --self.stiff:Reduce_to_nonsparse_table()
    --print( self.stiff.nsparse[1][1][1] )
    --Displacements
    self.disp = self.stiff:Solve_linsys_with_Espindola_solver( self.load )
--    self.disp:print()
--    ROBERTSON AQUI
    for i = 1, self.disp.rows do
        if( self.disp[i][1] == nil ) then
            print( self.disp[i][1], 6 - i%6 , fem.sce[ self.name ].node.data:get( ( math.ceil(i/6) ) )[1] )
        end
        if( self.disp[i][1] == nil ) then
            self.disp[i][1] = 0
        end
    end



    --self.disp = self.stiff:Solve_linsys_with_gauss_reduction( self.load )
    --self.disp = self.stiff:Solve_linsys_with_iterative_method( self.stiff.x0, self.load, 1e-4, "no" )
--    self.stiff:export_to_Excel( "Stiff" )
    self.disp_mm = self.disp:clone( 1000 )
    --Elements loads
    for k, v in pairs( self.elements ) do
        Element[ self.name ][ k ].internal_loads = v:internal_loads_build( self.disp, self.stiff.id )
        Element[ self.name ][ k ].critical_points = v:eval_critial_points_stresses()
        local Mz, My
        if( Element[ self.name ][ k ].internal_loads[5][1] > Element[ self.name ][ k ].internal_loads[11][1] ) then
            My = Element[ self.name ][ k ].internal_loads[5][1]
        else
            My = Element[ self.name ][ k ].internal_loads[11][1]
        end
        if( Element[ self.name ][ k ].internal_loads[6][1] > Element[ self.name ][ k ].internal_loads[12][1] ) then
            Mz = Element[ self.name ][ k ].internal_loads[6][1]
        else
            Mz = Element[ self.name ][ k ].internal_loads[12][1]
        end
        Element[ self.name ][ k ].buckling_stress = Element[ self.name ][ k ]:buckling_critical_stress( Element[ self.name ][ k ].internal_loads[1][1], Element[ self.name ][ k ].internal_loads[7][1], Mz, My )
        --Failure criteria
        if( Element[ self.name ][ k ].fail_type == "Ductile" ) then
            Element[ self.name ][ k ].max_stress, Element[ self.name ][ k ].has_failed, Element[ self.name ][ k ].normalized_stress = Element[ self.name ][ k ]:ductile_failure( Element[ self.name ][ k ].critical_points, Element[ self.name ][ k ].buckling_stress )
        elseif ( Element[ self.name ][ k ].fail_type == "Fragile" ) then
            Element[ self.name ][ k ].max_stress, Element[ self.name ][ k ].has_failed, Element[ self.name ][ k ].normalized_stress = Element[ self.name ][ k ]:brittle_failure( Element[ self.name ][ k ].critical_points, Element[ self.name ][ k ].buckling_stress )
        elseif ( Element[ self.name ][ k ].fail_type == "Composite" ) then
            Element[ self.name ][ k ].max_stress, Element[ self.name ][ k ].has_failed, Element[ self.name ][ k ].normalized_stress = Element[ self.name ][ k ]:composite_uni_dir_rod_failure( Element[ self.name ][ k ].critical_points )
        end
        --Stresses normalization toward failure stress or buckling (values that range from 0 to 1)
    end
    print( "Elements loads evaluation complete" )

    Res[ self.name ]            = RES:new( { name = self.name } )
    Res[ self.name ].disp       = self.disp:clone( 1 )
    Res[ self.name ].disp_mm    = self.disp:clone( 1000 )
    Res[ self.name ].disp_nodes = Res[ self.name ]:build_displaced_nodes( 1 )--Treeview data format
    --self.disp = self.stiff:Solve_linsys_with_Cholesky( self.load )
    --self.disp:export_to_Excel()
    print( "-----Run complete-----" )
end

Res = {} --List of all results
RES = {} --Class for results

function RES:import_results_from_project()
    self.disp_mm    = self.disp:clone( 1000 )
    self.disp_nodes = self:build_displaced_nodes( 1 )--Treeview data format
end

function RES:build_displaced_nodes( scale )--Treeview data format
    local nodes = letk.List.new()
    local sce   = fem.sce[ self.name ]
    for i = 1, sce.node.data.itens do
        local new_row = {}
        local row = sce.node.data:get( i )
        new_row[1] = row[1]
        new_row[2] = row[2] + self.disp_mm[ (i*6 - 5) ][1]*scale
        new_row[3] = row[3] + self.disp_mm[ (i*6 - 4) ][1]*scale
        new_row[4] = row[4] + self.disp_mm[ (i*6 - 3) ][1]*scale
        nodes:append( new_row )
    end
    return nodes
end

--GMSH functions
function RES:GMSH_view_plain_mesh( nodes )
    self.GMSH_plain_mesh = GMSH:new( {
                                    name         = self.name,
                                    node_data    = nodes,
                                    element_data = fem.sce[ self.name ].element.data,
                                    lc           = 0.009, --Point "thickness"
                                    load_data    = fem.sce[ self.name ].load.data,
                                    } )
    self.GMSH_plain_mesh:update()
    self.GMSH_plain_mesh:export_and_view( "geometry" )
end
--END GMSH

function RES:new( new_att )
    local SELF = new_att or {}
    setmetatable( SELF, self )
    self.__index = self
    return SELF
end

function RES:save_results( file ) --To the project file
    --[[file:write( "\n--Results from scenario \""..self.name.."\"\n" )
    file:write( "Res."..self.name.." = RES:new( { name = \""..self.name.."\" } )\n" )
    file:write( "--Displacements matrix\n" )
    file:write( "Res."..self.name..".disp = Matrix:new( " )
    self.disp:print_to_file( file, "readable", "all" )
    file:write( ")\n" )
    file:write( "--ElementType declaration\n" )
    file:write( "fem.sce[ \""..self.name.."\" ]:build_ElementType_objects()\n\n" )
    file:write( "--Internal loads matrices\n" )
    for k, v in pairs( Element[ self.name ] ) do
        file:write( "Element[ \""..self.name.."\" ][ \""..k.."\" ].internal_loads = Matrix:new( { " )
        for i = 1, 11 do
            file:write( "{"..Element[ self.name ][ k ].internal_loads[i][1].."}, " )
        end
        file:write( "{"..Element[ self.name ][ k ].internal_loads[12][1].."} } )\n" )
    end
    file:write( "\n--Element critical stresses list in MPa {axial, shearload, torsion, flexion}\n" )
    for k, v in pairs( Element[ self.name ] ) do
        file:write( "Element[ \""..self.name.."\" ][ \""..k.."\" ].critical = { " )
        for i = 1, 3 do
            file:write( Element[ self.name ][ k ].critical[i]..", " )
        end
        file:write( Element[ self.name ][ k ].critical[4].." }\n" )
    end
    file:write( "\n--Element buckling stress in MPa\n" )
    for k, v in pairs( Element[ self.name ] ) do
        file:write( "Element[ \""..self.name.."\" ][ \""..k.."\" ].buckling_stress = "..Element[ self.name ][ k ].buckling_stress.."\n" )
    end
    file:write( "\n--Element failure stress in MPa\n" )
    for k, v in pairs( Element[ self.name ] ) do
        file:write( "Element[ \""..self.name.."\" ][ \""..k.."\" ].max_stress, Element[ \""..self.name.."\" ][ \""..k.."\" ].has_failed, Element[ \""..self.name.."\" ][ \""..k.."\" ].normalized_stress = "..
                        Element[ self.name ][ k ].max_stress..", "..tostring(Element[ self.name ][ k ].has_failed)..", "..Element[ self.name ][ k ].normalized_stress.."\n" )
    end]]
end
