function proj = getProjection(varargin)
%GETPROJECTION Get projection structure
%
%   PROJ = GETPROJECTION(VARARGIN) returns the projection structure from
%   the variable list of arguments in VARARGIN. If the arguments do not
%   contain the name-value pair, 'Parent',axes, then PROJ is the default
%   Plate Carree projection.
%
%   See also GEOSHOW, GEOSTRUCTSHOW, GEOVECSHOW.

% Copyright 2006-2015 The MathWorks, Inc.

% Find the Parent parameter from the inputs,
default = [];
parent = map.internal.findNameValuePair('Parent', default, varargin{:});

% If not found, set the parent to gca.
if isempty(parent)
   parent = gca;
end

% Verify that the parent is a valid axis handle and contains a proj struct.
% If true, obtain the projection structure; otherwise, return a default
% projection.
validAxesHandle = isscalar(parent) && ishghandle(parent,'axes');
if validAxesHandle
   proj = get(parent,'UserData');
   if ~isstruct(proj) && ~isfield(proj,'mapprojection')
      proj = getDefaultProjection;
   end
else
   proj = getDefaultProjection;
end

%--------------------------------------------------------------------------
function proj = getDefaultProjection
% Create a default Plate Carree projection structure.  
% Use a scalefactor of 180/pi to scale the natural map units (for an earth
% radius of unity) to degrees.

proj = defaultm('pcarree');
proj.scalefactor = 180/pi;
proj = defaultm(proj);
