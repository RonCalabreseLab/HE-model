// TODO: put list of params expected

// Name the simulations (no _ allowed)
str simname = "simhe-6inputs"

// Model directory relative to current simulation location
str relmodeldir = "../../model/"

// Add common model files location
setenv SIMPATH {getenv SIMPATH} {relmodeldir}

// For reading parameters from the environment variable
include readParameters

//load variable parameter values from environment variable
//str parrow = {read_env_params}
read_env_params
echo "Parameter row: " {parrow}

// list of input directories (numbered 1-6)
str inputdirs = "5_19A 5_19B 5_20B 5_22B 5_26A 5_27B"

// select one dir based on parameter value
int inputdirnum = { get_param 14 }
str inputdirname = {getarg {arglist {inputdirs}} -arg {inputdirnum}}
echo "Input dir: " { inputdirname }

// relative location
str inputdir = { "../../common/input-patterns/" @{ inputdirname } }

// put the inputdir on SIMPATH to load weight functions from there
setenv SIMPATH {getenv SIMPATH} {inputdir}
include synaptic_wts_new.g

// synaptic weight
float syne_gbar = { {get_param 9 } / 50 } * 10e-9

// get this from trial num (used to be {getenv SGE_TASK_ID})
str trial = { get_param 15 }
str sgetaskid = { trial }

echo "Trial #" {trial}

// for overwriting custom model params
include assignParams

// include the model
include simhe.g

