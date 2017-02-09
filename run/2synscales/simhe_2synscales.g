// TODO: put list of params expected

// Name the simulations (no _ allowed)
str simname = "simhe-2synscales"

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
int inputdirnum = { get_param_byname "inputdir" } 
str inputdirname = {getarg {arglist {inputdirs}} -arg {inputdirnum}}
echo "Input dir: " { inputdirname }

// relative location
str inputdir = { "../../common/input-patterns/" @{ inputdirname } }

// put the inputdir on SIMPATH to load weight functions from there
setenv SIMPATH {getenv SIMPATH} {inputdir}
include synaptic_wts_new.g

// use the input dir on output path as well
str outputfileroot = "input" @ {inputdirname} @ "/data-" @ {simname} @ \
	"-setCId" @ { get_param_byname "SetCId" } @ \
  "-batch" @ { get_param_byname "batch" } @ "/"
str tmpdir = { getenv HOME } @ "/simhe/scratch/"

// SynS multipliers, sigmas, for each HE
float synS_mult_HE8 = {get_param_byname "synS_mult_HE8" }
float synS_mult_HE12 = {get_param_byname "synS_mult_HE12" }

// apply multiplier to values set by synaptic_wts_new.g
synwt8 = synwt8 * synS_mult_HE8
synwt12 = synwt12 * synS_mult_HE12

echo "sigma_HE8 = " {synwt8}
echo "sigma_HE12 = " {synwt12}

// get this from trial num (used to be {getenv SGE_TASK_ID})
str trial = { get_param_byname "trial" }
str sgetaskid = { trial }

echo "Trial #" {trial}

// for overwriting custom model params
include assignParams

// include the model
include simhe.g

