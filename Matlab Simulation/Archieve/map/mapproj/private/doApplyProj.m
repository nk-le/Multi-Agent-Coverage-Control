function outputs = doApplyProj(mproj, mstruct, in1, in2, varargin)
% Parse projection function inputs and apply forward or inverse operation.
%
% The following syntaxes are supported:
%
%   outputs = doApplyProj(mproj, mstruct, in1, in2, objectType, direction)
%   outputs = doApplyProj(mproj, mstruct, in1, in2, in3, objectType, direction)
%   outputs = doApplyProj(..., 'inverse', savepts)
%
% In the 2-D case, outputs is a cell array containg two coordinate
% arrays and a SAVEPTS structure: {out1, out2, savepts}.  In the 3-D
% case, a third coordinate array is included:  {out1, out2, out3, savepts}.

% Copyright 2008-2017 The MathWorks, Inc.

workingIn2D = ischar(varargin{1}) || isstring(varargin{1});
if workingIn2D
    objectType = varargin{1};
    direction  = varargin{2};
else
    in3        = varargin{1};
    objectType = varargin{2};
    direction  = varargin{3};
end
    
switch direction
    
    case 'forward'
        
        [x, y, savepts] = mproj.applyForward(mproj, mstruct, in1, in2, objectType);
        if workingIn2D
            outputs = {realnan(x), realnan(y), savepts};
        else
            [x, y, z] = adjustTrimmingFor3D(...
                realnan(x), realnan(y), in3, savepts, objectType);
            outputs = {x, y, z, savepts};
        end

    case 'inverse'

        % Because of the way doApplyProj is called by its clients, all
        % inputs are certain to exist, with the exception of SAVEPTS.
        % It's important to test for its existence before trying to use
        % it on the right hand side of an expression.
        if (workingIn2D && numel(varargin) < 3) ...
            || (~workingIn2D && numel(varargin) < 4)
            savepts = struct('trimmed',[],'clipped',[]);
        else
            savepts = varargin{end};
        end
        [lat, lon] = mproj.applyInverse( ...
            mproj, mstruct, in1, in2, objectType, savepts);
        if workingIn2D
            outputs = {realnan(lat), realnan(lon)};
        else
            alt = in3;            
            if ~isempty(savepts.clipped) && strcmp(objectType,'line')
                %  Adjust for clipped data in line objects.
                alt(savepts.clipped(:,1)) = [];
            elseif strcmp(objectType,'patch')
                %  Patches can only have a scalar altitude.
                alt = alt(1);
            end
            outputs = {realnan(lat), realnan(lon), alt};
        end

    otherwise
        
        error(message('map:validate:invalidDirectionString', ...
            direction, 'forward', 'inverse'))
end

%-----------------------------------------------------------------------

function y = realnan(x)
% Replace all instances of NaN + NaNi with NaN, while leaving other
% complex elements unchanged.
%
%  Some operations on NaNs produce NaN + NaNi.  However operations
%  outside the map may product complex results and we don't want
%  to destroy this indicator.

y = x;
y(isnan(y)) = NaN;
