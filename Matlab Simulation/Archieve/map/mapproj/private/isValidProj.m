function valid = isValidProj(proj, fieldNames)
%ISVALIDPROJ True for a PROJ structure containing FIELDNAMES.
%
%   VALID = ISVALIDPROJ(PROJ, FIELDNAMES) returns 1 if PROJ is a structure
%   containing FIELDNAMES.
%
%   See also ISGEOTIFF, ISMSTRUCT.

%   Copyright 1996-2017 The MathWorks, Inc.

if nargin > 1
    if isstring(fieldNames)
        fieldNames = cellstr(fieldNames);
    end
end

if ~isstruct(proj)
   valid = false;
   return
else
   valid = true;
end
for i=1:length(fieldNames)
   if (~isfield(proj,fieldNames(i)))
     valid = false;
     break;
   end
end
