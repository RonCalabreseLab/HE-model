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
function modify_cell_params (HE_num, mode_name)
	str path = "/HE" @ {HE_num} @ "_" @ {mode_name}

	// soma
	set_gmax_par_byname {path}/soma K1_ron "soma_K1"
	set_gmax_par_byname {path}/soma K2_ron "soma_K2"

	// neurites
	set_neurites_par_byname {path} K1_ron  "neurite_K1"
	set_neurites_par_byname {path} K2_ron  "neurite_K2"
	set_neurites_par_byname {path} A_ron   "neurite_A"
	set_neurites_par_byname {path} P_ron   "neurite_P"
	set_neurites_par_byname {path} CaS_ron "neurite_CaS"
	set_neurites_par_byname {path} K_Ca    "neurite_KCa"

	// do it for all 3
	set_neurite_Ca_conc {path} 1
	set_neurite_Ca_conc {path} 2
	set_neurite_Ca_conc {path} 3

	// axon
	set_gmax_par_byname {path}/axon Na_ron "axon_Na"
	set_gmax_par_byname {path}/axon K1_ron "axon_K1"
	set_gmax_par_byname {path}/axon K2_ron "axon_K2"
	set_gmax_par_byname {path}/axon A_ron  "axon_A"

end

function modify_syn_params (HE_num)
	setfield /HE{HE_num}_peri_SynE/SynE Gbar {{ {get_param_byname "synE" } / 50 } * 10e-9}
	setfield /HE{HE_num}_sync_SynE/SynE Gbar {{ {get_param_byname "synE" } / 50 } * 10e-9} 
end
