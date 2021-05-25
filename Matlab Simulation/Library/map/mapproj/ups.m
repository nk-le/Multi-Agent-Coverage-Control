function varargout = ups(varargin)
%UPS Universal Polar Stereographic system
% 
%  This is a perspective projection on a plane tangent to the north or south 
%  pole This projection has two significant properties.  It is conformal, 
%  being free from angular distortion.  Additionally, all great and small 
%  circles are either straight lines or circular arcs on this projection.  
%  
%  This projection has two zones, 'north' and 'south'.  In the northern zone 
%  scale is true along latitude 87 degrees, 7 minutes N, and is constant 
%  along any other parallel.  In the southern zone the latitude of true scale 
%  is 87 degrees, 7 minutes S. This projection is not equal area.
% 
%  This projection is a special case of the stereographic projection in the 
%  polar aspect.  It is used as part of the Universal Transverse Mercator 
%  (UTM) system to extend coverage to the poles.

% Copyright 1996-2008 The MathWorks, Inc.

if nargin == 1
    %  Set defaults (see Snyder, working manual).
    mstruct = varargin{1};
    
    if isempty(mstruct.zone)
		mstruct.zone = 'north';
		mstruct.geoid = [];
		mstruct.maplatlimit = [];
		mstruct.maplonlimit = [];
		mstruct.flatlimit = [];
		mstruct.flonlimit = [];
		mstruct.origin = [];
		mstruct.mlinelocation = [];
		mstruct.plinelocation = [];
		mstruct.mlabellocation = [];
		mstruct.plabellocation = [];
		mstruct.mlabelparallel = [];
		mstruct.plabelmeridian = [];
    end
	
    if strmatch(mstruct.zone,'north')
		trimlatInDegrees = [-Inf 6];
	elseif strmatch(mstruct.zone,'south')
		trimlatInDegrees = [-Inf 10];
    end
	[mstruct.trimlat, mstruct.trimlon] ...
          = fromDegrees(mstruct.angleunits, trimlatInDegrees, [-180 180]);
    mstruct.mapparallels = [];
	mstruct.nparallels   = 0;
	mstruct.fixedorient  = [];
	mstruct.falseeasting = 2000000; % meters
	mstruct.falsenorthing = 2000000; % meters
	mstruct.scalefactor = 0.994;

	varargout = {mstruct};
else
    varargout = cell(1,max(nargout,1));
    [varargout{:}] = stereo(varargin{:});
end
