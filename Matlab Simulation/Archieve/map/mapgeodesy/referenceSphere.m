classdef referenceSphere < map.geodesy.Sphere
%referenceSphere Reference sphere
%
%   A referenceSphere object represents a sphere with a specific name and
%   radius that can be used in map projections and other geodetic
%   operations. It has the following properties.
%
%       * A name (Name)
%
%       * A unit of length (LengthUnit) indicating the unit for the radius
%
%       * A scalar radius (Radius) 
%
%   S = referenceSphere returns a reference sphere object representing a
%   unit sphere.
%
%   S = referenceSphere(NAME) returns a reference sphere object
%   corresponding to NAME, which specifies an approximately spherical body.
%   NAME is one of the following: 'unit sphere', 'earth', 'sun', 'moon',
%   'mercury', 'venus', 'mars', 'jupiter', 'saturn', 'uranus', 'neptune',
%   'pluto'.  NAME is case-insensitive.  The radius of the reference sphere
%   is given in meters.
%
%   S = referenceSphere(NAME, LENGTHUNIT) returns a reference sphere with
%   radius given in the specified length unit. LENGTHUNIT can be any length
%   unit supported by validateLengthUnit.
%
%   referenceSphere properties:
%      Name - Name of reference sphere
%      LengthUnit - Unit of length for radius
%      Radius - Radius of sphere
%
%   referenceSphere properties (read-only):
%      SemimajorAxis - Equatorial radius of sphere, a = Radius
%      SemiminorAxis - Distance from center of sphere to pole, b = Radius
%      InverseFlattening - Reciprocal of flattening, 1/f = Inf
%      Eccentricity - First eccentricity of sphere, ecc = 0
%      Flattening - Flattening of sphere, f = 0
%      ThirdFlattening - Third flattening of sphere, n = 0
%      MeanRadius - Mean radius of sphere
%      SurfaceArea - Surface area of sphere
%      Volume - Volume of sphere
%
%   The first 7 read-only properties are provided to ensure that reference
%   sphere objects can be used interchangeably with reference ellipsoid
%   objects in most contexts. These properties are omitted when an object
%   is displayed on the command line. The last 2 properties, SurfaceArea
%   and Volume, are also omitted, because their values are only needed in
%   certain cases.
%
%   Example
%   -------
%   % Construct a reference sphere that models the Earth as a sphere with
%   % a radius of 6,371,000 meters, then switch to use kilometers instead.
%   s = referenceSphere('Earth')
%   s.LengthUnit = 'kilometer'
%
%   % Surface area of the sphere in square kilometers
%   s.SurfaceArea
%
%   % Volume of the sphere in cubic kilometers
%   s.Volume
%
%   See also referenceEllipsoid, validateLengthUnit

% Copyright 2011-2020 The MathWorks, Inc.

%#codegen
    
    properties
        %Name Name of reference sphere
        %
        %   A value naming or describing the reference sphere.
        %
        %   Default value: 'Unit Sphere'
        Name = 'Unit Sphere';
    end
    
    properties (Dependent = true)
        %LengthUnit Unit of length for radius
        %
        %   An empty character vector, or any unit-of-length accepted by
        %   the validateLengthUnit function.
        %
        %   Default value: ''
        LengthUnit
    end
    
    properties (Access = private, Hidden = true)
        pLengthUnit = '';  % Stores value of LengthUnit
    end
    
    %--------------------------- Constructor ------------------------------

    methods
        function obj = referenceSphere(name, lengthUnit)
            if nargin > 0
                
                % Ensure that NAME is a string or character vector.
                validateattributes(name,{'char','string'}, ...
                    {'nonempty','scalartext'},'referenceSphere','NAME',1)
                
                % Make 'unitsphere' equivalent to 'Unit Sphere'.
                if strncmpi(name,'unitsphere',length(name))
                    name = 'Unit Sphere';
                end
                
                % Names and radii in meters
                spheres = { ...
                    'Unit Sphere',    1; ...
                    'Earth',   6371000; ...
                    'Sun',     6.9446e+08; ...
                    'Moon',    1738000; ...
                    'Mercury', 2439000; ...
                    'Venus',   6051000; ...
                    'Mars',    3.39e+06; ...
                    'Jupiter', 6.9882e+07; ...
                    'Saturn',  5.8235e+07; ...
                    'Uranus',  2.5362e+07; ...
                    'Neptune', 2.4622e+07; ...
                    'Pluto',   1151000 ...
                    };
                
                validNames = spheres(:,1)';
                
                name = validatestring(name, validNames, ...
                    'referenceSphere', 'NAME', 1);
 
                obj.Name = name;
                obj.Radius = spheres{strcmp(name, validNames), 2};
                
                % Set LengthUnit to 'meter', except for the unit sphere.
                if ~strcmp(obj.Name, 'Unit Sphere')
                    obj.pLengthUnit = 'meter';
                end
                
                if nargin > 1
                    obj.LengthUnit = validateLengthUnit(lengthUnit);
                end
            end
        end
    end
    
    %--------------------------- Get method ------------------------------
    
    methods
        
        function lengthUnit = get.LengthUnit(obj)
            lengthUnit = obj.pLengthUnit;
        end
    end
    
    %---------------------------- Set methods -----------------------------
    
    methods
        function obj = set.Name(obj, name)
            % Accept any valid name, including empty.
            if ~isempty(name)
                validateattributes(name, {'char','string'}, {'scalartext'}, '', 'Name')
            else
                validateattributes(name, {'char','string'}, {}, '', 'Name')
            end
            obj.Name = name;
        end
        
        
        function obj = set.LengthUnit(obj, unit)
            % If the length unit is not yet designated, validate the input
            % and assign it. Otherwise rescale the radius, then make
            % the assignment.
            if isempty(unit)
                % It would be unusual to change LengthUnit to empty, but
                % there's no reason to disallow it. Ensure an empty char,
                % vs. empty of some class other than char.
                obj.pLengthUnit = '';
            else
                unit = validateLengthUnit(unit);
                if ~isempty(obj.pLengthUnit)
                    ratio = unitsratio(unit, obj.pLengthUnit);
                    obj.a = ratio * obj.a;
                end
                obj.pLengthUnit = unit;
            end
        end
    end
end
