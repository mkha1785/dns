fidu=fopen('test-0-0-0-0000.0000.data');

%
%########################################################################
%#  plotting output file
%########################################################################

%ts=input('time=? ');

%range=0:.05:1.00;
range=0:.25:10.0;
%range=[.00];
name='../src/impulse/kh24';
%name='../src/kh/khK';
%name='../src/kh/khQ';  %nopq
name='../src/temp';

mkpr=0;            % make ps and jpeg files
mkcontour=1;       % use pcolor or contour


s=findstr(name,'/');
s=s(length(s));
shortname=name(s+1:length(name));

for i=range
  ts=i;
  ts = sprintf('%9.5f',10000+ts);
  ts=ts(2:10);

  fname=[name,ts,'.vor']
  fidvor=fopen(fname,'r');
  time=fread(fidvor,1,'float64')
  data=fread(fidvor,3,'float64');
  nx=data(1);
  ny=data(2);
  nz=data(3);
  
  x=fread(fidvor,nx,'float64');
  y=fread(fidvor,ny,'float64');
  z=fread(fidvor,nz,'float64');
  x = x*(nx/ny);
  
  
  q = fread(fidvor,nx*ny*nz,'float64');
  tmp = fread(fidvor,1,'float64');
  tmp=size(tmp);
  if (tmp(1)~=0) 
    disp('Error reading input file...')
  end
  fclose(fidvor);
  q = reshape(q,nx,ny,nz);
  qmax=max(max(max(q)));
  vor = squeeze(q(:,:,1));
  disp(sprintf('max vor=                %f ',qmax));

  
  
  fname=[name,ts,'.psi']
  fidvor=fopen(fname,'r');
  time=fread(fidvor,1,'float64')
  data=fread(fidvor,3,'float64');
  nx=data(1);
  ny=data(2);
  nz=data(3);
  
  x=fread(fidvor,nx,'float64');
  y=fread(fidvor,ny,'float64');
  z=fread(fidvor,nz,'float64');
  x=x*(nx/ny);
  
  q = fread(fidvor,nx*ny*nz,'float64');
  tmp = fread(fidvor,1,'float64');
  tmp=size(tmp);
  if (tmp(1)~=0) 
    disp('Error reading input file...')
  end
  fclose(fidvor);
  q = reshape(q,nx,ny,nz);
  psi = squeeze(q(:,:,1));

  
  
  
  
  
  stitle=sprintf('%s    time=%.2f  max=%f',shortname,time,qmax)

  
    %
    %  2D field.  options set above:
    %  mkcontour=0,1    use pcolor, or contour plot
    %
    figure(1)
    clf
    subplot(2,1,1)

    if (mkcontour==0)
      pcolor(x,y,vor')
      shading interp
    else
      v = -12:1:3;
      v=2.^v;
      contour(x,y,vor',v)
      hold on
      contour(x,y,vor',[0 0],'k')
      hold off
    end
    
    title(stitle);
    axis equal

    
    subplot(2,1,2)

    if (mkcontour==0)
      pcolor(x,y,psi')
      shading interp
    else
      v=20;                             % use 20 contours
      contour(x,y,psi',v)
    end
    axis equal
    
    

  
    if (mkpr) 
      orient tall
      pname=[name,'.vor.ps'];
      disp('creating ps...')
      print('-depsc',pname);
      pname=[name,'.vor.jpg'];
      disp('creating jpg...')
      print('-djpeg','-r 96',pname);
    end

    'pause'
    pause
  end
end
return




%
%########################################################################
%#  restart file
%########################################################################
time=fread(fidu,1,'float64');


data=fread(fidu,4,'float64');
nx=data(1);
ny=data(2);
nz=data(3);
n_var=data(4);

q = fread(fidu,nx*ny*nz*n_var,'float64');
fclose(fidu);

disp(sprintf('restart dump:\ntime=%f  dims=%i %i %i %i',time,nx,ny,nz,n_var))
q = reshape(q,nx,ny,nz,n_var);

u = squeeze(q(:,:,1,1));
figure(1)
subplot(2,2,1)
pcolor(u')
shading interp

v = squeeze(q(:,:,1,2));
subplot(2,2,2)
pcolor(v')
shading interp


