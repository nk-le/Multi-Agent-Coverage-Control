function R = parseRasterDirection(R, varargin)
% Parse and validate name-value inputs for the following spatial
% referencing properties: ColumnsStartFrom and RowsStartFrom.

% Copyright 2015 The MathWorks, Inc.

    validPropertyNames = {'ColumnsStartFrom','RowsStartFrom'};
    try
        for k = 1:2:length(varargin)
            name = validatestring(varargin{k}, validPropertyNames, '', 'Name');
            value = varargin{k+1};
            if strcmp(name, 'ColumnsStartFrom')
                R.ColumnsStartFrom = validatestring(value,{'north','south'},'','Value');
            else
                R.RowsStartFrom = validatestring(value,{'west','east'},'','Value');
            end
        end
    catch e
        throwAsCaller(e)
    end
end
