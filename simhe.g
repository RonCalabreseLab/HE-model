// Override HEganglia in .g files (for simulating whole chain)
//str HEganglia = "8 9 10 11 12 13 14"
str HEganglia = "8 12"

// input (mod function) settings (varies by input pattern)
//str inputdir = "/usr/local/lgenesis/evolution_models/PreMotorInput/StandardInputs/Spikes_and_Mod"
//str inputduration = 100//90  // seconds
str inputsamplerate = 1000 //samples/second
int verbose = 1

// sim options (to move to another file for evolution): 
//str outputfileroot = "./Debug/"  // defined in calling .g for evo alg
//str pfile     = "./HE_cell.p"    // ditto
str outputfileroot = "data/"
int compressoutput = 1
str pfile = "../../common/modelHE/simhe.p" // load generic P file and then overwrite parameters

//str outputfileroot = {"./Jul22_8to15/" @ he_num @ uniquemodelid}
// this needs to go into the settings file.. stupid genesis

//include ./PreMotorInput/StandardInputs/synaptic_wts_delays_new.g

// Options:
str output_type = "binary" 			// ascii or binary

//----------------------------
// generic parameters
str coordmodes = "peri sync" 
str HNganglia = "3 4 6 7" 
//str HEganglia = "12" moved to initial model file to allow parametrization for external control
//str HEganglia = "7 8 9 10 11 12 13 14" // OVERRIDE ganglia

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
//  include HEchan_injection.g
// end injection channels ----------------------------------------------------------------------------------------
include synEobj.g
include SynapticInput.g

include outputfile_multigang.g  

include compartments.g // Added for compatibility with readcell library
//include protocols.g // < needs to be rewritten for chain simulation

// simulation timestep // varying timestep to evaluate spikes
float dt =  {5*10**-5}//{5*10**-5}	////simulation time step in sec, 5e-5  {5*10**-5}
setclock  0  {dt}       //set the simulation clock
setclock  1 {5*10**-4}//  2000 samples/second saved

// build library of generic compartments and channels
pushe /library
	make_cylind_compartment		// makes "asymmetric cylindrical compartment" - the only type used in this simulation
	make_Na_ron		
	make_K1_ron		
	make_K2_ron		
	make_P_ron		
	make_CaS_ron     
	make_Ca_conc     
	make_K_Ca  		
	make_A_ron		
	
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
		// function to possibly modify cell parameters;
		// must be defined in run scripts: 
		// TODO: define extern? make this optional?
		modify_cell_params {currentHE} {currentMode} 
	end
end


loadHNinput {coordmodes} {HNganglia} {inputdir} {inputduration} {inputsamplerate}
make_syn_connections {coordmodes} {HNganglia} {HEganglia} 0.020 {dt} 0.1


foreach currentHE({arglist {HEganglia}})
	//	echo "    Setting syn weights" /HE{currentHE}
	set_syn_wts{currentHE}
	//set_syne_gbar {syne_gbar} {currentHE}
	// moved to modify_syn_params
	modify_syn_params {currentHE}
end
set_slowsyn_wts {coordmodes} {HNganglia} {HEganglia} {slowratio}
// must setup output (save) messages before calling SETUP on hines-solved elements


// include pseudo experimental protocols: --------------------------------------
//include protocols.g
//createCC
//initrampgenCC /HE8_sync/soma
//initrampgenCC /HE12_sync/soma

//{coordmodes} {HNganglia} {HEganglia} 

// Block all channels
//BlockAllChannels 1 {HEganglia} {coordmodes}
//zeroCaPerfusion 1 {HEganglia} {coordmodes}

// Block synapses except for SynE
//set_synE_only {coordmodes} {HNganglia} {HEganglia} 
//set_gbar 0 "8"
// -----------------------------------------------------------------------------

// save output data:
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
    // chanmode: 1 safest: 24s on new simulacrum
    //           2 for saving Vm only: 12s but synapse messages don't work
    //           3 none saved: 12s but synapse messages don't work
    //           4 saves Im, etc: 14s but synapse messages don't work
		setmethod 11 // 11 Crank-Nicholson
		call /HE{currentHE}_{currentMode} SETUP
	end
end

//setmethod 2 // for non-hines 

reset

// test for output file existence before simulation
//foreach currentHE({arglist {HEganglia}})
//	sh "test -e HE"{currentHE}"soma_Vm.txt && echo HE"{currentHE}"soma_Vm.txt exists before simulation"
//end

//step 15 -t
// Run step protocol (to get tau, etc.)
//stepsCC(baselevel, basetime, level, dlevel, width, npulses, compartment)
//stepsCC 0 2 -.2e-9 -0.20e-9 1 10 
//rampCC -1e-9 2 1e-9 8 1
//step 30 -t
//rampCC -1e-9 2 1e-9 8 1

//fiInhibitionCurve 1

///////////////////////////////////////////////////////////////////////////////
// CG: disable for getting the Genesis shell and to inspect the model
step {inputduration} -t
//bye // instead use genesis -batch

// compress output files if requested
if ({compressoutput} == 1)
	echo "Compressing"
	compressOutputFiles 1
end
