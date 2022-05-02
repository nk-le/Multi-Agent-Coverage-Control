function A = extractFeatureAttributes(S)
%extractFeatureAttributes Extract attributes from geographic data structure
%
%   A = extractFeatureAttributes(S) returns the attributes of the
%   geographic data structure S.  The output A is a structure having the
%   same size as S, or empty, if no attributes are present.
%
%   Example
%   -------
%   S = shaperead('concord_hydro_area.shp')
%   A = map.graphics.internal.extractFeatureAttributes(S)

%   Copyright 2012 The MathWorks, Inc.

validateattributes(S,{'struct'},{},mfilename,'S',1);

reservedNames = {'Geometry', 'X', 'Y', 'Lat', 'Lon', ...
                 'BoundingBox', 'Height', 'INDEX'};

fieldNames = fieldnames(S);
fieldsToRemove = intersect(fieldNames, reservedNames);
if numel(fieldsToRemove) == numel(fieldNames)
    A = [];
else
    A = rmfield(S, fieldsToRemove);
end
