function [x, y] = vectorsFromGPC(p)
% Convert a structure array of the sort returned from gpcmex to a pair of
% NaN-separated coordinate vectors representing a multipart polygon.

% Copyright 2009 The MathWorks, Inc.

if isempty(p)
    x = [];
    y = [];
else
    % Determine the indices at which the parts will start and end in the
    % output vectors.
    numberOfVerticesPerPart = arrayfun(@(s) numel(s.x), p);
    
    first = cumsum(1 + [0; numberOfVerticesPerPart(1:end-1)]);
    last  = cumsum( ...
        [numberOfVerticesPerPart(1); 1 + numberOfVerticesPerPart(2:end)]);
    
    % Initialize the outputs as column vectors fill with NaN. After the
    % vertex coordinates are assigned, the remaining NaNs will serve to
    % separate the parts. Terminating NaNs are not provided.
    x = NaN(last(end),1);
    y = NaN(last(end),1);
    
    % Copy the vertex coordinates into the output vectors for all parts.
    for k = 1:numel(p)
        x(first(k):last(k)) = p(k).x;
        y(first(k):last(k)) = p(k).y;
    end
    
    % Set the vertex direction around holes to be counter-clockwise. (This
    % could be performed in the preceding loop, but that would entail
    % multiple calls to ispolycw. If we had a lightweight "isringcw"
    % function, however, then we might best call that within the loop.)
    reverseVertices = find(~xor(ispolycw(x,y), [p.ishole]'));
    for t = 1:numel(reverseVertices)
        k = reverseVertices(t);
        x(first(k):last(k)) = p(k).x(end:-1:1);
        y(first(k):last(k)) = p(k).y(end:-1:1);
    end
end
