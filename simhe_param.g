// TODO: merge this into simhe.g
// Parameterized version of HE model. Replaces the G/P file formalism of Damon. 

// Sets parameters and calls simhe.g
float PI = 3.14159
float syne_gbar
str sgetaskid = "" // {getenv SGE_TASK_ID}

str HEganglia = "8 12"

str outputfileroot = ""
str pfile = "simhe.p" // load generic P file and then overwrite parameters

// TODO: include rest of simhe.g
include simhe.g
