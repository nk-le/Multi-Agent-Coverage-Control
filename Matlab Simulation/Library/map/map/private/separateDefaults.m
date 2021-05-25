function [defaultProps, otherProps] = separateDefaults(props)
%SEPARATEDEFAULTS Separate default parameter/value pairs
%
%   [DEFAULTPROPS, OTHERPROPS] = SEPARATEDEFAULTS(PROPS) separates the HG
%   parameter-value pairs in the cell array PROPS by testing if the
%   elements have the prefix 'Default' in their property names. If true,
%   remove the prefix and return the resulting pairs in the defaultProps
%   array. Return any pairs without the 'Default' prefix in the otherProps
%   array. This function is case-insensitive.

% Copyright 2006 The MathWorks, Inc.

% Number of characters in 'default'
n = numel('default');

% Split pairs into two separate arrays
isDefault = false(1,numel(props));
for k = 1:2:numel(props)
   isDefault(k:(k+1)) = strncmpi('default',props{k},n);
end
defaultProps = props( isDefault(:));
otherProps   = props(~isDefault(:));

% Strip prefix 'Default' from property names in the defaultProps array
for k = 1:2:numel(defaultProps)
   defaultProps{k}(1:n) = [];
end
