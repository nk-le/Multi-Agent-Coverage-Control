function [out1, out2, out3] = inputm(npts,hndl)
%INPUTM  Return latitudes and longitudes of mouse click locations
%
%   [LAT, LON] = INPUTM returns the latitudes and longitudes in geographic
%   coordinates of points selected by mouse clicks on a displayed map. The
%   point selection continues until the return key is pressed. Points 
%   outside the projection bounds are ignored.
%
%   [LAT, LON] = INPUTM(N) returns N points specified by mouse clicks.
%
%   [LAT, LON] = INPUTM(N,H) prompts for points from the map axes specified
%   by the handle H.  If omitted, the current axes (gca) is assumed.
%
%   [LAT, LON, BUTTON] = INPUTM(N) returns a third result, BUTTON, that
%   contains a vector of integers specifying which mouse button was used
%   (1,2,3 from left) or ASCII numbers if a key on the keyboard was used.
%
%   MAT = INPUTM(...) returns a single matrix, where MAT = [LAT LON].
%
%   Note
%   ----
%   INPUTM cannot be used with a 3-D display, including those created
%   using GLOBE.
%
%   See also GINPUT.

% Copyright 1996-2016 The MathWorks, Inc.

if nargin == 0
    npts = [];     
    hndl = [];
elseif nargin == 1
    hndl = [];
end

if isempty(hndl)
    hndl = get(get(0,'CurrentFigure'),'CurrentAxes');
    if isempty(hndl)
        error(['map:' mfilename ':mapdispError'], 'No axes in current figure')
    end
end

% Ensure that handle object is an axes.
gcm(hndl);

% Make HNDL the current axes.
axes(hndl)

% Test for 2D view.  Does not work on 3D views.
if any(get(gca,'view') ~= [0 90])
    btn = questdlg( {'Must be in 2D view for operation.',...
                     'Change to 2D view?'},...
                      'Incorrect View','Change','Cancel','Change');

    switch btn
        case 'Change'      
            view(2);
        case 'Cancel'      
            out1 = [];  
            out2 = [];  
            out3 = []; 
            return
    end
end

% Select points on the map.
if isempty(npts)
    [x,y,out3] = ginput;
else
    [x,y,out3] = ginput(npts);
end

% Compute the inverse transformation for the selected point.
mstruct = gcm(hndl);
[lat, long] = feval(mstruct.mapprojection, mstruct, x, y, ...
   'none', 'inverse');

% Forward project the lat, long points to validate if the user clicked
% within the limits of the map.
outOfBounds = false(size(lat));
tol = 1e-4;
for k=1:numel(lat)
   [xCalc, yCalc] = feval(mstruct.mapprojection, mstruct, lat(k), long(k), ...
      'geopoint', 'forward');
   xOutOfBound = isempty(xCalc) || max(abs(x(k) - xCalc)) > tol;
   yOutOfBound = isempty(yCalc) || max(abs(y(k) - yCalc)) > tol;
   outOfBounds(k) = xOutOfBound || yOutOfBound;
end
lat(outOfBounds)  = [];
long(outOfBounds) = [];

% Set output arguments.
if nargout <= 1
    out1 = [lat long];
else
    out1 = lat;  
    out2 = long;
end
