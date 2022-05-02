function h = fill3m(varargin)
%FILL3M Project filled 3-D patch objects on map axes
%
%  FILL3M(lat,lon,z,cdata) projects 3D patch objects onto the current
%  map axes.  The input latitude and longitude data must be in the same
%  units as specified in the current map axes.  The input cdata defines
%  the patch face color.  If the input vectors are NaN clipped, then
%  a single patch is drawn with multiple faces.  FILL3M will clear the
%  current map if the hold state is off.
%
%  FILLM(lat,lon,z,'PropertyName',PropertyValue,...) uses the patch
%  properties supplied to display the patch.  Except for xdata, ydata
%  and zdata, all patch properties available through FILL3 are supported
%  by FILL3M.
%
%  h = FILL3M(...) returns the handles to the patch objects drawn.
%
%  See also FILLM, FILL, PATCHM, PATCH.

% Copyright 1996-2015 The MathWorks, Inc.

if nargin == 0
	patchm;
    return
end

narginchk(4,inf)

lat = varargin{1};
lon = varargin{2};
z = varargin{3};
varargin(1:3) = [];

%  Display the map
nextmap(varargin);
h0 = patchm(lat,lon,z,varargin{:});

% Assign output arguments if specified
if nargout > 0
    h = h0;
end
