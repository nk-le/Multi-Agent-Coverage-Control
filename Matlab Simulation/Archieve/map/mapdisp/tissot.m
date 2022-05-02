function hout = tissot(varargin)
%TISSOT  Project Tissot indicatrices on map axes
%
%  TISSOT plots Tissot indicatrices projected onto the
%  current map axes.  A Tissot indicatrix is a small circle
%  which is drawn in a map projection.  If the projection is
%  conformal, then the circle remains a circle on the projection.
%  Otherwise, the circle becomes an ellipse.  On an equal area
%  projection, this ellipse has the same area as the original circle.
%  The Tissot Indicatrices are a graphical tool to demonstrate the
%  distortion associated with a map projection.
%
%  TISSOT('LineSpec') draws the circle using the properties specified by a
%  LineSpec.  Any LineSpec supported by PLOT can be supplied.
%
%  TISSOT('PropertyName',PropertyValue,...) draws the circle using the
%  properties specified.  Any line property can be supplied.
%
%  TISSOT('LineSpec','PropertyName',PropertyValue,...) is a valid form.
%
%  TISSOT(npts,...) uses the data in the vector npts to control the
%  number and location of the indicatrices.  The options for
%  npts are as follows:
%         npts = [Radius of circles]  (in same length unit as equatorial radius)
%         npts = [Lat of circle center, Lon of circle center]
%         npts = [Lat, Lon, Radius]
%         npts = [Lat, Lon, Radius, Number of points per circle]
%  Default values for omitted portions of npts are
%         radius     =  0.1  (0ne tenth of the equatorial radius)
%         lat center =  30   (every 30 degrees)
%         lon center =  30   (every 30 degrees)
%         points     = 100   (100 points per circle)
%
%  h = TISSOT(...) returns the handle to the objects drawn.  These
%  circles are drawn as a single NaN clipped object
%
%  See also SCIRCLE1, SCIRCLE2.

% Copyright 1996-2020 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

%  Validate map axes
ax = getParentAxesFromArgList(varargin);
if ~isempty(ax)
    mstruct = gcm(ax);
else
    mstruct = gcm;
end

%  Default data
maplat    = mstruct.maplatlimit;
maplong   = mstruct.maplonlimit;
ellipsoid = mstruct.geoid;
units     = mstruct.angleunits;

[latlim,longlim] = fromDegrees(units,[ -85    85],[-360   360]);

defaultcen  = fromDegrees(units,[30 30]);
defaultfill = 100;

if isobject(ellipsoid)
    semimajorAxis = ellipsoid.SemimajorAxis;
else
    semimajorAxis = ellipsoid(1);
end
defaultrad = 0.1 * semimajorAxis;

%  Argument error tests

if nargin == 0
    npts = [];
else
    if ischar(varargin{1}) || isStringScalar(varargin{1})
	      npts = [];
	else
	      npts = varargin{1};
          npts = npts(:)';
          varargin(1) = [];
    end
end

%  Check for NPTS to be either empty, or <= 4 elements.  If
%  empty, set the grid altitude to the default.
if isempty(npts)
     radius = defaultrad;
     npts = defaultcen;
     fillpts = defaultfill;
elseif length(npts) == 1
     radius  = npts;
     npts = defaultcen;
     fillpts = defaultfill;
elseif length(npts) == 2
     radius = defaultrad;
     fillpts = defaultfill;
elseif length(npts) == 3
     radius = npts(3);
     npts = npts(1:2);
     fillpts = defaultfill;
elseif length(npts) == 4
     radius = npts(3);
     fillpts = npts(4);
     npts = npts(1:2);
else
     error(['map:' mfilename ':mapdispError'], ...
         'Parameter NPTS must be a vector with 4 elements or less.');
end

%  Construct the lat and long vectors for the entire world

latline  = [fliplr(0:npts(1):latlim(2)), 0:-npts(1):latlim(1) ];
latline  = latline(  latline>=maplat(1)  &  latline<= maplat(2));

longline = [fliplr(0:-npts(2):longlim(1)), 0:npts(2):longlim(2) ];
longline = longline(longline>=maplong(1) & longline<= maplong(2));

if any([isempty(latline),isempty(longline)])
    return
end	

[latgrid,longrid] = ndgrid(latline,longline);
radius = radius(ones(size(latgrid)));

%  Compute the tissot indicatrices and pack them into a single
%  NaN clipped vector

[tissotlat,tissotlon] = scircle1('gc',latgrid(:),longrid(:),...
                                radius(:),[],ellipsoid,units,fillpts);

%  Link all circles into a single NaN clipped vector

r = size(tissotlat,1);

tissotlat(r+1,:) = NaN;
tissotlat = tissotlat(:);

tissotlon(r+1,:) = NaN;
tissotlon = tissotlon(:);

%  Plot the circles

if ~isempty(varargin)
%  Must do varargin before Tag because varargin{1} may be a line spec string
    h = plotm(tissotlat,tissotlon,varargin{:},'Tag','Tissot');
else
    h = plotm(tissotlat,tissotlon,'Tag','Tissot');
end

%  Set the output arguments

if nargout == 1
    hout = h;
end
