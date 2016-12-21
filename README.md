## Leech heartbeat system HE motor neuron model from the Calabrese lab

Multicompartmental HE motor neuron model constructed by Lamb
(2013). Modified by Cengiz Gunay <cengique@users.sf.net> to enable
parameter search in different combinations of free parameters and
input-output patterns.

The simulation is set up as a network of two bilateral electrically
coupled HE neurons receiving inputs from HN motor interneurons. This
model is configured to simulate HE neurons in segments 8 and 12 that
receive four inputs from HN neurons 3, 4, 6, and 7.

### Requirements:

- "Leech" version of the Genesis simulator (lgenesis). You can find more
  information about it on the [Calabrese lab web
  page](http://www.biology.emory.edu/research/Calabrese/software.html).

- Parameter names and values are read into Genesis through environment
  variables using the [param-search-neuro](https://github.com/cengique/param-search-neuro)
  package. After downloading it, you would need to add the
  `param_file/` folder into your simrc file. Here's an example:

```bash
setenv GENPATH /usr/local/genesis/lgenesis-noX_Hines/
setenv SIMPATH . {getenv GENPATH}			\
		 {getenv GENPATH}/startup		\
		 {getenv GENPATH}/neurokit    		\
		 {getenv GENPATH}/neurokit/prototypes 	\
		 {getenv HOME}/work/brute_scripts/param_file
```

### Running the model

To start the simulation, go to one of the folders under `run/` and run
`simhe_*.g` with the Leech Genesis (lgenesis). Make sure the parameter
values are set in the environment variables before this. The
`sim_genesis.sh` of the `param-search-neuro` package under
`sge_scripts/` will keep track of the simulation time. Here's an
example in the Bash shell:

```bash
$ export GENESIS=lgenesis
$ export GENESIS_PAR_ROW="1 2 3"
$ export GENESIS_PAR_ROW="par1 par2 par3"
$ sim_genesis.sh simhe_ind_synscale.g
```

(You can replace `sim_genesis.sh` with `lgenesis`.)

### Available parameter variation configurations under `run/`

In order of increasing complexity:

[inputpatters](run/inputpatterns) In addition to the 13 maximal ion
  channel and electrical coupling conductance parameters of Lamb
  (2013), it adds a `inputdir` parameter that can take values 1-6 to
  point to one of the input-output datasets in the
  [input-patterns](https://bitbucket.org/calabreselab/input-patterns)
  repository. See the README in the [inputpatters](run/inputpatterns)
  folder for more information.

[synscale](run/synscale) Starts from the `inputpatters` configuration
  and adds a global synaptic scaling parameter (sigma) `synS_mult`
  that scales both HE8 and HE12 synaptic weights.

[2synscales](run/2synscales) Replaces the single sigma with two
  parameters, one for each HE neuron, `synS_mult_HE8` and
  `synS_mult_HE12`.

[ind_synscale_1model](run/ind_synscale_1model) Instead of global
  synaptic multipliers, introduces individual multipliers for each of
  the inputs to the respective HE neurons (e.g.,
  `synS_mult_HE8_HN3`). It also adds a new parameter `SetCId`, which
  points to the index of the original model in the set C found by Lamb
  (2013). This parameter is used for informational reasons - the
  actual parameter values are used for conductances.

[ind_synscale](run/ind_synscale) Still using the individual synaptic
  multipliers like the last case, but allows changing ion channel
  conductance parameters of the HE8 and HE12 neurons independently.