!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!Copyright 2007.  Los Alamos National Security, LLC. This material was
!produced under U.S. Government contract DE-AC52-06NA25396 for Los
!Alamos National Laboratory (LANL), which is operated by Los Alamos
!National Security, LLC for the U.S. Department of Energy. The
!U.S. Government has rights to use, reproduce, and distribute this
!software.  NEITHER THE GOVERNMENT NOR LOS ALAMOS NATIONAL SECURITY,
!LLC MAKES ANY WARRANTY, EXPRESS OR IMPLIED, OR ASSUMES ANY LIABILITY
!FOR THE USE OF THIS SOFTWARE.  If software is modified to produce
!derivative works, such modified software should be clearly marked, so
!as not to confuse it with the version available from LANL.
!
!Additionally, this program is free software; you can redistribute it
!and/or modify it under the terms of the GNU General Public License as
!published by the Free Software Foundation; either version 2 of the
!License, or (at your option) any later version. Accordingly, this
!program is distributed in the hope that it will be useful, but WITHOUT
!ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
!FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
!for more details.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#include "macros.h"
#if 0
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! our wrapper for ECMWF FFT99 
! 
!
! provides public interfaces:
!   fft_interface_init               call this before using any other routines
!   fft1                             fft along first dimension of 3D array
!   ifft1	                     ifft along first dimension of 3D array
! 
! Routines work on data of the form:  p(n1d,n2d,n3d)
! Size of the grid point data         p(1:n1,1:n2,1:n3)
! Size of fourier coefficients        p(1:n1+2,1:n2+2,1:n3+2)
!

FFT data representation:

sum over m=1..n/2:

   f = fhat(1)  +  2 fhat(2*m+1) cos(m*2pi*x) - 2*fhat(2m+2) sin(m*2pi*x)


     if isign = +1, and m coefficient vectors are supplied
     each containing the sequence:

     a(0),b(0),a(1),b(1),...,a(n/2),b(n/2)  (n+2 values)

     then the result consists of m data vectors each
     containing the corresponding n+2 gridpoint values:

     x(0), x(1), x(2),...,x(n-1),0,0.

     note: the fact that the gridpoint values x(j) are real
     implies that b(0)=b(n/2)=0.  for a call with isign=+1,
     it is not actually necessary to supply these zeros.


In otherwords:

 grid space data:    1 2 3 4 5 6 7 8 * *
 
 fourier space:      0 0 1 1 2 2 3 3 4 4
 rearranged:         0 4 1 1 2 2 3 3 * *


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#endif


module fft_interface
use params
implicit none
integer, parameter ::  num_fftsizes=3

integer :: init=0
type fftdata_d
   CPOINTER,dimension(:),pointer :: trigs
   integer :: ifax(13)
   integer :: size
end type
type(fftdata_d) :: fftdata(num_fftsizes)


private :: fftinit, getindex
contains 




subroutine fft_interface_init()
integer :: i

init=1
do i=1,num_fftsizes
   fftdata(i)%size = 0	
enddo
end subroutine




subroutine fft_get_mcord(mcord,n)
!
!  i=1   0 cosine mode             mcord=0
!  i=2   n/2 cosine mode           mcord=  n/2
!  i=3   1 cosine mode             mcord =  1
!  i=4   1 sine mode               mcord = -1
!  i=5   2 cosine mode             mcord =  2
!  i=6   2 sine mode               mcord=  -2
!  etc...
!
integer n,mcord(:)
integer i
do i=1,n
   mcord(i)=(i-1)/2	
   if (mod(i,2)==0) mcord(i)=-mcord(i)
   if (i==2) mcord(i)=n/2
enddo
end subroutine







subroutine fftinit(n,index)
integer n,index
character(len=80) message

if (init==0) call abortdns("fft99_interface.F90: call fft_interface_init to initialize first!")
if (n>1000000) call abortdns("fft99_interface.F90: n>1 million")

fftdata(index)%size=n
allocate(fftdata(index)%trigs(3*n/2+1))

write(message,'(a,i6)') 'Initializing FFT99 of size n=',n
call print_message(message)

call set99(fftdata(index)%trigs,fftdata(index)%ifax,n)
if (n<0) call abortdns("Error: invalid value of n for fft")

end subroutine




subroutine getindex(n1,index)
integer n1,index

character(len=80) message_str
integer i,k


