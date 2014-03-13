// Function to read variable parameter values from environment variable.

// constants
float PI = 3.14159265359

// Assume there is only one
str parrow
function read_env_params
  echo "*********************************************************************"
  echo "Reading environment variable GENESIS_PAR_ROW"
  parrow = {getenv GENESIS_PAR_ROW}

  if ({parrow} == "")
    echo "*********************************************************************"
    echo "Error: This script needs to read the parameters from the environment "
    echo "        variable GENESIS_PAR_ROW. Set the variable prior to running"
    echo "        the script. Aborting simulation."
    echo "*********************************************************************"
    quit
  end
end

// From the parameter string (parrow), return parameter number (num)
function get_param (num)
  return {getarg {arglist {parrow}} -arg {num}}
end

// returns surface of compartment at path
function calc_surf (path)
  return { PI * { getfield {path} dia }  * { getfield {path} len} }
end

// returns volume of compartment at path
function calc_vol (path)
  return { PI * {{ getfield {path} dia } ** 2}  * { getfield {path} len} / 4 }
end

// finds the target field in element
// if tabchannel, then Gbar
// if Ca_concen, then B, etc.
function find_def_field (path)
  str fieldname
  // Is it a tabchannel?
  if ( {exists {path} Gbar} )
    fieldname = "Gbar"
  elif ( {exists {path} B} ) 
    // or Ca_concen?
    fieldname = "B"
  end
  return {fieldname}
end

// return proper readcell parameter (Gbar, B, etc) value from element at path
function get_gmax (path)
  return { getfield {path} { find_def_field {path}}}
end

// convert from integer param value to specific gmax value by
// dividing by 50 and then scale by gmax in path (gmax's from P file are the maximal values)
// (already scaled by compartment area)
function get_gmax_spec (path, param_num)
  return { { {get_param {param_num} } / 50 } * { get_gmax {path} } }
end

// Takes specific gmax value and applies to channel 
// No need to scale by compartment area because P file value is already scaled
// removed: { calc_surf { path } }
function set_gmax (path, chan, value)
  setfield {path}/{chan} { find_def_field {path}/{chan} } { { value } }
end

// Set gmax value from integer parameter
function set_gmax_par (path, chan, param_num)
  set_gmax {path} {chan} {get_gmax_spec {path}/{chan} {param_num}}
end

// Set gmax for all neurites from param
function set_neurites_par (path, chan, param_num)
  set_gmax_par {path}/neurite1 { chan } { param_num }
  set_gmax_par {path}/neurite2 { chan } { param_num }
  set_gmax_par {path}/neurite3 { chan } { param_num }
end

// Set gmax for all neurites from value
// (obsolete)
function set_neurites_val (path, chan, value)
  set_gmax {path}/neurite1 { chan } { value }
  set_gmax {path}/neurite2 { chan } { value }
  set_gmax {path}/neurite3 { chan } { value }
end
