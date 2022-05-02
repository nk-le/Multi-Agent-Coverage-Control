function gtif  = proj2gtif(proj)
%PROJ2GTIF Convert a projection structure to a GTIF structure.
%
%   GTIF = PROJ2GTIF(PROJ) returns a GTIF structure. PROJ is
%   a structure returned from GEOTIFFINFO or a valid MSTRUCT.
%
%   See also GEOTIFFINFO, MSTRUCT2GTIF.

%   Copyright 2003-2011 The MathWorks, Inc.

if isGeoTiff(proj)
    % GeoTIFF
    gtif = proj;
    % Verify GeoTIFF
    code = projcode(gtif.CTProjection);
    if (isequal(code.CTcode, 32767))
        error(message('map:projections:userDefinedOrUnknownCode', 'PROJ'))
    end
    gtif.GeoTIFFCodes = int16GeoTiffCodes(gtif.GeoTIFFCodes);
elseif ismstruct(proj)
    % mstruct
    gtif = mstruct2gtif(proj);
else
    error(message('map:validate:missingStructureFields', 'PROJ'))
end