i=0
do 
   i=i+1

   if (i>num_fftsizes) then
      write(message_str,'(a,i10)') "fft_interface.F90:  Failed initializing an fft of size =",n1
      call abortdns(message_str)
   endif

   if (fftdata(i)%size==0) then
      call fftinit(n1,i)      
      exit 
   endif
   if (n1==fftdata(i)%size) exit 
enddo
index=i
end subroutine




!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Compute 3D in-place iFFT of p
! FFT taken along first direction
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
subroutine ifft1(p,n1,n1d,n2,n2d,n3,n3d)
integer n1,n1d,n2,n2d,n3,n3d
real*8 p(n1d,n2d,n3d)
real*8 w(n2*(n1+1))

real*8 :: scale=1,tmx1,tmx2
character(len=80) message_str
integer index,j,k

call wallclock(tmx1)
if (tims(19)==0) ncalls(19)=0  ! timer was reset, so reset counter too

if (n1==1) return
ASSERT("ifft1: dimension too small ",n1+2<=n1d)
call getindex(n1,index)



j=0  ! j=number of fft's computed for each k
do k=1,n3
   do j=1,n2

      ! move the last cosine mode back into correct location:
      p(n1+1,j,k)=p(2,j,k)
      !p(2,j,k)=0             ! not needed?
      !p(n1+2,j,k)=0          ! not needed?
   enddo

   call fft991(p(1,1,k),w,fftdata(index)%trigs,fftdata(index)%ifax,1,n1d,n1,n2,1)
enddo

call wallclock(tmx2) 
tims(19)=tims(19)+(tmx2-tmx1)          
ncalls(19)=ncalls(19)+1
end subroutine



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Compute 3D in-place iFFT of p
! FFT taken along first direction
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
subroutine ifft1_dim2(p,n1,n1d,n2,n2d,n3,n3d)
integer n1,n1d,n2,n2d,n3,n3d
real*8 p(n1d,n2d,n3d)
real*8 w(n2*(n1+1))

real*8 :: scale=1,tmx1,tmx2
character(len=80) message_str
integer index,i,j,k

call wallclock(tmx1)
if (tims(19)==0) ncalls(19)=0  ! timer was reset, so reset counter too

if (n2==1) return
ASSERT("ifft1: dimension too small ",n2+2<=n2d)
call getindex(n2,index)

j=0  ! j=number of fft's computed for each k
do k=1,n3
   do i=1,n1

      ! move the last cosine mode back into correct location:
      p(i,n2+1,k)=p(i,2,k)

!      call fft991(p(i,1,k),w,fftdata(index)%trigs,fftdata(index)%ifax,&
!          n1d,1,n2,1,1)

   enddo
   call fft991(p(1,1,k),w,fftdata(index)%trigs,fftdata(index)%ifax,&
        n1d,1,n2,n1,1)
enddo

call wallclock(tmx2) 
tims(19)=tims(19)+(tmx2-tmx1)          
ncalls(19)=ncalls(19)+1
end subroutine



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Compute 3D in-place FFT of p
! FFT taken along first direction
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
subroutine fft1(p,n1,n1d,n2,n2d,n3,n3d)
integer n1,n1d,n2,n2d,n3,n3d
real*8 p(n1d,n2d,n3d)
real*8 :: scale
real*8 :: w(n2*(n1+1)) 
real*8 :: tmx1,tmx2
integer index,j,k

call wallclock(tmx1)
if (tims(18)==0) ncalls(18)=0  ! timer was reset, so reset counter too


if (n1==1) return
ASSERT("fft1: dimension too small ",n1+2<=n1d)
call getindex(n1,index)

scale=n1
scale=1/scale

do k=1,n3
   !   do j=1,n2
   !         p(n1+1,jj,k)=0
   !         p(n1+2,jj,k)=0
   !   enddo
   call fft991(p(1,1,k),w,fftdata(index)%trigs,fftdata(index)%ifax,1,n1d,n1,n2,-1)
   !     move the last cosine mode into slot of first sine mode:
   do j=1,n2
      p(2,j,k)=p(n1+1,j,k)
   enddo
   
enddo
call wallclock(tmx2) 
tims(18)=tims(18)+(tmx2-tmx1)          
ncalls(18)=ncalls(18)+1
end subroutine




end ! module mod_fft_interface


