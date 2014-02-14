/*  This file contains functions to implement various aspects of common lab protocols
	Such as 0Na perfusion (set Na channels to 0), TEA electrodes, voltage clamp steps, ramps
	 .. currently a work in progress.
	Many aspects of this are untested with the Hines solver (by me, at least), so use 
	caution.
	-Damon Lamb
*/


/*  Function createChirp creates a source which outputs a Chirp protocol loaded from the specified file
	the chirp data points in the file are presumed to be from -1 to 1, or a p-p amplitude of 2, for 60 seconds at steps of 2^-14.
*/
function createChirp(chirpfile, amplitude)
	str chirpfile
	float amplitude
	echo "Creating chirp from: " {chirpfile} " with amplitude " {amplitude}
	
	create table 		/chirpsource
	create neutral 		/chirpsource/amplitude
	create calculator 	/chirpsource/scaled
	setfield /chirpsource step_mode 1 stepsize 0 // step_mode 1: loop acts as function generator, step by main clock time step
	//setfield /chirpsource step_mode 0 stepsize 0 // step_mode 0: IO - calculates based on PRD for each step, step by main clock time step
	call /chirpsource TABCREATE 983041 0 60 // source data is in steps of 2^-14 from 0 to 60 seconds
	file2tab {chirpfile} /chirpsource table -xy 983041 // one additional time step to include both 0 and 60

	setfield /chirpsource/amplitude x {amplitude/2}
	//addmsg   /chirpsource/amplitude /chirpsource PRD x  //does not work
	
	addmsg   /chirpsource/amplitude /chirpsource/scaled MULTIPLY x
	addmsg   /chirpsource/ /chirpsource/scaled MULTIPLY output
	setfield /chirpsource/scaled output_init 1
	//call /chirpsource/scaled PROCESS  -> this gets undone by reset, must call later after final reset
end

/* 	createCC(compartment)
	Creates the base elements for the ramp and pulse protocols.
*/
function createCC
// create pulsegen and calculator for step and ramp protocols
	create pulsegen 	/pgen			// for step protocols _--_
	create calculator	/rampgen		// for ramp protocols _/\_
	create neutral		/rampgen/istep	// for ramp protocols _/\_
end

/*	Function initpgenCC initializes messages from a pulsegen object to inject current into the given compartment (typically soma)
	Takes the following argument
		str compartment	: compartment to inject current into (typically soma)
 	e.g.: initstepsCC /HE12_sync/soma
*/
function initpgenCC(compartment)
	str compartment
	//connects pulsegenator to the compartment
	echo "Creating message from /pgen to" {compartment}
	addmsg 	/pgen	{compartment}	INJECT output
end

/*	Function initrampgenCC initializes messages from a rampgen object to inject current into the given compartment (typically soma)
	Takes the following argument
		str compartment	: compartment to inject current into (typically soma)
 	e.g.: initstepsCC /HE12_sync/soma
*/
function initrampgenCC(compartment)
	str compartment
	//connects pulsegenator to the compartment
	if (-1 == {getmsg {compartment} -find /rampgen INJECT})
	echo "Creating message from /rampgen to" {compartment}
		addmsg 	/rampgen	{compartment}	INJECT output
	end
end

	


