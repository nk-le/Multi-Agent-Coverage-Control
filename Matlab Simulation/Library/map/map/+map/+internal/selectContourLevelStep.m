function levelstep = selectContourLevelStep(zmin, zmax)
% Select a level step automatically.

% Copyright 2015 The MathWorks, Inc.

    % Adapted from:
    %    toolbox/matlab/specgraph/@specgraph/@contourgroup/refresh.m

    range = zmax - zmin;
    range10 = 10^(floor(log10(range)));
    nsteps = range/range10;
    if nsteps < 1.2
        range10 = range10/10;
    elseif nsteps < 2.4
        range10 = range10/5;
    elseif nsteps < 6
        range10 = range10/2;
    end
    levelstep = range10;
end
