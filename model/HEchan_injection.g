// genesis HEchan.g
// ****Warning this file although similar to HNchan.g
// has been modified by Paul Garcia and is not the same.
// filltable.g and constants.g were not modified and are
// the same in both HN and HE simulations.
// do not use this HEchan.g file in an HN simulation
// Last modified:   August 22, 2003

// Modified by Damon Lamb 20 May 2009 to add Ca_conc and K_Ca 



/*
** This file depends on functions and constants defined in defaults.g
*/

include filltable.g
include constants.g
// based on the file HNchan.g used in Adam and Andrew's models






// alpha version of K_Ca ---------------------------------------------------------------------------------
function make_K_Ca_inj
    str chanpath = "K_Ca_inj"    

echo " WARNING - K_Ca_inj still needs a link to a calcium shell. Currently, it links to the existing calcium shell driven by the CaS_ron CaS channel."
    if ({exists {chanpath}})
        return
    end
    create tabchannel {chanpath}
    setfield  {chanpath}  \
	 		Ek	{EK1}	  \
	 		Gbar	{100e-9}  \  
	 		Ik	0	  \
	 		Gk	0	  \
		 	Xpower 1 \
		 	Ypower 0 \
		 	Zpower 1  
// note! concentrations in mM
	float 	camin = 60e-6 //   61e-6 //Genesis values are in mM, so nM is e-6
	// e-4 before, wrong calc I think.
	float 	camax = 15e-5  
    int     xdivs = 2999
	// Voltage gate    
    call    {chanpath}	  TABCREATE X 100 -0.100 0.050
	// calcium gate
    call    {chanpath} TABCREATE Z {xdivs} {camin} {camax}

    settab2const {chanpath}  Z_A  0  {xdivs}  .3    // -0 thru 100 => .04.  set to constant time_constant for now  // change 0.4 to 0.3

    int i
    float x,dx,dy,y
    dx = ({camax} - {camin})/{xdivs}
    dy = 1 / ({camax} - {camin})
    x = 0

    for (i = 0 ; i <= {xdivs} ; i = i + 1)
	    y = {dy} * x 
	    // y = 7e3 * {x} - 1
	    /*
	    if ({y}<0)
	    	y = 0
	    end
	    if ({y}>1)
	    	y = 1
	    end
	    */   
        setfield {chanpath} Z_B->table[{i}] {y}	// m_inf
            
        x = x + dx
    end

//FillTableTau {chanpath} X_A .001 .011 150 {k1shft1} -.006
	settab2const {chanpath}  X_A  0  100  .2
    FillTableInf {chanpath}  X_B  0    1  -80 -0.005 -.01  // shift (6th argument) changed from 0 to -10mV (-0.005)
	
	call {chanpath} TABFILL X 3000 0
		
// debug
//tab2file ./Debug/K_Ca_XA.txt {chanpath} 	 X_A -mode xy -overwrite
//tab2file ./Debug/K_Ca_XB.txt {chanpath} 	 X_B -mode xy -overwrite		
//tab2file ./Debug/K_Ca_A.txt {chanpath} 	 Z_A -mode xy -overwrite
//tab2file ./Debug/K_Ca_B.txt {chanpath} 	 Z_B -mode xy -overwrite

	setfield {chanpath} X_A->calc_mode 0 X_B->calc_mode 0
	tweaktau {chanpath} X
	setfield {chanpath} Z_A->calc_mode 0 Z_B->calc_mode 0 /* Setting the calc_mode to NO_INTERP for speed */
	tweaktau {chanpath} Z /* tweaking the tables for the tabchan calculation */

 	addfield {chanpath} addmsg1
    setfield {chanpath} addmsg1        "../Ca_conc . CONCEN Ca"
//---------------------------------------------

//echo "Created K_Ca object"

end





/***********************************************************************
			    Na-Current (HN3,4 cells)
 ***********************************************************************/

function make_Na_ron_inj	// Na-current
    str chanpath = "Na_ron_inj"
    if ({exists {chanpath}})
	return 
    end

    create  tabchannel	{chanpath}
    setfield  {chanpath}  \
	 Ek	{ENa}	  \
	 Gbar	{200e-9}  \
	 Ik	0	  \
	 Gk	0	  \
		 Xpower 3 \
		 Ypower 1 \
		 Zpower 0  

    call    {chanpath}	  TABCREATE X 100 -0.100 0.050

    settab2const {chanpath}  X_A  0  100  0.0001    // -0.1 thru 0.05=>0.
       //				-150		-.023
    FillTableInf {chanpath}  X_B  0   1 -150 {nashft_X} -.024
		/* Setting the calc_mode to NO_INTERP for speed */
		setfield {chanpath} X_A->calc_mode 0 X_B->calc_mode 0

		/* tweaking the tables for the tabchan calculation */
		tweaktau {chanpath} X

		/* Filling the tables using B-SPLINE interpolation */
		call {chanpath} TABFILL X 3000 0

