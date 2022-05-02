function s = nonOverlap(lim, limits)
%Subsets of interval not overlapping other intervals
%
%   Identify all subsets S of the interval defined by the 2-by-1 vector
%   LIM that are _not_ covered by the intervals defined by the columns
%   of the 2-by-N array LIMITS. Concatenate the results into a column
%   vector with separating and terminating NaNs. Handle these natural
%   end-member cases:
%
%   1. If LIM is fully covered by intervals in LIMITS, the result is [].
%
%   2. LIM is not covered at all, the result is [LIM; NaN].
%
%   Assumptions
%   -----------
%   1. LIM(1) <= LIM(2)
%   2. LIMITS(1,:) <= LIMITS(2,:)
%   3. None of the intervals in LIMITS intersect each other.
%
%   Example
%   -------
%   lim = [0 1]';
%   limits = [-4 -3; -0.5 0.1; 0.8 1.3; 4 6]'
%   s = nonOverlap(lim, limits)
%   % Results in [0.1; 0.8; NaN]

% Copyright 2010 The MathWorks, Inc.

assert(lim(1) <= lim(2), ...
    'map:nonOverlap:limReversed', ...
    '%s must be less or equal to %s.', 'LIM(1)', 'LIM(2)')

assert(all(limits(1,:) <= limits(2,:)), ...
    'map:nonOverlap:limitsReversed', ...
    '%s must be less or equal to %s.', 'LIMITS(1,:)', 'LIMITS(2,:)')

% Compute a "trial" intersection of LIM with each column of LIMITS; just
% assume that an intersection exists and compute what its limits would be.
intersections(2,:) = min(lim(2), limits(2,:));
intersections(1,:) = max(lim(1), limits(1,:));

% Discard any column that does not correspond to an actual intersection.
intersections(:,intersections(1,:) > intersections(2,:)) = [];

% Find the sub-intervals of LIM not covered by LIMITS
s = [lim(1); sort(intersections(:)); lim(2)];

% Reshape column vector to 2-by-M array.
s = reshape(s, [2 numel(s)/2]);

% Remove degenerate intervals.
s(:,degenerate(s)) = [];

% Insert NaN-separators and convert back to column vector shape.
s(3,:) = NaN;
s = s(:);

%---------------------------------------------------------------------------

function tf = degenerate(s)
% Identify an interval as degenerate the limits differ by more than a
% specific tolerance. For now we are using a relative tolerance. It's
% also conceivable to pass in an absolute tolerance value.

r = max(abs(s),[],1);
tol = 100 * eps(r);

tf = abs(s(2,:) - s(1,:)) < tol;
