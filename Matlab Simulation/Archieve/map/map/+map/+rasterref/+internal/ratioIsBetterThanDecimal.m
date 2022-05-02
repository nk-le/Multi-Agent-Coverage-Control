function tf = ratioIsBetterThanDecimal(N,D)
%ratioIsBetterThanDecimal True if rational form is easier to comprehend
%
%   tf = ratioIsBetterThanDecimal(N,D) returns true if the fraction N/D
%   is likely to be more comprehensible when displayed as a ratio
%   than when displayed in decimal form. Assuming real, integer-valued
%   N and D, and positive D, true is returned when:
%
%     abs(N) = 1 and D >= 2
%     abs(N) = 2 and D = 3 or 5
%     abs(N) = 3 and D = 2, 4, 5, 8, 10, 16, 32, or 64
%     abs(N) = 4 and D = 3 or 5
%     abs(N) = 5 and D = 2, 3, 4, 6, 8, 12, or 16
%
% Example
% -------
% % Check results for selected ratios with N between 1 and 100 and D
% % between 1 and 1200. Skip N/D pairs that are not in reduced form.
% D = unique([(1:12),[16 18 24 25 32 36 64 72], (10:5:100), ...
%             10*[16 18 24 25 32 36 64 72],150,500,999,1000,1200]);
% N = 1:100;
% N = unique([1:20, N(isprime(N)) 100]);
% 
% fprintf('Displayed as ratio:\n\n')
% for k = 1:numel(N)
%     for j = 1:numel(D)
%         num = N(k);
%         den = D(j);
%         if (gcd(num,den) == 1);
%             if map.rasterref.internal.ratioIsBetterThanDecimal(num,den)
%                 fprintf('%d/%d\n\n', num, den)
%             end
%         end
%     end
% end
%
% fprintf('\nDisplayed as decimal value:\n\n')
% for k = 1:numel(N)
%     for j = 1:numel(D)
%         num = N(k);
%         den = D(j);
%         if (gcd(num,den) == 1)
%             if ~map.rasterref.internal.ratioIsBetterThanDecimal(num,den)
%                 str = evalc('builtin(''disp'', num/den)');
%                 fprintf('%d/%d shown as: %s\n', ...
%                      num, den, str)
%             end
%         end
%     end
% end

% Copyright 2013 The MathWorks, Inc.

% The sign of N doesn't matter, but the implementation is easier if it's
% nonnegative.
N = abs(N);

% This should be positive already, but just to be sure.
D = abs(D);

if isIntegerValued(N) && isIntegerValued(D) && ~isIntegerValued(N/D)
    % At this point, we know that N and D are finite integers, so GCD will
    % succeed, and N/D is non-integer, so there's work to do. Start by
    % ensuring reduced form.
    g = gcd(N,D);
    N = N/g;
    D = D/g;
    switch(N)
        case 1
            tf = (D >= 2);
        case 2
            tf = any(D == [3, 5]);
        case 3
            tf = any(D == [2, 4, 5, 8, 10, 16, 32, 64]);
        case 4
            tf = any(D == [3, 5]);
        case 5
            tf = any(D == [2, 3, 4, 6, 8, 12, 16]);
        otherwise
            tf = false;
    end
else
    tf = false;
end

%--------------------------------------------------------------------------

function tf = isIntegerValued(x)
% Returns true if and only if X is integer-valued. X can have any numeric
% class, but would typically be double or single. Not to be confused with
% the MATLAB function ISINTEGER.
tf = isfinite(x) & (x == round(x));
