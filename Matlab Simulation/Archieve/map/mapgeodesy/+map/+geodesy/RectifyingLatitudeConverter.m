classdef RectifyingLatitudeConverter
%RectifyingLatitudeConverter Convert between geodetic and rectifying latitudes
%
%   The rectifying latitude maps an ellipsoid (oblate spheroid) to a sphere
%   while preserving the distances along the meridians.  Rectifying
%   latitudes are used when implementing map projections, such as
%   Equidistant Cylindrical, that preserve such distances. A
%   map.geodesy.RectifyingLatitudeConverter object provides conversion
%   methods between geodetic and rectifying latitudes for an ellipsoid with
%   a given third flattening.
%
%   RectifyingLatitudeConverter properties:
%      ThirdFlattening - Third flattening of oblate spheroid
%
%   RectifyingLatitudeConverter methods:
%      RectifyingLatitudeConverter - Construct rectifying latitude converter
%      forward - Geodetic latitude to rectifying latitude
%      inverse - Rectifying latitude to geodetic latitude
%
%   See also geocentricLatitude, parametricLatitude, map.geodesy.AuthalicLatitudeConverter, map.geodesy.ConformalLatitudeConverter, map.geodesy.IsometricLatitudeConverter

% Copyright 2012-2017 The MathWorks, Inc.

