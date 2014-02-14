// this file is custom for parameter search and contains its specific parameters

// For reading parameters from the environment variable
include readParameters

//load variable parameter values from environment variable
str parrow = {read_env_params}
echo "Parameter row: " {parrow}

