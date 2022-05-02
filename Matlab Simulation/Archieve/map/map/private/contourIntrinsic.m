function [L, P] = contourIntrinsic(Z, levels, rasterInterpretation, edgefix)
%contourIntrinsic Contour lines and polygons in intrinsic coordinates
%
%   [L, P] = contourIntrinsic(Z, levels, rasterInterpretation, edgefix)
%   contour the data grid Z in intrinsic raster coordinates, at the
%   contour levels specified in the vector LEVELS, and returns the
%   results in the form of line and polygon mapstructs L and P.
%
%   The rasterInterpretation input is a string with a value of either
%   'postings' or 'cells'. In the 'postings' case, there is no
%   extrapolation beyond data points them selves, so Z with size M-by-N
%   the contour lines are bounded by the limits [1 N] in X and [1 M] in
%   Y. In the case of postings, Z is extrapolated a distance of 0.5 (in
%   intrinsic units) beyond the data extent, resulting in limits of
%   [0.5, N + 0.5] in X and [0.5, M + 0.5] in Y.
%
%   The edgefix input is a scalar structure with three fields, each a
%   scalar-valued logical:
%
%       AverageFirstRow
%       AverageLastRow
%       AverageFirstAndLastColumns
%
%   Application notes: Any of the first three might be true when, in
%   terms of external coordinates, Z is referenced to a geographic
%   (latitude-longitude) system and that some special handling of the
%   edges is required. When working with a projected map (x-y) system
%   rather than latitude-longitude, the values of all three should be
%   set to false.
%
%   The outputs, L and P, are line and polygon mapstructs. The line
%   mapstruct L one element per contour level, and has the fields:
%
%       Geometry
%       BoundingBox
%       X
%       Y
%       Level
%
%   The polygon mapstruct P has one more element than L, and has fields:
%
%       Geometry
%       BoundingBox
%       X
%       Y
%       MinLevel
%       MaxLevel
%
%   L(k).X and L(k).Y are vertex arrays including all the contour lines
%   at the k-th contour level, L(k).Level. The vertices are ordered such
%   that the "uphill" side of each line is on its right-hand side.
%   MinLevel and MaxLevel are scalars such that the polygon defined by
%   P(k).X and P(k).Y bounds an area in which the value of Z remains
%   between P(k).MinLevel and P(k).MaxLevel.
%
%   See GEOCONTOURS for more details on the fields MinLevel and MaxLevel.

% Copyright 2010-2020 The MathWorks, Inc.

% contourc requires real-valued input of class double.
validateattributes(Z, {'numeric'}, {'real'}, 'contourIntrinsic','Z',1)
Z = double(Z);

% Z must contain at least one finite value.
if isempty(Z) || all(isnan(Z(:)) | isinf(Z(:)))
    [L, P] = emptyContourStructures();
    return
end

[M, N] = size(Z);
if strcmp(rasterInterpretation,'cells')
    % Pad all four edges of Z with a layer one cell thick, contour,
    % and map back to the intrinsic coordinates of the input grid.
    A = fillNullDataAreas(Z);
    A = padgrid(A, edgefix);
    L = contourLines(A, levels);
    for k = 1:numel(L)
        % Account for the geometrical effects of padding.
        L(k).X = mapBackToRegularGrid(L(k).X, N);
        L(k).Y = mapBackToRegularGrid(L(k).Y, M);
    end
    [xNull, yNull] = nullAreaPolygon(padgrid(Z, edgefix));
    xNull = mapBackToRegularGrid(xNull, N);
    yNull = mapBackToRegularGrid(yNull, M);
    xLimit = [0.5, N + 0.5];
    yLimit = [0.5, M + 0.5];
else
    % Raster interpretation is 'postings'; work directly with contourc.
    % Z must be at least 2-by-2 to avoid a degenerate fill polygon.
    if M < 2 || N < 2
        [L, P] = emptyContourStructures();
        return
    end
    
    A = fillNullDataAreas(Z);
    A = fixgrid(A, edgefix);
    L = contourLines(A, levels);
    [xNull, yNull] = nullAreaPolygon(fixgrid(Z, edgefix));
    xLimit = [1 N];
    yLimit = [1 M];
end

