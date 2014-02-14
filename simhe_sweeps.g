// Override HEganglia in .g files (for simulating whole chain)
//str HEganglia = "8 9 10 11 12 13 14"

// input (mod function) settings (varies by input pattern)
//str inputdir = "/usr/local/lgenesis/evolution_models/PreMotorInput/StandardInputs/Spikes_and_Mod"
//str inputduration = 100//90  // seconds
str inputsamplerate = 1000 //samples/second
int verbose = 1
float slowratio = 0.33
str sgetaskid = {getenv SGE_TASK_ID}

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

// OVER RIDE ganglia
//str HEganglia = "7 8 9 10 11 12 13 14"

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

// injection channels ----------------------------------------------------------------------------------------
//include HEchan_injection.g
// end injection channels ----------------------------------------------------------------------------------------
include synEobj.g
include SynapticInput.g

include outputfile_multigang.g  

include compartments.g // Added for compatibility with readcell library
//include protocols.g // < needs to be rewritten for chain simulation

// simulation timestep // varying timestep to evaluate spikes
float dt =  {5*10**-5}	////simulation time step in sec
setclock  0  {dt}       //set the simulation clock
setclock  1 {5*10**-4}//  2000 samples/second saved

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
	
	// injection (parameter variation) currents ----------------------------------------------------
	//make_CaS_inj
	// end injection channels ----------------------------------------------------------------------------------------
	
	createSynE
pope // returning to the root element 


echo Making neuron(s)
foreach currentMode({arglist {coordmodes}})
	foreach currentHE({arglist {HEganglia}})
		echo "    " /HE{currentHE}_{currentMode}
		readcell {pfile} /HE{currentHE}_{currentMode} -hsolve // hines solver!
	end
end


loadHNinput {coordmodes} {HNganglia} {inputdir} {inputduration} {inputsamplerate}
make_syn_connections {coordmodes} {HNganglia} {HEganglia} 0.020 {dt} 0.1


foreach currentHE({arglist {HEganglia}})
//	echo "    Setting syn weights" /HE{currentHE}
	set_syn_wts{currentHE}
	set_gbar {syne_gbar} {currentHE}
end
set_slowsyn_wts {coordmodes} {HNganglia} {HEganglia} {slowratio}
// must setup output (save) messages before calling SETUP on hines-solved elements

save_soma_Vm {HEganglia}

//save_all_Vm {coordmodes} {HEganglia}
//saveAllCurrents 2 {HEganglia} {coordmodes}
//saveSynapseCurrents 2 {HEganglia} {coordmodes}
//save_syn_connections {coordmodes} {HNganglia} {HEganglia}
//debugK_Ca {coordmodes} {HEganglia} "neurite1 neurite2 neurite3" // 
//saveMembraneCurrents 0 {HEganglia} {coordmodes}


// After all external messages have been setup (assuming chanmode 1):
// for each cell, setup hines solver options and method.
foreach currentMode({arglist {coordmodes}})
	foreach currentHE({arglist {HEganglia}})
		setfield /HE{currentHE}_{currentMode} \
		   path /HE{currentHE}_{currentMode}/##[][TYPE=compartment]  \
		   comptmode       1                       \
		   chanmode        1                       \
		   outclock        1                       \
		   storemode       1	// calcmode        0                       
		setmethod 11
		call /HE{currentHE}_{currentMode} SETUP
	end
end

//setmethod 2 // for non-hines 

reset

// test for output file existence before simulation
//foreach currentHE({arglist {HEganglia}})
//	sh "test -e HE"{currentHE}"soma_Vm.txt && echo HE"{currentHE}"soma_Vm.txt exists before simulation"
//end

step {inputduration} -t

bye


