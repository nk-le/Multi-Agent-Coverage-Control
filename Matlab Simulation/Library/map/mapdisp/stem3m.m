function hndl = stem3m(lat, lon, z, varargin)
%STEM3M Project stem plot on map axes
%
%  STEM3M(lat,lon,z) constructs a thematic map where a stem of height
%  z is drawn at each lat/lon data point.
%
%  STEM3M(lat,lon,z,'LineSpec') draws each stem using a LineSpec.
%  Any LineSpec supported by PLOT can be used.
%
%  STEM3M(lat,lon,z,'PropertyName',PropertyValue,...) uses the
%  specified line properties to draw the stems.
%
%  h = STEM3M(...) returns the handle of the stem plot.  The stems
%  are drawn as a single NaN clipped line.
%
%  See also SYMBOLM, PLOTM, PLOT.

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

%  Input dimension tests
if ~isequal(size(lat),size(lon),size(z))
    error(message('map:validate:inconsistentSizes3', ...
        'STEM3M','LAT','LON','Z'))
else
    lat = lat(:);
    lon = lon(:);
    z = z(:);
end

if nargin > 3
    [varargin{:}] = convertStringsToChars(varargin{:});
end

%  Test for a valid symbol string
symbolcell = [];
stylecell = [];

if rem(length(varargin),2)
    [lstyle, lcolor, lmark] = internal.map.parseLineSpec(varargin{1});

    varargin(1) = [];
    symbolcell= {};
    stylecell= {};

    if ~isempty(lstyle)
        stylecell{1} = 'LineStyle';
        stylecell{2} = lstyle;
    end

    if ~isempty(lmark)
        symbolcell{1} = 'Marker';
        symbolcell{2} = lmark;
    end

    if ~isempty(lcolor)
        stylecell{length(stylecell)+1} = 'Color';
        stylecell{length(stylecell)+1} = lcolor;
        symbolcell{length(symbolcell)+1} = 'Color';
        symbolcell{length(symbolcell)+1} = lcolor;
    end
end

% Construct the spatial bar chart
latmat = [lat             lat]';
lonmat = [lon             lon]';
altmat = [zeros(size(z))  z  ]';
latmat(3,:) = NaN;
lonmat(3,:) = NaN;
altmat(3,:) = NaN;

%  Display the vertical bar portion of the map
hndl1 = plot3m(latmat(:),lonmat(:),altmat(:));
if ~isempty(stylecell)
    set(hndl1,stylecell{:});
end

if ~isempty(varargin)
    set(hndl1,varargin{:});
end

set(hndl1,'Marker','none');

%  Display the symbol portion of the map
hndl2 = plot3m(lat,lon,z);
if ~isempty(symbolcell)
    set(hndl2,symbolcell{:});
end

if ~isempty(varargin)
    set(hndl2,varargin{:});
end

set(hndl2,'LineStyle','none');

%  Set handle return argument if necessary
if nargout == 1
    hndl = [hndl1; hndl2];
end