/*	Function stepsCC initializes a pulsegen object and injects current into a compartment specified in initstepsCC (typically soma)
 	in basic steps as specified by arguments. This function assumes that the model has been allowed
	to run for some reasonable amount of time to establish a reasonable baseline prior to calling this function, 
	or that the baseline value and time is sufficient to reach steady/stable state.
	Takes the following arguments		
		float baselevel : the holding iinj level in A
		float basetime	: duration of baseline level in seconds
		float level   	: pulse 1 level
		float dlevel	: change in pulse level with each pulse
		float width  	: pulse 1 width in seconds
		int   npulses	: number of pulses
		str compartment	: compartment to inject current into (typically soma)
 	e.g.: stepsCC 0 0.5 -1e-9 0.20e-9 0.5 10 /HE_sync_R/soma
	      would execute 8 0.5 second pulses off of a baseline 0nA (held for 0.5 seconds) from -1.0 na to +1.0 na 
*/
function stepsCC(baselevel, basetime, level, dlevel, width, npulses)
	float baselevel, basetime, level, dlevel, width
	int npulses
	
	int ipulse
	float totaltime = {basetime + width}

	echo "Setting up CC; arguments:" {baselevel}, {basetime}, {level}, {dlevel}, {width}, {npulses}
	
    //Initialize pulsegenerator
	setfield /pgen baselevel {baselevel} delay1 {basetime} width1 {width} trig_mode 0
	
	for (ipulse = 0; ipulse <npulses; ipulse = ipulse + 1)
		echo setting level to {level + ipulse * dlevel} and stepping for {width}s	
		// set pgen to appropriate value, then step for basetime + width	
		setfield /pgen level1 {level + ipulse * dlevel}
		step {totaltime} -t		
	end
end


/*	Function rampCC creates a calculator object and injects current into the given compartment (typically soma)
	 in basic ramp as specified by arguments. This function assumes that the model has been allowed
	to run for some reasonable amount of time to establish a baseline prior to calling this function, 
	or that the baseline value and time is sufficient to reach steady state. Baseline is repeated at the end (_/\_/\_).
	Takes the following arguments
		float baselevel : the holding Vm level
		float basetime	: duration of baseline level in seconds
		float peak   	: peak command voltage
		float width  	: duration of ramp width in seconds
		int   nreps		: number of repetitions of the ramp
 	e.g.: rampCC -0.3 5 1 10 2 /HE_sync_R/soma
	      would execute 2 10 second ramps off of a baseline -0.3 na (held for 5 seconds) up to +1.0 na (5s up, 5s down)
*/
function rampCC(baselevel, basetime, peak, width, nreps)
	float baselevel, basetime, peak, width
	int nreps
	
	int irep
	
	// TODO:check for erroneous input (e.g. width <=0)
	echo arguments: {baselevel}, {basetime}, {peak}, {width}, {nreps}

	float tstep = {getclock 0}
	float istep = {tstep*(peak - baselevel)/(width/2)} 
	float totaltime = {basetime + width}
	float halfwidth = {width/2}
	
	echo "  " tstep: {tstep}  istep: {istep}  totaltime: {totaltime}  halfwidth: {halfwidth}
	
	//setclock 4 9999 // set the 'blank' reset to a very long time
	
	//sets up calculator element and connects it to the compartment
	setfield /rampgen/istep	x	{istep}
	// if messages have not been setup yet, do so
	if (-1 == {getmsg /rampgen -find /rampgen/istep SUM})
		addmsg	/rampgen/istep /rampgen	SUM x	
	end
	// moved to separate function to be compatible with Hines solver.

	for (irep = 0; irep <nreps; irep = irep + 1)
		//baseline for basetime
		setfield /rampgen output_init {baselevel}
		setfield /rampgen resetclock 0
		step {basetime} -t
		
		// first half of ramp
		setfield /rampgen resetclock 4
		setfield /rampgen/istep	x	{istep}
		step {halfwidth} -t
		// second half of ramp
		
		setfield /rampgen resetclock 4
		setfield /rampgen/istep	x	{-istep}
		step {halfwidth} -t
	end
	//baseline for basetime
	setfield /rampgen output_init {baselevel}
	setfield /rampgen resetclock 0
	step {basetime} -t
	setfield /rampgen output_init 0
	setfield /rampgen resetclock 0
		
	//setclock 0 {currentclock}
end
// ------------------------------------------------------




/* 	createVC(compartment)
	Creates and hooks up voltage clamp element to specified compartment element
	Also creates the base elements for the ramp and pulse protocols.
	
*/
function createVC(compartment)
	str compartment
// TODO: add checks for existance of these objects before creation/hookup.

