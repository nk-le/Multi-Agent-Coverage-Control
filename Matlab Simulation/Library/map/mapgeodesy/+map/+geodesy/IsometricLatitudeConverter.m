classdef IsometricLatitudeConverter
%IsometricLatitudeConverter Convert between geodetic and isometric latitudes
%
%   The isometric latitude is a nonlinear function of the geodetic latitude
%   that is directly proportional to the spacing of parallels, relative to
%   the Equator, in an ellipsoidal Mercator projection.  It is a
%   dimensionless quantity and, unlike other types of auxiliary latitude,
%   the isometric latitude is not angle-valued. It equals Inf at the north
%   pole and -Inf at the south pole. A map.geodesy.IsometricLatitudeConverter
%   object provides conversion methods between geodetic and isometric
%   latitudes for an ellipsoid with a given eccentricity.
%
%   IsometricLatitudeConverter properties:
%      Eccentricity - Eccentricity of oblate spheroid
%
%   IsometricLatitudeConverter methods:
%      IsometricLatitudeConverter - Construct isometric latitude converter
%      forward - Geodetic latitude to isometric latitude
%      inverse - Isometric latitude to geodetic latitude
%
%   See also geocentricLatitude, parametricLatitude, map.geodesy.AuthalicLatitudeConverter, map.geodesy.ConformalLatitudeConverter, map.geodesy.RectifyingLatitudeConverter

% Copyright 2012-2017 The MathWorks, Inc.

