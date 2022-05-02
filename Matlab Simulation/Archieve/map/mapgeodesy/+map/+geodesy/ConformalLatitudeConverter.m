classdef ConformalLatitudeConverter
%ConformalLatitudeConverter Convert between geodetic and conformal latitudes
%
%   The conformal latitude maps an ellipsoid (oblate spheroid) to a sphere
%   while preserving shapes and angles locally. (Curves that meet at a
%   given angle on the ellipsoid meet at the same angle on the sphere.)
%   Conformal latitudes are used when implementing conformal map
%   projections on the ellipsoid.  A map.geodesy.ConformalLatitudeConverter
%   object provides conversion methods between geodetic and conformal
%   latitudes for an ellipsoid with a given eccentricity.
%
%   ConformalLatitudeConverter properties:
%      Eccentricity - Eccentricity of oblate spheroid
%
%   ConformalLatitudeConverter methods:
%      ConformalLatitudeConverter - Construct conformal latitude converter
%      forward - Geodetic latitude to conformal latitude
%      inverse - Conformal latitude to geodetic latitude
%
%   See also geocentricLatitude, parametricLatitude, map.geodesy.AuthalicLatitudeConverter, map.geodesy.IsometricLatitudeConverter, map.geodesy.RectifyingLatitudeConverter

% Copyright 2012-2017 The MathWorks, Inc.

