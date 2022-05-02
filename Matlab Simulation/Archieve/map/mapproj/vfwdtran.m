function [th,len] = vfwdtran(varargin)
%VFWDTRAN  Direction angle in map plane from azimuth on ellipsoid
%
%  th = VFWDTRAN(lat,lon,az) transforms the azimuth angle at specified 
%  latitude and longitude points on the sphere into the projection space.
%  The map projection currently displayed is used to define the projection
%  space.  The input angles must be in the same units as specified by
%  the current map projection.  The inputs can be scalars or matrices
%  of the equal size. The angle in the projection space is defined 
%  positive counter-clockwise from the x axis.
%
%  th = VFWDTRAN(mstruct,lat,lon,az) uses the map projection defined by the
%  input mstruct to compute the map projection.
%
%  [th,len] = VFWDTRAN(...) also returns the vector length in the projected 
%  coordinate system. A value of 1 indicates no scale distortion.
%
%  This transformation is limited to the region specified by
%  the frame limits in the current map definition.
%
%  See also VINVTRAN, DEFAULTM

% Copyright 1996-2020 The MathWorks, Inc.
% Written by:  E. Byrns, W. Stumpf

%  Parse inputs

if nargin == 3 && ~isstruct(varargin{1})
	  mstruct = [];
      lat   = varargin{1};
	  lon   = varargin{2};
	  az    = varargin{3};
elseif nargin == 4 && isstruct(varargin{1})
	  mstruct = varargin{1};
      lat   = varargin{2};
	  lon   = varargin{3};
	  az    = varargin{4};
else
   error(message('map:validate:invalidArgCount'))	  
end

%  Initialize output

if isempty(mstruct)
   mstruct = gcm;
end

%  Check inputs

checkellipsoid(mstruct.geoid, 'vfwdtran', 'mstruct.geoid');

if ~isequal(size(lat),size(lon),size(az))
    error(message('map:validate:inconsistentSizes3', ...
        'VFWDTRAN','LAT','LON','AZIMUTH'))
end

if strcmp(mstruct.mapprojection,'globe')
    error(message('map:validate:globeNotSupported','VFWDTRAN'))
end

%  Ensure real input

lat = real(lat);
lon = real(lon);
az = real(az);

%  Transform data to degrees

[lat, lon, origin, frmlon, frmlat] = toDegrees(mstruct.angleunits, ...
    lat, lon, mstruct.origin, mstruct.flonlimit, mstruct.flatlimit);

%  Rotate the input data to the base coordinate system.
%  This is the same coordinate system as the map frame.

[LatRot,LonRot] = rotatem(lat,lon,origin,'forward','degrees');

%  Check for points outside the map frame

indx = find(LonRot < min(frmlon) | LonRot > max(frmlon) | ...
            LatRot < min(frmlat) | LatRot > max(frmlat) );

if ~isempty(indx)
   warning(message('map:projections:outsideMapFrame'))
   LatRot(indx)=NaN;
   LonRot(indx)=NaN;
end

%  Check for points near the edge of the map. Back away from 
%  the edges.

% Back away from the poles to avoid problems reckoning. Convergence of
% the meridians makes east-west movements cross the dateline in longitude, 
% even if we back away by a couple of meters.

latlim = 89.9;dlat = 90-latlim;

indx = find(LatRot <= -latlim);
if ~isempty(indx);    LatRot(indx) = LatRot(indx)+dlat;   end   
indx = find(LatRot >= latlim);
if ~isempty(indx);    LatRot(indx) = LatRot(indx)-dlat;   end   

% Back away from the edges

epsilon = 10000*epsm('degrees');

indx = find(LonRot <= min(frmlon)+epsilon);
if ~isempty(indx);    LonRot(indx) = min(frmlon)+epsilon;   end   
indx = find(LonRot >= max(frmlon)-epsilon);
if ~isempty(indx);    LonRot(indx) = max(frmlon)-epsilon;   end   

indx = find(LatRot <= min(frmlat)+epsilon);
if ~isempty(indx);    LatRot(indx) = min(frmlat)+epsilon;   end   
indx = find(LatRot >= max(frmlat)-epsilon);
if ~isempty(indx);    LatRot(indx) = max(frmlat)-epsilon;   end   

%  Return processed data back to the original space

[LatNew,LonNew] = rotatem(LatRot,LonRot,origin,'inverse','degrees');

%  Reckon a point about 10 centimeters off the starting point

epsilon = 10*epsm('degrees');

rng = epsilon*ones(size(LatNew));

[Lat2,Lon2] = reckon('rh',LatNew,LonNew,rng,az,mstruct.geoid,'degrees');
%  Transform to the projection space

[x1,y1] = map.crs.internal.mfwdtran(mstruct,LatNew,LonNew);
[x2,y2] = map.crs.internal.mfwdtran(mstruct,Lat2,Lon2);

%  Compute the angle theta.

th = atan2(y2-y1,x2-x1);
th = npi2pi(th,'radians');
th = fromRadians(mstruct.angleunits,th);

%  Compute the length of the vector

len = hypot(y2 - y1, x2 - x1) ./ rng;
