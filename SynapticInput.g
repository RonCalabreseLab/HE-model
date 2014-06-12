// HNinput.g
// This file contains the code to load the spiketime files for all presynaptic HN cells
// as well as the 'modulation waveform' representing the presynaptic membrane voltage.
// Originally created while preparing multi-compartmental model for use with evolutionary algorithms.
// 
// Oct 2010
// Damon Lamb

// loads HN spike tables from rootdir into 
// /HNinput/{input_id}_{mode}_spikes and modulation waveforms to /HNinput/HN{curID}_{curMode}_mod
// NOTE: table goes from 0 to length, resulting in one additional time step to account for the last entry.
//       input must be similarly structured. This is mathematically consistent with an end time

float slowratio = 0.33  // Ratio of slow to fast synchan components of the synaptic input.

function loadHNinput(coord_modes, input_ids, rootdir, length, samplefreq)
  str coord_modes // peri or sync
  str input_ids  // 3, 4, 6, 7, or X for the source of the input 
  str rootdir //root directory for the spike and presynaptic Vm waveform files, WITHOUT trailing /
  float length, samplefreq  // length in seconds and sample frequency of presynaptic voltage file(s)
  int nsamples = length * samplefreq 
  float Vm	
  if ({verbose} == 1)
		echo "Loading HN spike times and presynaptic voltage tables from " {rootdir}
  end
  str curMode, curID
  pushe /  
		create neutral HNinput
		
		// loop over modes and input IDs
		foreach curMode({arglist {coord_modes}})
			foreach curID ({arglist {input_ids}})
				if ({verbose} == 1)
					echo "   " HN{curID}_{curMode} into HNinput/{curID}_{curMode}_spikes
				end
				// create a timetable for each mode-input ID pair
				create timetable HNinput/HN{curID}_{curMode}_spikes
				// initialize timetable
				setfield HNinput/HN{curID}_{curMode}_spikes maxtime 2000 method 4 act_val 1.0 fname {rootdir}/HN{curID}_{curMode}
				// load data into timetable
				call HNinput/HN{curID}_{curMode}_spikes TABFILL
				// create a spikegen to translate spiketimes into SPIKE messages to the synchans
				create spikegen HNinput/HN{curID}_{curMode}_spikes/spike
				setfield HNinput/HN{curID}_{curMode}_spikes/spike output_amp 1 thresh 0.5 abs_refract 0.005
				addmsg HNinput/HN{curID}_{curMode}_spikes HNinput/HN{curID}_{curMode}_spikes/spike INPUT activation
				if ({verbose} == 1)
					echo "   " HN{curID}_{curMode}_mod into HNinput/HN{curID}_{curMode}_mod
				end
				// create a voltage table for the presynaptic (modulation) waveform 		
				create table HNinput/HN{curID}_{curMode}_mod
				setfield HNinput/HN{curID}_{curMode}_mod step_mode 2 stepsize 0
				call HNinput/HN{curID}_{curMode}_mod TABCREATE {nsamples} 0 {length - 1/samplefreq}
				file2tab {rootdir}/HN{curID}_{curMode}_mod HNinput/HN{curID}_{curMode}_mod table -xy {nsamples} 
				// debug //			
				//tab2file ./Debug/testsyn{curID}table_{curMode}_new HNinput/HN{curID}_{curMode}_mod table -mode xy -overwrite
			end
		end
  pope
end


// creates generic SynS (synchan + synS-mod chan) objects
function createHNsyn(input_ids)
	
  str input_ids  // 3, 4, 6, 7, or X for the source of the input 
  str HE_ids    // ganglia # of HE cells in which to create the SynS objects
  //echo "Creating SynS (mod and synchan) objects for HN: " {input_ids} 
  str curID, chanpath
 
	// loop over modes and input IDs
  foreach curID ({arglist {input_ids}})
       
    /* mod object not used anymore - mod waveform directly created and passed to synchan
		*/
		
    chanpath = "SynS" @ {curID}
    create  synchan {chanpath}
    if ({strcmp {curID} "X"} == 0)
      echo {curID} ":X"
      setfield        ^			\
        Ek		-0.0625 	\
        tau1	1.0e-2 		\      // sec
        tau2	4.0e-3		\      // sec
        gmax	0               // Siemens  	
			
		else // synchan from 2 4 6 7
      setfield        ^			\
        Ek		-0.0625		\
        tau1	1.25e-2 		\      // sec // adjusted for testing the result of faster dynamics, formerly 5e-2s
        tau2	4.0e-3		\      // sec
        gmax	0               // Siemens
        
        
      chanpath = "SynS_slow" @ {curID}
			//echo "Creating slow aspect of synaptic input: " {chanpath}
      create  synchan {chanpath}
				setfield        ^			\  // Formerly, this was approximated with a single synchan (above). Slower dynamics are used here.
        	Ek		-0.0625		\
        	tau1	15e-2 		\   	
        	tau2	4.0e-3		\      // sec
        	gmax	0               // Siemens
				
			end
		end
	end


// adjusted to be compatible with hines by moving SynE outside of the cell
function set_gbar(gbar, currentHE)
	float gbar
	str currentHE
	setfield /HE{currentHE}_peri_SynE/SynE Gbar {gbar}
	setfield /HE{currentHE}_sync_SynE/SynE Gbar {gbar} 
end

