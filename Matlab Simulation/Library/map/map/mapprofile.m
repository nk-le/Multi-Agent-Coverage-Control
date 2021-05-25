function [zout,rng,lat,lon] = mapprofile(varargin)
%MAPPROFILE Interpolate between waypoints on regular data grid
%
% MAPPROFILE plots a profile of values between waypoints on 
% a displayed regular data grid. MAPPROFILE uses the current
% object if it is a regular data grid, or the first regular 
% data grid found on the current axes. The grid's zdata is 
% used for the profile. The color data is used in the absence 
% of zdata. The result is displayed in a new figure.
%
% [ZI,RI,LAT,LON] = MAPPROFILE returns the values of the profile
% without displaying them. The output ZI contains interpolated 
% values from map along great circles between the waypoints. 
% RI is a vector of associated distances from the first waypoint 
% in units of degrees of arc along the surface. lat and lon are 
% the corresponding latitudes and longitudes. 
%
% [ZI,RI,LAT,LON] = MAPPROFILE(Z,R,LAT,LON) accepts as input a regular
% data grid and waypoint vectors. No displayed grid is required. Sets of
% waypoints may be separated by NaNs into line sequences. The output
% ranges are measured from the first waypoint within a sequence.  R can
% be a geographic raster reference object, a referencing vector, or a
% referencing matrix.
%
% If R is a geographic raster reference object, its RasterSize property
% must be consistent with size(Z).
%
% If R is a referencing vector, it must be a 1-by-3 with elements:
%
%     [cells/degree northern_latitude_limit western_longitude_limit]
%
% If R is a referencing matrix, it must be 3-by-2 and transform raster
% row and column indices to/from geographic coordinates according to:
% 
%                  [lon lat] = [row col 1] * R.
%
% If R is a referencing matrix, it must define a (non-rotational,
% non-skewed) relationship in which each column of the data grid falls
% along a meridian and each row falls along a parallel.
%
% [ZI,RI,LAT,LON] = MAPPROFILE(Z,R,LAT,LON,UNITS)
% specifies the units of the output ranges along the profile. 
% Valid range units inputs are any distance type recognized by
% UNITSRATIO. Surface distances are computed using the default 
% radius of the earth. If omitted, 'degrees' are assumed.
%
% [ZI,RI,LAT,LON] = MAPPROFILE(Z,R,LAT,LON,ELLIPSOID) uses the ellipsoid
% defined by ELLIPSOID, which is a reference ellipsoid (oblate spheroid)
% object, a reference sphere object, or a vector of the form
% [semimajor_axis, eccentricity]. The output range is reported in the same
% distance units as the semimajor axes of the ellipsoid. If ELLIPSOID is
% omitted, a sphere is assumed.
%
% [ZI,RI,LAT,LON] = MAPPROFILE(Z,R,LAT,LON,UNITS,...
% 'trackmethod','interpmethod') and
% [ZI,RI,LAT,LON] = MAPPROFILE(Z,R,LAT,LON,ELLIPSOID,...
% 'trackmethod','interpmethod') control the interpolation methods
% used. Valid track methods are 'gc' for great circle tracks 
% between waypoints, and 'rh' for rhumb lines. Valid methods
% for interpolation within the matrix are 'bilinear' for linear 
% interpolation, 'bicubic' for cubic interpolation, and 'nearest' 
% for nearest neighbor interpolation. If omitted, 'gc' and 'bilinear'
% are assumed.
%
% See also LOS2

% Copyright 1996-2020 The MathWorks, Inc.

% Defaults for optional arguments
rngunits = 'deg'; 
trackmethod = 'gc';
interpmethod = 'bilinear';

% other inputs
narginchk(0, 7)

if nargin > 4
    [varargin{:}] = convertStringsToChars(varargin{:});
end

if numel(varargin) == 0 % get from figure
   [map,R] = getrmm;
   [lat,lon] = inputm;
   hasUnitsInput = false;
elseif length(varargin) == 4
   [map,R,lat,lon] = deal(varargin{1:4});
   hasUnitsInput = false;
elseif length(varargin) == 5
   [map,R,lat,lon,rngunits] = deal(varargin{1:5});
   hasUnitsInput = true;
elseif length(varargin) == 6
   [map,R,lat,lon,rngunits,trackmethod] = deal(varargin{1:6});
   hasUnitsInput = true;
elseif length(varargin) == 7
   [map,R,lat,lon,rngunits,trackmethod,interpmethod] = deal(varargin{1:7});
   hasUnitsInput = true;
end

% check if ellipsoid was provided
if isnumeric(rngunits) || isobject(rngunits)
    ellipsoid = checkellipsoid(rngunits,'MAPPROFILE','ELLIPSOID');
    hasUnitsInput = false;
else
    ellipsoid = [];
    if isa(R, 'map.rasterref.GeographicRasterReference') && isscalar(R) ...
            && ~isempty(R.GeographicCRS) && ~isempty(R.GeographicCRS.Spheroid)
        ellipsoid = R.GeographicCRS.Spheroid;
    end
end

checklatlon(lat, lon, mfilename, 'LAT', 'LON', 3, 4)

% check trackmethod
if isempty(trackmethod)
    trackmethod = 'gc';
