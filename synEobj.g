// creates generic SynE object
function createSynE
    str chanpath = "SynE"
    create SynE_object  {chanpath}
    setfield  {chanpath}  \
	         Gbar            6e-9       \
             rectify         0     \ // 0 no rectify, 1 pass pos. curr., 2 pass neg. curr.
             TauPre  	     0.02      \
             TauPost         0.02
             // Fc = 1/(2*pi*tau), so where tau = 0.02, Fc = 7.9577Hz
end

