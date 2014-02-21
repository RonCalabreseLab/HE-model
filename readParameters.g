// Function to read variable parameter values from environment variable.
// Assume there is only one
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

// convert from integer param value to specific gmax value
function get_gmax_spec (path, param_num)
  return { {getparam {param_num} } / { getfield {path} gmax} }
end

// returns compartment surface
function calc_surf (path)
  return { PI * { getfield {path} dia }  * { getfield {path} len} }
end

// Set gmax value normalized by P file value and multiplied by compartment area
function set_gmax_par (path, chan, param_num)
  setfield {path} gmax { {get_gmax_spec {path} {param_num}} * \
      { calc_surf { path } } }
end

// Set gmax for all neurites
function set_neurites_par (chan, param_num)
  set_gmax_par /neurite1/ { chan } { param_num }
  set_gmax_par /neurite2/ { chan } { param_num }
  set_gmax_par /neurite3/ { chan } { param_num }
end
