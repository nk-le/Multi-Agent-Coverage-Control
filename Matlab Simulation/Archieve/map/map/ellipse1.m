function [latout,lonout] = ellipse1(varargin)
%ELLIPSE1 Geographic ellipse from center, semimajor axes, eccentricity and
%         azimuth
%
%   [LAT,LON] = ELLIPSE1(LAT0,LON0,ELLIPSE) computes ellipse(s) with
%   center(s) at LAT0, LON0.  ELLIPSE must have the form [semimajor axis,
%   eccentricity].  LAT0 and LON0 can be scalar or column vectors. The
%   input and output latitudes and longitudes are in units of degrees.
%   ELLIPSE must have the same number of rows as the input LAT0 and LON0.
%   The semimajor axis (ELLIPSE(1)) is in degrees of arc length on a
%   sphere. All ellipses are oriented so that their major axis runs
%   north-south.
%
%   [LAT,LON] = ELLIPSE1(LAT0,LON0,ELLIPSE,OFFSET) computes the ellipses
%   where the major axis is rotated from due north by an azimuth OFFSET.
%   The offset angle is measure clockwise from due north.  If OFFSET =[],
%   then no offset is assumed.
%
%   [LAT,LON] = ELLIPSE1(LAT0,LON0,ELLIPSE,OFFSET,AZ) computes partial
%   elliptical arcs defined by the limits given in the two-element vector
%   AZ, starting at the azimuth in the first column and ending at the
%   azimuth in the second column.  If AZ = [], then a complete ellipse is
%   computed.
%
%   [lat,LON] = ELLIPSE1(LAT0,LON0,ELLIPSE,OFFSET,AZ,ELLIPSOID) computes
%   the ellipse(s) on the reference ellipsoid defined by ELLIPSOID.
%   ELLIPSOID is a reference ellipsoid (oblate spheroid) object, a
%   reference sphere object, or a vector of the form [semimajor_axis,
%   eccentricity].  The semimajor axis of the ellipse must be in the
%   same units as the ellipsoid's semimajor axis, unless ELLIPSOID is [].
%   If ELLIPSOID is [], then the semimajor axis of the ellipse is
%   interpreted as an angle and the ellipse is computed on a sphere,
%   as in the preceding syntax.
%
%   [LAT,LON] = ELLIPSE1(LAT0,LON0,ELLIPSE,OFFSET,ANGLEUNITS),
%   [LAT,LON] = ELLIPSE1(LAT0,LON0,ELLIPSE,OFFSET,AZ,ANGLEUNITS), and
%   [LAT,LON] = ELLIPSE1(LAT0,LON0,ELLIPSE,OFFSET,AZ,ELLIPSOID,ANGLEUNITS)
%   use ANGLEUNITS to specify the angle units of the inputs and outputs.
%   ANGLEUNITS can be 'degrees' or 'radians'.
%
%   [LAT,LON] = ELLIPSE1(LAT0,LON0,ELLIPSE,OFFSET,AZ,ELLIPSOID,UNITS,NPTS)
%   uses the scalar NPTS to determine the number of points per ellipse
%   computed.  The default value of NPTS is 100.
%
%   [LAT,LON] = ELLIPSE1(TRACKSTR,...) uses TRACKSTR to define either a
%   great circle or rhumb line distances from the ellipse center. If
%   TRACKSTR is 'gc', then great circle distances are computed (the
%   default). If TRACKSTR is 'rh', then rhumb line distances are computed.
%
%   MAT = ELLIPSE1(...) returns a single output argument where
%   MAT = [LAT LON].  This is useful if only one ellipse is computed.
%
%   Multiple ellipses can be calculated with a common center by providing
%   scalar LAT0 and LON0 inputs and a 2-column ELLIPSE matrix.
%
%   See also AXES2ECC, SCIRCLE1, TRACK1

% Copyright 1996-2017 The MathWorks, Inc.

if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end

if nargin == 0
    error(message('map:validate:invalidArgCount'))
    
elseif (nargin < 3  && ~ischar(varargin{1})) ||  (nargin == 3 && ischar(varargin{1}))
    error(message('map:validate:invalidArgCount'))
    
