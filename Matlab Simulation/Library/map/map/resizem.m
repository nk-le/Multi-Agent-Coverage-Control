function [Z, R] = resizem(Z, vec, R, method, n)
%RESIZEM  Resize regular data grid
%
%      RESIZEM will be removed in a future release.
%      Use GEORESIZE or IMRESIZE instead.
%
%   Z = RESIZEM(Z1, SCALE) returns a regular data grid Z that is SCALE time
%   the size of the input, Z1. RESIZEM uses interpolation to resample to a
%   new sample density/cell size.  If SCALE is between 0 and 1, the size of
%   Z is smaller than the size of Z1.  If SCALE is greater than 1, the size
%   of Z is larger. For example, if SCALE is 0.5, the number of rows and
%   the number of columns will be halved.  By default, RESIZEM uses nearest
%   neighbor interpolation.
%
%   Z = RESIZEM(Z1, [NUMROWS NUMCOLS]) resizes Z1 to have NUMROWS rows and
%   NUMCOLS columns. NUMROWS and NUMCOLS must be positive whole numbers.
%
%   [Z, R] = RESIZEM(Z1, SCALE, R1) or
%   [Z, R] = RESIZEM(Z1, [NUMROWS NUMCOLS], R1) resizes a data grid that
%   is spatially referenced by R1.  R1 can be a referencing vector, a
%   referencing matrix, or a geographic raster reference object.
%
%   If R1 is a geographic raster reference object, its RasterSize property
%   must be consistent with size(Z1) and its RasterInterpretation must be
%   'cells'.
%
%   If R1 is a referencing vector, it must be a 1-by-3 with elements:
%
%     [cells/degree northern_latitude_limit western_longitude_limit]
%
%   If R1 is a referencing matrix, it must be 3-by-2 and transform raster
%   row and column indices to/from geographic coordinates according to:
% 
%                     [lon lat] = [row col 1] * R1.
%
%   If R1 is a referencing matrix, it must define a (non-rotational,
%   non-skewed) relationship in which each column of the data grid falls
%   along a meridian and each row falls along a parallel. The output R will
%   be the same type as R1 (referencing object, vector, or matrix). If R1
%   is a referencing vector, the form [NUMROWS NUMCOLS] is not supported
%   and SCALE must be a scalar resizing factor.
%
%   [...] = RESIZEM(..., METHOD) resizes a regular data grid using one
%   of the following three interpolation methods:
%
%        'nearest'  (default) nearest neighbor interpolation
%
%        'bilinear' bilinear interpolation
%
%        'bicubic'  bicubic interpolation
%
%   If the grid size is being reduced (SCALE is less than 1 or [NUMROWS
%   NUMCOLS] is less than the size of the input grid) and METHOD is
%   'bilinear' or 'bicubic', RESIZEM applies a low-pass filter before
%   interpolation, to reduce aliasing. The default filter size is 11-by-11.
%
%   You can specify a different length for the default filter using:
%
%        [...] = RESIZEM(..., METHOD, N)
%
%   N is an integer scalar specifying the size of the filter, which is
%   N-by-N.  If N is 0 or METHOD is 'nearest', RESIZEM omits the
%   filtering step.
%
%   You can also specify your own filter H using:
%
%        [...] = RESIZEM(..., METHOD, H)
%
%   H is any two-dimensional FIR filter (such as those returned by Image
%   Processing Toolbox functions FTRANS2, FWIND1, FWIND2, or FSAMP2).
%   If H is specified, filtering is applied even when METHOD is
%   'nearest'.
%
%   See also GEORESIZE, IMRESIZE

% Copyright 1996-2020 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

narginchk(2,5)

if nargin == 2
    R = [];
    method = [];
    n = [];
elseif nargin == 3
    if ischar(R) || isstring(R)
        method = R;
        R = [];
        n=[];
    else
        method = [];
        n = [];
    end
elseif nargin == 4
    if ischar(R) || isstring(R)
        n = method;
        method = R;
        R = [];
    else
        n = [];
    end
end

%  Set the default method
method = convertStringsToChars(method);
if isempty(method)
    method = 'nearest';
end

%  Resize the map
originalSize = size(Z);
if issparse(Z)
    % IMRESIZE won't support sparse matrix computations
    Z = reduce(Z,vec);
else
    if isempty(n)
        Z = imresize(Z,vec,method);
    else
        Z = imresize(Z,vec,method,n);
    end
end

%  Update the referencing vector if one was supplied
if ~isempty(R)
    R = updateReferencing(R, originalSize, size(Z), isscalar(vec));
end

%--------------------------------------------------------------------------

