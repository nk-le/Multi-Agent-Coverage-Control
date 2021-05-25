function mstruct = zoneupdate(mstruct)
% In the case of UTM or UPS, update zone-specific fields in the map
% projection structure mstruct to ensure consistency with its zone field.
% Otherwise pass the input through without change.

% Copyright 2012 The MathWorks, Inc.

if strcmp(mstruct.mapprojection,'utm')
    % Manually convert the trim latitude and longitude in UTM; this is not
    % required in UPS because defaultm handles it for us.
    [mstruct.trimlat, mstruct.trimlon] = fromDegrees( ...
        mstruct.angleunits, [-80 84],[-180 180]);
    update = true;
elseif strcmp(mstruct.mapprojection, 'ups')
    update = true;
else
    update = false;
end

if update
    mstruct.origin = [];
    mstruct.mapparallels = [];
    mstruct.fixedorient = [];
    mstruct.maplatlimit = [];
    mstruct.maplonlimit = [];
    mstruct.flatlimit   = [];
    mstruct.flonlimit   = [];
    mstruct.falsenorthing = [];
    mstruct.mlabelparallel = [];
    mstruct.plabelmeridian = [];
    mstruct.mlineexception = [];
    mstruct.plineexception = [];
    mstruct.mlinelimit  = [];
    mstruct.plinelimit  = [];
    mstruct.mlabellocation = [];
    mstruct.plabellocation = [];
    mstruct.mlinelocation = [];
    mstruct.plinelocation = [];
    mstruct.labelunits = [];
    
    mstruct = defaultm(mstruct);
end
