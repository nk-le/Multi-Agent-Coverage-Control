function [latstd,lonstd] = stdm(lat,lon,ellipsoid,units)
%STDM  Standard deviation for geographic points
%
%  [latstd,lonstd] = STDM(lat,lon) computes standard deviation for
%  geographic data.  This function assumes that the data is distributed
%  on a sphere.  In contrast, STD assumes that the data is distributed
%  on a Cartesian plane.  Deviations are "sample" standard deviations,
%  normalized by (n-1), where n is the sample size. The square of the
%  sample standard deviation is an unbiased estimator of the variance.
%  When lat and lon are vectors, a single deviation location is returned.
%  When lat and long are matrices, latstd and lonstd are row vectors
%  providing the deviations for each column of lat and lon.  N-dimensional
%  arrays are not allowed.  Deviations are taken from the mean position
%  as returned by MEANM.  Deviations in longitude consider departure.
%  The deviations are degrees of distance.
%
%  [latstd,lonstd] = STDM(lat,lon,ellipsoid) computes the standard
%  deviation on the ellipsoid defined by the input ellipsoid, which is a
%  reference ellipsoid (oblate spheroid) object, a reference sphere object,
%  or a vector of the form [semimajor_axis, eccentricity].  If omitted, the
%  unit sphere is assumed.  The output deviations are returned in the same
%  units as the semimajor axis.
%
%  [latstd,lonstd] = STDM(lat,lon,'units') use the input 'units'
%  to define the angle units of the inputs and outputs.  If
%  omitted, 'degrees' are assumed.
%
%  [latstd,lonstd] = STDM(lat,lon,ellipsoid,'units') is a valid form.
%
%  mat = STDM(...) returns a single output, where mat = [latbar,lonbar].
%  This is particularly useful if the lat and lon inputs are vectors.
%
%  See also STD, MEANM, STDIST.

% Copyright 1996-2018 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

narginchk(2, 4)
if nargin == 2
    ellipsoid = [];
    units = [];
elseif nargin == 3
    if ischar(ellipsoid) || isstring(ellipsoid)
        units = ellipsoid;
        ellipsoid = [];
    else
        units = [];
    end
end

%  Empty argument tests
units = convertStringsToChars(units);
if isempty(units)
    units = 'degrees';
end

if isempty(ellipsoid)
    ellipsoid = [1 0];
    useSphericalDistance = true;
else
    ellipsoid = checkellipsoid(ellipsoid,'STDM','ELLIPSOID');
    useSphericalDistance = false;
end

%  Input dimension tests
validateattributes(lat, {'single','double'}, {'real','finite','2d'},'','lat')
validateattributes(lon, {'single','double'}, {'real','finite','2d'},'','lon')

if ~isequal(size(lat),size(lon))
    error(message('map:validate:inconsistentSizes2','STDM','LAT','LON'))
end

%  Convert inputs to radians.  Ensure that longitudes are
%  in the range 0 to 2pi since they will be treated as distances.

[lat, lon] = toRadians(units, lat, lon);
lon = wrapTo2Pi(lon);

%  Calculate the appropriate geographic means

[latbar,lonbar] = meanm(lat,lon,ellipsoid,'radians');

[m,n]=size(lat);
if m==1
    if n==1
        % Scalar input
        latstd = 0;
        lonstd = 0;
    else
        % Vector input
        lat=lat(:);
        lon=lon(:);
        latstd = norm(lat-latbar)*ellipsoid(1) / sqrt(n-1);
        lonstd = norm(departure(lon,lonbar*ones(n,1),lat,ellipsoid,'radians')) / sqrt(n-1);
    end
    
else
    % Matrix input, operate column-wise
    latstd=zeros(1,n);
    lonstd=zeros(1,n);
    for i=1:n
        latstd(i) = norm(lat(:,i)-latbar(i))*ellipsoid(1) / sqrt(m-1);
        lonstd(i) = norm(departure(lon(:,i),lonbar(i)*ones(m,1),lat(:,i),ellipsoid,'radians')) / sqrt(m-1);
    end
end

%  Set the output arguments

if useSphericalDistance
    [latstd, lonstd] = fromRadians(units, latstd, lonstd);
end

if nargout < 2
    latstd = [latstd lonstd];
end
