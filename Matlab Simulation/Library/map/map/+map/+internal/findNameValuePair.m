function [value, remargs] = findNameValuePair(name, default, varargin)
%FINDNAMEVALUEPAIR Find name-value pair and return non-matching pairs
%
%   [VALUE, REMARGS] = findNameValuePair(NAME, DEFAULT, Name, Value)
%   returns the value of the last name-value pair in the input whose name
%   matches the string NAME. If there is no match, VALUE equals DEFAULT.
%   REMARGS is a cell vector containing all non-matching input pairs.
%   Partial strings are matched (meaning that a Name string in a name-value
%   pair could be a truncated version of the first input, NAME), and
%   matching is case-insensitive. The number of inputs is assumed to be
%   even. (If the last value is missing, no error is thrown. Instead, the
%   last Name is skipped and it ends up in the remaining arguments list.)
%   If necessary, you can use internal.map.CheckNameValuePairs to
%   pre-validate that there are an even number of name-value inputs and
%   that the first element in each pair is a string.

% Copyright 2009-2017 The MathWorks, Inc.

    value = default;
    remargs = varargin;
    if ~isempty(varargin)
        [varargin{:}] = convertStringsToChars(varargin{:});
        deleteIndex = false(size(varargin));
        % Ignore the last Name if the length of the name-value list is odd.
        n = 2*floor(numel(varargin)/2);
        for k = 1:2:n
            if strncmpi(name, varargin{k}, numel(varargin{k}))
                % Found a match. Copy the value, overwriting any earlier
                % values, and flag the pair for removal from REMARGS.
                value = varargin{k+1};
                deleteIndex(k:k+1) = true;
            end
        end    
        remargs(deleteIndex)=[];
    end
end
