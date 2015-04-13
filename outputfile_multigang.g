/*	
	outputfile.g
	This file contains functions to save output from the model, as well as a few functions for cleaning up file i/o.
	Most output files are accompanied by a header file containing column headers for simplified plot labeling.
	This is paired with a set of matlab scripts and functions which read in the output this file helps create and analyzes/plots it.
	
	Note: it is best to set float_format (outputformat parameter) to a value such that the time step is captured in the output (no truncation)
	that is, set to something better than ceiling(-log10(timestep)) places. (e.g. %0.5g for 2^-16)
	Better yet (though resulting in huge files) is to set it to %0.15g or %0.16g so the full representable number is output without truncation.
	 
	Still a work in progress, so forgive some haxy code.
	-Damon Lamb
*/


// sets up the base output file root element when this file is included
str outputelroot = "/output"
str outputformat = "%0.8g"
// the following must be set elsewhere prior to loading this file
//str outputfileroot = {"./Jul22_8to15/" @ he_num}

if(0=={exists {outputelroot}})
	create neutral {outputelroot}
end	

// create target directories
sh {"mkdir -p " @ {tmpdir} @ {outputfileroot}}
sh {"mkdir -p " @ {outputfileroot}}

/* Function flushAllFiles
	Flushes /*.out elements off of the root element /
	If the asc_file object field 'flush' is set to 0 the data is buffered in memory.
	If we do not manually flush that data (write it to disk from the buffer), the data
	written to disk will be incomplete, as GENESIS does flush files upon exit.
*/   
function flushAllFiles
	str filehandle
	foreach filehandle ({el {outputelroot}/#.out})
		call {filehandle} FLUSH
	end
end

/* Function flushDeleteAllFiles
	Flushes and deletes / *.out elements off of the root element /
	If the asc_file object field 'flush' is set to 0 the data is buffered in memory.
	If we do not manually flush that data (write it to disk from the buffer), the data
	written to disk will be incomplete, as GENESIS does flush files upon exit.
*/   
function flushDeleteAllFiles
	str filehandle
	foreach filehandle ({el {outputelroot}/#.out})
		call {filehandle} FLUSH
		call {filehandle} DELETE
	end
end

/* Function bye closes all files created by protocols in this file (everything in the specified element path)
    then exits genesis.
*/
function bye
	flushDeleteAllFiles
	exit	
end

/*	setupOutputFile creates an asc_file to save data to with the specified parameters:
	OutputFileName	:	name of output file (without suffix)
	OutputElement 	:	name of output element to create 
	e.g. setupOutputFile "example" "demo.out"
	will create demo.out in the outputelroot
*/
function setupOutputFile(OutputFileName, OutputElement)
	str OutputFileName, OutputElement
	if ({verbose} == 1)
		echo "  Creating output element: " {outputelroot}/{OutputElement} \
      "  filename:" {tmpdir @ outputfileroot}{OutputFileName}
	end
	if(0=={exists {outputelroot}/{OutputElement}})
		if ({strcmp {output_type} "ascii"}==0)
			create asc_file {outputelroot}/{OutputElement}
			setfield {outputelroot}/{OutputElement} append 0 \
		    filename {tmpdir @ outputfileroot}{OutputFileName}".txt" \
		    initialize 1 leave_open 1 flush 0 float_format {outputformat}
			useclock {outputelroot}/{OutputElement} 1
		elif ({strcmp {output_type} "binary"}==0)
			create disk_out {outputelroot}/{OutputElement}
			setfield {outputelroot}/{OutputElement} append 0 \
		    filename {tmpdir @ outputfileroot}{OutputFileName}".bin" \
		    initialize 1 leave_open 1 flush 0
			useclock {outputelroot}/{OutputElement} 1
		else
			error "output_type not recognized: "{output_type}". Must be one of ascii or binary."
		end
	else
		echo "error - attempted to duplicate existing element: " {outputelroot}/{OutputElement}
	end	
end

/* compressOutputFiles - Cycle through all output elements and
compress files in the same place. 
deleteorigs - If 1, delete original file and leave only compressed file.
*/
function compressOutputFiles(deleteorigs)
  str outputel
	foreach outputel ({el {outputelroot}/# })
		str filename = {getfield {outputel} filename}
		echo "Flushing & compressing: "{filename}
		call {outputel} DELETE			// flushes first
		sh gen2flac {filename}
		if ({deleteorigs} == 1)
			sh rm {filename}
		end
		// Move files to final destination
    str comp_filename={strsub {filename} .bin .genflac}
		sh mv {comp_filename} {outputfileroot}
	end
end

function save_soma_Vm(HEganglia)
	str HEganglia
	str currentHE, filename, objname
	// - - -  - - - - - - -  - - - - - - - - -  - SGE_TASK_ID for cluster only
	foreach currentHE({arglist {HEganglia}})
		//filename = "HE" @ currentHE @ "soma_Vm" @ sgetaskid @ ".txt" //for cluster
		//filename = "HE" @ currentHE @ "soma_Vm.txt"
    // CG: standardized name for outputs
		filename = simname @ "_somaVm_HE_" @ currentHE @ "_trial_" @ sgetaskid
		objname = "HE" @ currentHE @ "soma_Vm.out"
		setupOutputFile {filename} {objname}
    addmsg /HE{currentHE}_peri/soma     {outputelroot}/{objname} SAVE Vm
		addmsg /HE{currentHE}_sync/soma     {outputelroot}/{objname} SAVE Vm
	end
end

function save_all_Vm(coord_modes, HEganglia)
	str coord_modes, HEganglia
	str cell, currentHE, curMode, compartment, filename, objname
	
	foreach currentHE({arglist {HEganglia}})
		filename = "HE" @ currentHE @ "_all_Vm.txt"
		objname = "HE" @ currentHE @ "_all_Vm.out"
		setupOutputFile {filename} {objname}

		foreach curMode({arglist {coord_modes}})
			cell = {"/HE"@{currentHE}@"_"@{curMode}@"/"}
			foreach compartment({el {cell}#})
				addmsg {compartment}     {outputelroot}/{objname} SAVE Vm

			end	
		end
	end

end


// NOTE: you cannot change the time step after setting the delay table nsteps (by calling this function)
//  todo: add a 'reset' of nsteps function to be called after changing the simulation dt
function save_syn_connections( coord_modes, input_ids, HE_ganglia)
	str input_ids  //= eg "3 4 6 7 X" //for the source of the input 
	str coord_modes //= eg "peri sync"
	str HE_ganglia // = "8 9 10 11 12 13 14"
	str curHN, curMode, curHE


	str filename = "HEsynaptic_debug.txt"
	str objname = "HEsyanptic_debug.out"
	setupOutputFile {filename} {objname}

	// save synE 
	foreach curHE({arglist {HE_ganglia}})
		addmsg HE{curHE}_sync/synaptic/SynE {outputelroot}/{objname} SAVE 	Ik
		addmsg HE{curHE}_peri/synaptic/SynE {outputelroot}/{objname} SAVE 	Ik
		//echo HE{curHE}_sync/synaptic/SynE
		//echo HE{curHE}_peri/synaptic/SynE
	end
	// save 
	foreach curHE({arglist {HE_ganglia}})
		// setup messages (and delay table for mod function)
		foreach curMode({arglist {coord_modes}})
			foreach curHN ({arglist {input_ids}})	
				// link mod table to buffer
				addmsg /HNinput/HN{curHN}_{curMode}_mod {outputelroot}/{objname} SAVE output
				//echo /HNinput/HN{curHN}_{curMode}_mod
				// link buffer to synchan
				addmsg  /HE{curHE}_{curMode}/synaptic/HN{curHN}_ModDelay  {outputelroot}/{objname} SAVE output
				//echo /HE{curHE}_{curMode}/synaptic/HN{curHN}_ModDelay 
				// link spikes to synchan 
				addmsg /HNinput/HN{curHN}_{curMode}_spikes/spike {outputelroot}/{objname} SAVE state
				//echo /HNinput/HN{curHN}_{curMode}_spikes/spike 
				addmsg /HE{curHE}_{curMode}/synaptic/SynS{curHN} {outputelroot}/{objname} SAVE Gk
				//echo /HE{curHE}_{curMode}/synaptic/SynS{curHN} 
			end
		end
	end
end


//	Function debugK_Ca loops over each channel or Caconc element in each compartment and
//	sets up a message to save it to a file if the element is associated with calcium dynamics
//
function debugK_Ca( coord_modes, HE_ganglia, compartments )
	str coord_modes, HE_ganglia, compartments
	str curHE, curComp, curMode, outobj
	str header
	str headtmp = ""
	
	foreach curHE({arglist {HE_ganglia}})
		header = "Time "
		outobj = {"HE"@{curHE}@"_K_Ca_currents.out"}
		setupOutputFile {"HE"@{curHE}@"_K_Ca_currents.txt"} {outobj}
		outobj = {{outputelroot}@"/"@{outobj}}
		foreach curMode({arglist {coord_modes}})
			foreach curComp({arglist {compartments}})
				addmsg /HE{curHE}_{curMode}/{curComp}/Ca_conc 	{outobj} SAVE Ca
				addmsg /HE{curHE}_{curMode}/{curComp}/CaS_ron 	{outobj} SAVE Ik
				addmsg /HE{curHE}_{curMode}/{curComp}/K_Ca 	{outobj} SAVE Z
				addmsg /HE{curHE}_{curMode}/{curComp}/K_Ca 	{outobj} SAVE X
				addmsg /HE{curHE}_{curMode}/{curComp}/K_Ca 	{outobj} SAVE Ik
				
				headtmp = {"/HE"@{curHE}@"_"@{curMode}@"/"@{curComp}@"/Ca_conc"}
				header =  {header @ " " @ {headtmp}}
				headtmp = {"/HE"@{curHE}@"_"@{curMode}@"/"@{curComp}@"/CaS_ron"}
				header =  {header @ " " @ {headtmp}}
				headtmp = {"/HE"@{curHE}@"_"@{curMode}@"/"@{curComp}@"/K_Ca_Z"}
				header =  {header @ " " @ {headtmp}}
				headtmp = {"/HE"@{curHE}@"_"@{curMode}@"/"@{curComp}@"/K_Ca_X"}
				header =  {header @ " " @ {headtmp}}
				headtmp = {"/HE"@{curHE}@"_"@{curMode}@"/"@{curComp}@"/K_Ca_ik"}
				header =  {header @ " " @ {headtmp}}
			end
   		end
   		// write header
   		headtmp = {{tmpdir @ outputfileroot}@"HE"@{curHE}@"_K_Ca_Header.txt"}
   		openfile  {headtmp} w
		writefile {headtmp} {header}
		closefile {headtmp}
    end
end


//	Function saveCurrents loops over each channel (element) in each compartment and
//	sets up a message to save it to a file
//	savewhich indicates which subset of currents is saved:
//	0: save all (active membrane currents and active synaptic currents (synS & synE))
//	1: save active membrane currents only
//	2: save active synaptic currents only 
//
function saveCurrents(verbose, savewhich, HE_ganglia, coord_modes)
	int verbose, savewhich
//	str Cells = "/HE_sync/ /HE_peri/"  // hardcoded base element path for now, can easily parametrize later 
	str cell, curMode, compartment, channel, savedChannel, curHE
	int savechannel // boolean only used for the two synapse currents
	str condheader, currheader, currentout, conductanceout
	
	foreach curHE({arglist {HE_ganglia}})
		condheader = "Time "
		currheader = "Time "
		
		currentout = {"HE"@{curHE}@"_AllCurrents.out"}
		conductanceout = {"HE"@{curHE}@"_AllConductances.out"}
		echo {currentout}
		echo " ---- " {verbose}
		echo {conductanceout}
		
		setupOutputFile "HE"{curHE}"_AllConductances.txt" {conductanceout}
		setupOutputFile "HE"{curHE}"_AllCurrents.txt" {currentout}

		// loop over each mode, compartment in each cell, tabchannel in each compartment, and save if gbar != 0
		foreach curMode({arglist {coord_modes}})
			cell = {"/HE"@{curHE}@"_"@{curMode}@"/"}
			if(2==verbose)
				echo looping over compartments in {cell}
			end
			foreach compartment({el {cell}#})
				if(2==verbose)
					echo "  " looping over channels in compartment {compartment} 
				end	    	
				foreach channel({el {compartment}/#})
					if(2==verbose)
						echo "      " checking if {channel} is a tabchannel with Gbar != 0 and saving its output if it is
					end 
					
					if(savewhich==1 || savewhich==0) // save active membrane currents
		   				if(1=={isa tabchannel {channel}}) //(note: no shortcircuit logic, hence split if)
	   						if(0 != {getfield {channel} Gbar}) // if this channel has no conductance, don't bother saving it   
								if(1<=verbose)
									echo "        +" Saving {channel} Ik and Gk
								end 
	   							currheader =  {currheader @ channel @ " "}
	   							condheader =  {condheader @ channel @ " "}
								addmsg {channel} 	{outputelroot}/{currentout} SAVE Ik					
								addmsg {channel} 	{outputelroot}/{conductanceout} SAVE Gk
							end   
						end	
					end
					if(savewhich==2 || savewhich==0) // save synaptic currents (synE and synS)
						savechannel = 0
		   				if(1=={isa synchan {channel}}) 
	   						if(0 != {getfield {channel} gmax}) // if this channel has no conductance, don't bother saving it   
	   							savechannel = 1;
	   							if(1<=verbose)
									echo "        +" Saving {channel} Ik and Gk
								end 
	   							currheader =  {currheader @ channel @ " "}
	   							condheader =  {condheader @ channel @ " "}
								addmsg {channel} 	{outputelroot}/{currentout} SAVE Ik				
								addmsg {channel} 	{outputelroot}/{conductanceout} SAVE Gk				
	   						end
	   					end
						if(1=={isa SynE_object {channel}})
	   						if(0 != {getfield {channel} Gbar}) // if this channel has no conductance, don't bother saving it   
	   							if(1<=verbose)
									echo "        +" Saving {channel} Ik
								end 
	   							currheader =  {currheader @ channel @ " "}
								addmsg {channel} 	{outputelroot}/{currentout} SAVE Ik					
	   						end
	   					end
					end    										
				end	
			end
			
			// in Hines-solved model, synE is a separate object 
			///HE{currentHE}_peri_SynE/SynE
			if(savewhich==2 || savewhich==0) // save synaptic currents (synE and synS)
				echo "        -- checking for separate SynE object (for use with Hines-solved model)"
				channel={"/HE"@{curHE}@"_"@{curMode}@"_SynE/SynE"}
				savechannel = 0
				if(1=={isa SynE_object {channel}})
					if(0 != {getfield {channel} Gbar}) // if this channel has no conductance, don't bother saving it   
						if(1<=verbose)
							echo "        +" Saving {channel} Ik
						end 
						currheader =  {currheader @ channel @ " "}
						addmsg {channel} 	{outputelroot}/{currentout} SAVE Ik					
					end
				end
			end    	
					
		end 
			
		
		openfile {tmpdir @ outputfileroot}"HE"{curHE}"_AllCondHeader.txt" w
		writefile {tmpdir @ outputfileroot}"HE"{curHE}"_AllCondHeader.txt" {condheader}
		closefile {tmpdir @ outputfileroot}"HE"{curHE}"_AllCondHeader.txt"
		
		openfile {tmpdir @ outputfileroot}"HE"{curHE}"_AllCurrHeader.txt" w
		writefile {tmpdir @ outputfileroot}"HE"{curHE}"_AllCurrHeader.txt" {currheader}
		closefile {tmpdir @ outputfileroot}"HE"{curHE}"_AllCurrHeader.txt"
	end
end


function saveAllCurrents(verbose, HE_ganglia, coord_modes)
	int verbose
	echo "Saving all currents & conductances"
	str HE_ganglia, coord_modes
	saveCurrents {verbose} 0 {HE_ganglia} {coord_modes}
end
function saveMembraneCurrents(verbose, HE_ganglia, coord_modes)
	int verbose
	str HE_ganglia, coord_modes
	saveCurrents {verbose} 1 {HE_ganglia} {coord_modes}
end
function saveSynapseCurrents(verbose, HE_ganglia, coord_modes)
	int verbose
	str HE_ganglia, coord_modes
	saveCurrents {verbose} 2 {HE_ganglia} {coord_modes}
end