// create vclamp objects values from Neurokit vclamp.g

	create diffamp /Vclamp
	setfield ^ saturation 999.0 gain 0.002 	// (1/R)
	create RC /Vclamp/lpfilter
	setfield ^ R 500.0 C 1e-7 // tau = RC. Should result in 0.05 ms tau unless units are off
	create PID /Vclamp/PID					
	setfield ^ gain 1e-6 tau_i 2e-5 tau_d 5e-6 saturation 999.0 // gain ~10/Rin of cell
// create pulsegen and calculator for step and ramp protocols
	create pulsegen 	/pgen			// for step protocols _--_
	create calculator	/rampgen		// for ramp protocols _/\_
	create neutral		/rampgen/vstep	// for ramp protocols _/\_
// hookup vclamp elements (but not source)
	addmsg /Vclamp/lpfilter /Vclamp 			PLUS state
	addmsg /Vclamp 			/Vclamp/PID			CMD output
	addmsg {compartment}	/Vclamp/PID			SNS Vm
	addmsg /Vclamp/PID		{compartment}		INJECT output
	
end

/*	Function stepsVC creates a pulsegen object connected to a preexisting voltage clamp object and clamps
	voltage in basic steps as specified by arguments. This function assumes that the model has been allowed
	to run for some reasonable amount of time to establish a reasonable baseline prior to calling this function, 
	or that the baseline value and time is sufficient to reach steady state.
	Takes the following arguments
		float baselevel : the holding Vm level
		float basetime	: duration of baseline level in seconds
		float level   	: pulse 1 level
		float dlevel	: change in pulse level with each pulse
		float width  	: pulse 1 width in seconds
		int   npulses	: number of pulses
 	e.g.: stepsVC -0.070 0.5 -0.060 0.010 0.5 8 
	      would execute 8 0.5 second pulses off of a baseline -70 mV (held for 0.5 seconds) from -60 to +20 mV 
*/
function stepsVC(baselevel, basetime, level, dlevel, width, npulses)
	float baselevel, basetime, level, dlevel, width
	int npulses
	
	int ipulse
	float totaltime = {basetime + width}

	//connects pulsegenator to the voltage clamp
	if (-1 == {getmsg /Vclamp/lpfilter -find /pgen INJECT})
		addmsg 	/pgen	/Vclamp/lpfilter	INJECT output
	end
	//addmsg 	/pgen	/Vclamp/lpfilter	INJECT output
	
	echo arguments {baselevel}, {basetime}, {level}, {dlevel}, {width}, {npulses}
	float currentclock  =  {getclock 0} //save current clock and set to smaller time step to avoid numerical instability
	setclock  0  1.5258789062500000E-005  //1/(2^16)

	            
	setfield /pgen baselevel {baselevel} delay1 {basetime} width1 {width} trig_mode 0
	for (ipulse = 0; ipulse <npulses; ipulse = ipulse + 1)
		// set pgen to appropriate value, then step for basetime + width
	
		echo setting level to {level + ipulse * dlevel} and stepping for {totaltime}s
		
		setfield /pgen level1 {level + ipulse * dlevel}
		step {totaltime} -t		
	end
	setclock 0 {currentclock}
end


