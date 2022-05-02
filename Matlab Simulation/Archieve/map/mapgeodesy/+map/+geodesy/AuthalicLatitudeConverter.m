classdef AuthalicLatitudeConverter
%AuthalicLatitudeConverter Convert between geodetic and authalic latitudes
%
%   The authalic latitude maps an ellipsoid (oblate spheroid) to a sphere
%   while preserving surface area.  Authalic latitudes are used when
%   implementing equal area map projections on the ellipsoid.  A
%   map.geodesy.AuthalicLatitudeConverter object provides conversion
%   methods between geodetic and authalic latitudes for an ellipsoid
%   with a given eccentricity.
%
%   AuthalicLatitudeConverter properties:
%      Eccentricity - Eccentricity of oblate spheroid
%
%   AuthalicLatitudeConverter methods:
%      AuthalicLatitudeConverter - Construct authalic latitude converter
%      forward - Geodetic latitude to authalic latitude
%      inverse - Authalic latitude to geodetic latitude
%
%   See also geocentricLatitude, parametricLatitude, map.geodesy.ConformalLatitudeConverter, map.geodesy.IsometricLatitudeConverter, map.geodesy.RectifyingLatitudeConverter

% Copyright 2012-2017 The MathWorks, Inc.

% Reference
% ---------
% John P. Snyder, "Map Projections - A Working Manual,"  U.S. Geological
% Survey Professional Paper 1395, U.S. Government Printing Office,
% Washington, DC, 1987, page 16.
    
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
        
        % Series coefficients for geodetic-to-authalic conversion
        ForwardCoefficients = 0;
        
        % Series coefficients for authalic-to-geodetic conversion
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
        
        function converter = AuthalicLatitudeConverter(spheroid)
            %AuthalicLatitudeConverter Construct authalic latitude converter
            %
            %   converter = map.geodesy.AuthalicLatitudeConverter returns
            %   an authalic latitude converter object for a sphere (with
            %   Eccentricity 0).
            %
            %   converter = map.geodesy.AuthalicLatitudeConverter(spheroid)
            %   returns an authalic latitude converter object with
            %   Eccentricity matching the specified spheroid object.
            %
            %   Example
            %   -------
            %   % The two converters constructed below are equivalent.
            %   grs80 = referenceEllipsoid('GRS 80');
            %
            %   conv1 = map.geodesy.AuthalicLatitudeConverter;
            %   conv1.Eccentricity = grs80.Eccentricity
            %
            %   conv2 = map.geodesy.AuthalicLatitudeConverter(grs80)
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
            %   map.geodesy.AuthalicLatitudeConverter.
            
            if nargin > 0
                converter.Eccentricity = spheroid.Eccentricity;
            end
        end
        
        
        function beta = forward(converter, phi, angleUnit)
            %forward Geodetic latitude to authalic latitude
            %
            %   BETA = FORWARD(CONVERTER,PHI) returns the authalic
            %   latitude corresponding to geodetic latitude PHI.
            %
            %   BETA = FORWARD(CONVERTER,PHI,angleUnit) specifies the units
            %   of input PHI and output BETA.
            %
            %   Example
            %   -------
            %   phi = [-90 -67.5 -45 -22.5 0 22.5 45 67.5 90];
            %   conv = map.geodesy.AuthalicLatitudeConverter(wgs84Ellipsoid);
            %   beta = forward(conv,phi)
            %
            %   Input Arguments
            %   ---------------
            %   CONVERTER -- Authalic latitude converter, specified as a
            %     scalar map.geodesy.AuthalicLatitudeConverter object.
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
            %   BETA -- Authalic latitude of each element in PHI, returned
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
                beta = phi - rad2deg(delta);
            else
                beta = phi - delta;
            end
        end
        
        
        function phi = inverse(converter, beta, angleUnit)
            %inverse Authalic latitude to geodetic latitude
            %
            %   PHI = INVERSE(CONVERTER,BETA) returns the geodetic
            %   latitude corresponding to authalic latitude BETA.
            %
            %   PHI = INVERSE(CONVERTER,BETA,angleUnit) specifies the units
            %   of input BETA and output PHI.
            %
            %   Example
            %   -------
            %   beta = [-90 -67.4092 -44.8717 -22.4094 0 22.4094 44.8717 67.4092 90];
            %   conv = map.geodesy.AuthalicLatitudeConverter(wgs84Ellipsoid);
            %   phi = inverse(conv,beta)
            %
            %   Input Arguments
            %   ---------------
            %   CONVERTER -- Authalic latitude converter, specified as a
            %     scalar map.geodesy.AuthalicLatitudeConverter object.
            %
            %   BETA -- Authalic latitude of one or more points, specified
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
            %   PHI -- Geodetic latitude of each element in BETA, returned
            %      as a scalar value, vector, matrix, or N-D array. Units
            %      are determined by the input argument angleUnit, if
            %      supplied; values are in degrees, otherwise.
            
            inDegrees = (nargin < 3) || map.geodesy.isDegree(angleUnit);
            
            % The following value will always be in radians, because the
            % elements of the vector converter.InverseCoefficients are in
            % radians.  For further explanation, see the Output Units
            % section in the help for map.geodesy.internal.sumSineSeries.
            delta = map.geodesy.internal.sumSineSeries( ...
                2*beta, converter.InverseCoefficients, inDegrees);
            
            if inDegrees
                phi = beta + rad2deg(delta);
            else
                phi = beta + delta;
            end
        end
        
    end
    
    %---------------------- Set and get methods --------------------------
    
    methods
        
        function converter = set.Eccentricity(converter, ecc)
            
            validateattributes(ecc, {'double'}, ...
                {'real','scalar','nonnegative','<=', 0.5},'','eccentricity')
            
            converter.pEccentricity = ecc;
            
            e2 = ecc^2;
            e4 = e2 * e2;
            e6 = e2 * e4;
            
            a = [ ...
                 e2 * (1/3 + e2 * (31/180 + e2 * 59/560)); ...
                -e4 * (17/360 + e2 * 61/1260); ...
                 e6 * 383/45360; ...
                 0];
            
            c = [ ...
                e2 * (1/3 + e2 * (31/180 + e2 * 517/5040)); ...
                e4 * (23/360 + e2 * 251/3780); ...
                e6 * 761/45360; ...
                0];
            
            converter.ForwardCoefficients = map.geodesy.internal.setUpSineSeries4(a);
            converter.InverseCoefficients = map.geodesy.internal.setUpSineSeries4(c);
        end
        
        
        function eccentricity = get.Eccentricity(converter)
            eccentricity = converter.pEccentricity;
        end
        
    end
    
end