%   Reference
%   ---------
%   John P. Snyder, "Map Projections - A Working Manual,"  US Geological
%   Survey Professional Paper 1395, US Government Printing Office,
%   Washington, DC, 1987, page 16.

    %------------------- Properties: Public + visible --------------------
    
    properties (Dependent)
        %ThirdFlattening Third flattening of spheroid
        %
        %   ThirdFlattening is a scalar double falling in the interval
        %   [0, ecc2n(0.5)], or approximately [0 0.071797].  (Flatter
        %   spheroids are possible in theory, but do not occur in practice
        %   and are not supported.)
        ThirdFlattening
    end
        
    %---------------- Properties: Private + hidden ---------------------
    
    properties (Access = private, Hidden)
        
        % Private copy of dependent third flattening property
        pThirdFlattening = 0;
        
    end
    
    
     properties (Access = private, Hidden, Transient)
        
        % Series coefficients for geodetic-to-rectifying conversion
        ForwardCoefficients = 0;
        
        % Series coefficients for rectifying-to-geodetic conversion
        InverseCoefficients = 0;
        
    end
    
    %-------------------------- Load object ----------------------------
    
    methods (Static)
        
        function converter = loadobj(converter)
            % Update the coefficients, which are stored in transient
            % properties, by triggering the set.ThirdFlattening method.
            
            converter.ThirdFlattening = converter.ThirdFlattening;
        end
        
    end
    
   %--------------- Constructor and ordinary methods --------------------
    
    methods
        
        function converter = RectifyingLatitudeConverter(spheroid)
            %RectifyingLatitudeConverter Construct rectifying latitude converter
            %
            %   converter = map.geodesy.RectifyingLatitudeConverter returns
            %   a rectifying latitude converter object for a sphere (with
            %   ThirdFlattening 0).
            %
            %   converter = map.geodesy.RectifyingLatitudeConverter(spheroid)
            %   returns a rectifying latitude converter object with
            %   ThirdFlattening matching the specified spheroid object.
            %
            %   Example
            %   -------
            %   % The two converters constructed below are equivalent.
            %   grs80 = referenceEllipsoid('GRS 80');
            %   
            %   conv1 = map.geodesy.RectifyingLatitudeConverter;
            %   conv1.ThirdFlattening = grs80.ThirdFlattening
            %
            %   conv2 = map.geodesy.RectifyingLatitudeConverter(grs80)
            %
            %   Input Argument
            %   --------------
            %   spheroid -- Reference spheroid, specified as a scalar
            %   referenceEllipsoid, oblateSpheroid, or referenceSphere
            %   object.
            %
            %   Output Argument
            %   ---------------
            %   converter -- Converter object, returned as a scalar
            %   map.geodesy.RectifyingLatitudeConverter.
            
            if nargin > 0
                converter.ThirdFlattening = spheroid.ThirdFlattening;
            end
        end
        
        
        function mu = forward(converter, phi, angleUnit)
            %forward Geodetic latitude to rectifying latitude
            %
            %   MU = FORWARD(CONVERTER,PHI) returns the rectifying
            %   latitude corresponding to geodetic latitude PHI.
            %
            %   MU = FORWARD(CONVERTER,PHI,angleUnit) specifies the units
            %   of input PHI and output MU.
            %
            %   Example
            %   -------
            %   phi = [-90 -67.5 -45 -22.5 0 22.5 45 67.5 90];
            %   conv = map.geodesy.RectifyingLatitudeConverter(wgs84Ellipsoid);
            %   mu = forward(conv,phi)
            %
            %   Input Arguments
            %   ---------------
            %   CONVERTER -- Rectifying latitude converter, specified as a
            %     scalar map.geodesy.RectifyingLatitudeConverter object.
            %
            %   PHI -- Geodetic latitude of one or more points, specified
            %     as a scalar value, vector, matrix, or N-D array. Values
            %     must be in units that match the input argument angleUnit,
            %     if supplied, and in degrees, otherwise.
            %     Data types: single or double.
            %
            %   angleUnit -- Units of angles, specified as 'degrees'
            %     (default) or 'radians'.  Data type: string or char.
            %   
            %   Output Argument
            %   ---------------
            %   MU -- Rectifying latitude of each element in PHI, returned
            %      as a scalar value, vector, matrix, or N-D array. Units
            %      are determined by the input argument angleUnit, if
            %      supplied; values are in degrees, otherwise.
            
            inDegrees = (nargin < 3) || map.geodesy.isDegree(angleUnit);
           
            % The following value will always be in radians, because the
            % elements of the vector converter.ForwardCoefficients are in
            % radians.  For further explanation, see the Output Units
            % section in the help for map.geodesy.internal.sumSineSeries.
            delta = map.geodesy.internal.sumSineSeries( ...
                2*phi, converter.ForwardCoefficients, inDegrees);
            
            if inDegrees
                mu = phi - rad2deg(delta);
            else
                mu = phi - delta;
            end
       end
        
        
        function phi = inverse(converter, mu, angleUnit)
            %inverse Rectifying latitude to geodetic latitude
            %
            %   PHI = INVERSE(CONVERTER,MU) returns the geodetic
            %   latitude corresponding to rectifying latitude MU.
            %
            %   PHI = INVERSE(CONVERTER,MU,angleUnit) specifies the units
            %   of input MU and output PHI.
            %
            %   Example
            %   -------
            %   mu = [-90 -67.3978 -44.8557 -22.3981 0 22.3981 44.8557 67.3978 90];
            %   conv = map.geodesy.RectifyingLatitudeConverter(wgs84Ellipsoid);
            %   phi = inverse(conv,mu)
            %
            %   Input Arguments
            %   ---------------
            %   CONVERTER -- Rectifying latitude converter, specified as a
            %     scalar map.geodesy.RectifyingLatitudeConverter object.
            %
            %   MU -- Rectifying latitude of one or more points, specified
            %     as a scalar value, vector, matrix, or N-D array. Values
            %     must be in units that match the input argument angleUnit,
            %     if supplied, and in degrees, otherwise.
            %     Data types: single or double.
            %
            %   angleUnit -- Units of angles, specified as 'degrees'
            %     (default) or 'radians'.  Data type: string or char.
            %   
            %   Output Argument
            %   ---------------
            %   PHI -- Geodetic latitude of each element in MU, returned
            %      as a scalar value, vector, matrix, or N-D array. Units
            %      are determined by the input argument angleUnit, if
            %      supplied; values are in degrees, otherwise.
             
            inDegrees = (nargin < 3) || map.geodesy.isDegree(angleUnit);
           
            % The following value will always be in radians, because the
            % elements of the vector converter.InverseCoefficients are in
            % radians.  For further explanation, see the Output Units
            % section in the help for map.geodesy.internal.sumSineSeries.
            delta = map.geodesy.internal.sumSineSeries( ...
                2*mu, converter.InverseCoefficients, inDegrees);
            
            if inDegrees
                phi = mu + rad2deg(delta);
            else
                phi = mu + delta;
            end
        end
        
    end
    
    %---------------------- Set and get methods --------------------------
    
    methods
        
        function converter = set.ThirdFlattening(converter, n)
            
            validateattributes(n, {'double'}, ...
                {'real','scalar','nonnegative','<=', ecc2n(0.5)},'','n')
            
            converter.pThirdFlattening = n;
            
            n2 = n^2;
            n3 = n*n2;
            n4 = n*n3;
            
            a = [ ...
                  n  * ( 3/2 - n2 * 9/16); ...
                -n2 * (15/16 - n2 * 15/32); ...
                 n3 * 35/48; ...
                -n4 * 315/512];
            
            c = [ ...
                 n * ( 3/2  - n2 * 27/32); ...
                n2 * (21/16 - n2 * 55/32); ...
                n3 * 151/96; ...
                n4 * 1097/512];                

            converter.ForwardCoefficients = map.geodesy.internal.setUpSineSeries4(a);
            converter.InverseCoefficients = map.geodesy.internal.setUpSineSeries4(c);
        end
        
        
        function n = get.ThirdFlattening(converter)
            n = converter.pThirdFlattening;
        end
        
    end
end