else
    trackmethod = validatestring(trackmethod, {'gc','rh'}, ...
        'MAPPROFILE', 'TRACMKETHOD', 1);
end

%  Try to ensure vectors don't begin or end with NaNs
if isnan(lat(1)) || isnan(lon(1))
	lat = lat(2:end);
	lon = lon(2:end);
end
if isnan(lat(end)) || isnan(lon(end))
	lat = lat(1:end-1);
	lon = lon(1:end-1);
end

%  If R is already spatial referencing object, validate it. Otherwise
%  convert the input referencing vector or matrix.
R = internal.map.convertToGeoRasterRef( ...
    R, size(map), 'degrees', 'mapprofile', 'R', 2);

% determine distances along the track, starting from zero at the
% beginning of each segment.
[z, rng, lat, lon] = doMapProfile(...
    map, R, lat, lon, ellipsoid, trackmethod, interpmethod);

% Convert ranges to desired distance units. If ellipsoid provided,
% output is in units semimajor axis.
if hasUnitsInput
    rng = deg2dist(rng, rngunits);
end

%if no output arguments, plot results
if nargout == 0   
   outputplot(nargin,numel(lat),lat,lon,rng,z,rngunits)
else
   zout = z;
end

%-----------------------------------------------------------------------

function outputplot(nin,npts,lat,lon,rng,z,rngunits)

% displays output in a new figure

if npts > 2 % plot on a map
   
   if nin == 0
      
      % Display results on a partial copy of the original map (line data only)
      hax = gca;
      hline = handlem('allline');
      mstruct = getm(hax);
      figure
      axesm miller
      set(gca,'UserData',mstruct)
      copyobj(hline,gca);
      
   else
      
      % Display results on a new map
      latlim = [min(lat(:)) max(lat(:))];
      lonlim = [min(lon(:)) max(lon(:))];
      latlim = mean(latlim)+1.5*diff(latlim)*[-1 1];
      lonlim = mean(lonlim)+1.5*diff(lonlim)*[-1 1];
      figure
      worldmap(latlim,lonlim)
      
   end
   
   % plot additional elements on a map axes
   
   framem on; gridm on; mlabel on; plabel on
   
   zdatam('frame',0)
   zdatam('alltext',0)
   zdatam('allline',0)
   zdatam('grid',0)     
   
   plot3m(lat,lon,z,'Tag','mapprofile1')
   plotm(lat,lon,':')
   stem3m(lat(:),lon(:),z(:))
   
   tightmap
   box off
   
   view(3)
   set(gca,'DataAspectRatio', [ 1 1 5*diff(zlim)/max(diff(xlim),diff(ylim))])

else   
   
   % 2-d plot
   figure
   plot(rng,z,'Tag','mapprofile1')
   if ischar(rngunits)
      xlabel(['Range [' rngunits ']' ])
   end
   ylabel 'Value'
   
end

%--------------------------------------------------------------------------

function dist = deg2dist(deg,units)
% Convert from spherical distance in degrees
%
%   DIST = DEG2DIST(DEG, UNITS) converts distances from degrees, as
%   measured along a great circle on a sphere with a radius of 6371 km
%   (the mean radius of the Earth) to the UNITS of length or angle
%   specified by the string  in UNITS.  If UNITS is 'degrees' or
%   'radians', then DIST itself will be a spherical distance.

angleUnits = {'degrees','radians'};
k = find(strncmpi(deblank(units), angleUnits, numel(deblank(units))));
if numel(k) == 1
    % In case units is 'degrees' or 'radians'
    dist = fromDegrees(angleUnits{k}, deg);
else
    % Assume that units specifies a length unit; convert using
    % kilometers as an intermediate unit.
    dist = unitsratio(units,'km') * deg2km(deg);
end

%--------------------------------------------------------------------------

function [z, rng, lat, lon] = doMapProfile(...
    map, R, lat, lon, ellipsoid, trackmethod, interpmethod)
% Core computations performed by MAPPROFILE. R is a geographic raster
% reference object.

% interpolate points to less than the elevation grid spacing
maxsep = 0.9/sampleDensity(R);
if strcmp(trackmethod,'rh')
    [lat,lon] = densifyRhumbline(lat, lon, maxsep, 'deg');
else
    [lat,lon] = densifyGreatCircle(lat, lon, maxsep, 'deg');
end
[latcells,loncells] = polysplit(lat,lon);

% extract the elevation profile

inGrid = ~isnan(lat);
z = NaN + zeros(size(lat));
z(inGrid) = interpGeoRaster(map, R, lat(inGrid), lon(inGrid), interpmethod);

rng = [];
for i=1:numel(latcells)
    leglat = latcells{i};
    leglon = loncells{i};
    
    if isempty(ellipsoid)
        legdist = distance(leglat(1:end-1),leglon(1:end-1),leglat(2:end),leglon(2:end));
    else % ellipsoid provided
        legdist = distance(leglat(1:end-1),leglon(1:end-1),leglat(2:end),leglon(2:end),ellipsoid);
    end
    
    legrng = [0; cumsum(legdist)];
    if i==1
        rng = [rng; legrng]; %#ok<AGROW>
    else
        rng = [rng; NaN;legrng]; %#ok<AGROW>
    end
end
