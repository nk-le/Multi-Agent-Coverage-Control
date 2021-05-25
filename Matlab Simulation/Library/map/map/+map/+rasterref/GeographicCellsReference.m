classdef (Sealed = true) GeographicCellsReference ...
    < map.rasterref.GeographicRasterReference & matlab.mixin.CustomDisplay
%GeographicCellsReference Reference raster cells to geographic coordinates
%
%   To construct a map.rasterref.GeographicCellsReference object, use
%   the georefcells function or the georasterref function.
%
%   Class Description
%   -----------------
%   map.rasterref.GeographicCellsReference properties:
%      LatitudeLimits - Latitude limits [southern_limit northern_limit]
%      LongitudeLimits - Longitude limits [western_limit eastern_limit]
%      RasterSize - Number of cells or samples in each spatial dimension
%      ColumnsStartFrom - Edge where column indexing starts: 'south' or 'north'
%      RowsStartFrom - Edge where row indexing starts: 'west' or 'east'
%      CellExtentInLatitude - Extent in latitude of individual cells
%      CellExtentInLongitude - Extent in longitude of individual cells
%
%   map.rasterref.GeographicCellsReference properties (read-only):
%      RasterExtentInLatitude - Extent in latitude of the full raster
%      RasterExtentInLongitude - Extent in longitude of the full raster
%      XIntrinsicLimits - Limits of raster in intrinsic X [xMin xMax]
%      YIntrinsicLimits - Limits of raster in intrinsic Y [yMin yMax]
%      RasterInterpretation - Geometric nature of raster (constant: 'cells')
%      CoordinateSystemType - Type of external system (constant: 'geographic')
%      AngleUnit - Unit of angle used for angle-valued properties
%
%   map.rasterref.GeographicCellsReference methods:
%      sizesMatch - True if object and raster or image are size-compatible
%      intrinsicToGeographic - Transform intrinsic to geographic coordinates
%      geographicToIntrinsic - Transform geographic to intrinsic coordinates
%      intrinsicYToLatitude  - Transform intrinsic Y to latitude
%      intrinsicXToLongitude - Transform intrinsic X to longitude
%      latitudeToIntrinsicY  - Transform latitude to intrinsic Y
%      longitudeToIntrinsicX - Transform longitude to intrinsic X
%      geographicToDiscrete - Transform geographic to discrete coordinates
%      contains - True if raster contains latitude-longitude points
%      geographicGrid - Geographic coordinates of raster elements
%      worldFileMatrix - World file parameters for transformation
%
%   See also georefcells, georasterref