function R = updateReferencing(R, originalSize, newSize, uniformScaling)

%  If a new referencing vector is to be returned, require the resize factor
%  to be scalar so that latitude and longitude are scaled equally.
refvecInput = isequal(size(R), [1 3]);
if refvecInput && ~uniformScaling
    error('map:resizem:nonScalarScaleFactor', ...
        ['The scale factor %s must be a scalar when resizing a regular', ...
        ' data grid that uses a referencing vector.'], 'M')
end

% If R is already spatial referencing object, validate it. Otherwise
% validate and convert the input referencing vector or matrix. The
% latitude and longitude limits, and the column and row directions,
% will be preserved.
S = internal.map.convertToGeoRasterRef( ...
    R, originalSize, 'degrees', mfilename, 'R', 2);
S.RasterSize = newSize;

assert(strcmp(S.RasterInterpretation,'cells'), ...
    'map:validate:unexpectedPropertyValueString', ...
    'Function %s expected the %s property of input %s to have the value: ''%s''.', ...
    'resizem', 'RasterInterpretation', 'R1', 'cells')

% Return the resized referencing object, or construct a new referencing
% vector or matrix.
if isobject(R)
    % Referencing object
    R = S;
elseif refvecInput
    % Referencing vector
    R = [sampleDensity(S) S.LatitudeLimits(2) S.LongitudeLimits(1)];
else
    % Referencing matrix
    R = map.internal.referencingMatrix(worldFileMatrix(S));
end

%--------------------------------------------------------------------------

function map = reduce(map0,vec)
%REDUCE  Reduce binary sparse matrix
%
%   map = reduce(map0,m)      %  Reduce by a factor of m
%   map = reduce(map0,[r c])  %  Reduce to row and column dimension

validateattributes(map0, {'numeric'}, {'2d','binary'}, 'REDUCE', 'MAP0', 1)
vec = ignoreComplex(vec, mfilename, 'vec');

%  Set the row and column scale factors

if isscalar(vec)
     if vec == 1
	     map = map0;        %  No reduction required
		 return
	 else
	     rowfact = 1 / vec;
		 colfact = 1 / vec;
     end
elseif numel(vec) == 2
     rowfact = size(map0,1) / vec(1);     %  Different row and column scaling
	 colfact = size(map0,2) / vec(2);
else
     error('map:resizem:tooManyElementsInScaleFactor', ...
         'Scale factors must be a vector of 2 elements or less.')
end

%  Ensure that reduction is occurring

if rowfact < 1 || colfact < 1
    error('map:resizem:cannotIncreaseSize', ...
        'REDUCE only supports matrix reduction.')
end

%  Determine the original size of the data grid

[m,n]=size(map0);

%  Compute the pre-multiplier for the reduction operation.  The
%  pre-multiplication will reduce the row dimension

prerows = (1:m)';
precols = fix( (rowfact-1+prerows) / rowfact);
indx = prerows + (precols-1)*m;
pre = sparse(m,m/rowfact);
pre(indx) = ones(size(indx));

%  Compute the post-multiplier for the reduction operation.  The
%  post-multiplication will reduce the column dimension

postrows = (1:n)';
postcols = fix( (colfact-1+postrows) / colfact);
indx = postrows + (postcols-1)*n;
post = sparse(n,n/colfact);
post(indx) = ones(size(indx));


%  Reduce the map matrix

map = pre'*map0*post;
map = (map~=0);       %  Ensure a binary output


%*************************************************************************
%*************************************************************************
%*************************************************************************
%
%  Following function IMRESIZE (and functions it calls) are called
%  by RESIZEM.  These functions have been made local to this RESIZEM
%  since they have been taken from other toolboxes for the
%  sole purpose of making RESIZEM work in the Mapping Toolbox.
%
%*************************************************************************
%*************************************************************************
%*************************************************************************


function [rout,g,b] = imresize(arg1,arg2,arg3,arg4,arg5,arg6)
%IMRESIZE Resize image.
%	B = IMRESIZE(A,M,'method') returns an image matrix that is
%	M times larger (or smaller) than the image A.  The image B
%	is computed by interpolating using the method in the string
%	'method'.  Possible methods are 'nearest','bilinear', or
%	'bicubic'. B = IMRESIZE(A,M) uses 'nearest' when A for indexed
%	images and 'bilinear' for intensity images.
%
%	B = IMRESIZE(A,[MROWS NCOLS],'method') returns a matrix of
%	size MROWS-by-NCOLS.
%
%	[R1,G1,B1] = IMRESIZE(R,G,B,M,'method') or
%	[R1,G1,B1] = IMRESIZE(R,G,B,[MROWS NCOLS],'method') resizes
%	the RGB image in the matrices R,G,B.  'bilinear' is the
%	default interpolation method.
%
%	When the image size is being reduced, IMRESIZE lowpass filters
%	the image before interpolating to avoid aliasing. By default,
%	this filter is designed using FIR1, but can be specified using
%	IMRESIZE(...,'method',H). The default filter is 11-by-11.
%	IMRESIZE(...,'method',N) uses an N-by-N filter.
%	IMRESIZE(...,'method',0) turns off the filtering.
%	Unless a filter H is specified, IMRESIZE will not filter
%	when 'nearest' is used.
%
%	See also IMZOOM, FIR1, INTERP2.

