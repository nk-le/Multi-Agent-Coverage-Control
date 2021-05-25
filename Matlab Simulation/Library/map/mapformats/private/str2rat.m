function [num, den] = str2rat(str)
%STR2RAT String to rational
%
%   In certain cases, convert a string to a double precision rational
%   number (returning the numerator and denominator as separate outputs),
%   such that the denominator equals 2^m * 3^n * 5^p for non-negative
%   integers m, n, and p. In other words, the largest prime factor of den
%   is no greater than 5.
%
%   The cases supported correspond to some typical cell extents, sample
%   spacings, and geographic limits of spatially-referenced raster grids.
%
%   The default behavior is to return num = str2double(x), even for
%   non-integer valued x, and den = 1. This is always the behavior when the
%   input is in exponential rather than fixed point notation.
%
%   In three special cases, both num and den are integer-valued and, as
%   noted above, den is the product of powers of 2, 3, and 5.
%
%   Case 1: The string ends in a single digit repeated at least 4 times,
%   for digits 1 through 4. The same holds for digits 5-8, except that the
%   last digit exceeds the preceding digits by 1 (e.g., 5556). Note: the
%   case of 9999 is handled naturally by case 3.)
%
%   Case 2: There are at least 8 significant digits after the decimal point
%   and, using 10^(numberOfDigitsAfterTheDecimalPoint) as a tolerance, rat
%   returns a denominator which is the product of powers of 2, 3, and 5.
%
%   Case 3: There is a rational equivalent to x (such that num/den ==
%   str2double(str)) exactly) in which den is the product of powers of 2,
%   3, and 5.
%
%   Examples
%   --------
%   % Case 1
%   str = '41.9983333';
%   [n,d] = str2rat(str)    % Returns 25199, 600
%   format long g
%   n/d                     % Displays: 41.9983333333333
%   n/d - str2double(str)   % Returns: 3.33333360913457e-08
%
%   % Case 2
%   str = '.000030864197531';               % 15 digits
%   [n,d] = str2rat(str)                    % Returns 1, 32400
%   abs((n/d) - str2double(str)) < 10^-15   % Returns true
%
%   % Case 3
%   str = '-0.4';
%   [n,d] = str2rat(str)    % Returns -2, 5
%   n/d == str2double(str)  % Returns true
%
%   See also RAT, STR2DOUBLE

% Copyright 2015 The MathWorks, Inc.

    persistent patterns
    patterns = {'1111','2222','3333','4444','5556','6667','7778','8889'};
    
    x = str2double(str);
    num = x;
    den = 1;
    
    % At this point, the outputs have nominal values. In many cases (such
    % as when str is a truncated decimal approximation to pi), these are
    % the values that will be returned. But in the three special cases
    % described in the help, we may be able to improve on this result.
    str = deblank(str);
    if ~any(isletter(str))
        parts = strsplit(str, '.');
        hasDecimalPoint = (length(parts) == 2);
        if hasDecimalPoint
            fractionalPart = parts{2};
            nonzeroPlaces = find(fractionalPart ~= '0');
            if any(nonzeroPlaces)
                numPlaces = length(fractionalPart);
                if numPlaces >= 4 && any(strcmp(fractionalPart(end-3:end), patterns))
                    % Case 1
                    tol = 10^-numPlaces;
                    [n, d] = rat(x,tol);
                    f = factor(d);
                    if all(f <= 5)
                        % Examplar: str = '41.9983333'
                        num = n;
                        den = d;
                    end
                else
                    numSignificant = numPlaces - nonzeroPlaces(1) + 1;
                    if numSignificant >= 8
                        % Case 2
                        tol = 10^-numPlaces;
                        [n, d] = rat(x,tol);
                        f = factor(d);
                        if all(f <= 5)
                            % Exemplar: str = '.000030864197531'
                            num = n;
                            den = d;
                        end
                    else
                        % Case 3
                        tol = eps(x);
                        [n, d] = rat(x,tol);
                        if (n/d) == x
                            f = factor(d);
                            if all(f <= 5)
                                % Exemplars:
                                %   str = -0.4;
                                %   str =  0.9999;
                                num = n;
                                den = d;
                            end
                        end
                    end
                end
            end
        end
    end
end
