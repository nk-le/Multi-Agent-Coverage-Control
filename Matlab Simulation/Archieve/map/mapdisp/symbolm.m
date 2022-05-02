function hndl = symbolm(varargin)
%SYMBOLM Project point markers with variable size
%
%  SYMBOLM will be removed in a future release. Use SCATTERM instead.
%
%  SYMBOLM(lat,lon,z,'MarkerType') constructs a thematic map where
%  the symbol size of each data point (lat, lon) is proportional to
%  it weighting factor (z).  The point corresponding to min(z) is
%  drawn at the default marker size, and all other points are
%  plotted with proportionally larger markers.  The MarkerType
%  string is a LineSpec string specifying a marker and optionally
%  a color.
%
%  SYMBOLM(lat,lon,z,'MarkerType','PropertyName',PropertyValue,...)
%  applies the line properties to all the symbols drawn.
%
%  SYMBOLM activates a Graphical User Interface to project a symbol
%  plot onto the current map axes.
%
%  h = SYMBOL(...) returns a vector of handles to the projected
%  symbols.  Each symbol is projected as an individual line object.
%
%  See also STEM3M, PLOTM, PLOT.

% Copyright 1996-2016 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

warning(message('map:removing:symbolm','SYMBOLM','SCATTERM'))

narginchk(4,inf)
 
lat = varargin{1};
lon = varargin{2};
z   = varargin{3};
sym = varargin{4};
varargin(1:4) = [];

%  Input dimension tests
if ~isequal(size(lat),size(lon),size(z))
    error(message('map:validate:inconsistentSizes3', ...
        'SYMBOLM','LAT','LON','Z'))
else
    lat = lat(:);
    lon = lon(:);
    z = z(:);
end

%  Test for a valid symbol string
[~, lcolor, lmark] = internal.map.parseLineSpec(sym);

if isempty(lmark)
    error(message('map:validate:symbolNotSpecified'))
end

%  Build up a new property string vector
symbolcell{1} = 'Marker';
symbolcell{2} = lmark;
if ~isempty(lcolor)
    symbolcell{length(symbolcell)+1} = 'Color';
    symbolcell{length(symbolcell)+1} = lcolor;
end

% Construct the data points vector
latmat = [lat   lat]';
lonmat = [lon   lon]';
altmat = zeros(size(latmat));

%  Display the map
h = plot3m(latmat,lonmat,altmat,symbolcell{:});
if ~isempty(varargin)
    set(h,varargin{:});
end

%  Determine if it is necessary to apply default colors to the symbols
%  All symbols will be the same color in this plot
needcolors = 0;
firstclr   = get(h(1),'Color');
for i = 2:length(h)
    currentclr = get(h(i),'Color');
    if any(firstclr ~= currentclr)
        needcolors = 1;
        break
    end
end

%  Set the symbol size proportional to the number of occurrences
%  Ensure uniform symbol color if needcolors == true
minmarker = get(h(1),'MarkerSize');
markervec = minmarker * z / min(z(:));       %  Proportional marker size

for i = 1:length(h)
    if needcolors
        set(h(i),'MarkerSize',markervec(i),'Color',firstclr);
    else
        set(h(i),'MarkerSize',markervec(i));
    end
end

%  Set handle return argument if necessary
if nargout == 1
    hndl = h;
end