elseif (nargin == 3 && ~ischar(varargin{1})) || (nargin == 4 && ischar(varargin{1}))
    
    if ~ischar(varargin{1})
        % Shift inputs since str omitted by user
		str     = [];
		lat     = varargin{1};
        lon     = varargin{2};
		ellipse = varargin{3};
    else
		str     = varargin{1};
		lat     = varargin{2};
        lon     = varargin{3};
		ellipse = varargin{4};
    end

	offset = [];
	npts  = [];
    az    = [];
	ellipsoid = [];
    units = [];

elseif (nargin == 4 && ~ischar(varargin{1})) || (nargin == 5 && ischar(varargin{1}))

    if ~ischar(varargin{1})
        % Shift inputs since str omitted by user
		str     = [];
		lat     = varargin{1};
        lon     = varargin{2};
		ellipse = varargin{3};
        offset = varargin{4};
	else
		str     = varargin{1};
		lat     = varargin{2};
        lon     = varargin{3};
		ellipse = varargin{4};
        offset = varargin{5};
    end

	npts  = [];
    az    = [];
	ellipsoid = [];
    units = [];

elseif (nargin == 5 && ~ischar(varargin{1})) || (nargin == 6 && ischar(varargin{1}))

    if ~ischar(varargin{1})
        %  Shift inputs since str omitted by user
		str     = [];
		lat     = varargin{1};
        lon     = varargin{2};
		ellipse = varargin{3};
        offset = varargin{4};
		lastin  = varargin{5};
	else
		str     = varargin{1};
		lat     = varargin{2};
        lon     = varargin{3};
		ellipse = varargin{4};
        offset  = varargin{5};
		lastin  = varargin{6};
    end

    if ischar(lastin)
         az    = [];
         ellipsoid = [];
         units = lastin;
         npts = [];
    else
		 az    = lastin;
         ellipsoid = [];
         units = [];
         npts = [];
    end

elseif (nargin == 6 && ~ischar(varargin{1})) || (nargin == 7 && ischar(varargin{1}))

    if ~ischar(varargin{1})
        % Shift inputs since str omitted by user
		str     = [];
		lat     = varargin{1};
        lon     = varargin{2};
		ellipse = varargin{3};
        offset  = varargin{4};
		az      = varargin{5};
        lastin = varargin{6};
	else
		str     = varargin{1};
		lat     = varargin{2};
        lon     = varargin{3};
		ellipse = varargin{4};
        offset  = varargin{5};
		az      = varargin{6};
        lastin = varargin{7};
    end

    if ischar(lastin)
		units = lastin;
        ellipsoid = [];
        npts = [];
    else
        units = [];
        ellipsoid = lastin;
        npts = [];
    end

elseif (nargin == 7 && ~ischar(varargin{1})) || (nargin == 8 && ischar(varargin{1}))

    if ~ischar(varargin{1})
        % Shift inputs since str omitted by user
		str     = [];
		lat     = varargin{1};
        lon     = varargin{2};
		ellipse = varargin{3};
        offset  = varargin{4};
		az      = varargin{5};
        ellipsoid = varargin{6};
		units   = varargin{7};
    else
		str     = varargin{1};
		lat     = varargin{2};
        lon     = varargin{3};
		ellipse = varargin{4};
        offset  = varargin{5};
		az      = varargin{6};
        ellipsoid   = varargin{7};
		units   = varargin{8};
    end

    npts = [];

elseif (nargin == 8 && ~ischar(varargin{1})) || (nargin == 9 && ischar(varargin{1}))

    if ~ischar(varargin{1})
        % Shift inputs since str omitted by user
		str     = [];
		lat     = varargin{1};
        lon     = varargin{2};
		ellipse = varargin{3};
        offset  = varargin{4};
		az      = varargin{5};
        ellipsoid = varargin{6};
		units   = varargin{7};
        npts    = varargin{8};
    else
		str     = varargin{1};
		lat     = varargin{2};
        lon     = varargin{3};
		ellipse = varargin{4};
        offset  = varargin{5};
		az      = varargin{6};
        ellipsoid = varargin{7};
		units   = varargin{8};
        npts    = varargin{9};
    end

end

%  Validate the track

if isempty(str)
    str = 'gc';
