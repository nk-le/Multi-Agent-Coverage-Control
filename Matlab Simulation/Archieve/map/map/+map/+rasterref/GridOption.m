classdef (Hidden) GridOption
% map.rasterref.GridOption is intentionaly undocumented and is intended for
% use only within other Mapping Toolbox classes. Its behavior may change,
% or the class itself may be removed, in a future release.

% The purpose of map.rasterref.GridOption is to support validation and
% tab-completion of the "gridOption" option string input in the raster
% reference worldGrid and geographicGrid methods.

% Copyright 2020 The MathWorks, Inc.

    enumeration
        fullgrid
        gridvectors
    end
end
