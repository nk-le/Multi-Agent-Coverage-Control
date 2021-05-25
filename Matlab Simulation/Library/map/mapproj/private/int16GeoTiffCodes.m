function icodes = int16GeoTiffCodes(codes)
%INT16GEOTIFFCODES Converts the GeoTIFF double codes to type int16.
%
%   ICODES = INT16GEOTIFFCODES(CODES) Converts the fields of CODES  to type
%   INT16 and returns the structure as ICODES.
%
%   See also PROJ2GTIF, MSTRUCT2GTIF.

%   Copyright 2003-2016 The MathWorks, Inc.

map.internal.assert(isstruct(codes), ...
    'map:validate:expectedStructure', 'GeoTIFFCodes')

fields = fieldnames(codes);
icodes = codes;
for k=1:length(fields)
    if (isnumeric(codes.(fields{k})))
       icodes.(fields{k})= int16(codes.(fields{k}));
    else
       error(message( ...
           'map:validate:expectedNumericField', 'GeoTIFFCodes', fields{k}))
    end
end