% Reference
% ---------
% John P. Snyder, "Map Projections - A Working Manual,"  U.S. Geological
% Survey Professional Paper 1395, U.S. Government Printing Office,
% Washington, DC, 1987, page 15.

    %------------------- Properties: Public + visible --------------------
    
    properties (Dependent = true)
        
        %Eccentricity First eccentricity of oblate spheroid
        %
        %   Eccentricity is a scalar double falling in the interval
        %   [0 0.5].  (Eccentricities larger than 0.5 are possible in
        %   theory, but do not occur in practice and are not supported.)
        Eccentricity
        
    end
        
    %---------------- Properties: Private + hidden ---------------------
    
    properties (Access = private, Hidden = true)
        
        % An isometric latitude converter adds a wrapper around a conformal
        % latitude converter.
        pConformalConverter = map.geodesy.ConformalLatitudeConverter();
        
    end
    
    %--------------- Constructor and ordinary methods --------------------
    
    methods
        
        function converter = IsometricLatitudeConverter(spheroid)
            %IsometricLatitudeConverter Construct isometric latitude converter
            %
            %   converter = map.geodesy.IsometricLatitudeConverter returns
            %   an isometric latitude converter object for a sphere (with
            %   Eccentricity 0).
            %
            %   converter = map.geodesy.IsometricLatitudeConverter(spheroid)
            %   returns an isometric latitude converter object with
            %   Eccentricity matching the specified spheroid object.
            %
            %   Example
            %   -------
            %   % The two converters constructed below are equivalent.
            %   grs80 = referenceEllipsoid('GRS 80');
            %   
            %   conv1 = map.geodesy.IsometricLatitudeConverter;
            %   conv1.Eccentricity = grs80.Eccentricity
            %
            %   conv2 = map.geodesy.IsometricLatitudeConverter(grs80)
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
            %   map.geodesy.IsometricLatitudeConverter.
 
            if nargin > 0
                converter.Eccentricity = spheroid.Eccentricity;
            end
        end
        
        
        function psi = forward(converter, phi, angleUnit)
            %forward Geodetic latitude to isometric latitude
            %
            %   PSI = FORWARD(CONVERTER,PHI) returns the isometric
            %   latitude corresponding to geodetic latitude PHI.
            %
            %   PSI = FORWARD(CONVERTER,PHI,angleUnit) specifies the units
            %   of input PHI.
            %
            %   Example
            %   -------
            %   phi = [-90 -67.5 -45 -22.5 0 22.5 45 67.5 90];
            %   conv = map.geodesy.IsometricLatitudeConverter(wgs84Ellipsoid);
            %   psi = forward(conv,phi)
            %
            %   Input Arguments
            %   ---------------
            %   CONVERTER -- Isometric latitude converter, specified as a
            %     scalar map.geodesy.IsometricLatitudeConverter object.
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
            %   PSI -- Isometric latitude of each element in PHI, returned
            %      as a scalar value, vector, matrix, or N-D array.
            %      Unlike PHI, isometric latitude is a dimensionless number
            %      and does not have an angle unit.
            %

            % When working in degrees, the isometric latitudes of the
            % poles match their exact values of -Inf and Inf (south and
            % north, respectively). But because pi/2 in floating point is
            % slightly less than the exact value of pi divided by 2, when
            % working in radians we'd get -/+ log(tan(pi/2)), or about
            % -/+ 37.3318561932689 if we omitted the special check below.

            inDegrees = (nargin < 3) || map.geodesy.isDegree(angleUnit);
            
            % Compute conformal latitude, chi, as an intermediate step in
            % computing isometric latitude from geodetic latitude.
            if inDegrees
                chi = forward(converter.pConformalConverter, abs(phi));
                psi = sign(phi) .* log(tand(45 + chi/2));
            else
                chi = forward(converter.pConformalConverter, abs(phi), 'radian');
                psi = sign(phi) .* log(tan(pi/4 + chi/2));
                
                % Ensure exact results (+/- Inf) at the poles.
                polar = (abs(phi) == pi/2);
                psi(polar) = sign(phi(polar)) * Inf;
            end
        end
        
        
        function phi = inverse(converter, psi, angleUnit)
            %inverse Isometric latitude to geodetic latitude
            %
            %   PHI = INVERSE(CONVERTER,PSI) returns the geodetic
            %   latitude corresponding to isometric latitude PSI.
            %
            %   PHI = INVERSE(CONVERTER,PSI,angleUnit) specifies the units
            %   of output PHI.
            %
            %   Example
            %   -------
            %   psi = [-Inf -1.6087 -0.87663 -0.40064 0 0.40064 0.87663 1.6087 Inf];
            %   conv = map.geodesy.IsometricLatitudeConverter(wgs84Ellipsoid);
            %   phi = inverse(conv,psi)
            %
            %   Input Arguments
            %   ---------------
            %   CONVERTER -- Isometric latitude converter, specified as a
            %     scalar map.geodesy.IsometricLatitudeConverter object.
            %
            %   PSI -- Isometric latitude of one or more points, specified
            %     as a scalar value, vector, matrix, or N-D array.
            %     Isometric latitude is a dimensionless number and does not
            %     have an angle unit.
            %     Data types: single or double.
            %   
            %   angleUnit -- Units of angles, specified as 'degrees'
            %     (default) or 'radians'.  Data type: string or char.
            %
            %   Output Argument
            %   ---------------
            %   PHI -- Geodetic latitude of each element in PSI, returned
            %      as a scalar value, vector, matrix, or N-D array.  Units
            %      are determined by the input argument angleUnit, if
            %      supplied; values are in degrees, otherwise.
            
            inDegrees = (nargin < 3) || map.geodesy.isDegree(angleUnit);
            
            % Compute conformal latitude, chi, as an intermediate step in
            % computing isometric latitude from geodetic latitude.
            
            if inDegrees
                chi = 2 * atand(exp(psi)) - 90;
                phi = inverse(converter.pConformalConverter, chi);
            else
                chi = 2 * atan(exp(psi)) - pi/2;
                phi = inverse(converter.pConformalConverter, chi, 'radian');
            end
        end
        
    end
    
    %---------------------- Set and get methods --------------------------
    
    methods
        
        function converter = set.Eccentricity(converter, ecc)
            
            validateattributes(ecc, {'double'}, ...
                {'real','scalar','nonnegative','<=', 0.5},'','eccentricity')
            
            converter.pConformalConverter.Eccentricity = ecc;
        end
        
        
        function eccentricity = get.Eccentricity(converter)
            eccentricity = converter.pConformalConverter.Eccentricity;
        end
        
    end
end
