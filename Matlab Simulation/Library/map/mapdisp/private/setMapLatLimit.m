function mstruct = setMapLatLimit(mstruct, maplatlimit)
% Update a map projection structure given a new value for its
% MapLatLimit property.

% Copyright 2008-2011 The MathWorks, Inc.

validateattributes(maplatlimit, {'double'}, ...
    {'real','finite','size',[1 2]}, '','maplatlimit')

% Manage "reversed" limits by fixing and warning.
if maplatlimit(1) > maplatlimit(2)
    warning(message('map:maplimits:reversingLimits'))
    maplatlimit = maplatlimit([2 1]);
end

% Define constant equal to 90-degrees in the angle units of the mstruct.
D90 = fromDegrees(mstruct.angleunits, 90);

azimuthalProjection = mprojIsAzimuthal(mstruct.mapprojection);

% Note: In a given call to axesm, this subfunction always runs ahead of
% subfunction setMapLonLimit. If mstruct.origin is empty at the start,
% NaNs are inserted into mstruct.origin(2), allowing setlonlimit to
% reset the origin longitude if necessary.

symmetricMaplatlimit = (maplatlimit(1) == -maplatlimit(2));
if azimuthalProjection && symmetricMaplatlimit
    % Special case: Azimuthal projection symmetric latitude limits:
    if isempty(mstruct.origin)
        % Put the origin on the Equator.
        mstruct.origin = [0 NaN 0];
        mstruct = setFlatlimitAzimuthal(mstruct, maplatlimit);
    elseif isnan(mstruct.origin(1))
        % Put the origin on the Equator.
        mstruct.origin(1) = 0;
        mstruct = setFlatlimitAzimuthal(mstruct, maplatlimit);
    elseif mstruct.origin(1) == 0
        % Origin is already on the Equator, so just set limits.
        mstruct = setFlatlimitAzimuthal(mstruct, maplatlimit);
    else
        warning(message('map:maplimits:latlimMismatchEquator', ...
            'MapLatLimit'))
    end   
elseif okToSetMapLimits(mstruct,'MapLatLimit')
    % Cover all other cases, with additional checks on consistency of
    % origin latitude.
    if azimuthalProjection
        if maplatlimit(1) == -D90
            if isempty(mstruct.origin)
                % Put the origin at the South Pole.
                mstruct.origin = [-D90 NaN 0];
                mstruct = setFlatlimitAzimuthal(mstruct, maplatlimit);
            elseif isnan(mstruct.origin(1))
                % No origin latitude; put it at the South Pole.
                mstruct.origin(1) = -D90;
                mstruct = setFlatlimitAzimuthal(mstruct, maplatlimit);
            elseif mstruct.origin(1) == -D90
                % Origin is already at South Pole, so just set limits.
                mstruct = setFlatlimitAzimuthal(mstruct, maplatlimit);
            else
                warning(message('map:maplimits:latlimMismatchSouthPole', ...
                    'MapLatLimit', 'MapLatLimit'))
            end
        elseif maplatlimit(2) == D90
            if isempty(mstruct.origin)
                % Put the origin at the North Pole.
                mstruct.origin = [D90 NaN 0];
                mstruct = setFlatlimitAzimuthal(mstruct, maplatlimit);
            elseif isnan(mstruct.origin(1))
                % No origin latitude; put it at the North Pole.
                mstruct.origin(1) = D90;
                mstruct = setFlatlimitAzimuthal(mstruct, maplatlimit);
            elseif mstruct.origin(1) == D90
                 % Origin is already at North Pole, so just set limits.
                mstruct = setFlatlimitAzimuthal(mstruct, maplatlimit);
            else                
                warning(message('map:maplimits:latlimMismatchNorthPole', ...
                    'MapLatLimit', 'MapLatLimit'))
            end
        else
            warning(message('map:maplimits:latlimOmitsPole', ...
                'MapLatLimit', 'maplatlimit(1)', 'maplatlimit(2)'))
        end
    else
        % Non-azimuthal projection: Frame limit is relative to the
        % Equator, without regard to the location of the origin.
        if isempty(mstruct.origin)
            mstruct.origin = [0 NaN 0];
        end
        mstruct.flatlimit = maplatlimit;
    end
end

% We're done with the maplatlimit property for now; let resetmstruct
% re-derive it from mstruct.origin and mstruct.flatlimit.
mstruct.maplatlimit = [];

%-----------------------------------------------------------------------

function mstruct = setFlatlimitAzimuthal(mstruct, maplatlimit)

if (maplatlimit(1) == -maplatlimit(2))
    % Origin on Equator
    radius = abs(maplatlimit(2));
else
    % Origin at pole
    radius = abs(diff(maplatlimit));
end
mstruct.flatlimit = [-Inf radius];
