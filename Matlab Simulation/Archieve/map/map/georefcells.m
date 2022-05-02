function R = georefcells(latlim, lonlim, varargin)
%GEOREFCELLS Reference raster cells to geographic coordinates
%
%   R = GEOREFCELLS() returns a default referencing object for a regular
%   raster of cells in geographic coordinates.
%
%   R = GEOREFCELLS(latlim,lonlim,rasterSize) constructs a referencing
%   object for a raster of cells spanning the specified limits in latitude
%   and longitude, with the numbers of rows and columns specified by
%   rasterSize.
%
%   R = GEOREFCELLS(latlim,lonlim,latcellextent,loncellextent) allows the
%   cell extents in latitude and longitude to be set precisely. The
%   geographic limits will be adjusted slightly, if necessary, to ensure an
%   integer number of cells in each dimension.
%
%   R = GEOREFCELLS(latlim,lonlim,___,Name,Value) allows the directions of
%   the columns and rows to be specified via name-value pairs. Use either
%   'ColumnsStartFrom','south' (the default) or 'ColumnsStartFrom','north'
%   to control the column direction. Likewise, use 'RowsStartFrom','west'
%   (the default) or 'RowsStartFrom','east' to control the row direction.
%
%   All limits and extents are specified in degrees.
%
%   To construct a geographic raster reference object from a world file
%   matrix, use the georasterref function.
%
%   Example
%   -------
%   % Construct a referencing object for a global raster comprising
%   % a grid of 180-by-360 one-degree cells, with rows that start at
%   % longitude -180, and with the first cell located in the northwest
%   % corner. This can be done by specifying either the raster size or the
%   % cell extents.
%
%   latlim = [-90 90];
%   lonlim = [-180 180];
%   rasterSize = [180 360];
%   extent = 1;
%
%   % Specify raster size.
%   R = georefcells(latlim,lonlim,rasterSize,'ColumnsStartFrom','north')
%
%   % Obtain the same result by specifying cell extents.
%   R = georefcells(latlim,lonlim,extent,extent,'ColumnsStartFrom','north')
%
%   See also GEOREFPOSTINGS, MAPREFCELLS, map.rasterref.GeographicCellsReference

% Copyright 2015-2019 The MathWorks, Inc.

    R = map.rasterref.GeographicCellsReference();
    if nargin > 0
        narginchk(3,8)
        R.LatitudeLimits = validateLatitudeLimits(latlim(:)');
        R.LongitudeLimits = validateLongitudeLimits(lonlim(:)');
        
        switch nargin
            case {3,5,7}
                R.RasterSize = varargin{1};
                if nargin > 3
                    R = parseRasterDirection(R, varargin{2:end});
                end

            case {4,6,8}
                cellExtentInLatitude  = varargin{1};
                cellExtentInLongitude = varargin{2};

                validateattributes(cellExtentInLatitude, {'double'}, ...
                    {'real','scalar','finite','positive','<=',180}, ...
                    '', 'cellExtentInLatitude')
                
                if cellExtentInLatitude > R.RasterExtentInLatitude / 2
                    error(message('map:spatialref:exceedsHalfLatlim', ...
                        'cellExtentInLatitude', ...
                        num2str(cellExtentInLatitude), num2str(diff(latlim)/2)))
                end
                
                validateattributes(cellExtentInLongitude, {'double'}, ...
                    {'real','scalar','finite','positive','<=',360}, ...
                    '', 'cellExtentInLongitude')

                R.CellExtentInLatitude = cellExtentInLatitude;
                R.CellExtentInLongitude = cellExtentInLongitude;
                if nargin > 4
                    R = parseRasterDirection(R, varargin{3:end});
                end
        end
    end
end


function latlim = validateLatitudeLimits(latlim)
    validateattributes(latlim, {'double'}, ...
        {'real','finite','size',[1 2],'>=',-90,'<=',90}, '', 'latlim')

    map.internal.assert(latlim(1) < latlim(2), ...
        'map:spatialref:expectedAscendingLimits','latlim')
end


function lonlim = validateLongitudeLimits(lonlim)
    validateattributes(lonlim, ...
        {'double'}, {'real','finite','size',[1 2]}, '', 'lonlim')

    map.internal.assert(lonlim(1) < lonlim(2), ...
        'map:spatialref:expectedAscendingLimits','lonlim')
end
