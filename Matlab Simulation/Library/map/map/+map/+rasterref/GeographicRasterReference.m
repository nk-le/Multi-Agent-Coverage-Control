classdef (Hidden) GeographicRasterReference ...
    < map.rasterref.internal.GeographicRasterReferenceAlias
%GeographicRasterReference (abstract) Reference raster to geographic coordinates

% Most of the content of this file was copied from the file
% map/+spatialref/GeoRasterReference.m, which was introduced in R2011a.

% Copyright 2010-2020 The MathWorks, Inc.
    
    %------------------- Properties: Public + visible --------------------
    
    properties (Dependent)
        %LatitudeLimits  Latitude limits
        %
        %   LatitudeLimits specifies the limits in latitude of the geographic
        %   quadrangle bounding the georeferenced raster.  It is a
        %   two-element vector of the form:
        %
        %             [southern_limit northern_limit]
        LatitudeLimits
        
        %LongitudeLimits  Longitude limits
        %
        %   LongitudeLimits specifies the limits in longitude of the geographic
        %   quadrangle bounding the georeferenced raster.  It is a
        %   two-element vector of the form:
        %
        %             [western_limit eastern_limit]
        LongitudeLimits
        
        %RasterSize Number rows and columns
        %
        %   RasterSize is a two-element vector [M N] specifying the
        %   number of rows (M) and columns (N) of the raster or image
        %   associated with the referencing object. In addition, for
        %   convenience, you may assign a size vector having more than
        %   two elements to RasterSize. This flexibility enables
        %   assignments like R.RasterSize = size(RGB), for example, where
        %   RGB is M-by-N-by-3. However, in such cases, only the first two
        %   elements of the size vector will actually be stored. The higher
        %   (non-spatial) dimensions will be ignored. M and N must be
        %   positive in all cases and must be 2 or greater when
        %   RasterInterpretation is 'postings'.
        RasterSize
    end
    
    properties (Dependent, SetAccess = private)
        %AngleUnit Unit of angle used for angle-valued properties
        %
        %   AngleUnit is a string that equals 'degree'.
        AngleUnit
    end
    
    properties (Dependent)
        %ColumnsStartFrom Edge from which column indexing starts
        %
        %   ColumnsStartFrom is a string that equals 'south' or 'north'.
        ColumnsStartFrom
        
        %RowsStartFrom Edge from which row indexing starts
        %
        %   RowsStartFrom is a string that equals 'west' or 'east'.
        RowsStartFrom
    end
    
    properties (Dependent, SetAccess = private)
        % RasterExtentInLatitude - Extent in latitude of the full raster
        %
        %    RasterExtentInLatitude is the latitude extent ("height") of the
        %    quadrangle covered by the raster.
        RasterExtentInLatitude
        
        % RasterExtentInLongitude - Extent in longitude of the full raster
        %
        %    RasterExtentInLongitude is the longitude extent ("width") of the
        %    quadrangle covered by the raster.
        RasterExtentInLongitude
    end
    
    properties (Abstract, SetAccess = protected, Transient = true)
        XIntrinsicLimits;  % Limits of raster in intrinsic X [xMin xMax]
        YIntrinsicLimits;  % Limits of raster in intrinsic Y [yMin yMax]
    end
    
    properties (Constant)
        % CoordinateSystemType - Type of external system (constant: 'geographic')
        %
        %   CoordinateSystemType describes the type of coordinate system
        %   represented to which the image or raster is referenced. It
        %   is a constant string with value 'geographic'.
        CoordinateSystemType = 'geographic';
    end
    
    properties (Dependent)
        % GeographicCRS - A geocrs representing the coordinate reference
        % system
        GeographicCRS
    end
    
    properties (Access = protected)
        % pGeographicCRS - A place to hold the value of the public
        % GeographicCRS property.
        pGeographicCRS
    end
    
    properties (Access = protected)
        %DeltaLatitudeNumerator - Numerator of rational DeltaLatitude property
        %
        %   DeltaLatitudeNumerator is a non-negative real number which,
        %   when divided by DeltaLatitudeDenominator, indicates the signed
        %   north-south distance ("delta latitude") traversed when moving
        %   from row I to row I + 1. A positive value indicates that
        %   columns run from south to north, whereas a negative value
        %   indicates that columns run from north to south.
        DeltaLatitudeNumerator = 1;
        
        %DeltaLatitudeDenominator - Denominator of rational DeltaLatitude property
        %
        %   DeltaLatitudeDenominator is a (strictly) positive real number
        %   that, when divided into DeltaLatitudeNumerator, defines
        %   "delta latitude."
        DeltaLatitudeDenominator = 1;
        
        %DeltaLongitudeNumerator - Numerator of rational DeltaLongitude property
        %
        %   DeltaLongitudeNumerator is a non-negative real number which,
        %   when divided by DeltaLongitudeDenominator, defines the signed
        %   east-west distance traversed when moving from column J to column
        %   J + 1. A positive value indicates that rows run from west to
        %   east, whereas a negative value indicates that rows run from
        %   east to west.
        DeltaLongitudeNumerator = 1;
        
        %DeltaLongitudeDenominator - Denominator rational DeltaLongitude property
        %
        %   DeltaLongitudeDenominator is a (strictly) positive real number
        %   that, when divided into DeltaLongitudeNumerator, defines
        %   "delta longitude."
        DeltaLongitudeDenominator = 1;
    end
    
    %---------------- Properties: Private or Protected -------------------
    
    properties (Abstract, Access = protected)
        Intrinsic
        
        % Latitude of the (1,1) corner of the raster
        FirstCornerLatitude
        
        % Longitude of the (1,1) corner of the raster
        FirstCornerLongitude
    end
    
    properties (Access = private, Transient = true)
        % Cache values of latitude and longitude limits, setting and
        % updating them as needed, rather than recomputing them each time.
        pLatitudeLimits
        pLongitudeLimits
    end
    
    properties (Constant, Access = private)
        % A place to hold the value of the public AngleUnit property.
        pAngleUnit = 'degree';
        
        % Latitude of the North Pole in current angle units
        % (always degrees).
        NorthPoleLatitude = 90;
        
        % Angular equivalent of a full cycle in current angle units
        % (always degrees).
        FullCycle = 360;
        
        % Function to wrap to a full cycle in longitude given the current
        % angle units (always degrees).
        WrapToCycleFcn = @wrapTo360;
    end
    
    properties (Constant, Abstract, Access = protected)
        % Number of rows or columns ("elements") minus number of intervals
        % of width abs(DeltaLatitude) or abs(DeltaLongitude). Equal to both:
        %
        %    R.RasterSize(1) - intervalsInLatitude
        %    R.RasterSize(2) - intervalsInLongitude
        %
        % where:
        %
        %   intervalsInLatitude = R.RasterExtentInLatitude / abs(deltaLatitude)
        %   intervalsInLongitude = R.RasterExtentInLongitude / abs(deltaLongitude)
        %   
        % and:
        %
        %   deltaLatitude = R.DeltaLatitudeNumerator / R.DeltaLatitudeDenominator
        %   deltaLongitude = R.DeltaLongitudeNumerator / R.DeltaLongitudeDenominator
        %
        % The value is always either 0 or 1.
        ElementsMinusIntervals
    end
    
    %---------------- Constructor and ordinary methods --------------------
    
    methods
        
        function R = GeographicRasterReference()
                % Initialized transient properties.
                [xlimits, ylimits] = limits(R.Intrinsic);
                R.XIntrinsicLimits = xlimits;
                R.YIntrinsicLimits = ylimits;
                
                R.pLatitudeLimits  = getLatitudeLimits(R);
                R.pLongitudeLimits = getLongitudeLimits(R);
        end
        
        
        function tf = sizesMatch(R,A)
            %sizesMatch True if object and raster or image are size-compatible
            %
            %   TF = sizesMatch(R,A) returns true if the size of the raster
            %   (or image) A is consistent with the RasterSize property of
            %   the referencing object R. That is,
            %
            %           R.RasterSize == [size(A,1) size(A,2)].
            
            tf = sizesMatch(R.Intrinsic, A);
        end

        
        function [lat, lon] = intrinsicToGeographic(R, xi, yi)
            %intrinsicToGeographic Convert from intrinsic to geographic coordinates
            %
            %   [LAT, LON] = intrinsicToGeographic(R, xIntrinsic, yIntrinsic)
            %   returns the geographic coordinates (LAT, LON) of a set
            %   of points given their intrinsic coordinates (xIntrinsic,
            %   yIntrinsic), based on the relationship defined by the
            %   referencing object R. xIntrinsic and yIntrinsic must
            %   have the same size. LAT and LON will have the same size
            %   as xIntrinsic and yIntrinsic. The input may include
            %   points that fall outside the limits of the raster (or
            %   image). Latitudes and longitudes for such points are
            %   linearly extrapolated outside the geographic quadrangle
            %   bounding the raster, but for any point that extrapolates
            %   to a latitude beyond the poles (latitude < -90 degrees
            %   or latitude > 90 degrees), the values of both LAT and
            %   LON are set to NaN.
            
            map.internal.validateCoordinatePairs(xi, yi, ...
                [class(R), ':intrinsicToGeographic'], ...
                'xIntrinsic', 'yIntrinsic')
            
            % Apply linear scale and shift
            lat = R.intrinsicYToLatitude(yi);
            lon = R.intrinsicXToLongitude(xi);
            
            % Extrapolation beyond the poles causes NaNs to be placed
            % in LAT. Replicate such NaNs in LON also.
            lon(isnan(lat)) = NaN;
        end
        
        
        function [xi, yi] = geographicToIntrinsic(R, lat, lon)
            %geographicToIntrinsic Convert from geographic to intrinsic coordinates
            %
            %   [xIntrinsic, yIntrinsic] = geographicToIntrinsic(R, LAT, LON)
            %   returns the intrinsic coordinates (xIntrinsic, yIntrinsic)
            %   of a set of points given their geographic coordinates
            %   (LAT, LON), based on the relationship defined by the
            %   referencing object R. LAT and LON must have the same
            %   size, and all (non-NaN) elements of LAT must fall within
            %   the interval [-90 90] degrees. xIntrinsic and yIntrinsic
            %   will have the same size as LAT and LON. The input may
            %   include points that fall outside the geographic
            %   quadrangle bounding the raster. As long as their
            %   latitudes are valid, the locations of such points will
            %   be extrapolated outside the bounds of the raster in the
            %   intrinsic coordinate system.
            
            map.internal.validateCoordinatePairs(lat, lon, ...
                [class(R), ':geographicToIntrinsic'], 'LAT', 'LON')
            
            xi = R.longitudeToIntrinsicX(lon);
            yi = R.latitudeToIntrinsicY(lat);
            
            % Latitudes beyond the poles cause NaNs to be placed
            % in yi. Replicate such NaNs in xi also.
            xi(isnan(yi)) = NaN;
        end
        
        
        function lat = intrinsicYToLatitude(R, yi)
            %intrinsicYToLatitude Convert from intrinsic Y to latitude
            %
            %   LAT = intrinsicYToLatitude(R, yIntrinsic) returns the
            %   latitude of the small circle corresponding to the line
            %   y = yIntrinsic, based on the relationship defined by the
            %   referencing object R. The input may include values that
            %   fall completely outside the intrinsic Y-limits of the
            %   raster (or image). In this case latitude is extrapolated
            %   outside the latitude limits, but for input values that
            %   extrapolate to latitudes beyond the poles (latitude < -90
            %   degrees or latitude > 90 degrees), the value of LAT is
            %   set to NaN. NaN-valued elements of yIntrinsic map to
            %   NaNs in LAT.
            
            d = R.DeltaLatitudeDenominator;
            yIntrinsicLimits1 = R.YIntrinsicLimits(1);
            
            lat = (R.DeltaLatitudeNumerator .* (yi - yIntrinsicLimits1) ...
                + d .* R.FirstCornerLatitude) ./ d;
            
            % Ensure perfect consistency with the first corner latitude.
            lat(yi == yIntrinsicLimits1) = R.FirstCornerLatitude;
            
            lat(beyondPole(R.NorthPoleLatitude, lat)) = NaN;
        end
        
        
        function lon = intrinsicXToLongitude(R, xi)
            %intrinsicXToLongitude Convert from intrinsic X to longitude
            %
            %   LON = intrinsicXToLongitude(R, xIntrinsic) returns the
            %   longitude of the meridian corresponding to the line
            %   x = xIntrinsic, based on the relationship defined by the
            %   referencing object R. The input may include values that
            %   fall completely outside the intrinsic X-limits of the
            %   raster (or image). In this case, longitude is
            %   extrapolated outside the longitude limits. NaN-valued
            %   elements of xIntrinsic map to NaNs in LON.
            
            d = R.DeltaLongitudeDenominator;
            xIntrinsicLimits1 = R.XIntrinsicLimits(1);
            
            lon = (R.DeltaLongitudeNumerator .* (xi - xIntrinsicLimits1) ...
                + d .* R.FirstCornerLongitude) ./ d;
            
            % Ensure perfect consistency with the first corner longitude.
            lon(xi == xIntrinsicLimits1) = R.FirstCornerLongitude;
        end
        
        
        function yi = latitudeToIntrinsicY(R, lat)
            %latitudeToIntrinsicY Convert from latitude to intrinsic Y
            %
            %   yIntrinsic = latitudeToIntrinsicY(R, LAT) returns the
            %   intrinsic Y value of the line corresponding to the small
            %   circle at latitude LAT, based on the relationship
            %   defined by the referencing object R. The input may
            %   include values that fall completely outside the latitude
            %   limits of the raster (or image). In this case yIntrinsic
            %   is either extrapolated outside the intrinsic Y limits --
            %   for elements of LAT that fall within the interval
            %   [-90 90] degrees, or set to NaN -- for elements of LAT
            %   that do not correspond to valid latitudes. NaN-valued
            %   elements of LAT map to NaNs in yIntrinsic.
            
            % Elements of LAT are less than -90 degrees or
            % that exceed +90 degrees should map to NaN.
            lat(beyondPole(R.NorthPoleLatitude, lat)) = NaN;
            
            % Shift and scale latitude
            yi = R.YIntrinsicLimits(1) + (lat - R.FirstCornerLatitude) ...
                .* R.DeltaLatitudeDenominator ./ R.DeltaLatitudeNumerator;
        end
        
        
        function xi = longitudeToIntrinsicX(R, lon)
            %longitudeToIntrinsicX Convert from longitude to intrinsic X
            %
            %   xIntrinsic = longitudeToIntrinsicX(R, LON) returns the
            %   intrinsic X value of the line corresponding to the
            %   meridian at longitude LON, based on the relationship
            %   defined by the referencing object R. The input may
            %   include values that fall completely outside the
            %   longitude limits of the raster (or image). In this case
            %   xIntrinsic is extrapolated outside the intrinsic X
            %   limits. NaN-valued elements of LON map to NaNs in
            %   xIntrinsic.
            
            lonlim = R.pLongitudeLimits;
            w = lonlim(1);
            e = lonlim(2);
            
            % Adjust longitude wrapping to get within the limits,
            % whenever possible.
            if (e - w) <= R.FullCycle
                rowsRunWestToEast = (R.DeltaLongitudeNumerator > 0);
                if rowsRunWestToEast
                    % Wrap to interval R.FirstCornerLongitude + [0 360]
                    lon = w + R.WrapToCycleFcn(lon - w);
                else
                    % Wrap to interval R.FirstCornerLongitude + [-360 0]
                    lon = e - R.WrapToCycleFcn(e - lon);
                end
            else
                % Any longitude can be wrapped to fall within the
                % interval [w e], and in fact there's more than one
                % solution for certain longitudes. Resolve the ambiguity
                % by moving longitudes that are west of the western
                % limit the minimal number of cycles to the east that
                % puts them within the limits. Likewise, move longitudes
                % that exceed the eastern limit the minimum number of
                % cycles to the west.
                offToWest = lon < w;
                lon(offToWest) = ...
                    w + R.WrapToCycleFcn(lon(offToWest) - w);
                
                offToEast = lon > e;
                t = e - R.FullCycle;
                lon(offToEast) ...
                    = t + R.WrapToCycleFcn(lon(offToEast) - t);
            end
            
            % Shift and scale longitude
            xi = R.XIntrinsicLimits(1) + (lon - R.FirstCornerLongitude) ...
                .* R.DeltaLongitudeDenominator ./ R.DeltaLongitudeNumerator;
        end
        
        
        function [row,col] = geographicToDiscrete(R, lat, lon)
            %geographicToDiscrete Transform geographic to discrete coordinates
            %
            %   [I,J] = geographicToDiscrete(R, LAT, LON) returns the subscript
            %   arrays I and J. When the referencing object R has
            %   RasterInterpretation 'cells', these are the row and column
            %   subscripts of the raster cells (or image pixels) containing
            %   each element of a set of points given their geographic
            %   coordinates (LAT, LON). If R.RasterInterpretation is
            %   'postings', then the subscripts refer to the nearest sample
            %   point (posting). LAT and LON must have the same size. I and
            %   J will have the same size as LAT and LON. For an M-by-N
            %   raster, 1 <= I <= M and 1 <= J <= N, except when a point
            %   LAT(k),LON(k) falls outside the image, as defined by
            %   R.contains(lat, lon), then both I(k) and J(k) are NaN.
            
            % Note: geographicToIntrinsic validates lat and lon
            [xi, yi] = geographicToIntrinsic(R, lat, lon);
            [row, col] = intrinsicToDiscrete(R.Intrinsic, xi, yi);
        end
        
        
        function tf = contains(R, lat, lon)
            %contains True if raster contains latitude-longitude points
            %
            %   TF = contains(R, LAT, LON) returns a logical array TF
            %   having the same size as LAT and LON such that TF(k) is
            %   true if and only if the point (LAT(k),LON(k)) falls
            %   within the bounds of the raster associated with
            %   referencing object R. Elements of LON can be wrapped
            %   arbitrarily without affecting the result.
            
            % Note: This implementation is a minor adaptation of the
            % Mapping Toolbox function INGEOQUAD, in which we simply
            % omit the wrapping step when computing "londiff".
            % And it's generalized to work with radians as well as
            % degrees.
            
            map.internal.validateCoordinatePairs(lat, lon, ...
                [class(R) '.contains'], 'LAT', 'LON')
            
            latlim = R.pLatitudeLimits;
            lonlim = R.pLongitudeLimits;
            
            % Initialize to include all points.
            tf = true(size(lat));
            
            % Eliminate points that fall outside the latitude limits.
            inlatzone = (latlim(1) <= lat) & (lat <= latlim(2));
            tf(~inlatzone) = false;
            
            % Eliminate points that fall outside the longitude limits.
            londiff = lonlim(2) - lonlim(1);  % No need to wrap here
            inlonzone = (R.WrapToCycleFcn(lon - lonlim(1)) <= londiff);
            tf(~inlonzone) = false;
        end
        
        
        function [lat, lon] = geographicGrid(R, gridOption)
            % geographicGrid - Geographic coordinates of raster elements
            %
            %   [LAT,LON] = geographicGrid(R) returns the locations of
            %   raster elements in geographic coordinates as 2-D arrays,
            %   LAT and LON. When R is a GeographicCellsReference object,
            %   the locations are cell centers. When R is a
            %   GeographicPostingsReference object, the locations are
            %   posting points. The location of raster element (i,j) is
            %   (LAT(i,j), LON(i,j)). The values of size(LAT) and size(LON)
            %   both equal the RasterSize property of R.
            %
            %   [LAT,LON] = geographicGrid(R,gridOption), where gridOption
            %   is 'gridvectors', returns LAT and LON as row vectors. The
            %   location of raster element (i,j) is (LAT(i), LON(j)). The
            %   value of [length(LAT) length(LON)] equals the RasterSize
            %   property of R. The default for gridOption is 'fullgrid'.
            %   geographicGrid(R,'fullgrid') is equivalent to
            %   geographicGrid(R).
            % 
            %   Example
            %   -------
            %   R = georefpostings([0 30],[-20 20],[4 5])
            %   [lat,lon] = geographicGrid(R)
            %   [lat,lon] = geographicGrid(R,"gridvectors")

            arguments
                R (1,1) map.rasterref.GeographicRasterReference
                gridOption (1,1) map.rasterref.GridOption = "fullgrid"
            end
            I = R.Intrinsic;
            numrows = I.NumRows;
            numcols = I.NumColumns;
            xi = 1:numcols;
            yi = 1:numrows;
            lat = intrinsicYToLatitude( R, yi);
            lon = intrinsicXToLongitude(R, xi);
            if gridOption == map.rasterref.GridOption.fullgrid
                lat = repmat(lat', [1 numcols]);
                lon = repmat(lon,  [numrows 1]);
            end
        end
        
        
        function W = worldFileMatrix(R)
            %worldFileMatrix World file parameters for transformation
            %
            %   W = worldFileMatrix(R) returns a 2-by-3 world file matrix.
            %   Each of the 6 elements in W matches one of the lines in a
            %   world file corresponding to the transformation defined by
            %   the referencing object R.
            %
            %   Given W with the form:
            %
            %                    W = [A B C;
            %                         D E F],
            %
            %   a point (xi, yi) in intrinsic coordinates maps to a point
            %   (lat, lon) in geographic coordinates like this:
            %
            %         lon = A * (xi - 1) + B * (yi - 1) + C
            %         lat = D * (xi - 1) + E * (yi - 1) + F
            %
            %   or, more compactly, [lon lat]' = W * [(xi - 1) (yi - 1) 1]'.
            %   The -1s allow the world file matrix to work with the
            %   Mapping Toolbox convention for intrinsic coordinates, which
            %   is consistent with the 1-based indexing used throughout
            %   MATLAB. W is stored in a world file with one term per line
            %   in column-major order: A, D, B, E, C, F.  That is, a world
            %   file contains the elements of W in the following order:
            %
            %         W(1,1)
            %         W(2,1)
            %         W(1,2)
            %         W(2,2)
            %         W(1,3)
            %         W(2,3).
            %
            %   The expressions above hold for a general affine
            %   transformation, but in the matrix returned by this method
            %   B, D, W(2,1), and W(1,2) are identically 0 because
            %   longitude depends only on intrinsic X and latitude depends
            %   only on intrinsic Y.
            %
            %   See also WORLDFILEREAD, WORLDFILEWRITE
            
            c = R.intrinsicXToLongitude(1);
            f = R.intrinsicYToLatitude(1);
            
            dlon = R.DeltaLongitudeNumerator / R.DeltaLongitudeDenominator;
            dlat = R.DeltaLatitudeNumerator  / R.DeltaLatitudeDenominator;
            
            W = [dlon        0      c;
                  0        dlat     f];
        end
        
        
        function tf = columnsRunSouthToNorth(R)
            % columnsRunSouthToNorth True if column index increases from south to north            
            tf = (R.DeltaLatitudeNumerator > 0);
        end
        
        
        function tf = rowsRunWestToEast(R)
            % columnsRunWestToEast True if row index increases from west to east
            tf = (R.DeltaLongitudeNumerator > 0);
        end
        
        
        function [sampleDensityInLatitude, sampleDensityInLongitude] ...
                = sampleDensity(R)
            % sampleDensity Cells or samples per unit angle in latitude and longitude
            sampleDensityInLatitude ...
                = abs(R.DeltaLatitudeDenominator / R.DeltaLatitudeNumerator);
            sampleDensityInLongitude ...
                = abs(R.DeltaLongitudeDenominator / R.DeltaLongitudeNumerator);
        end
    end
    
    
    methods (Hidden)
        function [Rnew, xSample, ySample] = scaleSizeAndDensity(R, latscale, lonscale)
            %scaleSizeAndDensity Scale reference object for resized raster 
            %
            %       FOR INTERNAL USE ONLY -- This method is intentionally
            %       undocumented and is intended for use only within other
            %       toolbox methods and functions. Its behavior may change,
            %       or the method itself may be removed in a future
            %       release.
            %
            %   [Rnew, xSample, ySample] = scaleSizeAndDensity(R,
            %   latscale, lonscale) scales the raster size and cell
            %   extents/sample sizes of the geographic raster reference
            %   object R, creating a new reference object with equal, or
            %   nearly equal, latitude and longitude limits. It also
            %   returns the locations of the new cell centers/sample
            %   postings in the intrinsic coordinates of the input. These
            %   can be used to scale and resample the raster itself to a
            %   new size. Scaling can be specified independently in the
            %   north-south and east-west dimensions.
            %
            %   R is either a GeographicCellsReference object or a
            %   GeographicPostingsReference object.
            %
            %   latscale is the factor by which to scale sample density and
            %   raster size in the north-south dimension.
            %
            %   lonscale is the factor by which to scale sample density and
            %   raster size in the east-west dimension.
            %
            %   Rnew is a raster reference object with the same class and
            %   row/column directions as R, with RasterSize and cell
            %   extents/sample spacing values that preserve, or nearly
            %   preserve, the LatitudeLimits and LongitudeLimits of R.
            %   If necessary, the limits are tightened slightly to enclose
            %   a discrete array of cells or postings within the original
            %   limits, while matching scale factors exactly as specified.
            %
            %   xSample indicates the location of the new cell centers or
            %   sample postings in the intrinsic space of the original
            %   raster. It's a vector of size Rnew.RasterSize(2)-by-1 such
            %   that xSample(j) is the location, relative to the input
            %   raster, of the cell centers or posting points in the j-th
            %   column of the new raster.
            %
            %   ySample indicates the location of the new cell centers or
            %   sample postings in the intrinsic space of the original
            %   raster. It's a vector of size Rnew.RasterSize(1)-by-1
            %   such that ySample(i) is the location, relative to the input
            %   raster, of the cell centers or posting points in the i-th
            %   row of the new raster.
            %
            %   Together, xSample and ySample indicate the locations at
            %   which to interpolate the columns and rows of a raster
            %   associated with R while resampling it to match Rnew.
            %
            %   Example
            %   -------
            %   % Rescale the raster reference object for a high-latitude
            %   % DTED Level 0 tile to an equal spacing in latitude and
            %   % longitude.
            %   latlim = [58 59];
            %   lonlim = [-75 -74];
            %   R = georefpostings(latlim,lonlim,[121 61])
            %   latscale = 1;
            %   lonscale = 2;
            %   [Rnew, xSample, ySample] = scaleSizeAndDensity(R, latscale, lonscale);
            %   Rnew
            
            latscale = abs(latscale);
            lonscale = abs(lonscale);
            
            % Let the intrinsic raster reference object do as much of the
            % work as possible. Pass lonscale as xscale, and latscale as
            % yscale.
            [numrows, numcols, xSample, ySample, xshift, yshift] ...
                = scaleRaster(R.Intrinsic, lonscale, latscale);
            
            % Copy the defining properties of R to the struct S.
            S = encodeInStructure(R);
            
            % New raster size
            S.RasterSize = [numrows numcols];
            
            % Shift in latitude dimension.
            num = R.DeltaLatitudeNumerator;
            den = R.DeltaLatitudeDenominator;
            S.FirstCornerLatitude = R.FirstCornerLatitude + yshift * num / den;
            
            % Scale in latitude dimension.
            [numScale, denScale] = map.rasterref.internal.simplifyRatio(latscale, 1);
            num = num * denScale;
            den = den * numScale;
            [S.DeltaLatitudeNumerator, S.DeltaLatitudeDenominator] ...
                = map.rasterref.internal.simplifyRatio(num, den);
            
            % Shift in longitude dimension.
            num = R.DeltaLongitudeNumerator;
            den = R.DeltaLongitudeDenominator;
            S.FirstCornerLongitude = R.FirstCornerLongitude + xshift * num / den;
            
            % Scale in longitude dimension.
            [numScale, denScale] = map.rasterref.internal.simplifyRatio(lonscale, 1);
            num = num * denScale;
            den = den * numScale;
            [S.DeltaLongitudeNumerator, S.DeltaLongitudeDenominator] ...
                = map.rasterref.internal.simplifyRatio(num, den);
            
            % Construct raster reference object for scaled raster.
            Rnew = resetFromStructure(R, S);
        end
        
        
        function [Rblock, rows, cols] = georefblock(R, rowLimits, colLimits)
            %georefblock Referencing object for sub-block of geographic raster
            %
            %       FOR INTERNAL USE ONLY -- This method is intentionally
            %       undocumented and is intended for use only within other
            %       toolbox methods and functions. Its behavior may change,
            %       or the method itself may be removed in a future
            %       release.
            %
            %   Rblock = georefblock(R,rowLimits,colLimits) returns a
            %   referencing object for a sub-block of a regular geographic
            %   raster or image, with referencing object R, consisting of
            %   the following rows and columns:
            %
            %        rowLimits(1):rowLimits(2)
            %        colLimits(1):colLimits(2).
            %
            %   The two-element row and column limits vectors must contain
            %   positive real integer values, must be strictly ascending,
            %   and must be bounded by R.RasterSize. An error is thrown if:
            %
            %       rowLimits(2) > R.RasterSize(1) or
            %       colLimits(2) > R.RasterSize(2).
            %
            %   [Rblock, rows, cols] = georefblock(___) returns the indices
            %   of the rows and columns to be copied from the input raster.
            %
            %   Example
            %   -------
            %   % Extract a 50-by-80 georeferenced block from the topo raster
            %   load topo60c
            %   startrow = 101;
            %   endrow = 150;
            %   startcol = 41;
            %   endcol = 120;
            %   [Rblock, rows, cols] = georefblock(...
            %       topo60cR,[startrow endrow],[startcol endcol]);
            %   topoblock = topo60c(startrow:endrow,startcol:endcol);
            
            attributes = {'real','positive','integer','numel',2};
            validateattributes(rowLimits, {'double'}, [attributes,{'increasing'}], '', 'rowLimits')
            if R.RasterExtentInLongitude == 360
                validateattributes(colLimits, {'double'}, attributes, '', 'colLimits')
            else
                validateattributes(colLimits, {'double'}, [attributes,{'increasing'}], '', 'colLimits')
            end
            
            if rowLimits(2) > R.RasterSize(1)
                error(message('map:spatialref:exceeds','rowLimits(2)', ...
                    'R.RasterSize(1)', num2str(R.RasterSize(1))))
            end
            
            if colLimits(2) > R.RasterSize(2)
                error(message('map:spatialref:exceeds','colLimits(2)', ...
                    'R.RasterSize(2)', num2str(R.RasterSize(2))))
            end
            
            % The following implementation is appropriate to both cells and
            % postings (which is why it is implemented here in the
            % geographic raster reference superclass.) There is only one
            % small difference, and that's handled by the abstract
            % is360DegreeRasterWithDuplicateColumns method.
            
            % Indices of rows and columns comprised by the block.
            rows = rowLimits(1):rowLimits(2);
            if colLimits(1) < colLimits(2)
                cols = colLimits(1):colLimits(2);
            elseif colLimits(1) > colLimits(2)
                if is360DegreeRasterWithDuplicateColumns(R)
                    % Last column and first column are duplicates of each
                    % other, so skip one. (Can only be true for postings.)
                    cols = [colLimits(1):R.RasterSize(2) 2:colLimits(2)];
                else
                    cols = [colLimits(1):R.RasterSize(2) 1:colLimits(2)];
                end
            else
                error(message('map:spatialref:equalColumnLimits'))
            end
            
            % Size of sub-block raster
            % (Start to assign fields in a temporary scalar struct, S.)
            S.RasterSize = [length(rows), length(cols)];
            
            % New first corner location in the intrinsic system
            firstCornerIntrinsicX = R.XIntrinsicLimits(1) + colLimits(1) - 1;
            firstCornerIntrinsicY = R.YIntrinsicLimits(1) + rowLimits(1) - 1;
            
            % Convert new first corner location to geographic system.
            S.FirstCornerLatitude = intrinsicYToLatitude(R, firstCornerIntrinsicY);
            S.FirstCornerLongitude = intrinsicXToLongitude(R, firstCornerIntrinsicX);
            
            % Copy the numerators.
            S.DeltaLatitudeNumerator  = R.DeltaLatitudeNumerator;
            S.DeltaLongitudeNumerator = R.DeltaLongitudeNumerator;
            
            % Copy the denominators.
            S.DeltaLatitudeDenominator  = R.DeltaLatitudeDenominator;
            S.DeltaLongitudeDenominator = R.DeltaLongitudeDenominator;
            
            % Construct a new object with internal properties matching the
            % fields of S, and with the same raster interpretation as R.
            Rblock = resetFromStructure(R, S);
        end
        
        
        function [Rsub, rows, cols] = setupCropAndSubsample(R, ...
                latlim, lonlim, rowSampleFactor, columnSampleFactor, ...
                southToNorth, westToEast)
            %setupCropAndSubsample Referencing object and indices for cropping/subsampling
            %
            %       FOR INTERNAL USE ONLY -- This method is intentionally
            %       undocumented and is intended for use only within other
            %       toolbox methods and functions. Its behavior may change,
            %       or the method itself may be removed in a future
            %       release.
            %
            %   [Rsub, rows, cols] = setupCropAndSubsample(R,
            %       latlim, lonlim, rowSampleFactor, columnSampleFactor,
            %       columnsRunSouthToNorth, rowsRunWestToEast)
            %   returns Rsub, a new geographic raster reference object for
            %   a cropped and/or subsampled version of the raster grid or
            %   image associated with R, along with the row and column
            %   indices of the corresponding subset of that grid or image.
            %
            %   Input Arguments
            %   ---------------
            %   R - Geographic raster reference object
            %
            %   latlim - Two-element latitude limits vector of the form
            %            [southern_limit northern_limit]
            %
            %   lonlim - Two-element longitude limits vector of the form
            %            [western_limit eastern_limit]
            %
            %   rowSampleFactor - Subsampling factor to be applied in
            %            in the row/latitude dimension:
            %                positive, scalar, integer-valued
            %
            %   columnSamplefactor - Subsampling factor to be applied in
            %            in the column/longitude dimension:
            %                positive, scalar, integer-valued
            %
            %   southToNorth - True if and only if columns are to run
            %            south to north in the cropped/subsampled grid:
            %                scalar, logical
            %
            %   westToEast - True if and only if rows are to run
            %            west to east in the cropped/subsampled grid:
            %                scalar, logical
            %
            %   Output Arguments
            %   ----------------
            %   Rsub - Geographic raster reference object for the
            %          cropped/subsampled grid or image
            %
            %   rows - Row vector with ordered list of the row indices
            %          for subsetting the raster associated with R.
            %
            %   rows - Row vector with ordered list of the column indices
            %          for subsetting the raster associated with R.
            %
            %   The input latitude and longitude limits are clamped inward
            %   if they extend beyond the corresponding limits of R, and
            %   snapped outward as required to align with cell boundaries
            %   or sample locations within the raster described by R.
            
            % Validate the requested quadrangle.
            [latlim, lonlimIntersection] = intersectgeoquad( ...
                R.LatitudeLimits, R.LongitudeLimits, latlim, lonlim);
            if isempty(latlim)
                error('map:selectGeoRasterSubsamplingLimits:noIntersection', ...
                    'The requested limits fail to intersect the input raster grid limits.');
            elseif numel(lonlimIntersection) == 4
                error('map:selectGeoRasterSubsamplingLimits:twoIntersections', ...
                    'Expected the requested longitude interval to intersect the limits of the input raster grid exactly once.');
            end
            if ~isequal(lonlimIntersection, [-180 180])
                lonlim = lonlimIntersection;
            end
            
            % Validate the sample factors. If a sample factor is greater
            % than the size of the input raster, adjust the sample factor.
            validateattributes(rowSampleFactor, {'numeric'}, ...
                {'scalar', 'integer', 'positive', 'finite'}, ...
                mfilename, 'rowSampleFactor');
            validateattributes(columnSampleFactor, {'numeric'}, ...
                {'scalar', 'integer', 'positive', 'finite'}, ...
                mfilename, 'columnSampleFactor');
            rowSampleFactor = min([rowSampleFactor, R.RasterSize(1)]);
            columnSampleFactor = min([columnSampleFactor, R.RasterSize(2)]);
            
            % Convert latitude-longitude limits to the intrinsic system,
            % without clamping their values.
            xIntrinsicLimits = longitudeToIntrinsicX(R, lonlim);
            yIntrinsicLimits = latitudeToIntrinsicY( R, latlim);
            
            % Code the relative row and column directions into the sample
            % factors by making them signed.
            xSampleFactor = columnSampleFactor * (-1 + ...
                2 * double((rowsRunWestToEast(R) == westToEast)));
            ySampleFactor = rowSampleFactor * (-1 + ...
                2 * double((columnsRunSouthToNorth(R) == southToNorth)));
            
            % Clamp limits as needed, compute row and column index vectors,
            % and compute new first corner location in the intrinsic system
            % of geographic raster reference R.
            [rows, cols, firstxi, firstyi] = setupCropAndSubsample( ...
                R.Intrinsic, xIntrinsicLimits, yIntrinsicLimits, ...
                xSampleFactor, ySampleFactor);
            
            % Size of cropped/subsampled raster.
            S.RasterSize = [numel(rows) numel(cols)];
            
            % Convert new first corner location to geographic system.
            S.FirstCornerLatitude = intrinsicYToLatitude(R, firstyi);
            S.FirstCornerLongitude = intrinsicXToLongitude(R, firstxi);
            
            % Scale and/or change the sign of the delta numerators.
            S.DeltaLatitudeNumerator  = ySampleFactor * R.DeltaLatitudeNumerator;
            S.DeltaLongitudeNumerator = xSampleFactor * R.DeltaLongitudeNumerator;
            
            % Copy the denominators.
            S.DeltaLatitudeDenominator  = R.DeltaLatitudeDenominator;
            S.DeltaLongitudeDenominator = R.DeltaLongitudeDenominator;
            
            % Construct a new object with internal properties matching the
            % fields of S, and with the same raster interpretation as R.
            Rsub = resetFromStructure(R, S);
        end
    end
    
    %-------------------------- Set methods ----------------------------
    
    methods
        
        function R = set.RasterSize(R, rasterSize)            
            % Save current values of dependent properties.
            latlim = R.pLatitudeLimits;
            lonlim = R.pLongitudeLimits;
            
            % Update the intrinsic properties on which RasterSize depends
            % and the transient properties that depend on them.
            try
                R = setIntrinsicRasterSize(R, rasterSize);
            catch e
                throwAsCaller(e)
            end
            
            % Reset "delta" properties while maintaining latitude and
            % longitude limits, and column and row directions.
            R = constrainToFitLatitudeLimits(R, latlim);
            R = constrainToFitLongitudeLimits(R, lonlim);            
        end
        
        
        function R = set.LatitudeLimits(R, latlim)
            validateattributes(latlim, ...
                {'double'}, {'real','row','finite','size',[1 2]}, ...
                [class(R) '.set.LatitudeLimits'], 'latlim')
            
            map.internal.assert(~any(beyondPole(R.NorthPoleLatitude, latlim)), ...
                'map:spatialref:invalidLatlim')
            
            map.internal.assert(latlim(1) < latlim(2), ...
                'map:spatialref:expectedAscendingLimits','latlim')
            
            % Reset delta latitude properties while maintaining raster
            % size and column direction.
            R = constrainToFitLatitudeLimits(R, latlim);
            
            R.pLatitudeLimits = getLatitudeLimits(R);
        end
        
        
        function R = set.LongitudeLimits(R, lonlim)
            validateattributes(lonlim, ...
                {'double'}, {'real','row','finite','size',[1 2]}, ...
                [class(R) '.set.LongitudeLimits'], 'lonlim')
            
            map.internal.assert(lonlim(1) < lonlim(2), ...
                'map:spatialref:expectedAscendingLimits','lonlim')
            
            % Reset delta longitude properties while maintaining raster
            % size and row direction.
            R = constrainToFitLongitudeLimits(R, lonlim);
            
            R.pLongitudeLimits = getLongitudeLimits(R);
        end
        
        
        function R = set.ColumnsStartFrom(R, edge)
            edge = validatestring(edge,{'north','south'});
            latlim = R.pLatitudeLimits;
            if strcmp(edge,'south')
                % Columns run south to north
                R.FirstCornerLatitude = latlim(1);
                R.DeltaLatitudeNumerator = abs(R.DeltaLatitudeNumerator);
            else
                % Columns run north to south
                R.FirstCornerLatitude = latlim(2);
                R.DeltaLatitudeNumerator = -abs(R.DeltaLatitudeNumerator);
            end
        end
        
        
        function R = set.RowsStartFrom(R, edge)
            edge = validatestring(edge,{'east','west'});
            lonlim = R.pLongitudeLimits;
            if strcmp(edge,'west')
                % Rows run west to east
                R.FirstCornerLongitude = lonlim(1);
                R.DeltaLongitudeNumerator = abs(R.DeltaLongitudeNumerator);
            else
                % Rows run east to west
                R.FirstCornerLongitude = lonlim(2);
                R.DeltaLongitudeNumerator = -abs(R.DeltaLongitudeNumerator);
            end
        end
        
        function R = set.GeographicCRS(R, crs)
            if ~isempty(crs)
                validateattributes(crs, ...
                    {'geocrs'}, {'scalar'}, ...
                    [class(R) '.set.GeographicCRS'], 'crs')
                if strcmp(crs.AngleUnit, R.AngleUnit)
                    R.pGeographicCRS = crs;
                else
                    error(message('map:spatialref:angleUnitInconsistent'))
                end
            else
                R.pGeographicCRS = [];
            end
        end
        
    end
    
    %----------------- Get methods for public properties ------------------
    
    methods
        function rasterSize = get.RasterSize(R)
            I = R.Intrinsic;
            rasterSize = [I.NumRows I.NumColumns];
        end
        
        
        function angleUnit = get.AngleUnit(R)
            angleUnit = R.pAngleUnit;
        end
        
        
        function limits = get.LatitudeLimits(R)
            limits = R.pLatitudeLimits;
        end
        
        
        function limits = get.LongitudeLimits(R)
            limits = R.pLongitudeLimits;
        end
        
        
        function edge = get.ColumnsStartFrom(R)
            if R.DeltaLatitudeNumerator > 0
                edge = 'south';
            else
                edge = 'north';
            end
        end
        
        
        function edge = get.RowsStartFrom(R)
            if R.DeltaLongitudeNumerator > 0
                edge = 'west';
            else
                edge = 'east';
            end
        end
        
        
        function extent = get.RasterExtentInLatitude(R)
            rasterExtentInYIntrinsic = abs(diff(R.YIntrinsicLimits));
            extent = abs(R.DeltaLatitudeNumerator) ...
                * rasterExtentInYIntrinsic / R.DeltaLatitudeDenominator;
        end
        
        
        function extent = get.RasterExtentInLongitude(R)
            rasterExtentInXIntrinsic = abs(diff(R.XIntrinsicLimits));
            extent = abs(R.DeltaLongitudeNumerator) ...
                * rasterExtentInXIntrinsic / R.DeltaLongitudeDenominator;
        end
        
        
        function crs = get.GeographicCRS(R)
            crs = R.pGeographicCRS;
        end       
    end
    
    %---------------------- Protected/private methods ---------------------
    
    methods (Access = protected)
        
        function latlim = getLatitudeLimits(R)
            yi = R.YIntrinsicLimits;
            columnsRunSouthToNorth = (R.DeltaLatitudeNumerator > 0);
            if columnsRunSouthToNorth
                latlim = R.intrinsicYToLatitude(yi);
            else
                latlim = R.intrinsicYToLatitude(yi([2 1]));
            end
        end
        
        
        function lonlim = getLongitudeLimits(R)
            xi = R.XIntrinsicLimits;
            rowsRunWestToEast = (R.DeltaLongitudeNumerator > 0);
            if rowsRunWestToEast
                lonlim = R.intrinsicXToLongitude(xi);
            else
                lonlim = R.intrinsicXToLongitude(xi([2 1]));
            end
        end
        
        
        function R = constrainToFitLatitudeLimits(R, latlim)
            % Constrain properties controlling latitude vs. intrinsicY
            %
            % If the raster has one or more rows, set the values of
            % these defining properties:
            %
            %     FirstCornerLatitude
            %     DeltaLatitudeNumerator
            %     DeltaLatitudeDenominator
            %
            % to be consistent with the specified LATLIM value, unless
            % the RasterInterpretation is 'postings' and the raster
            % has only one row. The extent in latitude (and intrinsic Y) of
            % such a raster is 0, so it requires special handling.
            
            s = latlim(1);
            n = latlim(2);
            if R.DeltaLatitudeNumerator > 0
                dlat = n - s;
                R.FirstCornerLatitude = s;
            else
                dlat = s - n;
                R.FirstCornerLatitude = n;
            end
            [R.DeltaLatitudeNumerator, R.DeltaLatitudeDenominator] ...
                = map.rasterref.internal.simplifyRatio( ...
                dlat, diff(R.YIntrinsicLimits));
        end
        
        
        function R = setLatitudeProperties(R, ...
                firstCornerLat, deltaLatNumerator, deltaLatDenominator)
            % Set properties controlling latitude vs. intrinsicY
            %
            % Set the following properties as a group:
            %
            %      FirstCornerLatitude
            %      DeltaLatitudeNumerator
            %      DeltaLatitudeDenominator
            %
            % These properties in combination with RasterSize(1)
            % determine the latitude limits and must be validated
            % together.
            
            % Validate individual inputs
            fname = [class(R) '.setLatitudeProperties'];
            
            validateattributes(firstCornerLat, {'double'}, ...
                {'real','scalar','finite'}, fname, 'firstCornerLat')
            
            validateattributes(deltaLatNumerator, {'double'}, ...
                {'real','scalar','finite','nonzero'}, ...
                fname, 'deltaLatNumerator')
            
            validateattributes(deltaLatDenominator, {'double'}, ...
                {'real','scalar','finite','positive'}, ...
                fname, 'deltaLatDenominator')
            
            % Assign property values
            R.FirstCornerLatitude = firstCornerLat;
            [R.DeltaLatitudeNumerator, R.DeltaLatitudeDenominator] ...
                = map.rasterref.internal.simplifyRatio( ...
                deltaLatNumerator, deltaLatDenominator);
            
            % Note: At this point the value object R has been
            % modified and could have invalid latitude limits, but
            % that's OK because we're about to check them. If there's
            % a problem this method will end in an error rather than
            % returning the modified version of R.
            
            % Determine the latitude limits implied by the inputs
            latlim = R.getLatitudeLimits();
            R.pLatitudeLimits = latlim;
            
            % Validate the implied latitude limits
            map.internal.assert(all(isfinite(latlim)), ...
                'map:spatialref:invalidLatProps',R.RasterSize(1), ...
                'FirstCornerLatitude','DeltaLatitudeNumerator','DeltaLatitudeDenominator')
        end
        
        
        function R = constrainToFitLongitudeLimits(R, lonlim)
            % Constrain properties controlling longitude vs. intrinsicX
            %
            % If the raster has one or more columns, set the values of
            % these defining properties:
            %
            %     FirstCornerLongitude
            %     DeltaLongitudeNumerator
            %     DeltaLongitudeDenominator
            %
            % to be consistent with a specific LONLIM value, unless
            % the RasterInterpretation is 'postings' and the raster has
            % only one column. The extent in longitude (and intrinsic X) of
            % such a raster is 0, so it requires special handling.
            
            w = lonlim(1);
            e = lonlim(2);
            if R.DeltaLongitudeNumerator > 0
                dlon = e - w;
                R.FirstCornerLongitude = w;
            else
                dlon = w - e;
                R.FirstCornerLongitude = e;
            end
            [R.DeltaLongitudeNumerator, R.DeltaLongitudeDenominator] ...
                = map.rasterref.internal.simplifyRatio( ...
                dlon, diff(R.XIntrinsicLimits));
        end
        
        
        function R = setLongitudeProperties(R, ...
                firstCornerLon, deltaLonNumerator, deltaLonDenominator)
            % Set properties controlling longitude vs. intrinsicX
            %
            % Set the following properties as a group:
            %
            %      FirstCornerLongitude
            %      DeltaLongitudeNumerator
            %      DeltaLongitudeDenominator
            %
            % These properties determine the longitude limits and must be
            % validated together.
            
            % Validate individual inputs
            fname = [class(R) '.setLongitudeProperties'];
            
            validateattributes(firstCornerLon, {'double'}, ...
                {'real','scalar','finite'}, fname, 'firstCornerLon')
            
            validateattributes(deltaLonNumerator, {'double'}, ...
                {'real','scalar','finite','nonzero'}, ...
                fname, 'deltaLonNumerator')
            
            validateattributes(deltaLonDenominator, {'double'}, ...
                {'real','scalar','finite','positive'}, ...
                fname, 'deltaLonDenominator')
            
            % Assign property values
            R.FirstCornerLongitude = firstCornerLon;
            [R.DeltaLongitudeNumerator, R.DeltaLongitudeDenominator] ...
                = map.rasterref.internal.simplifyRatio( ...
                deltaLonNumerator, deltaLonDenominator);
            
            R.pLongitudeLimits = getLongitudeLimits(R);
        end
        
        
        function S = encodeInStructure(R)
            % Encode the state of the geographic raster reference object R
            % into structure S.
            S = struct( ...
                'RasterSize',                R.RasterSize, ...
                'FirstCornerLatitude',       R.FirstCornerLatitude, ...
                'FirstCornerLongitude',      R.FirstCornerLongitude, ...
                'DeltaLatitudeNumerator',    R.DeltaLatitudeNumerator, ...
                'DeltaLatitudeDenominator',  R.DeltaLatitudeDenominator, ...
                'DeltaLongitudeNumerator',   R.DeltaLongitudeNumerator, ...
                'DeltaLongitudeDenominator', R.DeltaLongitudeDenominator);
            
            % Store CRS
            S.GeographicCRS = R.GeographicCRS;
        end
        
        
        function R = resetFromStructure(R, S)
            % Reset geographic raster reference object R to the state
            % defined by the scalar structure S.
            
            % Update the intrinsic properties on which RasterSize depends,
            % without using its set method.
            R = setIntrinsicRasterSize(R, S.RasterSize);
            
            % None of the following 6 properties have set methods.
            R.FirstCornerLatitude       = S.FirstCornerLatitude;
            R.FirstCornerLongitude      = S.FirstCornerLongitude;
            R.DeltaLatitudeNumerator    = S.DeltaLatitudeNumerator;
            R.DeltaLatitudeDenominator  = S.DeltaLatitudeDenominator;
            R.DeltaLongitudeNumerator   = S.DeltaLongitudeNumerator;
            R.DeltaLongitudeDenominator = S.DeltaLongitudeDenominator;
            
            R.pLatitudeLimits  = getLatitudeLimits(R);
            R.pLongitudeLimits = getLongitudeLimits(R);
            
            % Restore CRS
            if isfield(S,'GeographicCRS')
                R.GeographicCRS = S.GeographicCRS;
            end
        end
        
        
        function R = setAbsoluteDeltaLatitude(R, absoluteDeltaLatitude)
            % Set the absolute value of DeltaLatitude, preserving its sign.
            %
            %   R -- Geographic raster reference object
            %   absoluteDeltaLatitude -- New absolute value for deltaLatitude
            %
            % Set the protected, defining properties directly, without
            % triggering any additional set methods.
            
            % Current raster size and latitude limits
            rasterSize = R.RasterSize;
            latlim = R.pLatitudeLimits;
            
            % New delta latitude numerator and denominator
            [num, den] = map.rasterref.internal.simplifyRatio(absoluteDeltaLatitude, 1);
            num = num * sign(R.DeltaLatitudeNumerator);
            R.DeltaLatitudeNumerator = num;
            R.DeltaLatitudeDenominator = den;
            
            % New latitude limits and first corner latitude
            latlim = map.internal.snapLatitudeLimits(latlim, num, den);
            if num > 0
                R.FirstCornerLatitude = latlim(1);
            else
                R.FirstCornerLatitude = latlim(2);
            end
            
            % New raster size
            rasterSize(1) = R.ElementsMinusIntervals ...
                + round(den * (latlim(2) - latlim(1)) / abs(num));
            R = setIntrinsicRasterSize(R, rasterSize);
            
            R.pLatitudeLimits = R.getLatitudeLimits();
        end
        
        
        function R = setAbsoluteDeltaLongitude(R, absoluteDeltaLongitude)
            % Set the absolute value of DeltaLatitude, preserving its sign.
            %
            %   R -- Geographic raster reference object
            %   absoluteDeltaLongitude -- New absolute value for deltaLongitude
            %
            % Set the protected, defining properties directly, without
            % triggering any additional set methods.
            
            % Current raster size and longitude limits
            rasterSize = R.RasterSize;
            lonlim = R.pLongitudeLimits;
            
            % New delta latitude numerator and denominator
            [num, den] = map.rasterref.internal.simplifyRatio(absoluteDeltaLongitude, 1);
            num = num * sign(R.DeltaLongitudeNumerator);
            R.DeltaLongitudeNumerator = num;
            R.DeltaLongitudeDenominator = den;
            
            % New longitude limits and first corner longitude
            lonlim = map.internal.snapLongitudeLimits(lonlim, num, den);
            if num > 0
                R.FirstCornerLongitude = lonlim(1);
            else
                R.FirstCornerLongitude = lonlim(2);
            end
            
            % New raster size
            rasterSize(2) = R.ElementsMinusIntervals ...
                + round(den * (lonlim(2) - lonlim(1)) / abs(num));
            R = setIntrinsicRasterSize(R, rasterSize);
            
            R.pLongitudeLimits = getLongitudeLimits(R);
        end
    end
    
    
    methods (Access = private)
        function R = setIntrinsicRasterSize(R, rasterSize)
            % Update the intrinsic properties on which RasterSize depends.
            I = R.Intrinsic;
            I = setRasterSize(I, rasterSize);
            R.Intrinsic = I;
            
            % Update transient properties.
            [xlimits, ylimits] = limits(I);
            R.XIntrinsicLimits = xlimits;
            R.YIntrinsicLimits = ylimits;
        end
    end
    
    
    methods (Abstract, Access = protected)
        tf = is360DegreeRasterWithDuplicateColumns(R)
    end
end


function tf = beyondPole(northPoleLatitude, lat)
% True if lat falls north of 90 degrees N or south of 90
% degrees S. False otherwise, including when lat is
% NaN-valued.
    tf = (lat < -northPoleLatitude | northPoleLatitude < lat);
end
