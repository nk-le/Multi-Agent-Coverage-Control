function obj = setProperties(obj, options)
%map.internal.setProperties Set object properties from structure
%
%   OBJ = map.internal.setProperties(OBJ, OPTIONS) sets selected properties
%   of the value object OBJ.
%
%   map.internal.setProperties(H, OPTIONS) sets selected properties on the
%   handle object H.
%
%   Each property with public access in OBJ or H whose name matches a field
%   name of the scalar structure OPTIONS is assigned the value of that
%   field. Field names not matching property names are ignored. The set
%   operation is not performed if OBJ or H or OPTIONS is empty or if
%   OPTIONS is not a scalar structure. Note that even Hidden properties are
%   assigned, provided they have public access, and they match a field name
%   of OPTIONS.

% Copyright 2012-2013 The MathWorks, Inc.

% Set the property values of obj with the matching field names of options
% only if obj is a non-empty object and options is a non-empty scalar
% structure. Use of isprop allows hidden properties to be set.
if isobject(obj) && ~isempty(obj) && isstruct(options) && isscalar(options)
    names = fieldnames(options);
    for k = 1:length(names)
        if isprop(obj, names{k})
           obj.(names{k}) = options.(names{k});
        end
    end
end