//    setfield {chanpath} instant {INSTANTX}



 call	 {chanpath}    TABCREATE Y 100 -0.100 0.050
 //				.004 .006 500		 -.023
// echo FillTableTau_Na
 FillTableTau_Na {chanpath} Y_A .004 .006 500 {nashft_Y} -.023
//					 500		-.025  
 FillTableInf	{chanpath} Y_B 0     1	 500 {nashft_Y} -.025	

		/* Setting the calc_mode to NO_INTERP for speed */
		setfield {chanpath} Y_A->calc_mode 0 Y_B->calc_mode 0

		/* tweaking the tables for the tabchan calculation */
		tweaktau {chanpath} Y

		/* Filling the tables using B-SPLINE interpolation */
		call {chanpath} TABFILL Y 3000 0
end

//
function make_K1_ron_inj
    str chanpath = "K1_ron_inj"
    if ({exists {chanpath}})
	return
    end

    create  tabchannel	{chanpath}
    setfield  {chanpath}  \
	 Ek	{EK1}	  \
	 Gbar	{100e-9}  \
	 Ik	0	  \
	 Gk	0	  \
		 Xpower 2 \
		 Ypower 1 \
		 Zpower 0  

    call    {chanpath}	  TABCREATE X 100 -0.100 0.050
//    echo
//    echo K1_ronX
    FillTableTau {chanpath} X_A .001 .011 150 {k1shft1} -.006
 //					 -143
    FillTableInf {chanpath} X_B 0     1  -143 {k1shft} -.011
		/* Setting the calc_mode to NO_INTERP for speed */
		setfield {chanpath} X_A->calc_mode 0 X_B->calc_mode 0

		/* tweaking the tables for the tabchan calculation */
		tweaktau {chanpath} X

		/* Filling the tables using B-SPLINE interpolation */
		call {chanpath} TABFILL X 3000 0


 call	 {chanpath}    TABCREATE Y 100 -0.100 0.050
// echo
// echo K1_ronY
 FillTableTau {chanpath} Y_A .500 .200 -143 {k1shft} -.003
 FillTableInf {chanpath} Y_B 0	  1	111 {k1shft} -.018

		/* Setting the calc_mode to NO_INTERP for speed */
		setfield {chanpath} Y_A->calc_mode 0 Y_B->calc_mode 0

		/* tweaking the tables for the tabchan calculation */
		tweaktau {chanpath} Y

		/* Filling the tables using B-SPLINE interpolation */
		call {chanpath} TABFILL Y 3000 0
end


function make_K2_ron_inj
    str chanpath = "K2_ron_inj"
    if ({exists {chanpath}})
	return
    end

    create  tabchannel	{chanpath}
    setfield  {chanpath}  \
	 Ek	{EK2}	  \
	 Gbar	{80e-9}   \
	 Ik	0	  \
	 Gk	0	  \
		 Xpower 2 \
		 Ypower 0 \
		 Zpower 0

    call    {chanpath}	  TABCREATE X 100 -0.100 0.050

//    echo
//    echo K2_ronX

    FillTableTau {chanpath} X_A .057 .043 200 {k2shft} -.025
    FillTableInf {chanpath} X_B 0    1	  -83 {k2shft} -.010
		/* Setting the calc_mode to NO_INTERP for speed */
		setfield {chanpath} X_A->calc_mode 0 X_B->calc_mode 0

		/* tweaking the tables for the tabchan calculation */
		tweaktau {chanpath} X

		/* Filling the tables using B-SPLINE interpolation */
		call {chanpath} TABFILL X 3000 0

end

function make_K2Inact_inj
    str chanpath = "K2Inact_inj"
    if ({exists {chanpath}})
	return
    end

    create  tabchannel	{chanpath}
    setfield  {chanpath}  \
	 Ek	{EK2}	  \
	 Gbar	{GK2Inact}   \
	 Ik	0	  \
	 Gk	0	  \
		 Xpower 2 \
		 Ypower 1 \
		 Zpower 0

    call    {chanpath}	  TABCREATE X 100 -0.100 0.050

