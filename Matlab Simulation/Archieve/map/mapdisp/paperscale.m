function varargout = paperscale(varargin)
%PAPERSCALE Set figure properties for printing at specified map scale
%  
%   PAPERSCALE(paperdist,'punits',surfdist,'sunits') sets the figure
%   paper position to print the map in the current axes at the desired
%   scale.  The scale is described by the geographic distance which
%   corresponds to a paper distance.  For example, a scale of 1 inch =
%   10 kilometer is specified as PAPERSCALE(1,'inch',10,'km').  See
%   below for an alternate method of specifying the map scale.  The
%   surface distance units 'sunits' can be any units recognized
%   by UNITSRATIO. The paper units value can be any dimensional units
%   recognized for the figure PaperUnits property.
%       
%   PAPERSCALE(paperdist,'punits',surfdist,'sunits',lat,long) sets the
%   paper position so that the scale is correct at the specified
%   geographic location.  If omitted, the default is the center of the
%   map limits.
%  
%   PAPERSCALE(paperdist,'punits',surfdist,'sunits',lat,long,az) also 
%   specifies the direction along which the scale is correct.  If
%   omitted, 90 degrees (east) is assumed.
%  
%   PAPERSCALE(paperdist,'punits',surfdist,'sunits',lat,long,az,'gunits')
%   also specifies the units in which the geographic position and
%   direction are given.  If omitted, 'degrees' is assumed.
%  
%   PAPERSCALE(paperdist,'punits',surfdist,'sunits',lat,long,az,'gunits'
%   ,radius) uses the last input to determine the radius of the sphere.
%   RADIUS can be one of the values supported by KM2DEG, or it can be the
%   (numerical) radius of the desired sphere in the same units as the
%   surface distance.  If omitted, the default radius of the Earth is used.
%  
%   PAPERSCALE(scale,...)  where the numeric scale replaces the two 
%   property-value pairs "paperdist,'punits',surfdist,'sunits'" in the
%   above calling forms, specifies the scale as a ratio between distance
%   on the sphere and on paper.  This is commonly notated on maps as
%   1:scale, e.g. 1:100 000, or 1:1 000 000.  For example,
%   PAPERSCALE(100000) or PAPERSCALE(1000000,lat,long).
%  
%   [paperXdim,paperYdim] = PAPERSCALE(...)  returns the computed paper 
%   dimensions. The dimensions are in the paper units specified. For the
%   scale calling form, the returned  dimensions are in centimeters.
%  
%   See also DASPECTM, KM2DEG.

% Copyright 1996-2020 The MathWorks, Inc.

% Written by: W. Stumpf, A. Kim, T. Debole

% Fill in defaults. Convert all distances and angles to degrees

% Scale specification
if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end
if nargin == 0 % compute scale
   
   scale = 1; 
	coffset = 0; % offset in argument list to handle two basic calling forms

	surfacedist = 1; 
	surfaceunits = 'km';
	paperdist   = 100000/scale; 
	paperunits =   'centimeters';

elseif nargin == 1 || (nargin > 1 && ~ischar(varargin{2})) % scale calling form

	scale = varargin{1}; 
	if nargin > 1
		varargin =  {varargin{2:length(varargin)}};
	end
	coffset = 1; % offset in argument list to handle two basic calling forms

	surfacedist = 1; 
	surfaceunits = 'km';
	paperdist   = 100000/scale; 
	paperunits =   'centimeters';

elseif nargin >= 4 % property value pairs calling form

	paperdist = varargin{1};
	paperunits = varargin{2};
	surfacedist = varargin{3};
	surfaceunits = varargin{4};

	if nargin > 4
		varargin =  {varargin{5:length(varargin)}};
	end
	coffset = 4;

else
	error(message('map:validate:invalidArgCount'))
end

% switch on number of optional arguments

switch nargin - coffset
case 0 % scale only
    lat = mean(getm(gca,'mapLatLim'));
    lon = mean(getm(gca,'mapLonLim'));
    az = 90;    

    mapunits = getm(gca,'angleunits');
    [lat,lon] = toDegrees(mapunits,lat,lon);

	radius = 'earth';

case 2 % scale, lat-long

	lat = varargin{1};
	lon = varargin{2};

    az = 90;    
	radius = 'earth';

