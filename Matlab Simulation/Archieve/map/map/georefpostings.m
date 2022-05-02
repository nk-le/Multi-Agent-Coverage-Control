function R = georefpostings(latlim, lonlim, varargin)
%GEOREFPOSTINGS Reference raster postings to geographic coordinates
%
%   R = GEOREFPOSTINGS() returns a default referencing object for a raster
%   of regularly posted samples in geographic coordinates.
%
%   R = GEOREFPOSTINGS(latlim,lonlim,rasterSize) constructs a referencing
%   object for a raster spanning the specified limits in latitude and
%   longitude, with the numbers of rows and columns specified by
%   rasterSize.
%
%   R = GEOREFPOSTINGS(latlim,lonlim,latspacing,lonspacing) allows the
%   sample spacings in latitude and longitude to be set precisely. The
%   geographic limits will be adjusted slightly, if necessary, to ensure an
%   integer number of samples in each dimension.
%
%   R = GEOREFPOSTINGS(latlim,lonlim,___,Name,Value) allows the directions of
%   the columns and rows to be specified via name-value pairs. Use either
%   'ColumnsStartFrom','south' (the default) or 'ColumnsStartFrom','north'
%   to control the column direction. Likewise, use 'RowsStartFrom','west'
%   (the default) or 'RowsStartFrom','east' to control the row direction.
%
%   All limits and spacings are specified in degrees.
%
%   To construct a geographic raster reference object from a world file
%   matrix, use the GEORASTERREF function.
%
%   Example
%   -------
%   % Construct a referencing object for a global raster comprising a
%   % 181-by-361 grid of samples with 1-degree spacing, with rows that
%   % start at longitude -180, and with the first sample located in the
%   % northwest corner. This can be done by specifying either the raster
%   % size or the sample spacings.
%
%   latlim = [-90 90];
%   lonlim = [-180 180];
%   rasterSize = [181 361];
%   spacing = 1;
%
%   % Specify raster size.
%   R = georefpostings(latlim,lonlim,rasterSize,'ColumnsStartFrom','north')
%
%   % Obtain the same result by specifying sample spacings.
%   R = georefpostings(latlim,lonlim,spacing,spacing,'ColumnsStartFrom','north')
%
%   See also GEOREFCELLS, MAPREFPOSTINGS, map.rasterref.GeographicPostingsReference

% Copyright 2015-2019 The MathWorks, Inc.

    R = map.rasterref.GeographicPostingsReference();
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
                sampleSpacingInLatitude  = varargin{1};
                sampleSpacingInLongitude = varargin{2};

                validateattributes(sampleSpacingInLatitude, {'double'}, ...
                    {'real','scalar','finite','positive','<=',180}, ...
                    '', 'sampleSpacingInLatitude')
                
                if sampleSpacingInLatitude > R.RasterExtentInLatitude
                    error(message('map:spatialref:exceedsLatlim', ...
                        'sampleSpacingInLatitude', ...
                        num2str(sampleSpacingInLatitude), num2str(diff(latlim))))
                end
                
                validateattributes(sampleSpacingInLongitude, {'double'}, ...
                    {'real','scalar','finite','positive','<=',360}, ...
                    '', 'sampleSpacingInLongitude')

                R.SampleSpacingInLatitude = sampleSpacingInLatitude;
                R.SampleSpacingInLongitude = sampleSpacingInLongitude;
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