% Reference
% ---------
% John P. Snyder, "Map Projections - A Working Manual,"  US Geological
% Survey Professional Paper 1395, US Government Printing Office,
% Washington, DC, 1987, page 15.

    %------------------- Properties: Public + visible --------------------
    
    properties (Dependent)
        %Eccentricity First eccentricity of oblate spheroid
        %
        %   Eccentricity is a scalar double falling in the interval
        %   [0 0.5].  (Eccentricities larger than 0.5 are possible in
        %   theory, but do not occur in practice and are not supported.)
        Eccentricity
    end
        
    %---------------- Properties: Private + hidden ---------------------
    
    properties (Access = private, Hidden)
        
        % Private copy of dependent Eccentricity property
        pEccentricity = 0;
        
     end
    
        
     properties (Access = private, Hidden, Transient)
        
       % Series coefficients for conformal-to-geodetic conversion
        InverseCoefficients = 0;
        
    end
    
    %-------------------------- Load object ----------------------------
    
    methods (Static)
        
        function converter = loadobj(converter)
            % Update the coefficients, which are stored in a transient
            % property, by triggering the set.Eccentricity method.
            
            converter.Eccentricity = converter.Eccentricity;
        end
        
    end
    
    %--------------- Constructor and ordinary methods --------------------
    
    methods
        
        function converter = ConformalLatitudeConverter(spheroid)
            %ConformalLatitudeConverter Construct conformal latitude converter
            %
            %   converter = map.geodesy.ConformalLatitudeConverter returns
            %   a conformal latitude converter object for a sphere (with
            %   Eccentricity 0).
            %
            %   converter = map.geodesy.ConformalLatitudeConverter(spheroid)
            %   returns a conformal latitude converter object with
            %   Eccentricity matching the specified spheroid object.
            %
            %   Example
            %   -------
            %   % The two converters constructed below are equivalent.
            %   grs80 = referenceEllipsoid('GRS 80');
            %   
            %   conv1 = map.geodesy.ConformalLatitudeConverter;
            %   conv1.Eccentricity = grs80.Eccentricity
            %
            %   conv2 = map.geodesy.ConformalLatitudeConverter(grs80)
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
            %   map.geodesy.ConformalLatitudeConverter.

            if nargin > 0
                converter.Eccentricity = spheroid.Eccentricity;
            end
        end
        
        
        function chi = forward(converter, phi, angleUnit)
            %forward Geodetic latitude to conformal latitude
            %
            %   CHI = FORWARD(CONVERTER,PHI) returns the conformal
            %   latitude corresponding to geodetic latitude PHI.
            %
            %   CHI = FORWARD(CONVERTER,PHI,angleUnit) specifies the units
            %   of input PHI and output CHI.
            %
            %   Example
            %   -------
            %   phi = [-90 -67.5 -45 -22.5 0 22.5 45 67.5 90];
            %   conv = map.geodesy.ConformalLatitudeConverter(wgs84Ellipsoid);
            %   chi = forward(conv,phi)
            %
            %   Input Arguments
            %   ---------------
            %   CONVERTER -- Conformal latitude converter, specified as a
            %     scalar map.geodesy.ConformalLatitudeConverter object.
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
            %   CHI -- Conformal latitude of each element in PHI, returned as a 
            %      scalar value, vector, matrix, or N-D array.  Units
            %      are determined by the input argument angleUnit, if
            %      supplied; values are in degrees, otherwise.
            
            inDegrees = (nargin < 3) || map.geodesy.isDegree(angleUnit);
            
            ecc = converter.pEccentricity;
            if inDegrees
                t = ecc * sind(phi);
                chi = 2 * atand(tand(45 + phi/2) .* ...
                    ((1 - t)./(1 + t)).^(ecc/2)) - 90;
            else
                t = ecc * sin(phi);
                chi = 2 * atan(tan(pi/4 + phi/2) .* ...
                    ((1 - t)./(1 + t)).^(ecc/2)) - pi/2;
            end
        end
        
        
        function phi = inverse(converter, chi, angleUnit)
            %inverse Conformal latitude to geodetic latitude
            %
            %   PHI = INVERSE(CONVERTER,CHI) returns the geodetic
            %   latitude corresponding to conformal latitude CHI.
            %
            %   PHI = INVERSE(CONVERTER,CHI,angleUnit) specifies the units
            %   of input CHI and output PHI.
            %
            %   Example
            %   -------
            %   chi = [-90 -67.3637 -44.8077 -22.3643 0 22.3643 44.8077 67.3637 90];
            %   conv = map.geodesy.ConformalLatitudeConverter(wgs84Ellipsoid);
            %   phi = inverse(conv,chi)
            %
            %   Input Arguments
            %   ---------------
            %   CONVERTER -- Conformal latitude converter object
            %
            %     map.geodesy.ConformalLatitudeConverter, specified as a
            %     scalar object.
            %
            %   CHI -- Conformal latitude of one or more points, specified
            %     as a scalar value, vector, matrix, or N-D array.  Values
            %     must be in units that match the input argument angleUnit,
            %     if supplied, and in degrees, otherwise.
            %     Data types: single or double.
            %
            %   angleUnit -- Units of angles, specified as 'degrees'
            %     (default) or 'radians'.  Data type: string or char.
            %   
            %   Output Argument
            %   ---------------
            %   PHI -- Geodetic latitude of each element in CHI, returned
            %      as a scalar value, vector, matrix, or N-D array. Units
            %      are determined by the input argument angleUnit, if
            %      supplied; values are in degrees, otherwise.
            
            inDegrees = (nargin < 3) || map.geodesy.isDegree(angleUnit);
            
            % The following value will always be in radians, because the
            % elements of the vector converter.InverseCoefficients are in
            % radians.  For further explanation, see the Output Units
            % section in the help for map.geodesy.internal.sumSineSeries.
            delta = map.geodesy.internal.sumSineSeries( ...
                2*chi, converter.InverseCoefficients, inDegrees);
            
            if inDegrees
                phi = chi + rad2deg(delta);
            else
                phi = chi + delta;
            end
        end
        
    end
    
    %---------------------- Set and get methods --------------------------
    
    methods
        
        function converter = set.Eccentricity(converter, eccentricity)
            
            validateattributes(eccentricity, {'double'}, ...
                {'real','scalar','nonnegative','<=', 0.5},'','eccentricity')
            
            converter.pEccentricity = eccentricity;
            
            e2 = eccentricity^2;
            e4 = e2 * e2;
            e6 = e2 * e4;
            
            c = [ ...
                e2 * (1/2 + e2 * (5/24 + e2 * (1/12 + e2 * 13/360))), ...
                e4 * (7/48 + e2 * (29/240 + e2 * 811/11520)), ...
                e6 * (7/120 + e2 * 81/1120), ...
                e2 * e6 * 4279/161280];

            converter.InverseCoefficients = map.geodesy.internal.setUpSineSeries4(c);
        end
        
        
        function eccentricity = get.Eccentricity(converter)
            eccentricity = converter.pEccentricity;
        end
        
    end
    
end