/*	Function rampVC creates a calculator object connected to a preexisting voltage clamp object and clamps
	voltage in basic ramp as specified by arguments. This function assumes that the model has been allowed
	to run for some reasonable amount of time to establish a reasonable baseline prior to calling this function, 
	or that the baseline value and time is sufficient to reach steady state.
	Takes the following arguments
		float baselevel : the holding Vm level
		float basetime	: duration of baseline level in seconds
		float peak   	: peak command voltage
		float width  	: duration of ramp width in seconds
		int   nreps	: number of repetitions of the ramp
 	e.g.: rampVC -0.070 0.5 0 1 2 
	      would execute 2 1 second ramps off of a baseline -70 mV (held for 0.5 seconds) up to 0 (.5s up, .5s down)
*/
function rampVC(baselevel, basetime, peak, width, nreps)
	float baselevel, basetime, peak, width
	int nreps
	
	int irep
	
	// TODO:check for erroneous input (e.g. width <=0)
	echo arguments {baselevel}, {basetime}, {peak}, {width}, {nreps}
	float currentclock  =  {getclock 0} //save current clock and set to smaller time step to avoid numerical instability
	setclock  0  {2**(-16)}	
	//TODO: check need for changes to clock with Hines solver
	
	float tstep = {getclock 0}
	float vstep = {tstep*(peak - baselevel)/(width/2)} 
	float totaltime = {basetime + width}
	float halfwidth = {width/2}
	echo "  " tstep:{tstep} vstep:{vstep} totaltime:{totaltime} halfwidth:{halfwidth}
	
	setclock 4 9999 // set the 'blank' reset to a very long time
	
	//sets up calculator element and connects it to the voltage clamp
	setfield /rampgen/vstep	x	{vstep}
	addmsg	/rampgen/vstep /rampgen	SUM x	
	addmsg 	/rampgen	/Vclamp/lpfilter	INJECT output
  
	//setfield /pgen baselevel {baselevel} delay1 {basetime} width1 {width} trig_mode 0
	for (irep = 0; irep <nreps; irep = irep + 1)
		//baseline for basetime
		setfield /rampgen output_init {baselevel}
		setfield /rampgen resetclock 0
		step {basetime} -t
		
		// first half of ramp
		setfield /rampgen resetclock 4
		setfield	/rampgen/vstep	x	{vstep}
		step {halfwidth} -t
		// second half of ramp
		
		setfield /rampgen resetclock 4
		setfield	/rampgen/vstep	x	{-vstep}
		step {halfwidth} -t
	end
	
	setclock 0 {currentclock}
end


