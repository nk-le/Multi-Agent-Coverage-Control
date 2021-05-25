classdef (Sealed) geocrs
% GEOCRS Geographic coordinate reference system object
% 
% A geographic coordinate reference system (CRS) provides information that
% assigns latitude, longitude, and height coordinates to physical
% locations. Geographic CRSs consist of a datum, a prime meridian, and an
% angular unit of measurement.
% 
% g = GEOCRS(CODE) creates a geographic CRS object using the EPSG code
% specified by CODE.
% 
% g = GEOCRS(CODE,'Authority',AUTHORITY) creates a geographic CRS object
% using the specified code and authority. Supported authorities are "EPSG",
% "ESRI", and "IGNF".
% 
% g = GEOCRS(WKT) creates a geographic CRS object using a specified
% well-known text string representation specified by WKT.
% 
% See also projcrs referenceEllipsoid

% Copyright 2019-2020 The MathWorks, Inc.

    properties (Transient, SetAccess = private)
        Name (1,1) string
        Datum (1,1) string
        Spheroid map.geodesy.Spheroid = oblateSpheroid
        PrimeMeridian double = 0
        AngleUnit (1,1) string = "degree"
    end
    
    properties (Transient, Access = private)
        WKT
    end
    
    properties (Access = private)
        CRSStorage
    end
    
    methods
        function obj = geocrs(crs, namevalue)
            arguments
                crs {mustBeCRS} = []
                namevalue.Authority (1,1) map.crs.AuthorityName
            end
            
            if ~isempty(crs)
                % crs is a valid code or WKT string
                
                if isfield(namevalue, 'Authority')
                    % Format non-EPSG Authority codes. EPSG codes will be
                    % unchanged.
                    crs = formatNonEPSGCodeInput(crs, namevalue.Authority);
                else
                    % crs is either an EPSG code or WKT string
                    if ~isnumeric(crs) && ~startsWith(crs,...
                            ["GEOGCRS","GEOGRAPHICCRS","GEOGCS",...
                            "GEODCRS","GEODETICCRS"],"IgnoreCase",true)
                        % crs is not a geographic CRS WKT. Provide a
                        % helpful suggestion to use projcrs if the WKT is a
                        % projected WKT. Otherwise, only state that the
                        % WKT is not geographic.
                        if startsWith(crs, ["PROJCRS","PROJECTEDCRS","PROJCS"],"IgnoreCase", true)
                            ric = matlab.lang.correction.ReplaceIdentifierCorrection('geocrs','projcrs');
                            error(ric, message('map:crs:MustBeGeographicNotProjected'))
                        else
                            error(message('map:crs:MustBeGeographic'))
                        end
                    end
                end
                
                obj = setPropertiesFromCRSInput(obj, crs);
            end
        end
        
        
        function tf = isequal(obj1, obj2, objs)
        % isequal Compare two geocrs objects
        % 
        % tf = isequal(crs1,crs2) returns logical 1 (true) if the
        % coordinate reference systems (CRSs) crs1 and crs2 are equivalent.
        % Otherwise, it returns logical 0 (false). Two geocrs objects are
        % equivalent if they have the same datum name, reference spheroid,
        % prime meridian, and angle unit.
        %
        % See also geocrs
        
            arguments
                obj1
                obj2
            end
            arguments (Repeating)
                objs
            end
            if isa(obj1,"geocrs")
                tf = isequal2Inputs(obj1,obj2);
            else
                tf = false;
            end
            if tf
                for obji = objs
                    objn = obji{1};
                    tf = isequal2Inputs(obj1,objn);
                    if ~tf
                        % If any comparison is false, then return false
                        break
                    end
                end
            end
        end
        
        
        function tf = isequaln(obj1, obj2, objs)
            arguments
                obj1
                obj2
            end
            arguments (Repeating)
                objs
            end
            tf = isequal(obj1, obj2, objs{:});
        end
        
        
        function str = wktstring(obj, namevalue)
        % WKTSTRING Well-known text string
        % 
        % str = WKTSTRING(crs) returns the well-known text string
        % representation of the specified coordinate reference system. By
        % default, wktstring uses the WKT 2 standard and does not apply
        % formatting.
        % 
        % str = WKTSTRING(crs,Name,Value) specifies version and formatting
        % options using one or more Name,Value pair arguments. For example,
        % 'Format','formatted' includes line breaks and indentations in the
        % WKT string.
        % 
        % Example
        % -------
        % g = geocrs(4269);
        % wkt = wktstring(g,'Format','formatted')
        % 
        % See also geocrs projcrs
        
            arguments
                obj
                namevalue.Format (1,1) string = "compact"
                namevalue.Version (1,1) string = "WKT2"
            end
            
            wktformat = validatestring(namevalue.Format, ["formatted", "compact"]);
            wktversion = validatestring(namevalue.Version, ["WKT1", "WKT2"]);
            
            switch wktformat
                case "formatted"
                    wktformat = "MULTILINE=YES";
                case "compact"
                    wktformat = "MULTILINE=NO";
            end
            
            switch wktversion
                case "WKT2"
                    wktversion = "FORMAT=WKT2";
                case "WKT1"
                    wktversion = "FORMAT=WKT1";
            end
            
            if ~isempty(obj.WKT)
                str = map.internal.crs.formatWKT(obj.WKT, ...
                    "Format", wktformat, "Version", wktversion);
            else
                str = "";
            end
        end
        
        
        function obj = set.CRSStorage(obj, s)
            wkt = s.WKT;
            obj = setPropertiesFromCRSInput(obj, wkt);
        end
        
        
        function s = get.CRSStorage(obj)
            s.WKT = obj.WKT;
        end
    end
    
    methods (Access = private)
        function obj = setPropertiesFromCRSInput(obj, crs)
            [wkt, crsinfo] = map.internal.crs.getCRS(crs);
            if ~crsinfo.IsGeographic
                if crsinfo.IsProjected
                    ric = matlab.lang.correction.ReplaceIdentifierCorrection('geocrs','projcrs');
                    error(ric, message('map:crs:MustBeGeographicNotProjected'))
                else
                    checkForAuthorityMismatch(crs)
                    error(message('map:crs:MustBeGeographic'))
                end
            end
            
            if ~isempty(crsinfo.Name) && ~matches(crsinfo.Name,"unnamed")
                obj.Name = crsinfo.Name;
            end
            
            if ~isempty(crsinfo.Datum)
                obj.Datum = crsinfo.Datum;
            end
            
            haveSpeheroidCode = ~isempty(crsinfo.SpheroidCode);
            if haveSpeheroidCode
                ellipsoidcode = str2double(crsinfo.SpheroidCode);
                if ellipsoidcode > 7000 && ellipsoidcode < 8000
                    obj.Spheroid = referenceEllipsoid(ellipsoidcode);
                end
                
                if ~isempty(crsinfo.SpheroidAuthority)
                    % Insert the Authority ID (name and code) into the WKT.
                    ellipsoidauthority = crsinfo.SpheroidAuthority;
                    idstring = "],ID[""" + ellipsoidauthority + """," + ellipsoidcode;
                    wkt = insertBefore(wkt, "]]]", idstring);
                end
            end
            
            if ~isempty(crsinfo.PrimeMeridian)
                obj.PrimeMeridian = crsinfo.PrimeMeridian;
            end
            
            if ~isempty(crsinfo.AngleUnit)
                % Standardize AngleUnit
                try
                    if map.geodesy.isDegree(crsinfo.AngleUnit)
                        obj.AngleUnit = "degree";
                    else
                        obj.AngleUnit = "radian";
                    end
                catch
                    % AngleUnit is neither degrees nor radians (e.g. grad).
                    obj.AngleUnit = crsinfo.AngleUnit;
                end
            end
            
            if ~isempty(crsinfo.JSON) && strlength(crsinfo.JSON) > 0
                try
                    projjson = jsondecode(crsinfo.JSON);
                    projdatum = projjson.datum;
                    
                    % Check to see if there is a PROJJSON name for the
                    % datum. If so, apply the PROJJSON version.
                    datumName = datumNameFromPROJJSON(projdatum);
                    if ~isempty(datumName)
                        obj.Datum = datumName;
                    end
                    
                    if ~isa(obj.Spheroid,'referenceEllipsoid')
                        % No spheroid code or unsupported code.
                        % Check to see if there is a PROJJSON ellipsoid
                        % representation. If so, apply the PROJJSON
                        % version.
                        obj.Spheroid = spheroidFromPROJJSON(projdatum, haveSpeheroidCode);
                    end
                catch
                end
            end
            
            obj.WKT = wkt;
        end
        
        
        function tf = isequal2Inputs(obj1,obj2)
            if ~isa(obj1,"geocrs") || ~isa(obj2,"geocrs")
                % If the compared input is not a geocrs, then it is not equal.
                tf = false;
            elseif isequal(size(obj1),size(obj2))
                % Inputs are the same size. Ensure that they match on an
                % element-wise basis.
                if isscalar(obj1)
                    % Inputs are scalar, their values can directly be compared.
                    if isequal(obj1.AngleUnit, obj2.AngleUnit)
                        wkt1 = obj1.WKT;
                        wkt2 = obj2.WKT;
                        if ~isempty(wkt1) && ~isempty(wkt2)
                            tf = map.internal.crs.isequal(wkt1,wkt2);
                        elseif isempty(wkt1) && isempty(wkt2)
                            tf = true;
                        else
                            tf = false;
                        end
                    else
                        tf = false;
                    end
                elseif isempty(obj1)
                    % Inputs are the same size and empty, they are equal.
                    tf = true;
                else
                    % Inputs are the same size. Check element-wise for equality.
                    obj1i = obj1(:);
                    obj2i = obj2(:);
                    tf = true;
                    for oindex = 1:length(obj1i)
                        if ~isequal2Inputs(obj1i(oindex),obj2i(oindex))
                            tf = false;
                            break
                        end
                    end
                end
            else
                % Sizes are not equal
                tf = false;
            end
        end
    end
end


function datum = datumNameFromPROJJSON(projdatum)
    datum = '';
    if isfield(projdatum, "name") && ~isempty(projdatum.name)
        datum = projdatum.name;
    end
end


function spheroid = spheroidFromPROJJSON(projdatum, haveCode)
    projellipsoid = projdatum.ellipsoid;
    if ~haveCode
        % No recognized code. Try using the name.
        spheroid = referenceEllipsoid(projellipsoid.name);
    else
        % There is a code, but it is not supported in referenceEllipsoid.
        % Fill in the spheroid without specifying a code.
        if isfield(projellipsoid, "radius")
            spheroid = referenceSphere;
            spheroid.Radius = projellipsoid.radius;
        else
            spheroid = referenceEllipsoid;
            spheroid.SemimajorAxis = projellipsoid.semi_major_axis;
            spheroid.InverseFlattening = projellipsoid.inverse_flattening;
        end
        spheroid.Name = projellipsoid.name;
        spheroid.LengthUnit = "meter";
    end
end


function checkForAuthorityMismatch(crs)
    % Throw more helpful error messages when a different authority has a
    % valid code.
    
    if isnumeric(crs)
        % Expected EPSG code input. Check if the code may be an ESRI code.
        [~,crsinfo] = map.internal.crs.getCRS("ESRI:" + crs);
        if crsinfo.IsGeographic
            % The code is a valid ESRI code. Throw an error suggesting
            % this alternative authority.
            error(message('map:crs:AuthorityMustMatchGeocrsInput','EPSG','ESRI'))
        end
    else
        % Expected ESRI or IGNF code input. If expecting ESRI code input,
        % throw a more helpful error message if there is a valid EPSG code.
        if startsWith(crs,"ESRI:")
            crs = str2double(extractAfter(crs,"ESRI:"));
            [~,crsinfo] = map.internal.crs.getCRS(crs);
            if crsinfo.IsGeographic
                % The code is a valid EPSG code. Throw an error suggesting
                % this alternative authority.
                error(message('map:crs:AuthorityMustMatchGeocrsInput','ESRI','EPSG'))
            end
        end
    end
end
