classdef (Sealed) projcrs
% PROJCRS Projected coordinate reference system object
%
% A projected coordinate reference system (CRS) provides information that
% assigns Cartesian x and y map coordinates to physical locations.
% Projected CRSs consist of a geographic CRS and several parameters that
% are used to transform coordinates to and from the geographic CRS.
%
% p = PROJCRS(CODE) creates a projected CRS object using the EPSG code
% specified by CODE.
% 
% p = PROJCRS(CODE,'Authority',AUTHORITY) creates a projected CRS object
% using the specified code and authority. Supported authorities are "EPSG",
% "ESRI", and "IGNF".
% 
% p = PROJCRS(WKT) creates a projected CRS object using the well-known text
% string representation specified by WKT.
% 
% See also geocrs projfwd projinv

% Copyright 2019-2020 The MathWorks, Inc.

    properties (Transient, SetAccess = private)
        Name (1,1) string
        GeographicCRS geocrs
        ProjectionMethod (1,1) string
        LengthUnit (1,1) string = "meter"
    end
    
    properties (Dependent, SetAccess = private)
        ProjectionParameters
    end
    
    properties (Transient, Access = private)
        WKT
    end
    
    properties (Access = private)
        CRSStorage
    end
    
    properties (Transient, Access = private)
        % Cache for projection parameters
        ParameterData struct
    end
    
    
    methods
        function obj = projcrs(crs, namevalue)
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
                            ["PROJCRS","PROJECTEDCRS","PROJCS"],"IgnoreCase", true)
                        % crs is not a projected CRS WKT. Provide a helpful
                        % suggestion to use geocrs if the WKT is a
                        % geographic WKT. Otherwise, only state that the
                        % WKT is not projected.
                        if startsWith(crs,["GEOGCRS","GEOGRAPHICCRS","GEOGCS",...
                                "GEODCRS","GEODETICCRS"],"IgnoreCase",true)
                            ric = matlab.lang.correction.ReplaceIdentifierCorrection('projcrs','geocrs');
                            error(ric, message('map:crs:MustBeProjectedNotGeographic'))
                        else
                            error(message('map:crs:MustBeProjected'))
                        end
                        
                    end
                end
                
                obj = setPropertiesFromCRSInput(obj, crs);
            end
        end
        
        
        function tf = isequal(obj1, obj2, objs)
        % isequal Compare two projcrs objects
        % 
        % tf = isequal(crs1,crs2) returns logical 1 (true) if the
        % coordinate reference systems (CRSs) crs1 and crs2 are equivalent.
        % Otherwise, it returns logical 0 (false). Two projcrs objects are
        % equivalent if they have the same geographic CRS, projection
        % method, projection parameters, and length unit.
        %
        % See also projcrs
        
            arguments
                obj1
                obj2
            end
            arguments (Repeating)
                objs
            end
            if isa(obj1,"projcrs")
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
        % p = projcrs(27700);
        % wkt = wktstring(p,'Format','formatted')
        % 
        % See also projcrs geocrs
        
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
        
        
        function [x, y] = projfwd(obj, lat, lon)
            arguments
                obj
                lat {mustBeNumeric, mustBeReal, mustBeNonsparse, mustBeFloat}
                lon {mustBeNumeric, mustBeReal, mustBeNonsparse, mustBeFloat}
            end
            
            map.internal.assert(isequal(size(lat),size(lon)), ...
                'map:validate:inconsistentSizes2', 'projfwd', 'lat', 'lon')
            
            % The PROJ library expects vectors of class double.
            % Preserve the class type of the returned values. The inputs to this
            % function are expected to be floating point (either single or double).
            castToSingle = isa(lat,'single') || isa(lon,'single');
            
            try
                if ~isempty(obj.WKT)
                    % Strip out authority IDs to prevent axis orientation redefinition.
                    wkt = removeWKTAuthorityID(obj.WKT);
                    
                    [x, y] = map.internal.crs.projfwd(wkt, double(lat), double(lon));
                else
                    error(message('map:crs:TransformationNotSupported'))
                end
            catch err
                throw(err)
            end
            
            % If any of the input vectors are class single, then cast both to single.
            % (This is the same behavior as other projfwd cases).
            if castToSingle
                x = single(x);
                y = single(y);
            end
        end
        
        
        function [lat, lon] = projinv(obj, x, y)
            arguments
                obj
                x {mustBeNumeric, mustBeReal, mustBeNonsparse, mustBeFloat}
                y {mustBeNumeric, mustBeReal, mustBeNonsparse, mustBeFloat}
            end
            
            map.internal.assert(isequal(size(x),size(y)), ...
                'map:validate:inconsistentSizes2', 'projinv', 'x', 'y')
            
            % The PROJ library expects vectors of class double.
            % Preserve the class type of the returned values. The inputs to this
            % function are expected to be floating point (either single or double).
            castToSingle = isa(x,'single') || isa(y,'single');

            try
                if ~isempty(obj.WKT)
                    % Strip out authority IDs to prevent axis orientation redefinition.
                    wkt = removeWKTAuthorityID(obj.WKT);
                    
                    [lat, lon] = map.internal.crs.projinv(wkt, double(x), double(y));
                else
                    error(message('map:crs:TransformationNotSupported'))
                end
            catch err
                throw(err)
            end
            
            % If any of the input vectors are class single, then cast both to single.
            % (This is the same behavior as other projinv cases).
            if castToSingle
                lat = single(lat);
                lon = single(lon);
            end
        end
        
        
        function parameters = get.ProjectionParameters(obj)
            parameterData = obj.ParameterData;
            parameters = map.crs.ProjectionParameters(parameterData);
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
            if ~crsinfo.IsProjected
                if crsinfo.IsGeographic
                    ric = matlab.lang.correction.ReplaceIdentifierCorrection('projcrs','geocrs');
                    error(ric, message('map:crs:MustBeProjectedNotGeographic'))
                else
                    checkForAuthorityMismatch(crs)
                    error(message('map:crs:MustBeProjected'))
                end
            end
            obj.WKT = wkt;
            
            if ~isempty(crsinfo.Name) && ~matches(crsinfo.Name,"unnamed")
                obj.Name = crsinfo.Name;
            end
            
            if ischar(crsinfo.GCRSCode)
                % Authority name and code are explicitly known
                if strcmp(crsinfo.GCRSAuthority, "IGNF")
                    gcrscode = crsinfo.GCRSCode;
                else
                    gcrscode = str2double(crsinfo.GCRSCode);
                end
                obj.GeographicCRS = geocrs(gcrscode,"Authority",crsinfo.GCRSAuthority);
            elseif crsinfo.GCRSCode > 0
                % EPSG code inferred
                obj.GeographicCRS = geocrs(crsinfo.GCRSCode);
            end
            
            if ~isempty(crsinfo.Projection)
                obj.ProjectionMethod = crsinfo.Projection;
            end
            
            if ~isempty(crsinfo.LengthUnit)
                obj.LengthUnit = validateLengthUnit(crsinfo.LengthUnit);
            end
            
            if ~isempty(crsinfo.JSON) && strlength(crsinfo.JSON) > 0
                try
                    projjson = jsondecode(crsinfo.JSON);
                    
                    if isfield(projjson, "conversion") && ~isempty(projjson.conversion)
                        projconv = projjson.conversion;
                        
                        % Get projection parameter data from the PROJJSON.
                        if isfield(projconv, "parameters") && ~isempty(projconv.parameters)
                            obj.ParameterData = projconv.parameters;
                        end
                        
                        % Check to see if there is a PROJJSON name for the
                        % projection method. If so, try to apply the
                        % PROJJSON version.
                        if isfield(projconv, "method") && ~isempty(projconv.method)
                            obj.ProjectionMethod = projconv.method.name;
                        end
                    end
                    
                    % Check to see if GeographicCRS is empty. If so, try to
                    % apply the PROJJSON version.
                    if isempty(obj.GeographicCRS)
                        if isfield(projjson, "base_crs") && ~isempty(projjson.base_crs)
                            basecrs = projjson.base_crs;
                            if isfield(basecrs, "id") && ~isempty(basecrs.id)
                                if isfield(basecrs.id,"code") && ~isempty(basecrs.id.code)
                                    obj.GeographicCRS = geocrs(basecrs.id.code, "Authority", basecrs.id.authority);
                                end
                            end
                        end
                    end
                catch
                end
            end
        end
        
        
        function tf = isequal2Inputs(obj1,obj2)
            if ~isa(obj1,"projcrs") || ~isa(obj2,"projcrs")
                % If the compared input is not a projcrs, then it is not equal.
                tf = false;
            elseif isequal(size(obj1),size(obj2))
                % Inputs are the same size. Ensure that they match on an
                % element-wise basis.
                if isscalar(obj1)
                    % Inputs are scalar, their values can directly be compared.
                    if isequal(obj1.LengthUnit, obj2.LengthUnit)
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


