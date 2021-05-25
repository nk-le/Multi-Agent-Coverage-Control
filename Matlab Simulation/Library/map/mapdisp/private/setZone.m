function mstruct = setZone(mstruct, zone)
% Update a map projection structure given a new value for its Zone property.

% Copyright 2008-2016 The MathWorks, Inc.

switch mstruct.mapprojection
    
    case 'ups'
        if ~any(strcmp(zone,{'north','south'}))
            error('map:ups:invalidZoneDesignation',...
                'Incorrect UPS zone designation. Recognized zones are ''north'' and ''south''.')
        end
        mstruct.zone = zone;
        mstruct = feval(mstruct.mapprojection,mstruct);
        mstruct.maplatlimit = [];
        mstruct.flatlimit = [];
        mstruct.origin = [];
        mstruct.mlabelparallel = [];
        mstruct.mlinelimit = [];
        
    case 'utm'
        if isempty(zone)
            % Set to default.
            zone = '31N';
        end
        [latlim, lonlim] = utmzone(zone);
        mstruct.zone = upper(zone);
        mstruct.flatlimit = fromDegrees(mstruct.angleunits,latlim);
        mstruct.flonlimit = fromDegrees(mstruct.angleunits,[-3 3]);
        mstruct.origin = fromDegrees(mstruct.angleunits,[0 min(lonlim)+3 0]);
        mstruct.maplatlimit = [];
        mstruct.maplonlimit = [];
        
        mstruct.mlinelocation = [];
        mstruct.plinelocation = [];
        mstruct.mlabellocation = [];
        mstruct.plabellocation = [];
        mstruct.mlabelparallel = [];
        mstruct.plabelmeridian = [];
        mstruct.falsenorthing = [];
        
    otherwise
        error('map:setZone:mapdispError', ...
            'ZONE cannot be specified for this projection.')
end