%  Written by: Clay M. Thompson 7-7-92

% Trap imresize(r,b,g,...) calls.
if nargin==4
  if ~(ischar(arg3) || isstring(arg3)) % imresize(r,g,b,m)
    r = imresize(arg1,arg4,'bil');
    g = imresize(arg2,arg4,'bil');
    b = imresize(arg3,arg4,'bil');
    rout = r;
    return
  end
elseif nargin==5 % imresize(r,g,b,m,'method')
  r = imresize(arg1,arg4,arg5);
  g = imresize(arg2,arg4,arg5);
  b = imresize(arg3,arg4,arg5);
  rout = r;
  return
elseif nargin==6 % imresize(r,g,b,m,'method',h)
  r = imresize(arg1,arg4,arg5,arg6);
  g = imresize(arg2,arg4,arg5,arg6);
  b = imresize(arg3,arg4,arg5,arg6);
  rout = r;
  return
end

% Determine default interpolation method
if nargin<3
    if isgray(arg1)
        case0 = 'bil';
    else
        case0 = 'nea';
    end
else
    if ~isscalar(arg3)
        validateattributes(arg3, {'char','string'}, {'scalartext'});
    end
  method = [lower(arg3),'   ']; % Protect against short method
  case0 = method(1:3);
end

if numel(arg2)==1
  bsize = floor(arg2*size(arg1));
else
  bsize = arg2;
end

if any(size(bsize)~=[1 2])
  error(['map:' mfilename ':mapError'], ...
      'M must be either a scalar multiplier or a 1-by-2 size vector.')
end

if nargin<4
  nn = 11; h = []; % Default filter size
else
  if length(arg4)==1, nn = arg4; h = []; else nn = 0; h = arg4; end
end

[m,n] = size(arg1);

if nn>0 && case0(1)=='b'  % Design anti-aliasing filter if necessary
  if bsize(1)<m, h1 = fir1(nn-1,bsize(1)/m); else h1 = 1; end
  if bsize(2)<n, h2 = fir1(nn-1,bsize(2)/n); else h2 = 1; end
  if length(h1)>1 || length(h2)>1, h = h1'*h2; else h = []; end
end

if ~isempty(h) % Anti-alias filter A before interpolation
  a = filter2(h,arg1);
else
  a = arg1;
end

if case0(1)=='n' % Nearest neighbor interpolation
  dx = n/bsize(2); dy = m/bsize(1);
  uu = (dx/2+.5):dx:n+.5; vv = (dy/2+.5):dy:m+.5;
elseif all(case0 == 'bil') || all(case0 == 'bic')
  uu = 1:(n-1)/(bsize(2)-1):n; vv = 1:(m-1)/(bsize(1)-1):m;
else
  error(['map:' mfilename ':mapError'], ...
      ['Unknown interpolation method: ',method])
end

%
% Interpolate in blocks
%
nu = length(uu); nv = length(vv);
blk = bestblk([nv nu]);
nblks = floor([nv nu]./blk); nrem = [nv nu] - nblks.*blk;
mblocks = nblks(1); nblocks = nblks(2);
mb = blk(1); nb = blk(2);

rows = 1:blk(1); b = zeros(nv,nu);
for i=0:mblocks
  if i==mblocks, rows = (1:nrem(1)); end
  for j=0:nblocks
    if j==0, cols = 1:blk(2); elseif j==nblocks, cols=(1:nrem(2)); end
    if ~isempty(rows) && ~isempty(cols)
      [u,v] = meshgrid(uu(j*nb+cols),vv(i*mb+rows));
      % Interpolate points
      if case0(1) == 'n' % Nearest neighbor interpolation
        [M,N] = size(a);
        u(0.5 <= u & u < 1) = 1;
        v(0.5 <= v & v < 1) = 1;
        u(N < u & u <= N + 0.5) = N;
        v(M < v & v <= M + 0.5) = M;          
        b(i*mb+rows,j*nb+cols) = interp2(a,u,v,'nearest');
      elseif all(case0 == 'bil') % Bilinear interpolation
         b(i*mb+rows,j*nb+cols) = interp2(a,u,v,'linear');
     elseif all(case0 == 'bic') % Bicubic interpolation
        b(i*mb+rows,j*nb+cols) = interp2(a,u,v,'cubic');
      end
    end
  end
