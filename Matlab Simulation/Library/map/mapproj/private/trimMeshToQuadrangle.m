function [lat, lon] = trimMeshToQuadrangle(lat, lon, latlim, lonlim)
% If the lat-lon mesh is plaid and any limit falls between a pair of
% adjacent rows or columns, first snap each row or column that falls just
% outside of a limit to that limit. Then, in any case, for any mesh point
% that falls outside the quadrangle defined by latlim and lonlim, assign
% NaN to the corresponding elements of lat and lon. All angles are in
% radians.

% Copyright 2013-2015 The MathWorks, Inc.

% Check to see if (lat,lon) defines a plaid mesh.
latc = lat(:,1);   % Column vector of latitudes
lonr = lon(1,:);   % Row vector of longitudes
[lonm,latm] = meshgrid(lonr,latc);
isPlaid = isequal(lat,latm) && isequal(lon,lonm);

if isPlaid  
    
    %--------------- Process latitude vector and limits -------------------
    
    southToNorth = latc(1) <= latc(end);
    if southToNorth
        % Columns run south-to-north
        
        % Snap the first row that is not north of the southern limit to the
        % southern limit. (If the latitude of that row already equals the
        % latitude of the limit, nothing will change.)
        kSouth = find(latc <= latlim(1),1,'last');
        if ~isempty(kSouth)
            lat(kSouth,:) = latlim(1);
        end
        
        % Snap the last row that is not south of the northern limit to the
        % northern limit.
        kNorth = find(latc >= latlim(2),1,'first');
        if ~isempty(kNorth)
            lat(kNorth,:) = latlim(2);
        end
    else
        % Columns run north-to-south
        
        % Snap the last row that is not south of the northern limit to the
        % northern limit.
        kNorth = find(latc >= latlim(2),1,'last');
        if ~isempty(kNorth)
            lat(kNorth,:) = latlim(2);
        end
        
        % Snap the first row that is not north of the southern limit to the
        % southern limit.
        kSouth = find(latc <= latlim(1),1,'first');
        if ~isempty(kSouth)
            lat(kSouth,:) = latlim(1);
        end        
    end

    %--------------- Process longitude vector and limits ------------------

    % Flip, as needed, such that the rows run from west to east.
    t = unwrap(lonr);
    flipEW = t(end) < t(1);
    if flipEW
        lon = lon(:,end:-1:1);
        lonr = lonr(end:-1:1);
    end
    
    w = lonr(1);
    e = lonr(end);
    
    % See if the mesh spans either of the quandrangle's longitude limits.
    meshspan = wrapTo2Pi(e - w);
    spansWesternLimit = (wrapTo2Pi(lonlim(1) - w) <= meshspan);
    spansEasternLimit = (wrapTo2Pi(lonlim(2) - w) <= meshspan);
    
    limitspan = wrapTo2Pi(lonlim(2) - lonlim(1));
    inlonzone = (wrapTo2Pi(lonr - lonlim(1)) <= limitspan);
    
    if spansWesternLimit && any(~inlonzone)
        % Snap the last column that is not east of the western longitude
        % limit to the western limit. (If the longitude of that column
        % already equals the longitude of the limit, nothing will change.)
        
        % Wrap the mesh relative to western limit. We need to check the
        % transition from negative to positive values in d, if there is one.
        d = wrapToPi(lonr - lonlim(1));
        
        % If the mesh starts out with columns that are more than pi radians
        % west of lonlim(1), then d will start out with a sequence of
        % positive values that need to be adjusted.
        if d(1) > 0
            indx = 1:(find(d <= 0,1,'first') - 1);
            d(indx) = d(indx) - 2*pi;
        end
        
        kWest = find(d <= 0,1,'last');
        if ~isempty(kWest) && ~inlonzone(kWest)
            lon(:,kWest) = lonlim(1);
        end
    end
    
    if spansEasternLimit && any(~inlonzone)
        % Snap the first column that is not west of the eastern longitude
        % limit to the eastern limit. (If the longitude of that column
        % already equals the longitude of the limit, nothing will change.)
        
        % Wrap the mesh relative to the eastern limit. We need to check the
        % transition from negative to positive values in d, if there is one.
        d = wrapToPi(lonr - lonlim(2));
        
        % If the mesh starts out with columns that are more than pi radians
        % west of lonlim(2), then d will start out with a sequence of
        % positive values that need to be adjusted.
        if d(1) > 0
            indx = 1:(find(d <= 0,1,'first') - 1);
            d(indx) = d(indx) - 2*pi;
        end
        
        kEast = find(d >= 0,1,'first');
        if ~isempty(kEast) && ~inlonzone(kEast)
            lon(:,kEast) = lonlim(2);
        end
    end
    
    if flipEW
        % Undo east-west flip.
        lon = lon(:,end:-1:1);
    end
end

q = ~ingeoquad(rad2deg(lat), rad2deg(lon), ...
    rad2deg(latlim), rad2deg(lonlim));

% Discard points falling outside the quadrangle by replacing them with NaNs
lat(q) = NaN;
lon(q) = NaN;

% Ensure that lon falls within the interval specified by lonlim.
lon = lonlim(1) + wrapTo2Pi(lon - lonlim(1));