//    echo
//    echo K2Inact_ronX

    FillTableTau {chanpath} X_A .057 .043 200 0 -.035
    FillTableInf {chanpath} X_B 0    1	  -200 0 -.050
		/* Setting the calc_mode to NO_INTERP for speed */
		setfield {chanpath} X_A->calc_mode 0 X_B->calc_mode 0

		/* tweaking the tables for the tabchan calculation */
		tweaktau {chanpath} X

		/* Filling the tables using B-SPLINE interpolation */
		call {chanpath} TABFILL X 3000 0

    call    {chanpath}	  TABCREATE Y 100 -0.100 0.050

//    echo
//    echo K2Inact_ronY

//    FillTableTau {chanpath} Y_A .026 4.974 -500 0 -.045
    FillTableTau {chanpath} Y_A .026 {TauK2Inact} -500 0 -.045
    FillTableInf {chanpath} Y_B 0     1     500 0 -.050

		/* Setting the calc_mode to NO_INTERP for speed */
		setfield {chanpath} Y_A->calc_mode 0 Y_B->calc_mode 0

		/* tweaking the tables for the tabchan calculation */
		tweaktau {chanpath} Y

		/* Filling the tables using B-SPLINE interpolation */
		call {chanpath} TABFILL Y 3000 0
end

// make A channel
function make_A_inj
    str chanpath = "A_inj"
    if ({exists {chanpath}})
	return
    end

    create  tabchannel	{chanpath}
    setfield  {chanpath}  \
	 Ek	{EA}	  \
	 Gbar	{200e-9}   \
	 Ik	0	  \
	 Gk	0	  \
		 Xpower 2 \
		 Ypower 1 \
		 Zpower 0  

    call    {chanpath}	  TABCREATE X 100 -0.100 0.050
    //					  0.0028
    //settab2const {chanpath}  X_A  0  100  0.010  //-0.1 thru 0.05=>0.
    
//    echo
//    echo A_ronX
    FillTableTau {chanpath} X_A .005 .011 200 {ashft} -.020
    FillTableInf {chanpath}  X_B  0   1 -130 {ashft} -.034
		/* Setting the calc_mode to NO_INTERP for speed */
		setfield {chanpath} X_A->calc_mode 0 X_B->calc_mode 0

		/* tweaking the tables for the tabchan calculation */
		tweaktau {chanpath} X

		/* Filling the tables using B-SPLINE interpolation */
		call {chanpath} TABFILL X 3000 0


    call    {chanpath}	  TABCREATE Y 100 -0.100 0.050
//    echo
//    echo A_ronY
    FillTableTau {chanpath} Y_A .026 .0085 -300 {ashft} -.045
    FillTableInf {chanpath} Y_B 0     1     160 {ashft} -.053	

		/* Setting the calc_mode to NO_INTERP for speed */
		setfield {chanpath} Y_A->calc_mode 0 Y_B->calc_mode 0

		/* tweaking the tables for the tabchan calculation */
		tweaktau {chanpath} Y

		/* Filling the tables using B-SPLINE interpolation */
		call {chanpath} TABFILL Y 3000 0
end


function make_h_inj
  
   str chanpath="h_inj"
   if ({exists {chanpath}})
	return
    end 
    
    create  tabchannel	{chanpath}
    setfield  {chanpath}  \
	 Ek	{Eh}	  \
	 Gbar	{7e-9}	  \
	 Ik	0	  \
	 Gk	0	  \
		 Xpower 2 \
		 Ypower 0 \
		 Zpower 0

   call    {chanpath}	 TABCREATE X 100 -0.100 0.050
// add some fields			      
//    echo
//    echo h_ronX
    FillTableTau {chanpath} X_A .700 1.700 -100 0 -.073
    FillTableInf_h {chanpath} X_B 0 1 180 0 -.047

		 setfield {chanpath} X_A->calc_mode 0 X_B->calc_mode 0

		/* tweaking the tables for the tabchan calculation */
		tweaktau {chanpath} X

		/* Filling the tables using B-SPLINE interpolation */
		call {chanpath} TABFILL X 3000 0
end


// make CaF
function make_CaF_inj
    str chanpath = "CaF_inj"
    if ({exists {chanpath}})
	return
    end

    create  tabchannel	{chanpath}
    setfield  {chanpath}  \
	 Ek	{ECaF}	  \
	 Gbar	{16e-9}   \
	 Ik	0	  \
	 Gk	0	  \
		 Xpower 2 \
		 Ypower 1 \
		 Zpower 0

    call    {chanpath}	  TABCREATE X 100 -0.100 0.050

