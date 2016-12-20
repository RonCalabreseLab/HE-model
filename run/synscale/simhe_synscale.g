// TODO: put list of params expected

// Name the simulations (no _ allowed)
str simname = "simhe-synscale"
str outputfileroot = "data-" @ {simname} @ "/"

// Add common model files location
setenv SIMPATH {getenv SIMPATH} ../../common/modelHE/

// For reading parameters from the environment variable
include readParameters

//load variable parameter values from environment variable
//str parrow = {read_env_params}
read_env_params
echo "Parameter row: " {parrow}

// list of input directories (numbered 1-6)
str inputdirs = "5_19A 5_19B 5_20B 5_22B 5_26A 5_27B"

// select one dir based on parameter value
int inputdirnum = { get_param_byname "inputdir" } 
str inputdirname = {getarg {arglist {inputdirs}} -arg {inputdirnum}}
echo "Input dir: " { inputdirname }

// relative location
str inputdir = { "../../common/input-patterns/" @{ inputdirname } }

// put the inputdir on SIMPATH to load weight functions from there
setenv SIMPATH {getenv SIMPATH} {inputdir}
include synaptic_wts_new.g

// SynS multiplier, sigma
float synS_mult = {get_param_byname "synS_mult" }

// apply multiplier to values set by synaptic_wts_new.g
synwt8 = synwt8 * synS_mult
synwt12 = synwt12 * synS_mult

// get this from trial num (used to be {getenv SGE_TASK_ID})
str trial = { get_param_byname "trial" }
str sgetaskid = { trial }

echo "Trial #" {trial}

// for overwriting custom model params
include assignParams

// include the model
include simhe.g