end

if isgray(arg1), rout = max(0,min(b,1)); else rout = b; end


%*************************************************************************
%*************************************************************************
%*************************************************************************
%
%  Following functions ISGRAY, BESTBLK & FIR1 are called by
%  IMRESIZE.  They have been made local to RESIZEM
%  since they have been taken from other toolboxes for the
%  sole purpose of making RESIZEM work in the Mapping Toolbox.
%
%*************************************************************************
%*************************************************************************
%*************************************************************************


function y = isgray(x)
%ISGRAY True for intensity images.
%	ISGRAY(A) returns 1 if A is an intensity image and 0 otherwise.
%	An intensity image contains values between 0.0 and 1.0.
%
%	See also ISIND, ISBW.

%  Written by: Clay M. Thompson 2-25-93

y = min(min(x))>=0 & max(max(x))<=1;


%*************************************************************************
%*************************************************************************
%*************************************************************************


function [mb,nb] = bestblk(siz,k)
%BESTBLK Best block size for block processing.
%	BLK = BESTBLK([M N],K) returns the 1-by-2 block size BLK
%	closest to but smaller than K-by-K for block processing.
%
%	[MB,NB] = BESTBLK([M N],K) returns the best block size
%	as the two scalars MB and NB.
%
%	[...] = BESTBLK([M N]) returns the best block size smaller
%	than 100-by-100.
%
%	BESTBLK returns the M or N when they are already smaller
%	than K.
%
%	See also BLKPROC, SIZE.

%  Written by: Clay M. Thompson

if nargin==1, k = 100; end % Default block size

%
% Find possible factors of siz that make good blocks
%

% Define acceptable block sizes
m = floor(k):-1:floor(min(ceil(siz(1)/10),k/2));
n = floor(k):-1:floor(min(ceil(siz(2)/10),k/2));

% Choose that largest acceptable block that has the minimum padding.
[~,ndx] = min(ceil(siz(1)./m).*m-siz(1)); blk(1) = m(ndx);
[~,ndx] = min(ceil(siz(2)./n).*n-siz(2)); blk(2) = n(ndx);

if nargout==2
  mb = blk(1); nb = blk(2);
else
  mb = blk;
end


%*************************************************************************
%*************************************************************************
%*************************************************************************


function [b,a] = fir1(N,Wn,Ftype,Wind)
%FIR1	FIR filter design using the window method.
%	B = FIR1(N,Wn) designs an N'th order lowpass FIR digital filter
%	and returns the filter coefficients in length N+1 vector B.
%	The cut-off frequency Wn must be between 0 < Wn < 1.0, with 1.0
%	corresponding to half the sample rate.
%
%	If Wn is a two-element vector, Wn = [W1 W2], FIR1 returns an
%	order N bandpass filter with passband  W1 < W < W2.
%	B = FIR1(N,Wn,'high') designs a highpass filter.
%	B = FIR1(N,Wn,'stop') is a bandstop filter if Wn = [W1 W2].
%	For highpass and bandstop filters, N must be even.
%
%	By default FIR1 uses a Hamming window.  Other available windows,
%	including Boxcar, Hanning, Bartlett, Blackman, Kaiser and Chebwin
%	can be specified with an optional trailing argument.  For example,
%	B = FIR1(N,Wn,bartlett(N+1)) uses a Bartlett window.
%	B = FIR1(N,Wn,'high',chebwin(N+1,R)) uses a Chebyshev window.
%
%	FIR1 is a MATLAB implementation of program 5.2 in the IEEE
%	Programs for Digital Signal Processing tape.  See also FIR2,
%	FIRLS, REMEZ, BUTTER, CHEBY1, CHEBY2, YULEWALK, FREQZ and FILTER.

%  Written by: L. Shure

%	Reference(s):
%	  [1] "Programs for Digital Signal Processing", IEEE Press
%	      John Wiley & Sons, 1979, pg. 5.2-1.

nw = 0;
a = 1;
if nargin == 3
	if ~(ischar(Ftype) || isstring(Ftype))
		nw = max(size(Ftype));
      		Wind = Ftype;
		Ftype = [];
	end
elseif nargin == 4
   nw = max(size(Wind));