//    echo
//    echo CaF_ronX
    FillTableTau_CaF {chanpath} X_A
    FillTableInf {chanpath} X_B 0 1 -600 {CaFshft} -.0467
		/* Setting the calc_mode to NO_INTERP for speed */
		setfield {chanpath} X_A->calc_mode 0 X_B->calc_mode 0

		/* tweaking the tables for the tabchan calculation */
		tweaktau {chanpath} X

		/* Filling the tables using B-SPLINE interpolation */
		call {chanpath} TABFILL X 3000 0


 call	 {chanpath}    TABCREATE Y 100 -0.100 0.050
			   //.060 .310
// echo
// echo CaF_ronY
 FillTableTau {chanpath} Y_A .060 .310	 270 {CaFshft} -.055
 FillTableInf {chanpath} Y_B 0	   1   350 {CaFshft} -.0555

		/* Setting the calc_mode to NO_INTERP for speed */
		setfield {chanpath} Y_A->calc_mode 0 Y_B->calc_mode 0

		/* tweaking the tables for the tabchan calculation */
		tweaktau {chanpath} Y

		/* Filling the tables using B-SPLINE interpolation */
		call {chanpath} TABFILL Y 3000 0
end


//make CaS
// Cas adjusted for HE cells - inactivation gate slowed down
function make_CaS_inj
    str chanpath = "CaS_inj"
    if ({exists {chanpath}})
	return
    end

    create  tabchannel	{chanpath}
    setfield  {chanpath}  \
	 Ek	{ECaS}	  \
	 Gbar	{3e-9}	  \
	 Ik	0	  \
	 Gk	0	  \
		 Xpower 2 \
		 Ypower 1 \
		 Zpower 0

    call    {chanpath}	  TABCREATE X 100 -0.100 0.050
    FillTableTau {chanpath} X_A .005 .134 {CaSa} {CaSshft1}  -.0487
    FillTableInf {chanpath} X_B  0     1  -420 {CaSshft1} -.0472
		/* Setting the calc_mode to NO_INTERP for speed */
	setfield {chanpath} X_A->calc_mode 0 X_B->calc_mode 0
		/* tweaking the tables for the tabchan calculation */
	tweaktau {chanpath} X
		/* Filling the tables using B-SPLINE interpolation */
	call {chanpath} TABFILL X 3000 0
  // ----
 	call	 {chanpath}    TABCREATE Y 100 -0.100 0.050
 	FillTableTau {chanpath} Y_A .200 8 -250 {CaSshft2} -.043
 	// -------------------------5.250 changed to 8
 	FillTableInf {chanpath} Y_B 0 1  360 {CaSshft2} -.055
		/* Setting the calc_mode to NO_INTERP for speed */
	setfield {chanpath} Y_A->calc_mode 0 Y_B->calc_mode 0
		/* tweaking the tables for the tabchan calculation */
		
//tab2file ./Debug/CaS_XA.txt {chanpath} 	 X_A -mode xy -overwrite
//tab2file ./Debug/CaS_XB.txt {chanpath} 	 X_B -mode xy -overwrite
//tab2file ./Debug/CaS_YA.txt {chanpath} 	 Y_A -mode xy -overwrite
//tab2file ./Debug/CaS_YB.txt {chanpath} 	 Y_B -mode xy -overwrite


	tweaktau {chanpath} Y
		/* Filling the tables using B-SPLINE interpolation */
	call {chanpath} TABFILL Y 3000 0
end


function make_P_inj
    str chanpath = "P_inj"
    if ({exists {chanpath}})
	return
    end

    create  tabchannel	{chanpath}
    setfield  {chanpath}  \
	 Ek	{EP}	  \
	 Gbar	{7e-9}   \   // GP param sometime used		7e-9 default
	 Ik	0	  \
	 Gk	0	  \
		 Xpower 1 \
		 Ypower 0 \
		 Zpower 0
//	 Gbar	{10e-9}   \

    call    {chanpath}	  TABCREATE X 100 -0.100 0.050
			      //.010 .200	-.057
//    echo
//    echo P_ronX
    FillTableTau {chanpath} X_A .010 .200 400 {Pshft} -.057
			  //		 -120 0 -.039
    FillTableInf {chanpath} X_B 0     1  -120 0 -.039
		// Setting the calc_mode to NO_INTERP for speed
		setfield {chanpath} X_A->calc_mode 0 X_B->calc_mode 0

		// tweaking the tables for the tabchan calculation
		tweaktau {chanpath} X

		// Filling the tables using B-SPLINE interpolation
		call {chanpath} TABFILL X 3000 0

end


