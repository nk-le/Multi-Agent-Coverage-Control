function [ymat,xmat,trimpts] = trimdata(ymat,ylim,xmat,xlim,object)
%TRIMDATA Trim map data exceeding projection limits
%
%  [ymat,xmat,trimpts] = trimdata(ymat,ylim,xmat,xlim,'object') will
%  identify points in map data which exceed projection limits.
%  The projection limits are defined by the lower and upper inputs.
%  The particular object to be trimmed is identified by the 'object' input.
%
%  Allowable objects are:  'surface' for trimming graticules;
%  'light' for trimming lights; 'line' for trimming lines;
%  'patch' for trimming patches; 'text' for trimming text object
%  location points; and 'none' to skip all trimming operations.
%
%  See also CLLIPDATA, UNDOCLIP, UNDOTRIM

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

validateattributes(ymat, {'numeric'},{'2d'},'trimdata','ymat')
validateattributes(xmat, {'numeric'},{'2d'},'trimdata','xmat')

object = validatestring(object, ...
    {'surface','point','line','linem','patch','text','light','none'}, ...
    'trimdata','object');

map.internal.assert(isequal(size(xmat),size(ymat)), ...
    'map:validate:inconsistentSizes2','trimdata','xmat','ymat')

%  Switch according to the correct object
switch object
    case {'surface','point'}
        [ymat,xmat,trimpts] = trimnans(ymat,ylim,xmat,xlim);
        if ~isempty(trimpts)
            indx = trimpts(:,1) + (trimpts(:,2)-1)*size(xmat,1);
            trimpts = [indx  trimpts(:,3:4) ];
        end
        
    case {'line','linem'}
        [ymat,xmat,trimpts] = trimnans(ymat,ylim,xmat,xlim);
        
    case 'patch'
        [ymat,xmat,trimpts] = trimpatch(ymat,ylim,xmat,xlim);
        
    case 'text'
        offset = deg2rad(5);     %  Allow text to be 5 deg outside trim limits
        xlim = [min(xlim)-offset max(xlim)+offset];
        ylim = [min(ylim)-offset max(ylim)+offset];
        [ymat,xmat,trimpts] = trimnans(ymat,ylim,xmat,xlim);
        
    case 'light'
        offset = deg2rad(5);     %  Allow light to be 5 deg outside trim limits
        xlim = [min(xlim)-offset max(xlim)+offset];
        ylim = [min(ylim)-offset max(ylim)+offset];
        [ymat,xmat,trimpts] = trimnans(ymat,ylim,xmat,xlim);
        
    case 'none'
        trimpts = [];
end

%--------------------------------------------------------------------------

function [ymat,xmat,trimpts] = trimnans(ymat,ylim,xmat,xlim)
%TRIMNANS  Trim graticule and line data exceeding projection limits
%
%  TRIMNANS will identify points in graticule and line data which exceed
%  projection limits.  The projection limits are defined by the lower and
%  upper inputs.  Points outside the projection range are replaced with
%  NaNs, thereby trimming them from the display.

%  Need a column vector to properly compute the indx below.
if size(xmat,1) == 1
    xmat = xmat';
    ymat = ymat';
end

%  Compute the indices of data elements exceeding the specified limits

[rx,cx] = find(xmat > max(xlim) | xmat < min(xlim));
[ry,cy] = find(ymat > max(ylim) | ymat < min(ylim));

%  Pack these indices into a single matrix

trimpts = [rx  cx;  ry cy];

%  Trim the data by replacing out of range elements with NaNs

if ~isempty(trimpts)
    indx = trimpts(:,1) + (trimpts(:,2)-1)*size(xmat,1);
    trimpts(:,3:4) = [ymat(indx) xmat(indx)];
    xmat(indx) = NaN;
    ymat(indx) = NaN;
end

%--------------------------------------------------------------------------

function [yvec,xvec,trimpts] = trimpatch(yvec,ylim,xvec,xlim)
%TRIMPATCH  Trim patch vector data exceeding projection limits
%
%  TRIMPATCH will identify points in patch vector data
%  which exceed projection limits.  The projection limits
%  are defined by the lower and upper inputs.  Points outside
%  the projection range are replaced with their respective limits,
%  thereby trimming them from the display.  If a patch lies completely
%  outside the trim limits, it is completely replaced with NaNs.

xvec = xvec(:);
yvec = yvec(:);

%  Find the individual patches.
indx = find(isnan(xvec) | isnan(yvec));
if isempty(indx)
    indx = length(xvec)+1;
end

trimpts = [];
for i = 1:length(indx)
    if i == 1
        startloc = 1;
    else
        startloc = indx(i-1) + 1;
    end
    endloc = indx(i) - 1;
    indices = (startloc:endloc)';
    
    % Indices should not be empty unless there are adjacent NaN values in
    % the input vectors. This would be unexpected, but check to be sure.
    if ~isempty(indices)
        
        %  Patches which lie completely outside the trim window.
        %  If at least one point of the patch edge does not lie with the
        %  specified window limits, then the entire patch is trimmed.
        
        if ~any(xvec(indices) >= min(xlim) & xvec(indices) <= max(xlim) & ...
                yvec(indices) >= min(ylim)  & yvec(indices) <= max(ylim))
            trimpts = [trimpts;
                indices ones(size(indices)) ...
                yvec(indices) xvec(indices)]; %#ok<*AGROW>
            xvec(indices) = NaN;
            yvec(indices) = NaN;
        end
        
        %  Need to only test along edge since patch must lie somehow within
        %  the window.  Make sure that the original data is saved before
        %  the points are replaced with the limit data.
        
        %  Points off the bottom
        loctn = find( xvec(indices) < min(xlim) );
        if ~isempty(loctn)
            trimpts = [trimpts;
                indices(loctn) ones(size(loctn)) ...
                yvec(indices(loctn)) xvec(indices(loctn))];
            xvec(indices(loctn)) = min(xlim);
        end
        
        %  Points off the top
        loctn = find( xvec(indices) > max(xlim) );
        if ~isempty(loctn)
            trimpts = [trimpts;
                indices(loctn) ones(size(loctn)) ...
                yvec(indices(loctn)) xvec(indices(loctn))];
            xvec(indices(loctn)) = max(xlim);
        end
        
        %  Points off the left
        loctn = find( yvec(indices) < min(ylim) );
        if ~isempty(loctn)
            trimpts = [trimpts;
                indices(loctn) ones(size(loctn)) ...
                yvec(indices(loctn)) xvec(indices(loctn))];
            yvec(indices(loctn)) = min(ylim);
        end
        
        %  Points off the right
        loctn = find( yvec(indices) > max(ylim) );
        if ~isempty(loctn)
            trimpts = [trimpts;
                indices(loctn) ones(size(loctn)) ...
                yvec(indices(loctn)) xvec(indices(loctn))];
            yvec(indices(loctn)) = max(ylim);
        end
    end
end
