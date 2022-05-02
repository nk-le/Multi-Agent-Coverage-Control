function [x, y, z] = adjustTrimmingFor3D(x, y, height, savepts, objectType)
% Process only the Version 1.x objectTypes; this is a no-op for
% 'geopoint', 'geoline', etc.

% Copyright 2008-2011 The MathWorks, Inc.

switch  objectType
    case {'line','linem'}
        %  Adjust for clipped data in objects
        z = zline(x, height, savepts.clipped);
        
    case 'patch'
        z = height(ones(size(x)));
        
    case 'light'
        z = height;
        
        %  Eliminate any lights which have been trimmed
        trimmed = (isnan(x) | isnan(y));
        x(trimmed) = [];
        y(trimmed) = [];
        z(trimmed) = [];
        
        %  Clear any clip or trim markers
        savepts.clipped = [];
        savepts.trimmed = [];
        
    case {'none','surface','point','text','geosurface'}
        z = height;
end

%--------------------------------------------------------------------------

function zout = zline(x, z, clippts)
% Fill z line vector data to correspond with clipped x and y vectors

validateattributes(z, {'double'}, {'2d'})

%  Algorithm requires column vectors
%  X input will be made a column in clipline
if size(z,1) == 1
    z = z';
end

if isempty(clippts)
    %  No clips required
    zout = z;
else
    %  Initialize needed data
    xrow = size(x,1);
    [zrow,zcol] = size(z);

    %  Ensure that columns with no clips are copied
    %  and padded with NaNs at the end
    zout = z;

    %  Fill in extra rows with NaNs
    fillrows = zrow + 1:xrow;
    if ~isempty(fillrows)
        zout(fillrows,:) = NaN;
    end

    %  Adjust the z data column by column.  Place NaNs in the
    %  z data column where the clipping process placed them in
    %  the x data.  Shift the vector for the inclusion of this NaN.
    for i = 1:zcol
        %  Clip points for this column
        indx = find(clippts(:,2) == i);
        
        if ~isempty(indx)
            %  One column of data
            column = z(:,i);
            
            %  All the clip points
            locations = sort(clippts(indx,3));
            
            %  Shift the vector and fill NaNs
            for j = length(locations):-1:1
                lowerindx = 1:locations(j);
                upperindx = locations(j)+1 : zrow+length(locations)-j;
                column = [column(lowerindx); NaN; column(upperindx)];
            end

            %  Replace this column of data
            zout(1:length(column),i) = column;
        end
    end
end
