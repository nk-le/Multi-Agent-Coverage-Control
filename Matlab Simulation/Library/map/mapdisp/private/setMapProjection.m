function mstruct = setMapProjection(mstruct,mapprojection)
% Update a map projection structure given a new value for its
% MapProjection property.

% Copyright 2008 The MathWorks, Inc.

mapprojection = maps(mapprojection);

if isempty(mstruct.mapprojection)
    % We don't yet have a map projection.
    mstruct.mapprojection = mapprojection;
elseif ~isequal(mapprojection, mstruct.mapprojection)
    % We have a map projection, but we're changing it.
    
    % Get a default mstruct for the new projection.
    default = defaultm(mapprojection);
        
    % Reset if necessary.
    if switchingToFromAzimuthal(mstruct,default) ...
            || mprojIsExceptional(mstruct.mapprojection) ...
            || mprojIsExceptional(default.mapprojection)
        mstruct.flatlimit = [];
        mstruct.flonlimit = [];
        mstruct.maplatlimit = [];
        mstruct.maplonlimit = [];
        mstruct.mlabelparallel = [];
        mstruct.plabelmeridian = [];
        mstruct.mlinelocation = [];
        mstruct.plinelocation = [];
        mstruct.mlabellocation = [];
        mstruct.plabellocation = [];
        mstruct.mlineexception = [];
        mstruct.mlinelimit = [];
        mstruct.trimlat = default.trimlat;
        mstruct.trimlon = default.trimlon;
    elseif trimLimitsDiffer(mstruct,default)
        mstruct.trimlat = default.trimlat;
        mstruct.trimlon = default.trimlon;
    end
    
    if mprojIsExceptional(mstruct.mapprojection) ...
        || mprojIsExceptional(default.mapprojection)
        mstruct.origin = [];
    end
    
    % Reset the 'mapprojection' property itself.
    mstruct.mapprojection = mapprojection;
end

if any(strcmp(mstruct.mapprojection, {'utm','ups'}))
    mstruct.origin = []; % origin determined by ZONE
else
    mstruct.zone = [];
end
mstruct = feval(mstruct.mapprojection,mstruct);

%-----------------------------------------------------------------------

function tf = switchingToFromAzimuthal(mstruct,default)

tf = ~isequal(isinf(mstruct.trimlat(1)), isinf(default.trimlat(1)));

%-----------------------------------------------------------------------

function tf = trimLimitsDiffer(mstruct,default)

tf = (~isequal(mstruct.trimlat, default.trimlat) || ...
      ~isequal(mstruct.trimlon, default.trimlon));
  
%-----------------------------------------------------------------------

function tf = mprojIsExceptional(mapprojection)

exceptions = {...
    'globe', ...    % No need for map limits -- always covers entire planet
    'cassini', ...  % Always in a transverse aspect
    'wetch', ...    % Always in a transverse aspect
    'bries'};       % Always in an oblique aspect
tf = any(strcmpi(mapprojection,exceptions));
