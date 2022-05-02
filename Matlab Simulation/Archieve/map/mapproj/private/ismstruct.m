function value = ismstruct(proj)
%ISMSTRUCT True for a MSTRUCT projection structure.
%
%   VALUE = ISMSTRUCT(PROJ) returns 1 if PROJ contains mstruct projection
%   fields, 0 otherwise.
%
%   See also ISGEOTIFF, ISVALIDPROJ.

%   Copyright 1996-2003 The MathWorks, Inc.

fieldNames = {'falsenorthing',  ...
              'falseeasting',  ...
              'geoid', ...
              'mapprojection',  ...
              'origin',  ...
              'scalefactor'};
value = isValidProj(proj, fieldNames);

