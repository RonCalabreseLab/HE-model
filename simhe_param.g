// Parameterized version of HE model. Replaces the G/P file formalism of Damon. 
// $ parameters are overwritten with Perl.
// TODO: create 00_00_00..._inputs.g file from this?

// Sets parameters and calls simhe.g

//cd /var/tmp/dlamb/evolution

str HEganglia = "8 12"
str inputdir = "$INPUTDIR" // could be subjected to change with params
include $INPUTDIR/synaptic_wts_new.g

str outputfileroot = ""
str pfile = "simhe.p" // load generic P file and then overwrite parameters
// TODO: make sure to calculate Ca_conc = (6.5e-8 - 4e-8 * this->neurite_CaS)

// TODO: the following should go in assignParameters?
float syne_gbar = $SYNE_GBAR

// For reading parameters from the environment variable
include readParameters

//load variable parameter values from environment variable
str parrow = {read_env_params}
echo "Parameter row: " {parrow}

// assign parameters to Genesis variables 
// read Genesis variable names and assign all parameters
include assignParameters

include simhe.g