// set slow portion of syns to slowratio * fastsyns gmax
function set_slowsyn_wts(coord_modes, input_ids, HE_ganglia)
	str coord_modes //= eg "peri sync"
	str input_ids  //= eg "3 4 6 7 X" //for the source of the input 
	str HE_ganglia // = "8 9 10 11 12 13 14"
	// slowratio defined at top of file
	
	str curHN, curMode, curHE	
	
	foreach curHE({arglist {HE_ganglia}})
		foreach curMode({arglist {coord_modes}})
			foreach curHN ({arglist {input_ids}})	
  			//		echo {getfield /HE{curHE}_{curMode}/synaptic/SynS{curHN} gmax}
  			//		echo {{slowratio} * {getfield /HE{curHE}_{curMode}/synaptic/SynS{curHN} gmax}} 				
				setfield /HE{curHE}_{curMode}/synaptic/SynS_slow{curHN} gmax {{slowratio} * {getfield /HE{curHE}_{curMode}/synaptic/SynS{curHN} gmax}} 
  			//		echo {getfield /HE{curHE}_{curMode}/synaptic/SynS_slow{curHN} gmax}
			end
		end
	end
end

// set weight of syns (both slow and fast) to 0
function set_synE_only(coord_modes, input_ids, HE_ganglia)
	str coord_modes //= eg "peri sync"
	str input_ids  //= eg "3 4 6 7 X" //for the source of the input 
	str HE_ganglia // = "8 9 10 11 12 13 14"
	
	str curHN, curMode, curHE	
	
	foreach curHE({arglist {HE_ganglia}})
		foreach curMode({arglist {coord_modes}})
			foreach curHN ({arglist {input_ids}})	
				setfield /HE{curHE}_{curMode}/synaptic/SynS_slow{curHN} gmax 0
				setfield /HE{curHE}_{curMode}/synaptic/SynS{curHN} gmax 0
  		end
		end
	end
end


// uses hard coded modes (sync/peri)
function InstantiateSynE(curHE)
  str curHE
  
  create neutral HE{curHE}_peri_SynE 
  create neutral HE{curHE}_sync_SynE 
  
  copy /library/SynE HE{curHE}_peri_SynE 	
  copy /library/SynE HE{curHE}_sync_SynE 

  // sync
  addmsg HE{curHE}_peri/synaptic		HE{curHE}_sync_SynE/SynE VOLTAGE Vm
  addmsg HE{curHE}_sync/synaptic 		HE{curHE}_sync_SynE/SynE POSTVOLTAGE Vm		
  addmsg HE{curHE}_sync_SynE/SynE 	HE{curHE}_sync/synaptic INJECT Ik	

  // peri
  addmsg HE{curHE}_sync/synaptic 		HE{curHE}_peri_SynE/SynE VOLTAGE Vm
  addmsg HE{curHE}_peri/synaptic 		HE{curHE}_peri_SynE/SynE POSTVOLTAGE Vm
  addmsg HE{curHE}_peri_SynE/SynE		HE{curHE}_peri/synaptic INJECT Ik

end

// NOTE: you cannot change the time step after setting the delay table nsteps (by calling this function)
//  todo: add a 'reset' of nsteps function to be called after changing the simulation dt
function make_syn_connections( coord_modes, input_ids, HE_ganglia, delayPerGanglion, dt, defaultmod)
  str input_ids  //= eg "3 4 6 7 X" //for the source of the input 
  str coord_modes //= eg "peri sync"
  str HE_ganglia // = eg "8 9 10 11 12 13 14"
  float delayPerGanglion, dt, defaultmod

  int nsteps
  float delaytime
  str curHN, curMode, curHE
    
  foreach curHE({arglist {HE_ganglia}})
    InstantiateSynE {curHE}
    // setup messages (and delay table for mod function)
    str curHEname, modTablename
    foreach curMode({arglist {coord_modes}})
      foreach curHN ({arglist {input_ids}})	
        // create buffer table in each HE's synaptic compartment
        //echo "  making:  " /HE{curHE}_{curMode}/synaptic/HN{curHN}_ModDelay 
        //filename = "HE" @ currentHE @ "soma_Vm.txt"
        curHEname = "HE" @ {curHE} @ "_" @ {curMode}
        //  echo {curHEname}
        modTablename = "HNinput/HN" @ {curHN} @ "_" @ {curMode} @ "_" @ {curHEname} @ "_ModDelay"
        //echo {modTablename}
        
        create table {modTablename}
        setfield {modTablename} step_mode 6
        if ({strcmp {curHN} "X"} == 0)
          echo "WARNING: Delay from HNX per mode not implemented"
          delaytime = {({curHE}-3)*delayPerGanglion}
				else
          delaytime = {({curHE}-{curHN})*{delayPerGanglion}}
          //	nsteps = {round {(({curHE}-{curHN})*{delayPerGanglion})/{dt}}}
        end
        nsteps = {round {delaytime/dt}}
        //	echo {curHE} "-" {curHN} "  " {nsteps}
        call {modTablename} TABCREATE {nsteps-1} 0 {nsteps-1}
        //	echo "bump"
        setfield {modTablename} table ==={defaultmod}
        // link mod table to buffer
        addmsg /HNinput/HN{curHN}_{curMode}_mod {modTablename} INPUT output
        // link buffer to synchan
        addmsg  {modTablename}  /{curHEname}/synaptic/SynS{curHN} MOD output
        // link spikes to synchan 
        addmsg /HNinput/HN{curHN}_{curMode}_spikes/spike /{curHEname}/synaptic/SynS{curHN} SPIKE
        setfield /{curHEname}/synaptic/SynS{curHN} synapse[0].delay {delaytime}
        
        // Add links to slow synchan: ----------------------
        // link buffer to synchan
        addmsg  {modTablename}  /{curHEname}/synaptic/SynS_slow{curHN} MOD output
        // link spikes to synchan 
        addmsg /HNinput/HN{curHN}_{curMode}_spikes/spike /{curHEname}/synaptic/SynS_slow{curHN} SPIKE
        setfield /{curHEname}/synaptic/SynS_slow{curHN} synapse[0].delay {delaytime}
        // end slow synchan section ------------------------
      
    end
	end
end
end

