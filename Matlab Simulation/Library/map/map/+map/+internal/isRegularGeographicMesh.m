function tf = isRegularGeographicMesh(latmesh, lonmesh)
% True if the mesh represented by LATMESH and LONMESH is regular: Regular
% sampling in both latitude and longitude and aligned with meridians and
% parallels. LATMESH and LONMESH can be matrices of matching size. LATMESH
% can also be a column vector and LONMESH can be a row vector. Both LATMESH
% and LONMESH are in degrees.

% Copyright 2014 The MathWorks, Inc.

% Default return value. tf will remain false unless all of the following
% checks for regularity are satisified.
tf = false;

% Are all the latitudes identical across each row?
sameLatitudeAcrossEachRow = (size(latmesh,1) >= 1) ... 
    && ((size(latmesh,2) == 1) || (all(all(diff(latmesh,[],2) == 0))));

% Are all the longitudes identical up and down each column?
sameLongitudeAlongEachColumn = (size(lonmesh,2) >= 1) ...
    && ((size(lonmesh,1) == 1) || (all(all(diff(lonmesh,[],1) == 0))));

if sameLatitudeAcrossEachRow && sameLongitudeAlongEachColumn
    % Row vector of latitudes (with 2 or more elements)
    lat = latmesh(:,1)';
        
    % Is the spacing in latitude regular (within a tolerance)?
    spacingInLatitude = diff(lat);
    monotonicInLatitude ...
        = all(spacingInLatitude > 0) || all(spacingInLatitude < 0);
    if monotonicInLatitude
        absoluteSpacingInLatitude = abs(spacingInLatitude);
        n = numel(spacingInLatitude);
        averageSpacingInLatitude = sum(absoluteSpacingInLatitude) / n;
        tol = eps(180);
        if all(abs(absoluteSpacingInLatitude - averageSpacingInLatitude) < tol)
            % The spacing is regular in latitude; now check longitude.
            
            % Unwrapped vector of longitudes (with 2 or more elements)
            ascending = all(diff(lonmesh(1,:) > 0));
            if ascending
                lon = lonmesh(1,:);
            else
                lon = unwrapMultipart(lonmesh(1,:),'degrees');
            end
            
            % Is the spacing in longitude regular (within a tolerance)?
            spacingInLongitude = diff(lon);
            monotonicInLongitude ...
                = all(spacingInLongitude > 0) || all(spacingInLongitude < 0);
            if monotonicInLongitude
                absoluteSpacingInLongitude = abs(spacingInLongitude);
                n = numel(spacingInLongitude);
                averageSpacingInLongitude = sum(absoluteSpacingInLongitude) / n;
                tol = eps(720);
                if all(abs(absoluteSpacingInLongitude - averageSpacingInLongitude) < tol)
                    % The mesh is sufficently regular.
                    tf = true;
                end
            end
        end
    end
end
