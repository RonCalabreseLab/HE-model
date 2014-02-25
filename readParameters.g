// Function to read variable parameter values from environment variable.
// Assume there is only one
str parrow
function read_env_params
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

// convert from integer param value to specific gmax value by
// dividing to gmax in path (gmax's from P file are the maximal values)
function get_gmax_spec (path, param_num)
  return { {getparam {param_num} } / { getfield {path} gmax} }
end

// Takes specific gmax value and applies to channel scaled by compartment area
function set_gmax (path, chan, value)
  setfield {path} gmax { { value } * { calc_surf { path } } }
end

// Set gmax value normalized by P file value and multiplied by compartment area
function set_gmax_par (path, chan, param_num)
  set_gmax {path} {chan} {get_gmax_spec {path}/{chan} {param_num}}
end

// Set gmax for all neurites from param
function set_neurites_par (path, chan, param_num)
  set_gmax_par {path}/neurite1/ { chan } { param_num }
  set_gmax_par {path}/neurite2/ { chan } { param_num }
  set_gmax_par {path}/neurite3/ { chan } { param_num }
end

// Set gmax for all neurites from value
function set_neurites_val (path, chan, value)
  set_gmax {path}/neurite1/ { chan } { value }
  set_gmax {path}/neurite2/ { chan } { value }
  set_gmax {path}/neurite3/ { chan } { value }
end
