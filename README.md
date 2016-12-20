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
  `param_file/` folder into your simrc file.

### Running the model

To start the simulation, go to one of the folders under `run/` and run
`simhe_*.g` with the Leech Genesis (lgenesis). Make sure the parameter
values are set in the environment variables before this. The
`sim_genesis.sh` of the `param-search-neuro` package can help. Here's an
example in the Bash shell:

```bash
$ export GENESIS=lgenesis
$ export GENESIS_PAR_ROW="1 2 3"
$ export GENESIS_PAR_ROW="par1 par2 par3"
$ sim_genesis.sh simhe_ind_synscale.g
```

### Available parameter variation configurations under `run/`

[synscale](run/synscale) 
  Adds a global synaptic scaling parameter (sigma) that scales both HE8 and HE12.