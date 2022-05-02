function tf = okToSetMapLimits(mstruct,propname)
% True unless the projection type and/or orientation angle precludes
% controlling frame limits of a map projection structure by specifying
% MapLatLimit and MapLonLimit vectors.

% Copyright 2008-2011 The MathWorks, Inc.

tf = true;
if mprojIsExceptional(mstruct.mapprojection)
    id = ['map:okToSetMapLimits:ignoring' propname '1'];
    warning(id,'%s',getString(message('map:maplimits:cannotSetLimits', ...
        propname, propname, mstruct.mapprojection)))
    tf = false;
elseif ~isempty(mstruct.origin)
    origin = mstruct.origin;
    nonzeroOrientationAngle = (numel(origin) >= 3) && (origin(3) ~= 0);    
    if nonzeroOrientationAngle
        id = ['map:okToSetMapLimits:ignoring' propname '2'];
        warning(id,'%s',getString(message('map:maplimits:nonZeroOrientationAngle', ...
            propname)))
        tf = false;
    elseif ~mprojIsAzimuthal(mstruct.mapprojection)
        originlat = mstruct.origin(1);
        nonzeroOriginLat = ~isnan(originlat) && (originlat ~= 0);
        if nonzeroOriginLat && mprojIsRotational(mstruct.mapprojection)
            id = ['map:okToSetMapLimits:ignoring' propname '3'];
            warning(id,'%s',getString(message('map:maplimits:nonZeroOriginLatitude', ...
                propname, mstruct.mapprojection)))
            tf = false;
        end
    end
end

%-----------------------------------------------------------------------

function tf = mprojIsExceptional(mapprojection)

exceptions = {...
    'globe', ...    % No need for map limits -- always covers entire planet
    'cassini', ...  % Always in a transverse aspect
    'wetch', ...    % Always in a transverse aspect
    'bries'};       % Always in an oblique aspect
tf = any(strcmpi(mapprojection,exceptions));

%-----------------------------------------------------------------------

function tf = mprojIsRotational(mapprojection)

tf = ~any(strcmp(mapprojection, {...
       'utm', 'tranmerc', 'lambertstd', 'cassinistd', ...
       'eqaconicstd', 'eqdconicstd', 'polyconstd'}));
