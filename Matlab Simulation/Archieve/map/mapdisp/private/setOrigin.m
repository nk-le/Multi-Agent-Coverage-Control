function mstruct = setOrigin(mstruct, origin)
% Set/reset the Origin property of a map projection structure.

% Copyright 2008-2011 The MathWorks, Inc.

if ~isempty(origin)
    validateattributes(origin, {'double'}, {'real','row'}, '','origin')
end

% Validate origin
if numel(origin) > 3
    error(message('map:origin:tooManyElements','origin'))
end

if numel(origin) == 3 && ~isempty(mstruct.fixedorient)
    warning(message('map:origin:ignoringOrientation'))
    mstruct.origin = origin;
elseif strcmp(mstruct.mapprojection, 'utm')
    warning(message('map:origin:ignoringOriginForUTM'))
elseif strcmp(mstruct.mapprojection, 'ups')
    warning(message('map:origin:ignoringOriginForUPS'))
elseif isscalar(origin)
    % Interpret scalar value as origin longitude.
    mstruct.origin = [NaN origin];
else
    mstruct.origin = origin;
end
