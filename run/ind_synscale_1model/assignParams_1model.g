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

	// TODO: use the exists command to check and set default values
	// otherwise. Make an option to set all Rm Em values from single
	// variable: "Eleak" and "Rleak"

	// soma
	set_gmax_par_byname {path}/soma K1_ron "soma_K1"
	set_gmax_par_byname {path}/soma K2_ron "soma_K2"
	set_comp_field_par_byname {path}/soma Em "soma_Eleak"
	set_comp_field_par_byname {path}/soma Rm "soma_Rleak"

	// neurites
	set_neurites_par_byname {path} K1_ron  "neurite_K1"
	set_neurites_par_byname {path} K2_ron  "neurite_K2"
	set_neurites_par_byname {path} A_ron   "neurite_A"
	set_neurites_par_byname {path} P_ron   "neurite_P"
	set_neurites_par_byname {path} CaS_ron "neurite_CaS"
	set_neurites_par_byname {path} K_Ca    "neurite_KCa"
	set_neurites_field_par_byname {path} Em "neurite_Eleak"
	set_neurites_field_par_byname {path} Rm "neurite_Rleak"

	// do it for all 3
	set_neurite_Ca_conc {path} 1
	set_neurite_Ca_conc {path} 2
	set_neurite_Ca_conc {path} 3

	// axon
	set_gmax_par_byname {path}/axon Na_ron "axon_Na"
	set_gmax_par_byname {path}/axon K1_ron "axon_K1"
	set_gmax_par_byname {path}/axon K2_ron "axon_K2"
	set_gmax_par_byname {path}/axon A_ron  "axon_A"
	set_comp_field_par_byname {path}/axon Em "axon_Eleak"
	set_comp_field_par_byname {path}/axon Rm "axon_Rleak"

	// correct synaptic and dendrite compartments to neurite Rm, Em values
	set_comp_field_par_byname {path}/dendrite Rm "neurite_Rleak"
	set_comp_field_par_byname {path}/dendrite Em "neurite_Eleak"
	set_comp_field_par_byname {path}/synaptic Rm "neurite_Rleak"	
	set_comp_field_par_byname {path}/synaptic Em "neurite_Eleak"
end

function modify_syn_params (HE_num)
	str currentMode
	int HN_num
	foreach currentMode ({arglist "peri sync"})
	  foreach HN_num ({arglist "3 4 6 7"})
			pushe /HE{HE_num}_{currentMode}/synaptic/SynS{HN_num}
				// scale gmax by multiplier
				setfield gmax {{getfield gmax} * \
					{get_param_byname "synS_mult_HE"{HE_num}"_HN"{HN_num}}}
			pope
		end 
	end
	setfield /HE{HE_num}_peri_SynE/SynE Gbar {{ {get_param_byname "synE" } / 50 } * 10e-9}
	setfield /HE{HE_num}_sync_SynE/SynE Gbar {{ {get_param_byname "synE" } / 50 } * 10e-9} 
end
