function mstruct = setMapLonLimit(mstruct, maplonlimit)
% Update a map projection structure given a new value for its
% MapLonLimit property.

% Copyright 2008-2011 The MathWorks, Inc.


validateattributes(maplonlimit, {'double'}, ...
    {'real','finite','size',[1 2]}, '','maplonlimit')

if okToSetMapLimits(mstruct,'MapLonLimit')
    
    % Set the origin longitude if it is not currently set.
    if isempty(mstruct.origin)
        % The origin is not set at all; center the origin longitude in
        % the interval defined by maplonlimit and put the origin
        % latitude on the Equator.
        originlon = fromDegrees(mstruct.angleunits, ...
            centerlon(toDegrees(mstruct.angleunits,maplonlimit)));
        mstruct.origin = [0 originlon 0];
    else
        % Replace NaN-value in origin latitude with zero.
        if isnan(mstruct.origin(1))
            mstruct.origin(1) = 0;
        end
        
        if isnan(mstruct.origin(2))
        % The origin latitude is set, but the origin longitude is
        % not; center it in the interval defined by maplonlimit.
        originlon = fromDegrees(mstruct.angleunits, ...
            centerlon(toDegrees(mstruct.angleunits,maplonlimit)));
        mstruct.origin(2) = originlon;
        end
    end
    
    % Set flonlimit (and, in some cases, flatlimit)
    if ~mprojIsAzimuthal(mstruct.mapprojection)
        % Non-azimuthal projection: Set flonlimit to match maplonlimit
        % and the origin longitude.  Any issues with wrapping will be
        % handled later.
        mstruct.flonlimit = maplonlimit - mstruct.origin(2);
    else
        % For azimuthal projections, flonlimit is always [-180 180]
        % degrees.
        mstruct.flonlimit = fromDegrees(mstruct.angleunits, [-180 180]);
        
        % If flatlimit hasn't been set yet for an azimuthal projection
        % with origin on the Equator, use maplonlimit to set it now.
        if isempty(mstruct.flatlimit) && (mstruct.origin(1) == 0)
            radius = abs(diff(maplonlimit))/2;
            mstruct.flatlimit = [-Inf, radius];
        elseif ~isequal(maplonlimit, mstruct.origin(2) + mstruct.flonlimit)
            warning(message('map:maplimits:lonlimMismatch', ...
                'MapLonLimit', 'MapLonLimit', '''FLatLimit'',[]', 'AXESM'))
        end
    end
    
end

% We're done with the maplonlimit property for now; let resetmstruct
% re-derive it from mstruct.origin and mstruct.flonlimit.
mstruct.maplonlimit = [];

%-----------------------------------------------------------------------

function lon = centerlon(lonlim)
% Center of an interval in longitude
%
%   Accounts for wrapping.  Returns the longitude of the meridian halfway
%   from the western limit to the eastern limit, when traveling east.
%   All angles are in degrees.

lon = wrapTo180(lonlim(1) + wrapTo360(diff(lonlim))/2);
