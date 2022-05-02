function levelList = constructContourLevelList(zmin, zmax, levelstep)
% Return a level list given a step size and the extrema of the input data

% Copyright 2015 The MathWorks, Inc.

    % Adapted from:
    %    toolbox/matlab/specgraph/@specgraph/@contourgroup/refresh.m

    if zmin < 0 && zmax > 0
        step = levelstep;
        neg = -step:-step:zmin;
        pos = 0:step:zmax;
        levelList = [fliplr(neg) pos];
    elseif zmin < 0 && zmin < zmax
        step = levelstep;
        start = zmin - (step - mod(-zmin,step));
        levelList = start+step:step:zmax;
    elseif 0 <= zmin && zmin < zmax
        step = levelstep;
        start = zmin + (step - mod(zmin,step));
        levelList = start:step:zmax;
    else
        % zmin == zmax
        levelList = zmin;
    end
end