case 3 % scale, lat-lon, az

	lat = varargin{1};
	lon = varargin{2};
    az  = varargin{3};    

	radius = 'earth';

case 4 % scale, lat-lon, az, units

	lat = varargin{1};
	lon = varargin{2};
    az  = varargin{3};    
    units = varargin{4};
	
    [lat,lon,az] = toDegrees(units,lat,lon,az);

    radius = 'earth';

case 5 % scale, lat-lon, az, units, radius

	lat = varargin{1};
	lon = varargin{2};
    az  = varargin{3};    
    units = varargin{4};
	
    [lat,lon,az] = toDegrees(units,lat,lon,az);

	radius = varargin{5};

otherwise

	error(message('map:validate:invalidArgCount'))

end

sdistdeg = dist2deg(surfacedist, surfaceunits, radius);

%
% Get the size of the figure and axes
%

axunits = get(gca,'units'); set(gca,'units','Normalized');
axPos = get(gca,'Position');set(gca,'units',axunits);

% Get scaling from spherical to map coordinates.
% Use the center of the map, if a location of correct scale is not
% explicitly specified. Note that the scale of a map is generally 
% specified for the meridian(s) and parallel(s) at which scale is
% true (projection dependent).

% Assume a flat map, two-dimensional view. 

[xo,yo] = map.crs.internal.mfwdtran(lat,lon); % map coordinates 

% Compute geographical and map coordinates of a point displaced 
% the specified distance. 

[nlat,nlon] = reckon(lat,lon,sdistdeg,az);
[xn,yn] = map.crs.internal.mfwdtran(nlat,nlon); % map coordinates

% Compute distance between the two points in map coordinates. Some 
% error is introduced by the difference between arc length and the
% Euclidean distance in the map coordinate system.
% This error is small for small geographic distances.

cxdist = abs(xo-xn);
cydist = abs(yo-yn);

cdist = sqrt(cxdist^2+cydist^2);
theta = abs(atan2(cydist,cxdist));

% To get the length as a fraction of the data limits, pick the larger 
% of the x and y components and use that component to compute required 
% paper position size.

xlim = get(gca,'XLim');
ylim = get(gca,'YLim');
deltaXLim = diff(xlim);
deltaYLim = diff(ylim);

% Compute scale at current paper position and required paper size for requested scale

oldpaperunits = get(gcf,'PaperUnits');
set(gcf,'PaperUnits',paperunits)
oldpaperpos = get(gcf,'PaperPosition');

if cxdist > cydist
    paperXdim = paperdist*deltaXLim/(axPos(3)*cdist*cos(theta));
    paperYdim = paperXdim*deltaYLim/deltaXLim /(axPos(4)/axPos(3));
    oldscale = paperXdim/oldpaperpos(3);
else
    paperYdim = paperdist*deltaYLim/(axPos(4)*cdist*sin(theta));
    paperXdim = paperYdim*deltaXLim/deltaYLim /(axPos(3)/axPos(4));
    oldscale = paperYdim/oldpaperpos(4);
end

if nargin == 0 % compute present scale and bail
   set(gcf,'PaperUnits',oldpaperunits)
   varargout{1} = oldscale;
   return
end

% Set the figure paper position property

set(gcf,'PaperPosition',[1 1 paperXdim paperYdim])

% check that map fits on page

PaperSize=get(gcf,'PaperSize');
if paperXdim > PaperSize(1) || paperYdim >  PaperSize(2)
	warning(message('map:paperscale:figureExceedsPaperSize'))
end

% check that paperunits are dimensional

paperunits = get(gcf,'PaperUnits');
if strcmp(paperunits,'normalized') 
	warning(message('map:paperscale:needAbsolutePaperUnits')) 
end

% restore paper units

set(gcf,'PaperUnits',oldpaperunits)

% center on page 

PaperSize=get(gcf,'PaperSize');
PaperPosition=get(gcf,'PaperPosition');
PaperPosition(1)=(PaperSize(1)-PaperPosition(3))/2;
PaperPosition(2)=(PaperSize(2)-PaperPosition(4))/2;
set(gcf,'PaperPosition',PaperPosition);

% optional output arguments

if nargout >= 1; varargout{1} = paperXdim; end
if nargout == 2; varargout{2} = paperYdim; end
