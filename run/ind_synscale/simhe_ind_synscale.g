// TODO: put list of params expected

// Name the simulations (no _ allowed)
str simname = "simhe-modelpair-allsyns"

// Add common model files location
setenv SIMPATH {getenv SIMPATH} ../../common/modelHE/

// For reading parameters from the environment variable
// (To load it, download https://github.com/cengique/param-search-neuro
// and add the param_file/ into your simrc file)
include readParameters

//load variable parameter values from environment variable
read_env_params

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

// synaptic weights as Genesis globals
/*addglobal float "syne_gbar_HE8"
setglobal "syne_gbar_HE8" {{ {get_param_byname "synE_HE8" } / 50 } * 10e-9}
addglobal float "syne_gbar_HE12"
setglobal "syne_gbar_HE12" {{ {get_param_byname "synE_HE12" } / 50 } * 10e-9}
*/

// get this from trial num (used to be {getenv SGE_TASK_ID})
str trial = { get_param_byname "trial" }
str sgetaskid = { trial }

echo "Trial #" {trial}

// for overwriting custom model params
include assignParams

// include the model
include simhe.g