% Copyright 2013-2020 The MathWorks, Inc.

    %---- Constant property that helps make the class self-descriptive ----
    
    properties (Constant)
        % RasterInterpretation Geometric nature of raster
        % 
        %   RasterInterpretation, which controls handling of raster edges,
        %   among other things, has the constant value 'cells'. This
        %   indicates that the raster comprises a grid of quadrangular
        %   cells, and is bounded on all sides by cell edges. For an M-by-N
        %   raster, points with an intrinsic X-coordinate of 1 or N or an
        %   intrinsic Y-coordinate of 1 or M fall within the raster, not on
        %   its edges.
        RasterInterpretation = 'cells';
    end

    %-------- Concrete declarations of abstract superclass properties ------
    
    properties (SetAccess = protected, Transient = true)
        % XIntrinsicLimits - Limits of raster in intrinsic X [xMin xMax]
        %
        %    XIntrinsicLimits is a two-element row vector. For an M-by-N
        %    raster it equals [0.5, N + 0.5].
        XIntrinsicLimits;
        
        % YIntrinsicLimits - Limits of raster in intrinsic Y [yMin yMax]
        %
        %    YIntrinsicLimits is a two-element row vector. For an M-by-N
        %    raster it equals [0.5, M + 0.5].
        YIntrinsicLimits;
    end
    
    properties (Access = protected)
        Intrinsic = map.rasterref.internal.IntrinsicCellsReference;
        
        % Latitude of the outermost corner of the first (1,1) cell
        FirstCornerLatitude = 0.5;
        
        % Longitude of the outermost corner of the first (1,1) cell
        FirstCornerLongitude = 0.5;
    end
    
    properties (Constant, Access = protected)
        % Number of rows or columns ("elements") minus number of intervals
        % of width CellExtentInLatitude or CellExtentInLongitude. Equal to
        % both:
        %
        %    R.RasterSize(1) - intervalsInLatitude
        %    R.RasterSize(2) - intervalsInLongitude
        %
        % where:
        %
        %   intervalsInLatitude = R.RasterExtentInLatitude / R.CellExtentInLatitude
        %   intervalsInLongitude = R.RasterExtentInLongitude / R.CellExtentInLongitude
        ElementsMinusIntervals = 0;
    end

    %------------------ Add in CellExtent properties ----------------------
    
    properties (Dependent)
        % CellExtentInLatitude Extent in latitude of individual cells
        %
        %     Distance, in units of latitude, between the northern and
        %     southern limits of a single raster cell. The value is always
        %     positive, and is the same for all cells in the raster.
        CellExtentInLatitude
        
        % CellExtentInLongitude Extent in longitude of individual cells
        %
        %     Distance, in units of longitude, between the western and
        %     eastern limits of a single raster cell. The value is always
        %     positive, and is the same for all cells in the raster.
        CellExtentInLongitude
    end
    
    methods
        function extent = get.CellExtentInLatitude(R)
            extent = abs(R.DeltaLatitudeNumerator ...
                / R.DeltaLatitudeDenominator);
        end
        
        
        function extent = get.CellExtentInLongitude(R)
            extent = abs(R.DeltaLongitudeNumerator ...
                / R.DeltaLongitudeDenominator);
        end
        
        
        function R = set.CellExtentInLatitude(R, cellExtentInLatitude)
            fname = 'map.rasterref.GeographicCellsReference.set.CellExtentInLatitude';
            validateattributes(cellExtentInLatitude, {'double'}, ...
                {'real','scalar','finite','positive','<=',180}, fname, 'CellExtentInLatitude')
            if cellExtentInLatitude > R.RasterExtentInLatitude / 2
                error(message('map:spatialref:exceedsHalf', ...
                    'CellExtentInLatitude', 'RasterExtentInLatitude', ...
                    num2str(R.RasterExtentInLatitude/2)))
            end
            R = setAbsoluteDeltaLatitude(R, cellExtentInLatitude);
        end
        
        
        function R = set.CellExtentInLongitude(R, cellExtentInLongitude)
            fname = 'map.rasterref.GeographicCellsReference.set.CellExtentInLongitude';
            validateattributes(cellExtentInLongitude, {'double'}, ...
                {'real','scalar','finite','positive','<=',360}, fname, 'CellExtentInLongitude')
            R = setAbsoluteDeltaLongitude(R, cellExtentInLongitude);
        end
    end
    
    %------------------- geographicToDiscrete Alternative -----------------
    
    methods (Hidden)
        function [row, col, outside] = geographicToDiscreteOmitOutside(R, lat, lon)
            % Supports behavior of older functions, including imbedm.
            %
            % Results match geographicToDiscrete(R,lat,lon) except that:
            %
            %   * row and col are returned as vectors.
            %
            %   * When a point specified by (lat,lon) falls outside the
            %     raster limits, the elements corresponding to that point
            %     are omitted from row and col.
            %
            %   * A linear index to the elements of lat and lon that
            %     correspond to points falling outside the limits is
            %     returned as a vector in outside.
            %
            %   * When a point specified by lat and lon falls exactly on
            %     a cell boundary. In that case, the row or column index of
            %     the adjacent cell with the smaller index is returned,
            %     instead of the index of the cell with the larger index.
            
            
            % Find points outside raster, remove from further processing.
            outside = find(~contains(R, lat, lon));
            lat(outside) = [];
            lon(outside) = [];
            
            % Row and column subscripts
            minInternalLimit = 0.5;  % For GeographicCellsReference object
            row = ceil(latitudeToIntrinsicY(R, lat)  - minInternalLimit);
            col = ceil(longitudeToIntrinsicX(R, lon) - minInternalLimit);
            
            % Even though we've already eliminated all inputs that fall
            % outside the grid, it's still posssible for roundoff effects
            % in the preceding four lines to cause out-of-range results.
            % Avoid that by clamping to valid limits.
            row = max(row, 1);
            col = max(col, 1);
            row = min(row, R.RasterSize(1));
            col = min(col, R.RasterSize(2));
        end
    end
    
    %------------------------- save/load object ---------------------------
    
    methods (Hidden)
        function S = saveobj(R)
            % Use a protected superclass method to encode the defining
            % properties of the geographic raster reference object R into
            % structure S.
            S = encodeInStructure(R);
        end
    end
    
    
    methods (Static, Hidden)
        function R = loadobj(S)
            % Construct a default map.rasterref.GeographicCellsReference
            % object and use a protected superclass method to reset its
            % defining properties.
            R = map.rasterref.GeographicCellsReference;
            R = resetFromStructure(R,S);
        end
        
    end
    
    %--------------------------- Construction -----------------------------
    
    methods
        function R = GeographicCellsReference( ...
                rasterSize, firstCornerLat, firstCornerLon, ...
                deltaLatNumerator, deltaLatDenominator, ...
                deltaLonNumerator, deltaLonDenominator)
            %   R = map.rasterref.GeographicCellsReference( ...
            %       rasterSize, firstCornerLat, firstCornerLon, ...
            %       deltaLatNumerator, deltaLatDenominator, ...
            %       deltaLonNumerator, deltaLonDenominator)
            %   constructs a geographic raster referencing object from the
            %   following inputs (all 7 must be provided):
            %
            %     rasterSize -- A valid MATLAB size vector (as returned
            %        by SIZE) corresponding to the size of a raster or
            %        image to be used in conjunction with the referencing
            %        rasterSize must have at least two elements, but may
            %        have more. In this case only the first two
            %        (corresponding to the "spatial dimensions") are used
            %        and the others are ignored. For example, if rasterSize
            %        = size(RGB) where RBG is an RGB image, the rasterSize
            %        will have the form [M N 3] and the RasterSize property
            %        will be set to [M N].  M and N must be strictly
            %        positive.
            %
            %     firstCornerLat, firstCornerLon -- Scalar values
            %        defining the latitude and longitude position of the
            %        outermost corner of the first cell (1,1) of the
            %        raster.
            %
            %     deltaLatNumerator   -- Nonzero real number
            %     deltaLatDenominator -- Positive real number
            %
            %        The ratio deltaLatNumerator/deltaLatDenominator
            %        defines a signed north-south cell size.  A positive
            %        value indicates that columns run from south to north,
            %        whereas a negative value indicates that columns run
            %        from north to south.
            %
            %     deltaLonNumerator   -- Nonzero real number
            %     deltaLonDenominator -- Positive real number
            %
            %        The ratio deltaLonNumerator/deltaLonDenominator
            %        defines a signed east-west cell size.  A positive
            %        value indicates that rows run from west to east,
            %        whereas a negative value indicates that rows run from
            %        east to west.
            %
            %   Example 1
            %   ---------
            %   % Construct a referencing object for a global raster
            %   % comprising 180-by-360 one-degree cells, with rows that
            %   % start at longitude -180, and with the first cell
            %   % located in the northwest corner.
            %   R = map.rasterref.GeographicCellsReference( ...
            %       [180 360], 90, -180, -1, 1, 1, 1)
            %
            %   Example 2
            %   ---------
            %   % Construct a referencing object for the GTOPO30
            %   % tile that includes Sagarmatha (Mount Everest).
            %   R = map.rasterref.GeographicCellsReference( ...
            %        [120 120], 27, 86, 1, 120, 1, 120)
            
            if nargin == 7
                % Set the raster size first, because it determines the
                % values of the intrinsic limit properties.
                R.RasterSize = rasterSize;
                
                R = R.setLatitudeProperties( ...
                    firstCornerLat, deltaLatNumerator, deltaLatDenominator);
                
                R = R.setLongitudeProperties( ...
                    firstCornerLon, deltaLonNumerator, deltaLonDenominator);
            else
                % There must be exactly 7 inputs, or none.
                map.internal.assert(nargin == 0, ...
                    'map:validate:invalidArgCount')
            end
        end
    end
    
    %-------------------------- Custom display ----------------------------
    
    methods (Access = protected)
        function displayScalarObject(R)
            % Provide a custom display for the case in which the
            % referencing object R is scalar. Override the default property
            % order, and display the cell extent values as ratios if
            % appropriate.
            
            % The default header is fine.
            header = getHeader(R);
            disp(header)
 
            % Customize the property order.
            props = {
                'LatitudeLimits'
                'LongitudeLimits'
                'RasterSize'
                'RasterInterpretation'
                'ColumnsStartFrom'
                'RowsStartFrom'
                'CellExtentInLatitude'
                'CellExtentInLongitude'
                'RasterExtentInLatitude'
                'RasterExtentInLongitude'
                'XIntrinsicLimits'
                'YIntrinsicLimits'
                'CoordinateSystemType'
                'GeographicCRS'
                'AngleUnit'
                };

            % Always use format longG; restore current format when done.
            fmt = get(0,'format');
            clean = onCleanup(@() format(fmt));
            format('longG')

            % Construct a ready-to-display string listing the scalar
            % property names and their values.            
            values = cellfun(@(propertyName) R.(propertyName), ...
                props, 'UniformOutput', false);
            s = cell2struct(values, props, 1); %#ok<NASGU>
            str = evalc('builtin(''disp'', s)');
            
            % Override the format for the CellExtentInLatitude property,
            % if it would be more informative to display a ratio than a
            % decimal number.
            if map.rasterref.internal.ratioIsBetterThanDecimal( ...
                    R.DeltaLatitudeNumerator, R.DeltaLatitudeDenominator)
                str = map.rasterref.internal.replaceValueWithRatio( ...
                    str, 'CellExtentInLatitude', ...
                    abs(R.DeltaLatitudeNumerator), R.DeltaLatitudeDenominator);
            end
            
            % Likewise for the CellExtentInLongitude property.
            if map.rasterref.internal.ratioIsBetterThanDecimal( ...
                    R.DeltaLongitudeNumerator, R.DeltaLongitudeDenominator)
                str = map.rasterref.internal.replaceValueWithRatio( ...
                    str, 'CellExtentInLongitude', ...
                    abs(R.DeltaLongitudeNumerator), R.DeltaLongitudeDenominator);
            end
            
            % Display the modified string.
            disp(str)
            
            % Allow for the possibility of a footer.
            footer = getFooter(R);
            if ~isempty(footer)
                disp(footer);
            end
        end
    end
    
    %----------------------------- Abstract -------------------------------
    
    methods (Access = protected)
        function tf = is360DegreeRasterWithDuplicateColumns(~)
            tf = false;
        end
    end
end
