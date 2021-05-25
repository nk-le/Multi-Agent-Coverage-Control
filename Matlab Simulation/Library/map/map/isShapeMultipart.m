function tf = isShapeMultipart(xdata, ydata)
%isShapeMultipart  True if polygon or line has multiple parts
%
%   TF = isShapeMultipart(XDATA, YDATA) returns true if the polygon or
%   line shape specified by XDATA and YDATA consists of multiple
%   NaN-separated parts (i.e. has inner and/or multiple polygon rings or
%   multiple line segments).  The coordinate arrays XDATA and YDATA must
%   match in size and have identical NaN locations.
%
%   Examples
%   --------
%   isShapeMultipart([0 0 1],[0 1 0]) % False
%   isShapeMultipart([0 0 1 NaN 2 2 3 3],[0 1 0 NaN 2 3 3 2]) % True
%
%   load coast
%   isShapeMultipart(lat, long) % True
%
%   S = shaperead('concord_hydro_area');
%   isShapeMultipart( S(1).X,  S(1).Y) % False
%   isShapeMultipart(S(14).X, S(14).Y) % True
%
%   See also POLYSPLIT.

% Copyright 2005-2011 The MathWorks, Inc.

% Verify that xdata and ydata have the same size with NaNs in the same
% positions.
if ~isequal(isnan(xdata), isnan(ydata))
    error('map:isShapeMultipart:inconsistentXY', ...
        'XDATA and YDATA are mismatch in size or NaN locations.')
end

% Construct a column vector consisting of 1s and -1s.  Each NaN in xdata
% contributes an element to the vector.
nanPatterns = diff(~isnan(xdata(:)));
nanPatterns(nanPatterns == 0) = [];

% There are precisely four values of nanPatterns that correspond to a
% single-part shape: empty (e.g., [1 2 3 4 5] and the following three:
leadingNan = 1;                     % e.g., [NaN 1 2 3 4 ...]'
trailingNan = -1;                   % e.g., [1 2 3 4 NaN ...]'
leadingAndTrailingNans = [1; -1];   % e.g., [Nan 1 2 3 4 NaN ...]'

% We have a single-part shape if and only if nanPatterns is empty or equals
% one of the three special patterns identified above.
isSinglePartOrEmpty = isempty(nanPatterns) ...
    || isequal(nanPatterns,leadingNan) ...
    || isequal(nanPatterns,trailingNan) ...
    || isequal(nanPatterns,leadingAndTrailingNans);

% If the feature is not single-part (or empty), then it must multipart.
tf = ~isSinglePartOrEmpty;
