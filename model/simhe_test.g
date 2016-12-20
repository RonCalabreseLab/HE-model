// input (mod function) settings (varies by input pattern)
//str inputdir = "/usr/local/lgenesis/evolution_models/PreMotorInput/StandardInputs/Spikes_and_Mod"
//str inputduration = 100//90  // seconds
str inputsamplerate = 1000 //samples/second
int verbose = 1
// sim options (to move to another file for evolution): 
//str outputfileroot = "./Debug/"  // defined in calling .g for evo alg
//str pfile     = "./HE_cell.p"    // ditto

//str outputfileroot = {"./Jul22_8to15/" @ he_num @ uniquemodelid}
// this needs to go into the settings file.. stupid genesis

//include ./PreMotorInput/StandardInputs/synaptic_wts_delays_new.g

//----------------------------
// generic parameters
str coordmodes = "peri sync" 
str HNganglia = "3 4 6 7" 
//str HEganglia = "12" moved to initial model file to allow parametrization 
str currentHE, currentMode
//

// set pwd
//cd /usr/local/lgenesis/evolution_models/

if ({verbose} == 1)
	setprompt "HE Model Version 9.2 (beta) chain-sim"
	echo       ***********************
end

//include files
include defaults.g
include HEchan.g
//include cell_param.g // (soma parameters and cell dimensions)

include HNinput.g
include synEobj.g

//include syncreate_HE.g // must have leech-libraries 
//include syn_messages.g

include outputfile_multigang.g  

include compartments.g // Added for compatibility with readcell library
//include protocols.g // < needs to be rewritten for chain simulation

// simulation timestep 
float dt =  {2**-14}	// switched to next-lower power of 2. 0.0001             //simulation time step in sec
setclock  0  {dt}       //set the simulation clock
setclock  1 {{dt}*8}//  {2**-14}*2**3 = 2**-11 : 2048 samples/second saved

// build library of generic compartments and channels
pushe /library
	make_cylind_compartment		// makes "asymmetric cylindrical compartment" - the only type used in this simulation
	// These are some standard channels used in .p files 
	make_Na_ron			// makes "Na_ron" 
	make_K1_ron			// makes "K1_ron"
	make_K2_ron			// makes "K2_ron" 
	make_P_ron			// makes "P_ron" 
	make_CaS_ron        // makes "CaS_ron"
	make_Ca_conc        // makes "Ca_conc"  
	make_K_Ca  			// makes "K_Ca"	
	make_A_ron			// makes "A_ron"
	
	createHNsyn {HNganglia} // creates SynS objects from each HN/mode
	createSynE
pope // returning to the root element 


echo Making neuron(s)

foreach currentMode({arglist {coordmodes}})
	foreach currentHE({arglist {HEganglia}})
		echo "    " /HE{currentHE}_{currentMode}
		readcell {pfile} /HE{currentHE}_{currentMode} //TODO modify this for separate .p files for each ganglia
	end
end


loadHNinput {coordmodes} {HNganglia} {inputdir} {inputduration} {inputsamplerate}
make_syn_connections {coordmodes} {HNganglia} {HEganglia} 0.020 {dt} 0.1


foreach currentHE({arglist {HEganglia}})
	echo "    Setting syn weights" /HE{currentHE}
	set_syn_wts{currentHE}
	set_gbar {syne_gbar} {currentHE}
end

save_soma_Vm {HEganglia}

saveAllCurrents 2 {HEganglia} {coordmodes}

//save_syn_connections {coordmodes} {HNganglia} {HEganglia}

//debugK_Ca {coordmodes} {HEganglia} "neurite1 neurite2" // 
//saveMembraneCurrents 0 {HEganglia} {coordmodes}

check
reset
 // test for output file existence before simulation
//foreach currentHE({arglist {HEganglia}})
//	sh "test -e HE"{currentHE}"soma_Vm.txt && echo HE"{currentHE}"soma_Vm.txt exists before simulation"
//end

//step {inputduration} -t
//bye