if isempty(xNull)
    nullpoly = polyshape.empty;
else
    nullpoly = polyshape(xNull, yNull, 'Simplify', false);
end

% Find global maximum.
Zmin = min(Z(:));
Zmax = max(Z(:));
[row,col] = find(Z == Zmax);
xmax = col(1);
ymax = row(1);

L = fixLineTopology(L, xLimit, yLimit, xmax, ymax);

% Identify elements of the levels vector that fall within the data
% limits. (They are consistent with the behavior of contourc and with the
% values of the Level field in L set by contourMatrixToMapstruct.)
% In the special case in which Z is uniform and coincides with one of
% the elements in levels, levelsInLimits will be empty and P will have
% one element with MinLevel and MaxLevel values equal to the value of Z.
levelsInLimits = levels(Zmin <= levels & levels <= Zmax & Zmin < Zmax);
n = numel(levelsInLimits);

needPolygons = (nargout > 1);
if needPolygons
    % Adjust the line topology and construct a topologically correct
    % polygon mapstruct.

    P = constructContourPolygons(L, xLimit, yLimit);
    
    % Set MinLevel field for polygon mapstruct. (For P(1), if all the
    % levels fall above Zmin, use Zmin. Otherwise, use the highest level
    % that falls below Zmin.)
    P(1).MinLevel = min([Zmin max(levels(levels <= Zmin))]);
    for k = 2:n+1
        P(k).MinLevel = levelsInLimits(k - 1);
    end
    
    % Set MaxLevel field for polygon mapstruct. (For P(n+1), if all the
    % levels fall below Zmax, use Zmax. Otherwise, use the lowest level
    % that falls above Zmax.)
    for k = 1:n
        P(k).MaxLevel = levelsInLimits(k);
    end
    P(n+1).MaxLevel = max([Zmax min(levels(levels >= Zmax))]);
    
    if ~isempty(nullpoly)
        % Subtract the null polygon from each of the fill polygons.
        w = warning('off','MATLAB:polyshape:boundary3Points');
        c = onCleanup(@() warning(w));
        for k = 1:numel(P)
            fillpoly = polyshape(P(k).X, P(k).Y, 'Simplify', false);
            [P(k).X, P(k).Y] = boundary(subtract(fillpoly, nullpoly));
        end
    end
end

if ~isempty(xNull)
    % Remove contour line vertices that fall inside the null polygon.
    for k = 1:numel(L)
        x = L(k).X;
        y = L(k).Y;
        [in, on] = inpolygon(x, y, xNull, yNull);
        x(in & ~on) = NaN;
        y(in & ~on) = NaN;
        [L(k).X, L(k).Y] = removeExtraNanSeparators(x, y);
    end
end

%-----------------------------------------------------------------------

function A = padgrid(Z, edgefix)
% Augment Z with an additional row at the top, and additional row at the
% bottom, and additional column to the left, and an additional column to
% the right. If Z is M-by-N, then A is (M+2)-by-(N+2).

[M, N] = size(Z);

A = zeros(M + 2, N + 2);
A(2:M+1, 2:N+1) = Z;