else
    str = validatestring(str, {'gc','rh'}, 'ELLIPSE1', 'TRACKSTR', 1);
end


%  Allow for scalar starting point, but vectorized azimuths.  Multiple
%  ellipses starting from the same point

if length(lat) == 1 && length(lon) == 1 && size(ellipse,1) ~= 0
    lat = lat(ones([size(ellipse,1) 1]));
    lon = lon(ones([size(ellipse,1) 1]));
end

%  Empty argument tests.  Set defaults

useSphericalDistance = isempty(ellipsoid);
if useSphericalDistance
    useSphericalDistance = true;
    ellipsoid = [1 0];
else
    ellipsoid = checkellipsoid(ellipsoid, 'ELLIPSE1', 'ELLIPSOID');
end

if isempty(units)
    units = 'degrees';
else
    units = checkangleunits(units);
end

if isempty(npts)
    npts  = 100;
end

if isempty(offset)
    offset = zeros(size(lat));
end

if isempty(az)
     az = fromDegrees(units, [0 360]);
     az = az(ones([size(lat,1) 1]), :);
end

%  Dimension tests

validateattributes(lat,{'double'},{'real','column'},'ELLIPSE1','LAT0')

if ~isequal(size(lat),size(lon),size(offset))
    error(message('map:validate:inconsistentSizes3',...
        'ELLIPSE1','LAT0','LON0','OFFSET'))

elseif size(lat,1) ~= size(ellipse,1)
    error(['map:' mfilename ':mapError'], ...
        'Inconsistent dimensions for starting points and ellipse definition.')

elseif ~ismatrix(ellipse) || size(ellipse,2) ~= 2
    error(['map:' mfilename ':mapError'], ...
        'Ellipse definition must have 2 columns.')

elseif size(lat,1) ~= size(az,1)
    error(['map:' mfilename ':mapError'], ...
        'Inconsistent dimensions for starting points and azimuths.')

elseif ~ismatrix(az) || size(az,2) > 2
    error(['map:' mfilename ':mapError'], ...
        'Azimuth input must have two columns or less')
end

%  Angle unit conversion

[lat, lon, offset, az] = toRadians(units, lat, lon, offset, az);

%  Convert the range to radians if working with spherical distances.
%  Otherwise, reckon will take care of the conversion of the range inputs

if useSphericalDistance
    ellipse(:,1) = toRadians(units,ellipse(:,1));
end

%  Expand the azimuth inputs

if size(az,2) == 1       %  Single column azimuth inputs
    negaz = zeros(size(az));
    posaz = az;
else                     %  Two column azimuth inputs
    negaz = az(:,1);
    posaz = az(:,2);
end

%  Convert ellipse vector to semi-major/minor axes a and b.
a   = ellipse(:,1);
ecc = ellipse(:,2);
b = a .* sqrt(1 - ecc.^2);

%  Use real(npts) to avoid a cumbersome warning for complex n in linspace
npts = real(npts);


%---- Done parsing inputs: start the computations here ----

% Compute each ellipse in the plane
nellipses = size(negaz,1);
x = zeros([nellipses npts]);
y = zeros([nellipses npts]);
for k = 1:nellipses
    [x(k,:),y(k,:)] ...
        = ellipse2D(a(k), b(k), 0, 0, offset(k), negaz(k), posaz(k), npts);
end

