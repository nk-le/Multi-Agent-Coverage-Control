function daspectm(zunits,vfac,lat,lon,az,varargin)
%DASPECTM Control vertical exaggeration in map display
%
%   DASPECTM('zunits') sets the DataAspectRatio property of the map axes so
%   that the z axis is in proportion to the x and y projected coordinates.
%   This permits elevation data to be displayed without vertical
%   distortion. 'zunits' specifies the units of the elevation data, and can
%   be any length unit recognized by UNITSRATIO.
%
%   DASPECTM('zunits',vfac) sets the DataAspectRatio property so that the z
%   axis is vertically exaggerated by the factor vfac. If omitted, the
%   default is no vertical exaggeration.
%   
%   DASPECTM('zunits',vfac,lat,long) sets the aspect ratio based  on the
%   local map scale at the specified geographic location.  If omitted, the
%   default is the center of the map limits.
%
%   DASPECTM('zunits',vfac,lat,long,az) also specifies the direction  along
%   which the scale is computed. If omitted, 90 degrees (west)  is assumed.
%
%   DASPECTM('zunits',vfac,lat,long,az,radius)  uses the last input to
%   determine the radius of the sphere.  RADIUS can be one of the values
%   supported by KM2DEG, or it can be the (numerical) radius of the
%   desired sphere in zunits. If omitted, the default radius of the Earth
%   is used.
%
%   See also DASPECT, KM2DEG, PAPERSCALE

% Copyright 1996-2017 The MathWorks, Inc. 
% Written by: W. Stumpf, A. Kim, T. Debole

if nargin < 1 || nargin > 7 || nargin == 3
    error(message('map:validate:invalidArgCount'))
end

zunits = convertStringsToChars(zunits);
if nargin > 5
    [varargin{:}] = convertStringsToChars(varargin{:});
end

% Support old syntax:
%  daspectm(zunits,vfac,lat,lon,az,angleunits,radius)
if nargin == 6

   % radius or unit
   if ischar(varargin{1})
      strlist = {'earth','mercury','venus','moon', ...
                 'mars','jupiter','saturn','uranus', ...
                 'neptune','pluto','sun'};
      indx = find(strncmpi(varargin{1},strlist,length(varargin{1})));
      if ~isempty(indx) && (numel(indx) == 1)
         radius = strlist{indx};
      else
         radius = 'earth';
      end

    else
       radius = varargin{1};
    end

elseif nargin == 7
   radius = varargin{2};
else
   radius = 'earth'; 
end

% fill in values of optional arguments
if nargin < 5 
   az = 90;
end
mstruct = gcm;
if nargin < 4
    [lat, lon] = frameCenter(mstruct);
end
if nargin < 2
   vfac = 1;
end

% check for globe
if strcmp(getm(gca,'mapprojection'),'globe')
   error(message('map:daspectm:invalidAspectRatio'))
end

% Cartesian coordinates of starting point
[xo,yo] = feval(mstruct.mapprojection,mstruct,lat,lon,'geopoint','forward');
if isempty(xo)
    warning(message('map:daspectm:pointOutsideFrame',num2str([lat,lon])))
    [lat, lon] = frameCenter(mstruct);
    [xo,yo] = feval(mstruct.mapprojection,mstruct,lat,lon,'geopoint','forward');
end

% Geographical and paper coordinates of a point downrange
sdist = fromDegrees(mstruct.angleunits,dist2deg(1, zunits, radius));
[nlat,nlon] = reckon(lat,lon,sdist,az,mstruct.angleunits);
[xn,yn] = feval(mstruct.mapprojection,mstruct,nlat,nlon,'geopoint','forward');

% Distance between two points in Cartesian coordinates
cdist = hypot(xo - xn, yo - yn);

% Set the DataAspectRatio
zratio = 1/(cdist*vfac);
dataspectratios = [1 1 zratio];
set(gca,'DataAspectRatio',dataspectratios)

%-----------------------------------------------------------------------

function [lat, lon] = frameCenter(mstruct)
% Latitude and longitude of the center of the map frame

projectionIsAzimuthal = (mstruct.flatlimit(1) == -Inf);
if projectionIsAzimuthal
    % The map is centered on the origin.
    lat = mstruct.origin(1);
    lon = mstruct.origin(2);
else
    % The map is centered on the frame limits which might not be
    % centered on the origin; compute the frame center in rotated
    % coordinates and transform it back to geographic coordinates.
    [lat,lon] = rotatem( ...
        sum(mstruct.flatlimit)/2, ...
        sum(mstruct.flonlimit)/2, ...
        mstruct.origin,'inverse',mstruct.angleunits);
end
