function crs = formatNonEPSGCodeInput(crs, authority)
% Format crs input. If the authority is EPSG, return crs unchanged.
% Otherwise, format crs in order to request a non-EPSG code.

% Copyright 2020 The MathWorks, Inc.
    
    if ~strcmp(authority, "EPSG")
        if isnumeric(crs) || ~contains(crs,"[")
            crs = string(authority) + ":" + crs;
        else
            % Authority codes must be specified when providing
            % an authority name. WKT strings are not accepted.
            error(message('map:crs:AuthorityWithWKT'))
        end
    else
        if ~isnumeric(crs) && contains(crs,"[")
            % Authority codes must be specified when providing
            % an authority name. WKT strings are not accepted.
            error(message('map:crs:AuthorityWithWKT'))
        end
    end
end