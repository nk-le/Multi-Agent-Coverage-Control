function tf = isExtraNan(x, allowTerminatingNan)
%isExtraNan Identify extraneous NaN separators and terminators
%
%   TF = isExtraNan(X, allowTerminatingNan) returns a logical vector
%   indicating the locations of extraneous NaN values in the input vector X.
%
%   Inputs
%   ------
%   X --  Vector of class double or single, typically containing multiple,
%         NaN-separated parts and/or leading and trailing NaN values.
%
%   allowTerminatingNan -- Scalar logical. When false, all NaN values
%         following the last non-NaN in X are regarded as extraneous, and
%         TF(end) equals isnan(x(end)). When true, the final element in X
%         is considered essential, whether NaN-valued or not, and TF(end)
%         is always false.
%
%   Outputs
%   -------
%   TF -- Logical vector matching X in size. True for NaN-valued element of
%         X that is extra. False otherwise.
%
%   Examples
%   --------
%   % Remove all extraneous NaNs from x, including the terminating NaN
%   x = [NaN NaN 1:3 NaN 4:5 NaN NaN NaN 6:9 NaN NaN];
%   extra = map.internal.isExtraNan(x,false)
%   x(extra) = []
%
%   % Remove all extraneous NaNs from x, except for the terminating NaN
%   x = [NaN NaN 1:3 NaN 4:5 NaN NaN NaN 6:9 NaN NaN];
%   extra = map.internal.isExtraNan(x,true)
%   x(extra) = []

% Copyright 2012 The MathWorks, Inc.

% Logical vector indicating NaN-valued elements of x.
n = isnan(x);
if any(n)
    % Logical vector indicating elements of x followed by NaN.
    followedByNan = false(size(n));
    followedByNan(1:end-1) = n(2:end);
    
    % Preliminary output: A NaN followed by another NaN is always extraneous.
    tf = n & followedByNan;
    
    % Refine output: All leading NaNs are extraneous, even the first one.
    k = find(~n,1);
    tf(1:(k-1)) = true;
    
    % Refine output: The last element of x can be extraneous only if
    % terminating NaNs are not allowed.
    tf(end) = n(end) && ~allowTerminatingNan;
else
    % All elements of x are non-NaN.
    tf = false(size(x));
end