function wkt = removeWKTAuthorityID(wkt)
    % Remove authority ID(s) from WKT string
    wkt = erase(wkt,"," + whitespacePattern + ...
        "ID[""" + ("EPSG"|"ESRI") + """," + digitsPattern + "]");
    wkt = erase(wkt,"," + whitespacePattern + ...
        "ID[""" + ("IGNF"|"PROJ") + """,""" + alphanumericsPattern + """]");
end


function checkForAuthorityMismatch(crs)
    % Throw more helpful error messages when a different authority has a
    % valid code.
    
    if isnumeric(crs)
        % Expected EPSG code input. Check if the code may be an ESRI code.
        [~,crsinfo] = map.internal.crs.getCRS("ESRI:" + crs);
        if crsinfo.IsProjected
            % The code is a valid ESRI code. Throw an error suggesting
            % this alternative authority.
            error(message('map:crs:AuthorityMustMatchProjcrsInput','EPSG','ESRI'))
        end
    else
        % Expected ESRI or IGNF code input. If expecting ESRI code input,
        % throw a more helpful error message if there is a valid EPSG code.
        if startsWith(crs,"ESRI:")
            crs = str2double(extractAfter(crs,"ESRI:"));
            [~,crsinfo] = map.internal.crs.getCRS(crs);
            if crsinfo.IsProjected
                % The code is a valid EPSG code. Throw an error suggesting
                % this alternative authority.
                error(message('map:crs:AuthorityMustMatchProjcrsInput','ESRI','EPSG'))
            end
        end
    end
end
