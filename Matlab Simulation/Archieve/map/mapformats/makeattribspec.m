function attribspec = makeattribspec(S)
%MAKEATTRIBSPEC Attribute specification structure
%
%   ATTRIBSPEC = MAKEATTRIBSPEC(S) analyzes S and constructs an attribute
%   specification suitable for use with KMLWRITE. S is either a geopoint
%   vector, a geoshape vector with 'point' Geometry and no dynamic vertex
%   properties, or a geostruct (with 'Lat' and 'Lon' coordinate fields).
%   KMLWRITE, given a geopoint or geoshape vector or geostruct input,
%   constructs a HTML table that consists of a label for the attribute in
%   the first column and the character vector value of the attribute in the
%   second column.  You can modify ATTRIBSPEC, then pass it to KMLWRITE to
%   exert control over which attribute fields are written to the HTML table
%   and the format of the text conversion.
%
%   ATTRIBSPEC is a scalar MATLAB structure with two levels. The top level
%   consists of a field for each attribute in S.  Each of these fields, in
%   turn, contains a scalar structure with a fixed pair of fields:
%
%   AttributeLabel     A character vector that corresponds to the name of 
%                      the attribute field in S. With KMLWRITE, the string
%                      is used to label the attribute in the first column
%                      of the HTML table. The string may be modified prior
%                      to calling KMLWRITE.  You might modify an attribute
%                      label, for example, because you want to use spaces
%                      in your HTML table, but the attribute fieldnames in
%                      S must be valid MATLAB variable names and cannot
%                      have spaces themselves.
%
%   Format             The sprintf formatSpec that converts the attribute 
%                      value to text.
%
%   Example
%   -------
%   % Import a shapefile representing tsunami (tidal wave) events reported 
%   % over several decades, tagged geographically by source location.
%   s = shaperead('tsunamis', 'UseGeoCoords', true);
%
%   % Construct an attribute specification.
%   attribspec = makeattribspec(s);
%
%   % Modify the attribute spec to:
%   % (a) Display Max_Height, Cause, Year, Location, and Country attributes 
%   % (b) Rename the 'Max_Height' field to 'Maximum Height' 
%   % (c) Highlight each attribute label with a bold font 
%   % (d) Set to zero the number of decimal places used to display Year
%   % (e) We have independent knowledge that the height units are meters, 
%   %     so we will add that to the Height format specifier
%
%   desiredAttributes = ...
%      {'Max_Height', 'Cause', 'Year', 'Location', 'Country'};
%   allAttributes = fieldnames(attribspec);
%   attributes = setdiff(allAttributes, desiredAttributes);
%   attribspec = rmfield(attribspec, attributes);
%   attribspec.Max_Height.AttributeLabel = '<b>Maximum Height</b>';
%   attribspec.Max_Height.Format = '%.1f Meters';
%   attribspec.Cause.AttributeLabel = '<b>Cause</b>';
%   attribspec.Year.AttributeLabel = '<b>Year</b>';
%   attribspec.Year.Format = '%.0f';
%   attribspec.Location.AttributeLabel = '<b>Location</b>';
%   attribspec.Country.AttributeLabel = '<b>Country</b>';
% 
%   % Export the selected attributes and source locations to a KML file. 
%   filename = 'tsunami.kml';
%   kmlwrite(filename, s, 'Description', attribspec, 'Name', {s.Location})
%
%   See also KMLWRITE, MAKEDBFSPEC, SHAPEWRITE.

% Copyright 2007-2018 The MathWorks, Inc.

% Validate input.
types = {'struct', 'geopoint', 'geoshape'};
validateattributes(S, types, {'nonempty', 'vector'}, mfilename, 'S', 1)

% Convert S to a dynamic vector if it is a structure.
if isstruct(S)
    S = convertContainedStringsToChars(S);
    S = map.internal.struct2DynamicVector(S);
end

% Determine attribute fields.
attributeNames = fieldnames(S);
[~,fIndex] = setxor(attributeNames, ...
    {'Metadata', 'Geometry', 'Latitude', 'Longitude'});
attributeNames = attributeNames(sort(fIndex));

% Loop through each attribute, validate the value, and assign fields to
% the attribute structure.
for k = 1:numel(attributeNames)    
    % Obtain the attribute value.
    attributeName = attributeNames{k};
    v = S.(attributeName);
    if ischar(v)
        v = {v};
    end
    
    % Determine action for dynamic vertex properties.
    if length(v) ~= length(S) 
        if any(strcmp(attributeName, {'Height', 'Elevation', 'Altitude'}))
            % Ignore dynamic vertex properties that contain altitudes.
            continue
        else
            % Issue a warning for all other dynamic vertex properties.
            % Do not add property attributeName to the output structure.
            warning(message('map:validate:ignoringAttribute', attributeName))
            continue
        end
    end
    
    if isnumeric(v)
        % Attributes must be real and finite.
        map.internal.assert(all(~isinf(v)) && all(isreal(v)), ...
            'map:validate:attributeNotFiniteReal', attributeName)
        
        % Assign format.
        format = '%.15g';
        
    elseif iscell(v)
        % Cell arrays in a dynamic vector are always cellstrs.
        % Assign format.
        format = '%s'; 
        
    else
        warning(message('map:validate:unsupportedDataClass', class(v)));
        continue
    end
    
    % Assign attribspec field name.
    attribspec.(attributeNames{k}) = struct(...
        'AttributeLabel', attributeNames{k},...
        'Format', format);
end

% Return empty if there are no attributes or attribspec is unassigned.
if isempty(attributeNames) || ~exist('attribspec','var')
    attribspec = struct([]);
end