else
   Ftype = [];
end

Btype = 1;
if nargin > 2 && max(size(Ftype)) > 0
	Btype = 3;
end
if max(size(Wn)) == 2
	Btype = Btype + 1;
end

N = N + 1;
odd = rem(N, 2);
if (Btype == 3 || Btype == 4)
   if (~odd)
      disp('For highpass and bandstop filters, order must be even.')
      disp('Order is being increased by 1.')
      N = N + 1;
      odd = 1;
   end
end
if nw ~= 0 && nw ~= N
   error(['map:' mfilename ':mapError'], ...
       'The window length must be the same as the filter length.')
end
if nw > 0
   wind = Wind;
else
   wind = sym_window(N);  % Symmetric Hamming window
end

fl = Wn(1)/2;
if (Btype == 2 || Btype == 4)
   fh = Wn(2)/2;
   if (fl >= .5 || fl <= 0 || fh >= .5 || fh <= 0.)
      error(['map:' mfilename ':mapError'], ...
          'Frequencies must fall in range between 0 and 1.')
   end
   c1=fh-fl;
   if (c1 <= 0)
      error(['map:' mfilename ':mapError'], ...
          'Wn(1) must be less than Wn(2).')
   end
else
   c1=fl;
   if (fl >= .5 || fl <= 0)
      error(['map:' mfilename ':mapError'], ...
          'Frequency must lie between 0 and 1')
   end
end

nhlf = fix((N + 1)/2);
i1=1 + odd;

if Btype == 1			% lowpass
if odd
   b(1) = 2*c1;
end
xn=(odd:nhlf-1) + .5*(1-odd);
c=pi*xn;
c3=2*c1*c;
b(i1:nhlf)=(sin(c3)./c);
b = real([b(nhlf:-1:i1) b(1:nhlf)].*wind(:)');
gain = abs(polyval(b,1));
b = b/gain;
return;

elseif Btype ==2		% bandpass
b(1) = 2*c1;
xn=(odd:nhlf-1)+.5*(1-odd);
c=pi*xn;
c3=c*c1;
b(i1:nhlf)=2*sin(c3).*cos(c*(fl+fh))./c;
b=real([b(nhlf:-1:i1) b(1:nhlf)].*wind(:)');
gain = abs(polyval(b,exp(sqrt(-1)*pi*(fl+fh))));
b = b/gain;
return;

elseif Btype == 3		% highpass
b(1)=2*c1;
xn=(odd:nhlf-1);
c=pi*xn;
c3=2*c1*c;
b(i1:nhlf)=sin(c3)./c;
b=real([b(nhlf:-1:i1) b(1:nhlf)].*wind(:)');
b(nhlf)=1-b(nhlf);
b(1:nhlf-1)=-b(1:nhlf-1);
b(nhlf+1:N)=-b(nhlf+1:N);
gain = abs(polyval(b,-1));
b = b/gain;
return;

elseif Btype == 4		% bandstop
b(1) = 2*c1;
xn=(odd:nhlf-1)+.5*(1-odd);
c=pi*xn;
c3=c*c1;
b(i1:nhlf)=2*sin(c3).*cos(c*(fl+fh))./c;
b=real([b(nhlf:-1:i1) b(1:nhlf)].*wind(:)');
b(nhlf)=1-b(nhlf);
b(1:nhlf-1)=-b(1:nhlf-1);
b(nhlf+1:N)=-b(nhlf+1:N);
gain = abs(polyval(b,1));
b = b/gain;
return;
end

%---------------------------------------------------------------------
function w = sym_window(n)
%SYM_WINDOW   Symmetric Hamming window.
%   SYM_WINDOW Returns an exactly symmetric N point Hamming 
%   window by evaluating the first half and then flipping the same
%   samples over the other half.

if ~rem(n,2)
    % Even length window
    half = n/2;
    w = calc_hamming(half,n);
    w = [w; w(end:-1:1)];
else
    % Odd length window
    half = (n+1)/2;
    w = calc_hamming(half,n);
    w = [w; w(end-1:-1:1)];
end

%---------------------------------------------------------------------
function w = calc_hamming(m,n)
%CALC_HAMMING   Calculate the generalized cosine window samples.
%   CALC_HAMMING Calculates and returns the first M points of an N point
%   generalized cosine window determined by the 'window' string.

% We force rounding in order to achieve better numerical properties.
% For example, the end points of the hamming window should be exactly
% 0.08.

a0 = 0.54;
a1 = 0.46;
x = (0:m-1)'/(n-1);
w = a0 - a1*cos(2*pi*x);
