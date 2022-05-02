function [lat, lon] = meshgrat(Z, R, gratsize, angleUnits)
%MESHGRAT  Construct map graticule for surface object display
%
%      MESHGRAT will be removed in a future release.
%      Use geographicGrid or NDGRID instead.
%
%   [LAT, LON] = MESHGRAT(Z, R) constructs a graticule for use in
%   displaying a regular data grid, Z.  In typical usage, a latitude-
%   longitude graticule is projected, and the grid is warped to the
%   graticule using MATLAB graphics functions. In this two-argument
%   calling form, the graticule size is equal to the size Z. R can be a
%   geographic raster reference object, a referencing vector, or a
%   referencing matrix.
%
%   If R is a geographic raster reference object, its RasterSize property
%   must be consistent with size(Z).
%
%   If R is a referencing vector, it must be a 1-by-3 with elements:
%
%     [cells/degree northern_latitude_limit western_longitude_limit]
%
%   If R is a referencing matrix, it must be 3-by-2 and transform raster
%   row and column indices to/from geographic coordinates according to:
% 
%                     [lon lat] = [row col 1] * R.
%
%   If R is a referencing matrix, it must define a (non-rotational,
%   non-skewed) relationship in which each column of the data grid falls
%   along a meridian and each row falls along a parallel.
%
%   [LAT, LON] = MESHGRAT(Z, R, GRATSIZE) produces a graticule of
%   size GRATSIZE.  GRATSIZE is a two-element vector of the form
%
%             [number_of_parallels number_of_meridians].
%
%   If GRATSIZE = [], then the graticule returned has the default size
%   50-by-100. (But if GRATSIZE is omitted, a graticule of the same size
%   as Z is returned.) A finer graticule uses larger arrays and takes
%   more memory and time but produces a higher fidelity map.
%
%   [LAT, LON] = MESHGRAT(LAT, LON) takes the vectors LAT and LON and
%   returns graticule arrays of size numel(LAT)-by-numel(LON). In this
%   form, MESHGRAT is similar to the MATLAB function MESHGRID.
%
%   [LAT, LON] = MESHGRAT(LATLIM, LONLIM, GRATSIZE) returns a graticule
%   mesh of size GRATSIZE that covers the geographic limits defined by
%   the two-element vectors LATLIM and LONLIM.
%
%   [LAT, LON] = MESHGRAT(LAT, LON, ANGLEUNITS),
%   [LAT, LON] = MESHGRAT(LATLIM, LONLIM, ANGLEUNITS), and
%   [LAT, LON] = MESHGRAT(LATLIM, LONLIM, GRATSIZE, ANGLEUNITS) use
%   ANGLEUNITS to specify the angle units of the inputs and outputs.
%   ANGLEUNITS can be either 'degrees' (the default) or 'radians'.
%
%   See also MESHGRID, MESHM, SURFACEM, SURFM

% Copyright 1996-2020 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

unitsflag = 0;  %  Used to control a warning in lat/lon usage

narginchk(2, 4)

if nargin == 2          %  Two arguments defaults to size of Z
    gratsize = size(Z);
    angleUnits = [];
elseif nargin == 3 && (ischar(gratsize) || isstring(gratsize))
    angleUnits = gratsize;
    gratsize = [];
    unitsflag = 1; %  Skip warning
elseif nargin == 3 && ~(ischar(gratsize) || isstring(gratsize))
    angleUnits = [];
end

%  Test of the input gratsize.  If gratsize is empty (three arguments
%  supplied) then use the Mapping Toolbox default graticule size.

if isempty(gratsize)
    gratsize = [50 100];
end

%  Retrieve and set appropriate coordinate data

if min(size(Z)) == 1 && min(size(R)) == 1
    % MESHGRAT(LAT, LON, ...)
    
    lat = Z;
    lon = R;
    
    validateattributes(lat, {'double'}, {'2d'}, 'MESHGRAT', 'LAT', 1)
    validateattributes(lon, {'double'}, {'2d'}, 'MESHGRAT', 'LON', 2)
    
    if isempty(angleUnits)
        angleUnits = 'degrees';
    end
    [lat, lon] = toDegrees(angleUnits, real(lat), real(lon));
        
    if (length(lat) > 2 || length(lon) > 2) && ...
            ((nargin == 3 && ~unitsflag) || nargin == 4)
        warning('map:meshgrat:ignoringGratsize',...
            'Parameter %s ignored with vector %s and/or %s arguments.', ...
            'GRATSIZE', 'LAT', 'LON')
    else
        if isequal(size(gratsize),[2 1])
            gratsize = gratsize';
        end
        validateattributes(gratsize, ...
            {'double'}, {'real','positive','finite','size',[1 2]}, ...
            'MESHGRAT', 'GRATSIZE', 3)
    end
    
    lat = ignoreComplex(lat, mfilename, 'lat');
    lon = ignoreComplex(lon, mfilename, 'lon');
 
    % Use epsilon to eliminate edge collisions (e.g., 0 and 360 degrees).
    epsilon = 1.0E-10;
    
    if isequal(sort(size(lat)),[1 2])
        lat = linspace(min(lat)+epsilon, max(lat)-epsilon, max(gratsize(1),length(lat)));
    end
    if isequal(sort(size(lon)),[1 2])
        lon = linspace(min(lon)+epsilon, max(lon)-epsilon, max(gratsize(2),length(lon)));
    end
    [lon,lat] = meshgrid(lon,lat);
    
    [lat, lon ] = fromDegrees(angleUnits, lat, lon);
    
elseif min(size(Z)) ~= 1
    % MESHGRAT(Z, R, ...)
    
    validateattributes(Z, {'numeric'}, {'2d'}, 'MESHGRAT', 'Z', 1)    
    validateattributes(gratsize, ...
        {'double'}, {'real','positive','finite','size',[1 2]}, ...
        'MESHGRAT', 'GRATSIZE', 3)
        
    % This branch always uses units of degrees.
    R = internal.map.convertToGeoRasterRef( ...
        R, size(Z), 'degrees', mfilename, 'R', 2);
    
    [lat, lon] = map.internal.graticuleFromRasterReference(R, gratsize);
else
    error('map:gratsize:invalidAgumentList', ...
        'Incorrect specification of %s inputs.', 'MESHGRAT')
end

%  Adjust the output arguments if necessary
if nargout ~= 2
    lat = [lat lon];
end