% Map ellipses to the sphere or ellipsoid by converting their X-Y
% coordinates to polar form, then calling reckon.
[az, rng] = cart2pol(x, y);
t = ones([1,npts]);  % Use to replicate lat and lon along rows (Tony's trick).
% [latc,lonc] = reckon(str, lat(:,t), lon(:,t) ,rng, az, ellipsoid, 'radians');

if strcmp(str,'gc')
    if ellipsoid(2) ~= 0
        [latc,lonc] = geodesicfwd(lat(:,t), lon(:,t), az, rng, ellipsoid);
    else
        [latc, dlon] = greatCircleForward(lat(:,t), rng/ellipsoid(1), az);
        lonc = lon(:,t) + dlon;
    end    
else
    [latc,lonc] = rhumblinefwd(lat(:,t), lon(:,t), az, rng, ellipsoid);
end
lonc = wrapToPi(lonc);

% Convert the results to the desired units
[latc, lonc] = fromRadians(units, latc', lonc');

% Set the output arguments
if nargout <= 1
    latout = [latc lonc];
elseif nargout == 2
    latout = latc;
    lonout = lonc;
end

%==========================================================================

function [x, y] = ellipse2D(a, b, xc, yc, offset, azStart, azEnd, npts)

%   [X, Y] = ELLIPSE2D(A, B, XC, YC, OFFSET, AZSTART, AZEND, NPTS)
%   computes points along a single ellipse centered at the origin in 2D
%   Cartesian coordinates.  Inputs A and B are the lengths of the
%   semi-major and semi-minor axes, respectively.  XC and YC are the center
%   coordinates.  OFFSET is a rotational offset measured counter-clockwise
%   from the x-axis to the major axis.  AZSTART and AZEND are the starting
%   and ending azimuths, also measured counter-clockwise from the x-axis,
%   and NPTS is the number of points to be returned.  Angular inputs
%   OFFSET, AZSTART, and AZEND are assumed to be in radians.  To compute a
%   full ellipse, use AZSTART = 0 and AZEND = 2*pi.  Return arrays X and Y
%   will each be 1-by-NPTS in size.

% Convert azimuth limits to parametric angles and rotate the ellipse
% such that the major axis aligns with the X-axis.
t1 = az2parametric(a, b, azStart - offset);
t2 = az2parametric(a, b, azEnd   - offset);

% Approximate the partial integrals of the parametric sampling density, nu.
M = max(32,2*npts);   % Use at least 32 samples, more if npts > 16.
dt = (t2 - t1) / M;   % Compute the sample spacing.
t = t1 + (0:M) * dt;  % We'll calculate nu at each value in array t.
t(end) = t2;          % Ensure match at the upper end, in case of round off.

% Parametric sampling density, computed at M+1 points evenly distributed
% from t1 to t2.  This particular density was selected to evenly
% distribute, across all the chords connecting adjacent sampling points,
% the maximum departure from the ellipse of the chord from the ellipse
% itself.
nu = ((a * sin(t)).^2 + (b * cos(t)).^2).^(-1/4);

% Integrate nu using the trapezoid rule, including partial integrals.
% S(k) will approximate the integral of nu(t) from t=t1 to t=t(k).
S = dt * (2*cumsum(nu) - nu - nu(1)) / 2;

% Normalize the partial integrals such that S(end) = npts - 1.
S = (npts - 1) * S / S(end);
S(end) = (npts - 1); % Avoid running off the end due to round off.

% Interpolate to obtain sampling points:  Find the values of
% t at which S is an integer in the interval [0 (npts-1)].
ts = interp1(S(:),t(:),(0:(npts-1))')';

% Compute the sampling points and restore the rotational offset.
co = cos(offset);
so = sin(offset);
p = [co -so; so co] * [a * cos(ts); b * sin(ts)];
x = xc + p(1,:);
y = yc + p(2,:);

%==========================================================================

function t = az2parametric(a, b, az)

%   For points on an ellipse with major axis aligned with the X-axis,
%   convert azimuth angles AZ (angle measured counter-clockwise from the
%   X-axis) to parametric angles T, such that
%
%                       X = A * cos(T)
%                       Y = B * sin(T)
% 
%   given semi-major and -minor axes A and B.  AZ and T are in radians.
%   All angle-wrapping is preserved:  Any angle that is a precise multiple
%   of pi/2 is unchanged, and no angle changes quadrants.

t = atan2( a.*sin(az), b.*cos(az) )...
    + (az - atan2(sin(az), cos(az)));  % Preserve angle wrapping

%==========================================================================

function [phi, dlambda] = greatCircleForward(phi0, delta, az)
% Great circle forward computation in radians

cosdelta = cos(delta);
sindelta = sin(delta);

cosphi0 = cos(phi0);
sinphi0 = sin(phi0);

cosAz = cos(az);
sinAz = sin(az);

phi = asin(sinphi0.*cosdelta + cosphi0.*sindelta.*cosAz);
dlambda = atan2(sindelta.*sinAz, cosphi0.*cosdelta - sinphi0.*sindelta.*cosAz);
