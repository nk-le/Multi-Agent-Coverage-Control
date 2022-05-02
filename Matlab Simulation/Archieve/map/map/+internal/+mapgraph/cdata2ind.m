function index = cdata2ind(v,n)
%cdata2ind Map vector of strictly increasing values to index
%
%   index = cdata2ind(cdata,n) performs a linear or quasi-linear mapping
%   from a strictly increasing vector of real, finite values to a vector of
%   indices between 1 and n.  Typically, cdata represents a color data
%   vector that needs to be mapped to a colormap of length n.  If cmap is
%   such a colormap, then one could write:
%
%      n = size(cmap,1);
%      index = cdata2ind(cdata,n);
%      colors = cmap(index,:);
%
%   Example
%   -------
%   n = 40;
%   cdata = [-500.7 -300 1 2 3.3 4 5.24 25 30 100 200 500];
%   index = cdata2ind(cdata,n);
%   figure; plot(cdata, index, '-b+')
%   xlabel('cdata')
%   ylabel('index')
%   title(['Quasi-linear mapping of ' num2str(length(cdata)) ...
%         ' irregularly-spaced cdata to indices between 1 and ' ...
%         num2str(n)])
%
%   Input Arguments
%   ---------------
%   cdata -- Color data, specified as a strictly increasing vector of real,
%            finite values
%
%   n -- Number of available indices, specified as a non-zero scalar integer
%
%   Output Argument
%   ---------------
%   index -- Indices, returned as a column vector of integer values from 1
%            to n, increasing monotonically, containing one element for
%            each element in cdata
%
%   Specific Behavior
%   -----------------
%   If there are exactly enough indices (colors) to go around, such that
%   length(cdata) == n, then index = (1:n)';
%
%   If there's a shortage, such that length(cdata) > n, then index = 
%   [1, 1, ..., 1, 2, 3, ..., (n-1), n, n, ...n]', with the number of
%   repetitions of 1 and n being equal if the shortage (numel(cdata) - n)
%   is even, and with an extra leading 1 if the shortage is odd.
%
%   If there's an abundance of indices, such that length(cdata) < n, then
%   index = [1 ... n]' is strictly increasing (no repeated values) and the
%   intermediate values are selected to make the relationship between index
%   and cdata as linear as possible -- without allowing repeated indices.
%
%   In practice, if n is much larger than length(cdata), then the
%   relationship is nearly linear. If n is not much larger than
%   length(cdata), the relationship is still nearly linear, as long as the
%   elements of cdata are spaced fairly evenly. But if n is not much larger
%   than length(cdata) and the elements of cdata are spaced unevenly, then
%   the slope of the index vs. cdata curve will be larger than average in
%   between the closely-spaced elements of cdata. (See the plot generated
%   by the example.)

% Copyright 2013 The MathWorks, Inc.

m = numel(v);
if n == 0
    index = [];
elseif n == 1
    index = ones(m,1);
elseif n < m
    % There are not enough indices available to assign a unique index to
    % each level. Distribute what's available to the middle set of levels.
    % If the length of the shortage (m - n) is even, set the index to 1 to the
    % first (n - m)/2 levels and to n to the last (n - m)/2 colors.
    % Otherwise, set the index to 1 to the first (n - m + 1)/2 levels and
    % allocate n to the last (n - m - 1)/2 levels.
    index = ones(m,1);
    shortageIsEven = mod(m - n,2) == 0;
    if shortageIsEven
        h = (m - n) / 2;
        a = 1 + h;
        b = m - h;
    else
        h = (m - n + 1)/2;
        a = 1 + h;
        b = m - h + 1;
    end
    index(a:b) = (1:n);
    index(b:end) = n;
elseif m == n
    % There is exactly one index per cdata value.
    index = (1:n)';
else
    % The are enough indices to map each element of cdata to a unique index
    % in the interval [1 n], and some of values in 1,2,...,n will be left
    % unused. Define a mapping that makes the relationship as linear as
    % possible (some quantization is usually unavoidable), while ensuring
    % that each index value is unique -- index is a strictly increasing
    % vector of integers in [1 n].
    
    index = quasilinearIndex(v,1,n);
end

%--------------------------------------------------------------------------

function index = quasilinearIndex(v,n1,n2)

% Note: All values in index have to be unique. Therefore n1 must not equal
% n2 except possibly when numel(v) equals 0 or 1 -- the first two cases
% below.

m = numel(v);
switch(m)
    case 0
        index = zeros(0,1);
        
    case 1
        index = round((n1 + n2)/2);
        
    case 2
        % Safe to assume n2 > n1
        index = [n1; n2];
        
    otherwise
        % Safe to assume n2 > n1
        
        % Extrema
        vmin = min(v);
        vmax = max(v);
        
        % Linear approach (with rounding)
        index = n1 + round((n2 - n1) * (v(:) - vmin) / (vmax - vmin));
        
        repeatedIndices = ~isequal(unique(index,'stable'),index);
        if repeatedIndices
            % Use quasilinear approach
            
            % Indices of central value
            c = ceil(m/2);
            ic = n1 + round((n2 - n1) * ((v(c) - vmin) / (vmax - vmin)));
            
            if (ic - n1) < (c - 1)
                % Avoid repeating values in index(1:c):
                %   Recurse without the first element of v.
                index(2:end,1) = quasilinearIndex(v(2:end), n1 + 1, n2);
            elseif (n2 - ic) < (m - c)
                % Avoid repeating values in index(c:end):
                %   Recurse without the last element of v.
                index(1:end-1,1) = quasilinearIndex(v(1:end-1), n1, n2 - 1);
            else
                % There are enough index values available both before
                % and after index(c):
                %    Fix index(c) = ic, and recurse on both parts.
                index(1:c,1)   = quasilinearIndex(v(1:c),   n1, ic);
                index(c:end,1) = quasilinearIndex(v(c:end), ic, n2);
            end
        end
end
