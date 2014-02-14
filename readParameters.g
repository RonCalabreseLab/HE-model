// function to read variable parameter values from environment variable
function read_env_params
  str parrow = {getenv GENESIS_PAR_ROW}

  if ({parrow} == "")
    echo "*********************************************************************"
    echo "Error: This script needs to read the parameters from the environment "
    echo "        variable GENESIS_PAR_ROW. Set the variable prior to running"
    echo "        the script. Aborting simulation."
    echo "*********************************************************************"
    quit
  end

  return {parrow}
end

// from the parameter string (parrow), return parameter number (num)
function get_param (parrow, num)
  return {getarg {arglist {parrow}} -arg {num}}
end