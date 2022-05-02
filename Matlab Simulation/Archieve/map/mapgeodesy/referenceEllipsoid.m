classdef referenceEllipsoid < oblateSpheroid
%referenceEllipsoid Reference ellipsoid
%
%   A referenceEllipsoid is an oblateSpheroid object with three additional
%   properties:
%
%       * A name (Name)
%
%       * A unit of length (LengthUnit) indicating the units of the 
%         semimajor and semiminor axes
%
%       * A numeric code (Code) that matches an entry in the ellipsoid
%         table of the EPSG/OGP Geodetic Parameter Dataset
%
%   E = referenceEllipsoid returns a reference ellipsoid object
%   that represents the unit sphere.
%
%   E = referenceEllipsoid(NAME) returns a reference ellipsoid object
%   corresponding to NAME. NAME can be one of the short names or long names
%   in the following table.  The values of the SemimajorAxis and
%   SemiminorAxis properties are in meters.  Note that 'earth' is
%   synonymous with 'wgs84'.
%
%   EPSG Code   Short Name        Long Name
%   ---------   ----------        ---------
%   ----        'unitsphere'     'Unit Sphere'
%   7035        'sphere'         'Sphere'
%   7019        'grs80'          'GRS 1980'
%   7030        'wgs84',         'WGS 84'
%   7015        'everest'        'Everest 1830 (1937 Adjustment)'
%   7004        'bessel'         'Bessel 1841'
%   7001        'airy1830'       'Airy 1830'
%   7002        'airy1849'       'Airy Modified 1849'
%   7008        'clarke66'       'Clarke 1866'
%   7012        'clarke80'       'Clarke 1880 (RGS)'
%   7022        'international'  'International 1924'
%   7024        'krasovsky'      'Krassowsky 1940'
%   7043        'wgs72'          'WGS 72'
%   ----        'wgs60'          'World Geodetic System 1960'
%   ----        'iau65'          'International Astronomical Union 1965'
%   ----        'wgs66'          'World Geodetic System 1966'
%   ----        'iau68'          'International Astronomical Union 1968'
%   7030        'earth'          'WGS 84'
%   ----        'sun'            'Sun'
%   ----        'moon'           'Moon'
%   ----        'mercury'        'Mercury'
%   ----        'venus'          'Venus'
%   ----        'mars'           'Mars'
%   ----        'jupiter'        'Jupiter'
%   ----        'saturn'         'Saturn'
%   ----        'uranus'         'Uranus'
%   ----        'neptune'        'Neptune'
%   ----        'pluto'          'Pluto'
%
%   E = referenceEllipsoid(CODE) returns a reference ellipsoid object
%   corresponding to the numerical EPSG code, CODE.  All of the nearly 60
%   codes in the EPSG ellipsoid table are supported, in addition to the
%   ones listed above. The unit of length used for the SemimajorAxis and
%   SemiminorAxis properties depends on the ellipsoid selected, and is
%   indicated in the property E.LengthUnit.
%
%   E = referenceEllipsoid(NAME, LENGTHUNIT) and
%   E = referenceEllipsoid(CODE, LENGTHUNIT) return the ellipsoid object
%   with the SemimajorAxis and SemiminorAxis properties in the specified
%   length unit. LENGTHUNIT can be any length unit supported by
%   validateLengthUnit.
%
%   referenceEllipsoid properties:
%      Code - Numerical EPSG code
%      Name - Name of reference ellipsoid
%      LengthUnit - Unit of length for ellipsoid axes
%      SemimajorAxis - Equatorial radius of spheroid, a
%      SemiminorAxis - Distance from center of spheroid to pole, b
%      InverseFlattening - Reciprocal of flattening, 1/f = a /(a - b)
%      Eccentricity - First eccentricity of spheroid, ecc = sqrt(a^2 - b^2)/a
%
%   referenceEllipsoid properties (read-only):
%      Flattening - Flattening of spheroid, f = (a - b)/a
%      ThirdFlattening - Third flattening of spheroid, n = (a - b)/(a + b)
%      MeanRadius - Mean radius of spheroid, (2*a + b)/3
%      SurfaceArea - Surface area of spheroid
%      Volume - Volume of spheroid
%
%   Examples
%   --------
%   e = referenceEllipsoid
%   e = referenceEllipsoid('GRS80')
%   e = referenceEllipsoid('GRS 1980')
%   e = referenceEllipsoid('GRS80','kilometers')
%   e = referenceEllipsoid(7019)
%   e = referenceEllipsoid(7019,'kilometers')
%   info = geotiffinfo('boston.tif');
%   e = referenceEllipsoid(info.GeoTIFFCodes.Ellipsoid)
%
%   See also geocrs, geodetic2ecef, ecef2geodetic, ecefOffset
%            referenceSphere, validateLengthUnit, wgs84Ellipsoid

