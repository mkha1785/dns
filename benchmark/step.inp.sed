3            ! input file type
ns_uvw       ! equations
iso12        ! initial condition:  KH-blob, KH-anal, iso12
0            ! init condition subtype
none         ! forcing:  none, iso12
kediff       ! viscosity type  (value, smallest, kediff, Re)
1000.0        ! viscosity coefficient.  (300)
0.0           ! alpha (for NS-alpha model).  alpha>1 is in units of delx
.0            ! smagorinsky
0            ! compute_structure functions
fft-sphere   ! derivative method  (fft, fft-dealias, fft-sphere, 4th)
periodic     ! x bc  (periodic, no-slip)
periodic     ! y bc
periodic     ! z bc
-NDELT        ! time to run
1.50         ! adv cfl  (0 = disabled, use min_dt)
.25           ! vis cfl  (0 = disabled, use min_dt)
0             ! min_dt  
1             ! max_dt 
0.0          ! restart_dt  (0 = restart output disabled)
0          ! diag_dt   
-10          ! screen_dt
0           ! output_dt  (0 = output disabled, except for custom output times)
0           ! n_output_custom  number of custom output times  
0.00         ! custom output times, one per line


