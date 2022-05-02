function R = setRasterReferenceCRS(R, crs)
%setRasterReferenceCRS set CRS property of raster reference object

% Copyright 2020 The MathWorks, Inc.

    if ~isempty(R) && ~isempty(crs)
        try
            if isa(R, 'map.rasterref.GeographicRasterReference')
                if isa(crs, 'geocrs')
                    gcrs = crs;
                else
                    gcrs = geocrs(crs);
                end
                if strcmp(gcrs.AngleUnit, 'degree')
                    R.GeographicCRS = gcrs;
                end
            elseif isa(R, 'map.rasterref.MapRasterReference')
                if isa(crs, 'projcrs')
                    pcrs = crs;
                else
                    pcrs = projcrs(crs);
                end
                R.ProjectedCRS = pcrs;
            end
        catch
        end
    end
end