/*	Function BlockChannels loops over each channel (element) in each compartment and
	sets its Gbar to 0. Currently useing hardcoded base neutral objects for each cell of a single pair.
	Takes two arguments
		int verbose; if 1, echos all feedback about operation, if 2, echos changes only, if 0, echos nothing
		string blockedChannels - space delimited list of channel names to block
	e.g.: BlockChannels 1 "Na_ron P_ron" "8" "peri sync"
	note: leak conductance is not adjusted by this function
			Also this does not zero out synaptic conductance, although that would be affected by many of these manipulations.
			Synaptic conductance manipulation is handled elsewhere.
*/
function BlockChannels(verbose, blockedChannels, HE_ganglia, coord_modes)
	int verbose
	str blockedChannels, HE_ganglia, coord_modes

	str curHE, curMode, compartment, channel, blockedChannel, cell
	
	foreach curHE({arglist {HE_ganglia}})
		foreach curMode({arglist {coord_modes}})
			cell = {"/HE"@{curHE}@"_"@{curMode}@"/"}
			if(1==verbose)
				echo looping over compartments in {cell}
			end
			foreach compartment({el {cell}#})
				if(1==verbose)
					echo "  " looping over channels in compartment {compartment} 
				end
				
				foreach channel({el {compartment}/#})
					if(1==verbose)
						echo "      " checking if {substring {channel} {{strlen {compartment}}+1}} is in list: {blockedChannels}
					end 
					foreach blockedChannel({arglist {blockedChannels}})
						if(0=={strcmp {substring {channel} {{strlen {compartment}}+1}} {blockedChannel}})
							// could add tests to ensure this is a tabchannel (isa function), but skipping this test for now
							if(verbose >= 1)
								echo "   --" setting {channel} Gbar to 0		
							end						
							setfield {channel} Gbar 0
						end
					end			
				end	
			end
		end 
	end
end

// --------------------------- Bath/Drug  Protocols ---------------------------

// "blocks" K channels 
function TEAelectrodes(verbose, HE_ganglia, coord_modes)
	BlockChannels {verbose} "K1_ron K2_ron A_ron" {HE_ganglia} {coord_modes}
end

// "blocks" Ca channels, currently does not block chemical synaptic transmission (though perhaps it should..)
function zeroCaPerfusion(verbose, HE_ganglia, coord_modes)
	BlockChannels {verbose} "CaS_ron" {HE_ganglia} {coord_modes}
end

// "blocks" K_Ca channels
//  currently does not block chemical synaptic transmission (though it should..)
//  this simulates calcium substitution. Should adjust Ca current by permeability of replaced ion.
//  could be considered equivalent to intracellular (electrode) fast chelators
function CaSubPerfusion(verbose, HE_ganglia, coord_modes)
	BlockChannels {verbose} "K_Ca" {HE_ganglia} {coord_modes}
end

// "blocks" Na channels, currently does not block chemical synaptic transmission (though perhaps it should..)
function zeroNaPerfusion(verbose, HE_ganglia, coord_modes)
	BlockChannels {verbose} "Na_ron P_ron" {HE_ganglia} {coord_modes}
end

// "blocks" all channels
function BlockAllChannels(verbose, HE_ganglia, coord_modes)
	BlockChannels {verbose} "K1_ron K2_ron A_ron CaS_ron K_Ca Na_ron P_ron" {HE_ganglia} {coord_modes}
end

// ---------------------------- E-Phys Protocols ------------------------------

// blocks synaptic input, executes a 5s baseline, 10s ramp protocol from -0.4 nA to +1.0 nA 
function ficurve(verbose)
	// block inhibitory input
	set_synE_only {coordmodes} {HNganglia} {HEganglia}  // this function is in SynapticInput.g

	//rampCC(baselevel, basetime, peak, width, nreps)
	rampCC -0.3e-9 5 1e-9 10 4 //HE_sync_R/soma
	CaSubPerfusion {verbose}
	rampCC -0.3e-9 5 1e-9 10 4 //HE_sync_R/soma
end

// blocks synaptic input, executes a 10s baseline (0nA), 10s or 30s ramp protocol from 0 nA to -0.5 nA 
function fiInhibitionCurve(verbose)
	// block inhibitory input
	set_synE_only {coordmodes} {HNganglia} {HEganglia} // this function is in SynapticInput.g

	rampCC 0 10 -5e-10 5 2 	
	rampCC 0 10 -5e-10 10 2 
	rampCC 0 10 -5e-10 30 2 
end

// measure K_Ca from soma with voltage clamp
function measureKCa(verbose)
	zeroNaPerfusion	{verbose}
	// block inhibitory input
	set_synE_only {coordmodes} {HNganglia} {HEganglia} // this function is in SynapticInput.g
		// createVC called prior to this call..	
	//check
	stepsVC -0.070 4 -0.060 0.010 4 8 
	zeroCaPerfusion	{verbose} //CaSubPerfusion {verbose}  // or 
	stepsVC -0.070 4 -0.060 0.010 4 8 
	stepsVC -0.070 4 -0.000 0.000 0 1 
end

// measure K_Ca from soma with voltage clamp, blocking other K current
function measureKCasolo(verbose)
	zeroNaPerfusion	{verbose}
	TEAelectrodes {verbose}
	// block inhibitory input
	set_synE_only {coordmodes} {HNganglia} {HEganglia} // this function is in SynapticInput.g
		// createVC called prior to this call..	
	//check
	stepsVC -0.070 4 -0.060 0.010 4 8 
	zeroCaPerfusion	{verbose} //CaSubPerfusion {verbose}  // or 
	//check
	stepsVC -0.070 4 -0.060 0.010 4 8 
	stepsVC -0.070 4 -0.000 0.000 0 1 
end

// current clamp protocol to measure synaptic reversal
function synapticReversal(verbose)
	zeroNaPerfusion {verbose}
	//set_synE_zero
	check
	reset
	stepsCC 0 0 -.35e-9 0.02e-9 6 11 /HE_sync_R/soma
end

// current clamps to measure coupling, input R
function measureCoupling(verbose)
	zeroNaPerfusion {verbose}
	set_synE_only {coordmodes} {HNganglia} {HEganglia} // this function is in SynapticInput.g
	check
	reset
	stepsCC 0 2 -1e-9 0.5e-9 2 3 /HE_sync_R/soma	
end