% Copyright 2011-2020 The MathWorks, Inc.

%#codegen
    
    properties
        %Code Numerical EPSG code
        %
        %   A numerical code between 7000 and 8000 indicating a row in the
        %   EPSG ellipsoid table.
        %
        %   Default value: []
        Code = [];
        
        %Name Name of reference ellipsoid
        %
        %   A string scalar or character vector naming or describing the
        %   ellipsoid, for example, 'World Geodetic System 1984'
        %
        %   Default value: 'Unit Sphere'        
        Name = 'Unit Sphere';
    end
    
    properties (Dependent = true)
        %LengthUnit Unit of length for ellipsoid axes
        %
        %   An empty character vector, or any unit of length accepted by
        %   the validateLengthUnit function.
        %
        %   Default value: ''        
        LengthUnit
    end
    
    properties (Access = private, Hidden = true)
        pLengthUnit = '';  % Stores value of LengthUnit
    end
    
    properties (GetAccess = private, Constant = true)
        %Ellipsoids Table of ellipsoids supported by name
        %
        %   An N-by-7 cell matrix representing a table listing all
        %   ellipsoids that are supported by name. While most ellipsoids
        %   are defined in terms of their semimajor axis and their inverse
        %   flattening, there are exceptions. Hence, two defining
        %   parameters listed explicitly for each ellipsoid.
        %
        %   Column 1 -- EPSG code
        %   Column 2 -- Short (convenience) name
        %   Column 4 -- Name of first defining property
        %   Column 4 -- Value of first defining property
        %   Column 5 -- Name of second defining property
        %   Column 6 -- Value of second defining property
        %   Column 7 -- Full name
        %
        %   The SemimajorAxis and SemiminorAxis properties are in meters.
        %
        %   References
        %   ----------
        %   Moon, Mercury, Venus: Radii are from J.P. Snyder, Map Projections A
        %   Working Manual, U.S. Geological Survey Paper 1395, US Government
        %   Printing Office, Washington, DC, 1987, Table 2, p. 14. Radii agrees
        %   with the value tabulated in the Encyclopaedia Britannica. 1995.
        %
        %   Sun, Pluto: Radius is the value tabulated in the Encyclopaedia
        %   Britannica, 1995.
        %
        %   Mars, Jupiter: Ellipsoid is derived from polar and equatorial radii
        %   tabulated in the Encyclopaedia Britannica, 1995.
        %
        %   Saturn, Uranus, Neptune: Ellipsoid is derived from the 1 bar polar and
        %   equatorial radii tabulated in the Encyclopaedia Britannica, 1995.
        Ellipsoids = { ...
              [], 'unitsphere',    'SemimajorAxis', 1,           'Eccentricity',       0,             'Unit Sphere'; ...
            7035, 'sphere',        'SemimajorAxis', 6371000,     'Eccentricity',       0,             'Sphere'; ...
            7019, 'grs80',         'SemimajorAxis', 6378137,     'InverseFlattening',  298.257222101, 'GRS 1980'; ...
            7030, 'wgs84',         'SemimajorAxis', 6378137,     'InverseFlattening',  298.257223563, 'WGS 84'; ...
            7015, 'everest',       'SemimajorAxis', 6377276.345, 'InverseFlattening',  300.8017,      'Everest 1830 (1937 Adjustment)'; ...
            7004, 'bessel',        'SemimajorAxis', 6377397.155, 'InverseFlattening',  299.1528128,   'Bessel 1841'; ...
            7001, 'airy1830',      'SemimajorAxis', 6377563.396, 'InverseFlattening',  299.3249646,   'Airy 1830'; ...
            7002, 'airy1849',      'SemimajorAxis', 6377340.189, 'InverseFlattening',  299.3249646,   'Airy Modified 1849'; ...
            7008, 'clarke66',      'SemimajorAxis', 6378206.4,   'SemiminorAxis',      6356583.8,     'Clarke 1866'; ...
            7012, 'clarke80',      'SemimajorAxis', 6378249.145, 'InverseFlattening',  293.465,       'Clarke 1880 (RGS)'; ...
            7022, 'international', 'SemimajorAxis', 6378388,     'InverseFlattening',  297.0,         'International 1924'; ...
            7024, 'krasovsky',     'SemimajorAxis', 6378245,     'InverseFlattening',  298.3,         'Krassowsky 1940'; ...
            7043, 'wgs72',         'SemimajorAxis', 6378135,     'InverseFlattening',  298.26,        'WGS 72'; ...
              [], 'wgs60',         'SemimajorAxis', 6378165,     'InverseFlattening',  298.3,         'World Geodetic System 1960'; ...
              [], 'iau65',         'SemimajorAxis', 6378160,     'InverseFlattening',  298.25,        'International Astronomical Union 1965'; ...
              [], 'wgs66',         'SemimajorAxis', 6378145,     'InverseFlattening',  298.25,        'World Geodetic System 1966'; ...
              [], 'iau68',         'SemimajorAxis', 6378160,     'InverseFlattening',  298.2472,      'International Astronomical Union 1968'; ...
            7030, 'earth',         'SemimajorAxis', 6378137,     'InverseFlattening',  298.257223563, 'WGS 84'; ...
              [], 'sun',           'SemimajorAxis', 694460000,   'Eccentricity',       0,             'Sun'; ...
              [], 'moon',          'SemimajorAxis', 1738000,     'Eccentricity',       0,             'Moon'; ...
              [], 'mercury',       'SemimajorAxis', 2439000,     'Eccentricity',       0,             'Mercury'; ...
              [], 'venus',         'SemimajorAxis', 6051000,     'Eccentricity',       0,             'Venus'; ...
              [], 'mars',          'SemimajorAxis', 3396900,     'Eccentricity',       0.1105,        'Mars'; ...
              [], 'jupiter',       'SemimajorAxis', 71492000,    'Eccentricity',       0.3574,        'Jupiter'; ...
              [], 'saturn',        'SemimajorAxis', 60268000,    'Eccentricity',       0.4317,        'Saturn'; ...
              [], 'uranus',        'SemimajorAxis', 25559000,    'InverseFlattening',  1/0.0229,      'Uranus'; ...
              [], 'neptune',       'SemimajorAxis', 24764000,    'Eccentricity',       0.1843,        'Neptune'; ...
              [], 'pluto',         'SemimajorAxis', 1151000,     'Eccentricity',       0,             'Pluto'; ...
            }; 
        
        % The long names in the right hand column below are aliases that
        % are supported for backward compatibility.
        Aliases = [
            "sphere"      "Spherical Earth"
            "grs80"       "Geodetic Reference System 1980"
            "wgs84"       "World Geodetic System 1984"
            "everest"     "Everest 1830"
            "clarke80"    "Clarke 1880"
            "krasovsky"   "Krasovsky 1940"
            "wgs72"       "World Geodetic System 1972"
            ];
    end
    
    %--------------------------- Constructor ------------------------------
    
    methods
        function self = referenceEllipsoid(arg1,lengthUnit)
            %ReferenceEllipsoid Construct a reference ellipsoid object
            %
            %   E = referenceEllipsoid constructs a reference ellipsoid
            %   object E that represents the unit sphere.
            %
            %   E = referenceEllipsoid(NAME) returns a reference ellipsoid
            %   object corresponding to NAME. The values of the
            %   SemimajorAxis and SemiminorAxis properties are in meters.
            %
            %   E = referenceEllipsoid(CODE) returns a reference ellipsoid
            %   object corresponding to the numerical EPSG code, CODE.
            %
            %   E = referenceEllipsoid(..., LENGTHUNIT) returns the
            %   ellipsoid object with the SemimajorAxis and SemiminorAxis
            %   properties in the specified length unit. LENGTHUNIT can be
            %   any length unit supported by validateLengthUnit.
            %
            %   Example
            %   -------
            %   % Construct an object for the Clarke 1880 reference
            %   % ellipsoid based on its EPSG code, 7034.  Notice
            %   % that LengthUnit is 'Clarke's foot', a little-used unit.
            %   clarke1880 = referenceEllipsoid(7034)
            %
            %   % Change LengthUnit to 'meter'. Notice how the values of
            %   % SemimajorAxis and SemiminorAxis change, but the values of
            %   % the dimensionless shape properties, Inverse Flattening
            %   % and Eccentricity, do not.
            %   clarke1880.LengthUnit = 'meter'
            %
            %   % Follow an alternative path to the same state, beginning
            %   % with a unit sphere.
            %   s = referenceEllipsoid
            %
            %   % Set the semimajor axis, resulting in a much larger sphere.
            %   s.SemimajorAxis = 20926202
            %
            %   % Set semiminor axis to a slightly smaller value,
            %   % flattening the sphere into an ellipsoid.
            %   s.SemiminorAxis = 20854895
            %
            %   % Set the name and EPSG code.
            %   s.Code = 7034;
            %   s.Name = 'Clarke 1880'
            %
            %   % Set LengthUnit to 'Clarke's foot'.  The axes lengths do
            %   % not change because LengthUnit was previously empty.
            %   s.LengthUnit = 'Clarke''s foot'
            %
            %   % Set LengthUnit to 'meter'. This time the axes lengths
            %   % do change.
            %   s.LengthUnit = 'meter'
            %
            %   % The resulting object, s, should now be equivalent to the
            %   % clarke1880 object.
            %   isequal(s,clarke1880)
           
            if nargin > 0
                wgs84Strings = {'earth','wgs84','WorldGeodeticSystem1984'};
                if ~(ischar(arg1) || isstring(arg1))
                    % The first input is non-text, so it should be a
                    % numerical code. Validate it, then use it to select a
                    % row from the EPSG ellipsoid table.
                    code = arg1;
                    validateattributes(code, {'double'}, ...
                        {'real','integer','scalar','>=',7001,'<',8000}, ...
                        '', 'CODE', 1)
                    self = self.epsgEllipsoid(code);
                elseif any(strcmpi(removeSpaces(arg1),wgs84Strings))
                    % Bypass the table look-ups for WGS 84, which
                    % corresponds to EPSG ellipsoid code 7030.
                    self.Code = 7030;
                    self.Name = 'WGS 84';
                    self.SemimajorAxis = 6378137;
                    self.InverseFlattening = 298.257223563;
                    self.pLengthUnit = 'meter';
                else
                    % The first input is text, so it should be an ellipsoid
                    % name.
                    name = arg1;
                    
                    % Filter aliases: If name is an alias, replace it with
                    % the corresponding short name.
                    aliases = self.Aliases;
                    k = find(strcmpi(removeSpaces(name), replace(aliases(:,2)," ","")),1);
                    if ~isempty(k)
                        name = char(aliases(k,1));
                    end
                    
                    % Select a row from the Ellipsoids cell array, matching
                    % the input against either the second or last column.
                    % Ignore spaces in the input and in the Ellipsoids
                    % array.
                    names = referenceEllipsoid.Ellipsoids(:,[2 end]);
                    index = any(strcmpi(removeSpaces(name), cellfun( ...
                        @removeSpaces, names, 'UniformOutput', false)), 2);
                    if ~any(index)
                        % There was no match with all spaces removed, so
                        % there won't be a match when there aren't removed,
                        % either.  Call validatestring without removing
                        % spaces just to generate a helpful error message.
                        validatestring(name, names, mfilename, 'NAME', 1);
                    end
                    ellipsoid = referenceEllipsoid.Ellipsoids(index,:);
                    
                    % Set the defining geometric properties of the
                    % reference ellipsoid.
                    self.(ellipsoid{3}) = ellipsoid{4};
                    self.(ellipsoid{5}) = ellipsoid{6};
                    
                    % Set the remaining properties.
                    self.Name = ellipsoid{end};
                    self.Code = ellipsoid{1};
                    
                    % Set LengthUnit to 'meter', except for the unit sphere.
                    if ~strcmp(self.Name, 'Unit Sphere')
                        self.pLengthUnit = 'meter';
                    end                   
                end
            end
            
            if nargin > 1
                % Reset the length unit if specified by caller.
                self.LengthUnit = validateLengthUnit(lengthUnit, ...
                    'referenceEllipsoid','LENGTHUNIT',2);
            end
        end
        
    end
    
    %--------------------------- Get methods ------------------------------
    
    methods
        
        function lengthUnit = get.LengthUnit(self)
            lengthUnit = self.pLengthUnit;
        end
        
    end
    
    %-------------------------- Set Methods -------------------------------
    
    methods
        
        
        function self = set.Code(self, code)
            % Accept [], or any integer greater than 7000 and less than 8000.
            if ~isempty(code)
                validateattributes(code, {'double'}, ...
                    {'real','integer','scalar','>=',7001,'<',8000}, ...
                    '', 'CODE', 1)
                self.Code = code;
            else
                % code is empty, but ensure class double.
                self.Code = [];
            end
        end
        
        
        function self = set.Name(self, name)
            % Accept any valid string or character vector, including empty.
            if ~isempty(name)
                validateattributes(name, {'char','string'}, {'scalartext'})
            else
                validateattributes(name, {'char','string'}, {})
            end
            self.Name = name;
        end
        
        
        function self = set.LengthUnit(self, unit)
            % If the length unit is not yet designated, validate the input
            % and assign it. Otherwise rescale the axes lengths, then make
            % the assignment. Note that the semiminor axis of an oblate
            % spheroid object updates as needed when the semimajor
            % axis is reset, in order to maintain the same flattening.
            if isempty(unit)
                % It would be unusual to change LengthUnit to empty, but
                % there's no reason to disallow it. Ensure an empty char,
                % vs. empty of some class other than char.
                self.pLengthUnit = '';
            else
                unit = validateLengthUnit(unit);
                if ~isempty(self.pLengthUnit)
                    ratio = unitsratio(unit, self.pLengthUnit);
                    self.SemimajorAxis = ratio * self.SemimajorAxis;
                end
                self.pLengthUnit = unit;
            end
        end
    end
    
    %------------------------- Private Methods ----------------------------
    
    methods (Access = private)
        
        function self = epsgEllipsoid(self, code)
            % Set the properties of a referenceEllipsoid object based on
            % its EPSG code.
            
            % For performance reasons, cache the EPSG ellipsoid and unit of
            % measure tables into the persistent 2-D cell array variables
            % epsgEllipsoidTable and epsgUnitOfMeasureTable.
            persistent epsgEllipsoidTable
            if isempty(epsgEllipsoidTable)
                epsgEllipsoidTable = map.internal.epsgread('ellipsoid');
            end
            
            persistent epsgUnitOfMeasureTable
            if isempty(epsgUnitOfMeasureTable)
                epsgUnitOfMeasureTable = map.internal.epsgread('unit_of_measure');
            end
            
            self.Code = code;
            
            % Look up the code in the EPSG ellipsoid table.
            tvars = epsgEllipsoidTable(1,:);
            ecodes = epsgEllipsoidTable(:,matches(tvars,"code"));
            rec = epsgEllipsoidTable(matches(ecodes,string(code)),:);
            if isempty(rec)
                error(message('map:geodesy:epsgCodeNotFound',code,'ellipsoid'))
            else
                rec = cell2struct(rec,tvars,2);
            end
            
            % Set the Name and SemimajorAxis properties.
            self.Name = rec.name;
            self.SemimajorAxis = rec.semi_major_axis;
            
            % Most ellipsoids are defined by their inverse
            % flattening, but some are defined by their semiminor
            % axis. Set either the InverseFlattening property of
            % the SemiminorAxis property, but not both.
            if ~isequal(rec.inv_flattening,-999)
                self.InverseFlattening = rec.inv_flattening;
            else
                self.SemiminorAxis = rec.semi_minor_axis;
            end
            
            % Look up the "unit of measure" code and convert it to
            % a standard value.
            uom = epsgUnitOfMeasureTable;
            uom_codes = uom(:,matches(uom(1,:),"code"));
            uom_names = uom(:,matches(uom(1,:),"name"));
            uom_name = char(uom_names(matches(uom_codes,rec.uom_code)));
            self.pLengthUnit = validateLengthUnit(uom_name);
        end
        
    end
    
end

%--------------------------- Helper Function ------------------------------

function str = removeSpaces(str)
    str = char(str);
    str(isspace(str)) = [];
end
