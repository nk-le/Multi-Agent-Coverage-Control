function [x, y, labellat, labellon] = projectLabelPoints(mstruct, lat, lon)
% Project point locations for meridian or parallel labels.

% Copyright 2014 The MathWorks, Inc.

n = numel(lat);
labellat = zeros(1,n);
labellon = labellat;
x = labellat;
y = labellat;
m = 1;
for k = 1:n
    % Iterate, keeping results only for points that are not trimmed away.
    [xk,yk] = feval(mstruct.mapprojection, ...
        mstruct, lat(k), lon(k), 'geopoint', 'forward');
    if ~isempty(xk)
        labellat(m) = lat(k);
        labellon(m) = lon(k);
        x(m) = xk;
        y(m) = yk;
        m = m + 1;
    end
end
labellat(m:end) = [];
labellon(m:end) = [];
x(m:end) = [];
y(m:end) = [];
