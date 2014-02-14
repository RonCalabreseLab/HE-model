// Parameterized version of HE model. Replaces the G/P file formalism of Damon. 
// Sets parameters and calls simhe.g

//cd /var/tmp/dlamb/evolution

str HEganglia = "8 12"
str inputdir = "./input" // could be subjected to change with params
str outputfileroot = ""
str pfile = "simhe.p" // load generic P file and then overwrite parameters
// TODO: make sure to calculate Ca_conc = (6.5e-8 - 4e-8 * this->neurite_CaS)

// this must change with input parameter?
include ./input/synaptic_wts_new.g
float syne_gbar = 1.4e-09

// For reading parameters from the environment variable
include readParameters

//load variable parameter values from environment variable
str parrow = {read_env_params}
echo "Parameter row: " {parrow}

// assign parameters to Genesis variables 

// read Genesis variable names and assign all parameters
include assignParameters

include simge.g
