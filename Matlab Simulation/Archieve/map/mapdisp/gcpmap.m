function pt = gcpmap(hndl)
%GCPMAP Get current mouse point from map axes
%
%  mat = GCPMAP will compute the current point on a map axes
%  in Greenwich coordinates.  GCPMAP works much like
%  get(gca,'CurrentPoint') except that the returned
%  matrix is [lat lon z], not [x y z].
%
%  mat = GCPMAP(h) returns the current map point from the axes
%  specified by the handle h.
%
%  You must use VIEW(2) and an ordinary projection (not the Globe
%  projection) when working with the GCPMAP function.
%
%  See also INPUTM.

% Copyright 1996-2020 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

if nargin == 0
    hndl = get(get(0,'CurrentFigure'),'CurrentAxes');
    if isempty(hndl)
        error(['map:' mfilename ':noAxesInFigure'], ...
            'No axes in current figure.')
    end
end

%  Ensure that handle object is an axes.
gcm(hndl);

%  Get the current point
pt = get(hndl,'CurrentPoint');
x = pt(:,1);
y = pt(:,2);
z = pt(:,3);

%  Compute the inverse transformation for the selected projection
%  Use text as an object to represent a point calculation
[lat,long] = map.crs.internal.minvtran(x,y,z);

%  Set the output matrix
pt = [lat long pt(:,3)];
