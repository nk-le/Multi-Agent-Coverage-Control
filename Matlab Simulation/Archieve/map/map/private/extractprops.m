function props = extractprops(properties,k)
%EXTRACTPROPS Graphics property-value pairs for individual feature
%
%   PROPS = EXTRACTPROPS(PROPERTIES,K) returns a cell array containing the
%   graphics properties, in the form of name-value pairs, for the K-th
%   feature as specified in a PROPERTIES structure that was created with
%   ATTRIBUTES2PROPERTIES.  The help for ATTRIBUTES2PROPERTIES includes an
%   example.
%
%   PROPS has size 1-by-(2*P) where 0 <= P <= M and M is the number of
%   properties of the K-th feature specified in PROPERTIES.  Depending
%   on the specific features and symbolspec used to create PROPERTIES, M
%   can range from zero up to the number of columns in PROPERTIES.Names
%   and PROPERTIES.Values.  That is, unless the symbolspec explicitly
%   controls a given property of a given feature, that property does not
%   appear in PROPS; default values needed just to keep
%   PROPERTIES.Values rectangular are omitted.
%
%   See also ATTRIBUTES2PROPERTIES.

% Copyright 2006 The MathWorks, Inc.

nonNull = ~cellfun(@isempty,properties.Values(k,:));
props = [...
    properties.Names( 1,nonNull); ...
    properties.Values(k,nonNull)];
props = reshape(props,[1 numel(props)]);