if edgefix.AverageFirstRow
    % (Application: Average a row that's adjacent to a pole.)
    A(1, 2:end-1) = mean(Z(1,:));
else
    % Replicate first row.
    A(1, 2:end-1) = Z(1,:);
end

if edgefix.AverageLastRow
    % (Application: Average a row that's adjacent to a pole.)
    A(end, 2:end-1) = mean(Z(end,:));
else
    % Replicate last row.
    A(end, 2:end-1) = Z(end,:);
end

if edgefix.AverageFirstAndLastColumns
    % (Application: Average a grid across its bounding meridian.)
    firstLastAverage = (A(:,2) + A(:,end-1)) / 2;
    A(:,1)   = firstLastAverage;
    A(:,end) = firstLastAverage;
else
    % Replicate first and last columns.
    A(:,1)   = A(:,2);
    A(:,end) = A(:,end-1);
end

%-----------------------------------------------------------------------

function Z = fixgrid(Z, edgefix)
% Average the outer edges of Z, depending on the field values in
% edgefix.

if edgefix.AverageFirstAndLastColumns
    % (Application: Average a grid across its bounding meridian.)
    firstLastAverage = (Z(:,1) + Z(:,end)) / 2;
    Z(:,1)   = firstLastAverage;
    Z(:,end) = firstLastAverage;
end

if edgefix.AverageFirstRow
    % (Application: Average a row that's at a pole.)
    Z(1,:) = mean(Z(1,:));
end
    
if edgefix.AverageLastRow
    % (Application: Average a row that's at a pole.)
    Z(end, :) = mean(Z(end,:));
end

%-----------------------------------------------------------------------

function L = contourLines(Z, levels)
% Call contourc using the correct syntax for either a scalar level or
% multiple levels.  Pre-condition Z by applying a 5% perturbation
% (relative to the contour interval -- or the data range if only one
% contour level is provided) to any element that exactly equals an
% element of levels.

k = find(isfinite(Z));
assert(~isempty(k), 'map:contourIntrinsic:nonFiniteData', ...
    'Input contains no finite values - unable to calculate contours.')

zmin = min(Z(k));
zmax = max(Z(k));
midlevel = (zmin + zmax) / 2;

if isscalar(levels)
    delta = (zmax - zmin) / 20;
    matchesLevel = (Z == levels);
    if levels > midlevel
        Z(matchesLevel) = Z(matchesLevel) + delta;
    else
        Z(matchesLevel) = Z(matchesLevel) - delta;
    end
    c = contourc(Z, [levels levels]);
else
    delta = min(diff(levels)) / 20;
    for k = 1:numel(levels)
        matchesLevel = (Z == levels(k));
        if levels(k) > midlevel
            Z(matchesLevel) = Z(matchesLevel) + delta;
        else
            Z(matchesLevel) = Z(matchesLevel) - delta;
        end
    end
    c = contourc(Z, levels);
end

L = contourMatrixToMapstruct(c);

% Filter out contour line segments that run along the edge of the rectangle
% bounding the data area.
xLimit = [1 size(Z,2)];
yLimit = [1 size(Z,1)];
for k = 1:numel(L)
    [x, y] = filterEdgeSegments(L(k).X, L(k).Y, xLimit, yLimit);
    L(k).X = x;
    L(k).Y = y;
end

%-----------------------------------------------------------------------

function [xp, yp] = nullAreaPolygon(Z)
% Compute a (multipart) polygon bounding the null areas in Z, as defined
% by elements of Z that equal NaN.

if any(isnan(Z(:)))
    % Create an array the same size as Z, with 0s for non-NaN elements
    % and 2s for NaN-valued elements of A, and contour it at z == 1.
    [M, N] = size(Z);
    A = zeros(M,N);
    A(isnan(Z)) = 2;
    c = contourc(A, [1 1]);
    L = contourMatrixToMapstruct(c);
    
    % Convert to a valid polygon topology and extract the vertex arrays.
    [I, J] = find(A == 2);
    [~, ~, xp, yp] = adjustContourTopology( ...
        L.X, L.Y, [1 N], [1 M], J(1), I(1));
else
    xp = [];
    yp = [];
end

%-----------------------------------------------------------------------

function x = mapBackToRegularGrid(x, n)
% We've mapped the interval [1 n] to the interval [2 n+1], and extended
% by 0.5 in either direction such that [1/2 1] was mapped to [1 2] on
% the left and [n  n+1/2] was mapped to [n+1 n+2]. This function
% reverses that mapping.

q = (x < 2);          % Left extension
p = (x > (n + 1));    % Right extension
r = (~q & ~p);        % Original interval

x(q) = x(q) / 2;
x(p) = (x(p) + n - 1)/2;
x(r) = x(r) - 1;

%-----------------------------------------------------------------------

function L = fixLineTopology(L, xLimit, yLimit, xmax, ymax)
% Update contour line topology. Starting with the output of contourc as
% encoded in line mapstruct L, adjust the line topology of each level as
% required to ensure that the "uphill" area falls on the right as one
% traverses the vertices from first to last.

for k = 1:numel(L)
    [x, y] = adjustContourTopology( ...
        L(k).X, L(k).Y, xLimit, yLimit, xmax, ymax);
    L(k).X = x(:);
    L(k).Y = y(:);
    L(k).BoundingBox = [min(x) min(y); max(x) max(y)];
end
