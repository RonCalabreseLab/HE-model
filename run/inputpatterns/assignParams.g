// Ca_conc is skipped in the MOEA list! It's dependent on CaS
// calculate Ca_conc = (6.5e-8 - 4e-8 * this->neurite_CaS)
// set the B field of Ca_concen, but remove earlier scale by volume
function set_neurite_Ca_conc (path, num)
  set_gmax {path}/neurite{num} Ca_conc \
    { { 6.5e-8  \
    -  4e-8 * { get_gmax {path}/neurite{num}/CaS_ron } / { calc_surf { path }/neurite{num} } } \
    /  { calc_vol { path }/neurite{num} } }
end

// assigns parameter values already read from parameter row
function modify_cell_params (path)

// soma
set_gmax_par {path}/soma K1_ron 1
set_gmax_par {path}/soma K2_ron 2

// neurites
set_neurites_par {path} K1_ron  3
set_neurites_par {path} K2_ron  4
set_neurites_par {path} A_ron   5
set_neurites_par {path} P_ron   6
set_neurites_par {path} CaS_ron 7
set_neurites_par {path} K_Ca    8

// do it for all 3
set_neurite_Ca_conc {path} 1
set_neurite_Ca_conc {path} 2
set_neurite_Ca_conc {path} 3

// axon
set_gmax_par {path}/axon Na_ron 10
set_gmax_par {path}/axon K1_ron 11
set_gmax_par {path}/axon K2_ron 12
set_gmax_par {path}/axon A_ron  13

end
