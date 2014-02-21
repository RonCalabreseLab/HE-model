// Parameterized version of HE model. Replaces the G/P file formalism of Damon. 

// Sets parameters and calls simhe.g
float PI = 3.14159
float syne_gbar
str sgetaskid = "" // {getenv SGE_TASK_ID}

str HEganglia = "8 12"

str outputfileroot = ""
str pfile = "simhe.p" // load generic P file and then overwrite parameters

/*
// For reading parameters from the environment variable
include readParameters

//load variable parameter values from environment variable
str parrow = {read_env_params}
echo "Parameter row: " {parrow}

// TODO: include part of simhe.g until readcell [no! keep P file, there are multiple cells in the simulation!]

// assign parameters to Genesis variables 
// read Genesis variable names and assign all parameters
include assignParameters
*/

// TODO: include rest of simhe.g
include simhe.g
