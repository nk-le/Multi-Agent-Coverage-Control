function ellipsoid = validateEllipsoid(ellipsoid, func_name, var_name, arg_pos)
%map.geodesy.internal.validateEllipsoid Check validity of reference ellipsoid vector
%
%     This function is intentionally undocumented and is intended for
%     use only by other Mapping Toolbox functions.  Its behavior may
%     change, or the function itself may be removed, in a future
%     release.
%
%   ELLIPSOID = map.geodesy.internal.validateEllipsoid(ELLIPSOID, ...
%   FUNC_NAME, VAR_NAME, ARG_POS) ensures that the input ELLIPSOID is a
%   reference ellipsoid (oblate spheroid) object, a reference sphere
%   object, or a vector of the form
%
%                 [semimajor_axis eccentricity].
%
%   with 0 <= Eccentricity < 1.  (A scalar input is interpreted as the
%   semimajor axis and a zero eccentricity is appended in this case.) If
%   ELLIPSOID is an object it is converted to the 1-by-2 vector form.

% Copyright 2007-2019 The MathWorks, Inc.

if ~isobject(ellipsoid)
    if nargin == 3
        args = {func_name, var_name};
    else
        args = {func_name, var_name, arg_pos};
    end
    
    validateattributes( ...
        ellipsoid, {'double'}, {'real', 'finite', 'nonnegative', 'nonempty'}, ...
        args{:})
    
    % Check semimajor axis
    if ellipsoid(1) <= 0
        error(message('map:geodesy:expectedPositiveSemimajorAxis'))
    end
    
    if isscalar(ellipsoid)
        % Append zero eccentricity given scalar input
        ellipsoid(1,2) = 0;
    else
        % Ensure a 1-by-2 vector
        validateattributes(ellipsoid, {'double'}, {'size', [1 2]}, args{:})
        
        % Check eccentricity
        if ellipsoid(2) >= 1
            error(message('map:geodesy:invalidEccentricity'))
        end
    end
else
    % Assume that ellipsoid is an oblateSpheroid or referenceSphere object.
    ellipsoid = [ellipsoid.SemimajorAxis, ellipsoid.Eccentricity];
end
