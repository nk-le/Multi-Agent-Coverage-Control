function h = fillm(varargin)
%FILLM Project filled 2-D patch objects on map axes
%
%  FILLM(lat,lon,cdata) projects 2D patch objects onto the current
%  map axes.  The input latitude and longitude data must be in the same
%  units as specified in the current map axes.  The input cdata defines
%  the patch face color.  If the input vectors are NaN clipped, then
%  a single patch is drawn with multiple faces.  FILLM will clear the
%  current map if the hold state is off.
%
%  FILLM(lat,lon,'PropertyName',PropertyValue,...) uses the patch
%  properties supplied to display the patch.  Except for xdata, ydata
%  and zdata, all patch properties available through FILL are supported
%  by FILLM.
%
%  h = FILLM(...) returns the handles to the patch objects drawn.
%
%  See also FILL3M, FILL, PATCHM, PATCH.

% Copyright 1996-2015 The MathWorks, Inc.

if nargin == 0
	patchm;  
    return
end

narginchk(3,inf)

lat = varargin{1};
lon = varargin{2};
varargin(1:2) = [];

%  Display the map
nextmap(varargin);

h0 = patchm(lat,lon,varargin{:});

% Assign output arguments if specified
if nargout > 0
    h = h0;
end
