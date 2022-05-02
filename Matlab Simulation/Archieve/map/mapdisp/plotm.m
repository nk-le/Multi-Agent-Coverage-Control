function hndl = plotm(varargin)
%PLOTM Project 2-D lines and points on map axes
%
%  PLOTM(lat,lon) projects line objects onto the current
%  map axes.  The input latitude and longitude data must be in
%  the same units as specified in the current map axes.
%  PLOTM will clear the current map if the hold state is off.
%
%  PLOTM(lat,lon,'LineSpec') uses any valid LineSpec to display the line
%  object.
%
%  PLOTM(lat,lon,'PropertyName',PropertyValue,...) uses
%  the line object properties specified to display the line
%  objects.  Except for xdata, ydata and zdata, all line properties,
%  and styles available through PLOT are supported by PLOTM.
%
%  PLOTM(mat,...) uses a single input matrix, mat = [lat lon],
%  where the first half of the matrix columns represents the
%  latitude data and the second half of the columns represent
%  longitude data.
%
%  h = PLOTM(...) returns the handles to the line objects displayed.
%
%  See also PLOT3M, PLOT, LINEM, LINE.

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

if nargin == 0
	linem;
    return
else
	lat = varargin{1};
    if nargin >= 2
        lon = varargin{2};
    else
        lon = [];
    end

    if ischar(lon) || isstring(lon) || nargin == 1
        if size(lat,2) < 2
	        error(['map:' mfilename ':mapdispError'], ...
                'Input matrix must have at least two columns')
	    elseif rem(size(lat,2),2)
	        error(['map:' mfilename ':mapdispError'], ...
                'Input matrix must have an even number of columns')
	    else
		    indx = (1 + size(lat,2)/2) : size(lat,2);
		    lon = lat(:,indx);
            lat(:,indx) = [];
        end
        varargin(1) = [];
    else
        varargin(1:2) = [];
    end
end

%  Display the map
nextmap(varargin)
if ~isempty(varargin)
    hndl0 = linem(lat,lon,varargin{:});
else
    hndl0 = linem(lat,lon);
end

%  Set handle return argument if necessary
if nargout == 1
    hndl = hndl0;
end
