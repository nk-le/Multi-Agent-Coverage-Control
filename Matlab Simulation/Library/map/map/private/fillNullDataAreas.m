function Z = fillNullDataAreas(Z)
% Extrapolate into null-data areas in the 2-D grid Z, including
% null-data areas along the borders as well as in the interior of Z.
% Null data is indicated by a value of NaN. In the result, all
% NaN-valued elements are replaced by smoothly extrapolated values.

% Copyright 2010 The MathWorks, Inc.

if ~any(isnan(Z(:)))
    % No work to do -- return early.
    return
end

assert(~all(isnan(Z(:))), 'map:fillNullDataAreas:allNaN', ...
    'Cannot fill data grid because all elements are NaN.')

validateattributes(Z, {'double','single'}, {'2d'})

% Temporarily convert infinite values to +/- realmax.
posInf = (Z ==  Inf);
negInf = (Z == -Inf);
Z(posInf) =  realmax(class(Z));
Z(negInf) = -realmax(class(Z));

sz = size(Z);

k = 0;
kMax = sum(sz);

while any(isnan(Z(:))) && (k <= kMax)
    % If a NaN-valued element of Z has at least one non-NaN neighbor,
    % replace the value of that element with the average of the values
    % of all its non-NaN neighbors in a 4-connected neighborhood.
    
    C = zeros(sz);  % Count (number) of non-NaN neighbors
    S = zeros(sz);  % Sum of non-NaN neighbors
    
    % Process each of the cardinal directions in sequence, updating the
    % count and sum and accounting for edges (e.g., cells in the first
    % row have no neighbors above them).
    
    % Neighbors above. Use all the rows except the last to update
    % all the rows except the first.
    T = Z(1:end-1,:);
    N = isnan(T);
    T(N) = 0;
    C(2:end,:) = C(2:end,:) + double(~N);
    S(2:end,:) = S(2:end,:) + T;
    
    % Neighbors below. Use all the rows except the first to update
    % all the rows except the last.
    T = Z(2:end,:);
    N = isnan(T);
    T(N) = 0;
    C(1:end-1,:) = C(1:end-1,:) + double(~N);
    S(1:end-1,:) = S(1:end-1,:) + T;

    % Neighbors to the left. Use all the columns except the last
    % to update all the columns except the first.
    T = Z(:,1:end-1);
    N = isnan(T);
    T(N) = 0;
    C(:,2:end) = C(:,2:end) + double(~N);
    S(:,2:end) = S(:,2:end) + T;
    
    % Neighbors to the right. Use all the columns except the first
    % to update all the columns except the last.
    T = Z(:,2:end);
    N = isnan(T);
    T(N) = 0;
    C(:,1:end-1) = C(:,1:end-1) + double(~N);
    S(:,1:end-1) = S(:,1:end-1) + T;

    % Update NaN-valued elements of Z that have at least one non-NaN
    % neighbor.
    I = isnan(Z) & (C > 0);
    Z(I) = S(I) ./ C(I);
    
    k = k + 1;
end

% Restore infinite values, if any.
Z(posInf) =  Inf;
Z(negInf) = -Inf;
