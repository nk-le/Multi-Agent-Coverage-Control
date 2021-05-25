function s = replaceValueWithRatio(s, propname, numerator, denominator) %#ok<INUSD>
%replaceValueWithRatio Insert rational number into string
%
%   Within the string S, replace the value that follows the string
%   PROPNAME with the ratio: NUMERATOR / DENOMINATOR.

% Copyright 2010-2012 The MathWorks, Inc.

% Strategy: Identify two key index values relative to S:
%   k  -- Index at which PROPNAME starts
%   k2 -- Index of the return/newline character most closely following k
% If both are found, replace the text between the colon following
% PROPNAME and the return/newline following propname with a string
% containing the ratio NUMERATOR / DENOMINATOR. Use the evalc-disp
% expressions so in order to adapt automatically to whatever format
% setting is in effect.

numstr = evalc('builtin(''disp'',numerator)');
denstr = evalc('builtin(''disp'',denominator)');
numstr(isspace(numstr))= [];
denstr(isspace(denstr))= [];
k = strfind(s,propname);
if ~isempty(k)
    k = k(1) + numel(propname);
    k2 = find(isstrprop(s,'cntrl'));
    k2(k2 < k) = [];
    if ~isempty(k2)
        k2 = k2(1);
        s = [s(1:k+1) numstr '/' denstr s(k2:end)];
    end        
end
