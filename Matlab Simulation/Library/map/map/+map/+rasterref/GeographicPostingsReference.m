classdef (Sealed = true) GeographicPostingsReference ...
    < map.rasterref.GeographicRasterReference & matlab.mixin.CustomDisplay
 %GeographicPostingsReference Reference raster postings to geographic coordinates
%
%   To construct a map.rasterref.GeographicPostingsReference object, use
%   the georefpostings function or the georasterref function.
%
%   Class Description
%   -----------------
%   map.rasterref.GeographicPostingsReference properties:
%      LatitudeLimits - Latitude limits [southern_limit northern_limit]
%      LongitudeLimits - Longitude limits [western_limit eastern_limit]
%      RasterSize - Number of cells or samples in each spatial dimension
%      ColumnsStartFrom - Edge where column indexing starts: 'south' or 'north'
%      RowsStartFrom - Edge where row indexing starts: 'west' or 'east'
%      SampleSpacingInLatitude - Distance in latitude between adjacent samples
%      SampleSpacingInLongitude - Distance in longitude between adjacent samples
%
%   map.rasterref.GeographicPostingsReference properties (read-only):
%      RasterExtentInLatitude - Extent in latitude of the full raster
%      RasterExtentInLongitude - Extent in longitude of the full raster
%      XIntrinsicLimits - Limits of raster in intrinsic X [xMin xMax]
%      YIntrinsicLimits - Limits of raster in intrinsic Y [yMin yMax]
%      RasterInterpretation - Geometric nature of raster (constant: 'postings')
%      CoordinateSystemType - Type of external system (constant: 'geographic')
%      AngleUnit - Unit of angle used for angle-valued properties
%
%   map.rasterref.GeographicPostingsReference methods:
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
%   See also georefpostings, georasterref

 % Copyright 2013-2020 The MathWorks, Inc.
 
     %--- Constant property that helps make the class self-descriptive ----
  
     properties (Constant)
        % RasterInterpretation Geometric nature of raster
        % 
        %   RasterInterpretation, which controls handling of raster edges,
        %      among other things, has the constant value 'postings'. This
        %      indicates that the raster comprises a grid of sample points,
        %      where rows or columns of samples run along the edge of the
        %      grid. For an M-by-N raster, points with an intrinsic
        %      X-coordinate of 1 or N and/or an intrinsic Y-coordinate of 1
        %      or M fall right on an edge (or corner) of the raster.
        RasterInterpretation = 'postings';
    end

    %------- Concrete declarations of abstract superclass properties ------

    properties (SetAccess = protected, Transient = true)
        % XIntrinsicLimits - Limits of raster in intrinsic X [xMin xMax]
        %
        %    XIntrinsicLimits is a two-element row vector. For an M-by-N
        %    raster it equals [1 N].
        XIntrinsicLimits;
        
        % YIntrinsicLimits - Limits of raster in intrinsic Y [yMin yMax]
        %
        %    YIntrinsicLimits is a two-element row vector. For an M-by-N
        %    raster it equals [1 M].
        YIntrinsicLimits;
    end
    
    properties (Access = protected)
        % Use an intrinsic raster object appropriate for 'Postings'
        Intrinsic = map.rasterref.internal.IntrinsicPostingsReference;
        
        % Latitude of the first (1,1) sample point
        FirstCornerLatitude = 0.5;
        
        % Longitude of the first (1,1) sample point
        FirstCornerLongitude = 0.5;
    end
        
    properties (Constant, Access = protected)
        % Number of rows or columns ("elements") minus number of intervals
        % of width SampleSpacingInLatitude or SampleSpacingInLongitude.
        % Equal to both:
        %
        %   R.RasterSize(1) - intervalsInLatitude
        %   R.RasterSize(2) - intervalsInLongitude
        %
        % where:
        %
        %   intervalsInLatitude = R.RasterExtentInLatitude / R.SampleSpacingInLatitude
        %   intervalsInLongitude = R.RasterExtentInLongitude / R.SampleSpacingInLongitude
        ElementsMinusIntervals = 1;
    end
    
    %------------------ Add in SampleSpacing properties -------------------
    
    properties (Dependent)
        % SampleSpacingInLatitude Distance in latitude between adjacent samples
        %
        %     North-south distance, in units of latitude, between adjacent
        %     samples (postings) in the raster. The value is always
        %     positive, and is the constant throughout the raster.
        SampleSpacingInLatitude
        
        % SampleSpacingInLongitude Distance in longitude between adjacent samples
        %
        %     East-west distance, in units of longitude, between adjacent
        %     samples (postings) in the raster. The value is always
        %     positive, and is the constant throughout the raster.
        SampleSpacingInLongitude
    end
    
    
    methods
        function extent = get.SampleSpacingInLatitude(R)
            extent = abs(R.DeltaLatitudeNumerator ...
                / R.DeltaLatitudeDenominator);
        end
        
        
        function extent = get.SampleSpacingInLongitude(R)
            extent = abs(R.DeltaLongitudeNumerator ...
                / R.DeltaLongitudeDenominator);
        end
        
        
        function R = set.SampleSpacingInLatitude(R, sampleSpacingInLatitude)
            fname = 'map.rasterref.GeographicPostingsReference.set.SampleSpacingInLatitude';
            validateattributes(sampleSpacingInLatitude, {'double'}, ...
                {'real','scalar','finite','positive','<=',180}, fname, 'SampleSpacingInLatitude')
            if sampleSpacingInLatitude > R.RasterExtentInLatitude
                error(message('map:spatialref:exceeds', ...
                    'SampleSpacingInLatitude', 'RasterExtentInLatitude', ...
                    num2str(R.RasterExtentInLatitude)))
            end
            R = setAbsoluteDeltaLatitude(R, sampleSpacingInLatitude);
        end
        
        
        function R = set.SampleSpacingInLongitude(R, sampleSpacingInLongitude)
            fname = 'map.rasterref.GeographicCellsReference.set.SampleSpacingInLongitude';
            validateattributes(sampleSpacingInLongitude, {'double'}, ...
                {'real','scalar','finite','positive','<=',360}, fname, 'SampleSpacingInLongitude')
            R = setAbsoluteDeltaLongitude(R, sampleSpacingInLongitude);
        end
    end
    
    %------------------- geographicToDiscrete Alternative -----------------
    
    methods (Hidden)
        function [row, col, outside] = geographicToDiscreteOmitOutside(R, lat, lon)
            % Supports behavior of older functions, including imbedm
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
            
            [row, col] = geographicToDiscrete(R, lat, lon);
            n = isnan(row);
            row(n) = [];
            col(n) = [];
            outside = find(n);
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
            % Construct a default map.rasterref.GeographicPostingsReference
            % object and use a protected superclass method to reset its
            % defining properties.
            R = map.rasterref.GeographicPostingsReference;
            R = resetFromStructure(R,S);
        end
    end
    
    %--------------------------- Construction -----------------------------
    
    methods
        function R = GeographicPostingsReference(rasterSize, ...
                firstCornerLat, firstCornerLon, ...
                deltaLatNumerator, deltaLatDenominator, ...
                deltaLonNumerator, deltaLonDenominator)
            %   R = map.rasterref.GeographicPostingsReference( ...
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
            %        of the first sample (1,1) in the raster.
            %
            %     deltaLatNumerator   -- Nonzero real number
            %     deltaLatDenominator -- Positive real number
            %
            %        The ratio deltaLatNumerator/deltaLatDenominator
            %        defines a signed north-south sample spacing.  A
            %        positive value indicates that columns run from south
            %        to north, whereas a negative value indicates that
            %        columns run from north to south.
            %
            %     deltaLonNumerator   -- Nonzero real number
            %     deltaLonDenominator -- Positive real number
            %
            %        The ratio deltaLonNumerator/deltaLonDenominator
            %        defines a signed east-west sample spacing.  A positive
            %        value indicates that rows run from west to east,
            %        whereas a negative value indicates that rows run from
            %        east to west.
            %
            %   Example 1
            %   ---------
            %   % Construct a referencing object for the DTED Level 0 file
            %   % that includes Sagarmatha (Mount Everest). The DTED
            %   % columns run from south to north and the first column runs
            %   % along the western edge of the (one-degree-by-one-degree)
            %   % quadrangle, consistent with the default values for
            %   % 'ColumnsStartFrom' and 'RowsStartFrom'.
            %   R = map.rasterref.GeographicPostingsReference(...
            %       [121 121], 27, 86, 1, 120, 1, 120)
            %
            %   Example 2
            %   ---------
            %   % Repeat Example 1 with a different strategy: Create a
            %   % default object and then modify its properties as needed.
            %   R = map.rasterref.GeographicPostingsReference;
            %   R.RasterSize = [121 121];
            %   R.LatitudeLimits  = [27 28];
            %   R.LongitudeLimits = [86 87]
            
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
    
    methods (Access = 'protected')
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
                'SampleSpacingInLatitude'
                'SampleSpacingInLongitude'
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
            
            % Override the format for the SampleSpacingInLatitude property,
            % if it would be more informative to display a ratio than a
            % decimal number.
            if map.rasterref.internal.ratioIsBetterThanDecimal( ...
                    R.DeltaLatitudeNumerator, R.DeltaLatitudeDenominator)
                str = map.rasterref.internal.replaceValueWithRatio( ...
                    str, 'SampleSpacingInLatitude', ...
                    abs(R.DeltaLatitudeNumerator), R.DeltaLatitudeDenominator);
            end
            
            % Likewise for the SampleSpacingInLongitude property.
            if map.rasterref.internal.ratioIsBetterThanDecimal( ...
                    R.DeltaLongitudeNumerator, R.DeltaLongitudeDenominator)
                str = map.rasterref.internal.replaceValueWithRatio( ...
                    str, 'SampleSpacingInLongitude', ...
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
        function tf = is360DegreeRasterWithDuplicateColumns(R)
            tf = (R.RasterExtentInLongitude == 360);
        end
    end
end
