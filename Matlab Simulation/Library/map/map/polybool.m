function [x3, y3] = polybool(operation, x1, y1, x2, y2, varargin)
%POLYBOOL  Set operations on polygonal regions
%
%   POLYBOOL is not recommended. Use polyshape instead.
%
%   [x,y] = POLYBOOL(FLAG,x1,y1,x2,y2) performs the set operation
%   identified by FLAG on the polygons with vertices specified
%   by x1, y1 and x2, y2.  FLAG may be any of the following strings:
%   
%     Region intersection: 'intersection' 'and'   '&'
%     Region union:        'union'        'or'    '|'  '+'  'plus'
%     Region subtraction:  'subtraction'  'minus' '-'
%     Region exclusive or: 'exclusiveor'  'xor'
%   
%   The polygon inputs are NaN-delimited vectors, or cell arrays containing
%   individual polygonal contours.  The result is returned using the same
%   form as the input.
%
%   Most Mapping Toolbox functions adhere to the convention that individual
%   contours with clockwise-ordered vertices are external contours and
%   individual contours with counterclockwise-ordered vertices are internal
%   contours. Although the POLYBOOL function ignores vertex order, you
%   should follow the convention when creating contours to ensure
%   consistency with other functions.
%
%   Use FLATEARTHPOLY to prepare polygons that encompass a pole for POLYBOOL.
%
%   Example 1
%   ---------
%   Operations on two overlapping circular regions.
%
%       theta = linspace(0, 2*pi, 100);
%       x1 = cos(theta) - 0.5;
%       y1 = -sin(theta);    % -sin(theta) to make a clockwise contour
%       x2 = x1 + 1;
%       y2 = y1;
%       [xa, ya] = polybool('union', x1, y1, x2, y2);
%       [xb, yb] = polybool('intersection', x1, y1, x2, y2);
%       [xc, yc] = polybool('xor', x1, y1, x2, y2);
%       [xd, yd] = polybool('subtraction', x1, y1, x2, y2);
%
%       subplot(2, 2, 1)
%       patch(xa, ya, 1, 'FaceColor', 'r')
%       axis equal, axis off, hold on
%       plot(x1, y1, x2, y2, 'Color', 'k')
%       title('Union')
%
%       subplot(2, 2, 2)
%       patch(xb, yb, 1, 'FaceColor', 'r')
%       axis equal, axis off, hold on
%       plot(x1, y1, x2, y2, 'Color', 'k')
%       title('Intersection')
%
%       subplot(2, 2, 3)
%       % The output of the exclusive-or operation consists of disjoint
%       % regions.  It can be plotted as a single patch object using the
%       % face-vertex form.  Use poly2fv to convert a polygonal region
%       % to face-vertex form.
%       [f, v] = poly2fv(xc, yc);
%       patch('Faces', f, 'Vertices', v, 'FaceColor', 'r', 'EdgeColor', 'none')
%       axis equal, axis off, hold on
%       plot(x1, y1, x2, y2, 'Color', 'k')
%       title('Exclusive Or')
%
%       subplot(2, 2, 4)
%       patch(xd, yd, 1, 'FaceColor', 'r')
%       axis equal, axis off, hold on
%       plot(x1, y1, x2, y2, 'Color', 'k')
%       title('Subtraction')
%
%   Example 2
%   ---------
%   Operations on regions with holes.
%
%       Ax = {[1 1 6 6 1], [2 5 5 2 2], [2 5 5 2 2]};
%       Ay = {[1 6 6 1 1], [2 2 3 3 2], [4 4 5 5 4]};
%       subplot(2, 3, 1)
%       [f, v] = poly2fv(Ax, Ay);
%       patch('Faces', f, 'Vertices', v, 'FaceColor', 'r', 'EdgeColor', 'none')
%       axis equal, axis off, axis([0 7 0 7]), hold on
%       for k = 1:numel(Ax), plot(Ax{k}, Ay{k}, 'Color', 'k'), end
%       title('A')
%
%       Bx = {[0 0 7 7 0], [1 3 3 1 1], [4 6 6 4 4]};
%       By = {[0 7 7 0 0], [1 1 6 6 1], [1 1 6 6 1]};
%       subplot(2, 3, 4);
%       [f, v] = poly2fv(Bx, By);
%       patch('Faces', f, 'Vertices', v, 'FaceColor', 'r', 'EdgeColor', 'none')
%       axis equal, axis off, axis([0 7 0 7]), hold on
%       for k = 1:numel(Bx), plot(Bx{k}, By{k}, 'Color', 'k'), end
%       title('B')
%
%       subplot(2, 3, 2)
%       [Cx, Cy] = polybool('union', Ax, Ay, Bx, By);
%       [f, v] = poly2fv(Cx, Cy);
%       patch('Faces', f, 'Vertices', v, 'FaceColor', 'r', 'EdgeColor', 'none')
%       axis equal, axis off, axis([0 7 0 7]), hold on
%       for k = 1:numel(Cx), plot(Cx{k}, Cy{k}, 'Color', 'k'), end
%       title('A \cup B')
%
%       subplot(2, 3, 3)
%       [Dx, Dy] = polybool('intersection', Ax, Ay, Bx, By);
%       [f, v] = poly2fv(Dx, Dy);
%       patch('Faces', f, 'Vertices', v, 'FaceColor', 'r', 'EdgeColor', 'none')
%       axis equal, axis off, axis([0 7 0 7]), hold on
%       for k = 1:numel(Dx), plot(Dx{k}, Dy{k}, 'Color', 'k'), end
%       title('A \cap B')
%
%       subplot(2, 3, 5)
%       [Ex, Ey] = polybool('subtraction', Ax, Ay, Bx, By);
%       [f, v] = poly2fv(Ex, Ey);
%       patch('Faces', f, 'Vertices', v, 'FaceColor', 'r', 'EdgeColor', 'none')
%       axis equal, axis off, axis([0 7 0 7]), hold on
%       for k = 1:numel(Ex), plot(Ex{k}, Ey{k}, 'Color', 'k'), end
%       title('A - B')
%
%       subplot(2, 3, 6)
%       [Fx, Fy] = polybool('xor', Ax, Ay, Bx, By);
%       [f, v] = poly2fv(Fx, Fy);
%       patch('Faces', f, 'Vertices', v, 'FaceColor', 'r', 'EdgeColor', 'none')
%       axis equal, axis off, axis([0 7 0 7]), hold on
%       for k = 1:numel(Fx), plot(Fx{k}, Fy{k}, 'Color', 'k'), end
%       title('XOR(A, B)')
%
%   See also BUFFERM, FLATEARTHPOLY, ISPOLYCW, POLY2CW, POLY2CCW,
%            POLY2FV, POLYJOIN, POLYSPLIT, POLYSHAPE

% Copyright 1999-2017 The MathWorks, Inc.

if (nargin >= 6)
    % Check for obsolete 'cutvector', 'cell', and 'vector' options.
    errorOnObsoleteSyntax(varargin{1})
end

operation = validateSetOperationName(operation);

cellInput = iscell(x1) || iscell(y1) || iscell(x2) || iscell(y2);
if ~any(cellInput)
    [x3, y3] = polygonSetOperation(operation, x1, y1, x2, y2);
else
    [x3, y3] = polygonSetOperationCells(operation, x1, y1, x2, y2);
end

%-----------------------------------------------------------------

function [x3, y3] = polygonSetOperation(operation, x1, y1, x2, y2)
% Apply polygon set operations in the case where x1, y1, x2, and y2 are
% numerical vectors, possibly containing NaN-separators to distinguish
% between different parts within multipart polygons. The inputs may be
% either row vectors or column vectors. x3 and y3 will be column vectors
% unless x1 is a row vector.

operation = validatestring(operation, {'int','union','xor','diff'});

checkxy(x1, y1, mfilename, 'X1', 'Y1', 2, 3)
checkxy(x2, y2, mfilename, 'X2', 'Y2', 2, 3)

[x3, y3, emptyInput] = handleEmptyInputs(operation, x1, y1, x2, y2);
if ~emptyInput
    p1 = vectorsToGPC(x1, y1, mfilename, 'X1', 'Y1');
    p2 = vectorsToGPC(x2, y2, mfilename, 'X2', 'Y2');
    
    p3 = gpcmex(operation, p1, p2);
    
    [x3, y3] = vectorsFromGPC(p3);
    
    rowVectorInput = (size(x1,2) > 1);
    if ~isempty(x3) && rowVectorInput
        x3 = x3';
        y3 = y3';
    end
end

%-----------------------------------------------------------------

function [x3, y3] = polygonSetOperationCells(operation, x1, y1, x2, y2)
% Apply polygon set operations in the case where x1 and y1 are cell
% vectors, x2 and y2 are cell vectors, or all four sets of vertex
% coordinates are represented as cell vectors.
    
if iscell(x1)
    rowVectors = ~isempty(x1) && (ismatrix(x1{1})) && (size(x1{1}, 1) == 1);
    rowCellVectors = (ismatrix(x1)) && (size(x1, 1) == 1);
    
    assertNonNan(x1)
    assertNonNan(y1)
    [x1, y1] = polyjoin(x1, y1);
else
    rowVectors = (ismatrix(x1)) && (size(x1, 1) == 1);
    rowCellVectors = false;
    x1 = x1(:);
    y1 = y1(:);
end

if iscell(x2)
    assertNonNan(x2)
    assertNonNan(y2)
    [x2, y2] = polyjoin(x2, y2);
end

[x3, y3] = polygonSetOperation(operation, x1, y1, x2, y2);

if rowVectors
    x3 = x3';
    y3 = y3';
end

[x3, y3] = polysplit(x3,y3);

if rowCellVectors
    x3 = x3';
    y3 = y3';
end

%-----------------------------------------------------------------------

function operation = validateSetOperationName(operation)
% If possible, convert the string OPERATION to a standard set operation
% string accepted by gpcmex: 'int', 'union', 'xor', or 'diff'. The result
% is case-insensitive with respect to the input string.

if nargin > 0
    operation = convertStringsToChars(operation);
end

if ~ischar(operation)
    error(['map:' mfilename ':invalidOpFlag'], ...
        ['Function %s expected its first argument to be a string', ...
        ' specifying a polygon set operation.'], mfilename)
end

valid    = 1; % Put valid strings in column 1 of cell array "strings"
standard = 2; % Put standard strings in column 2

strings = {...
    'intersection', 'int'; ...
    'and',          'int'; ...
    '&',            'int'; ...
    'union',        'union'; ...
    'or',           'union'; ...
    '|',            'union'; ...
    '+',            'union'; ...
    'plus',         'union'; ...
    'exclusiveor',  'xor'; ...
    'xor',          'xor'; ...
    'subtraction',  'diff'; ...
    'minus',        'diff'; ...
    '-',            'diff'};

% Try to find a match in column 1.
match = strcmpi(operation, strings(:,valid));
if ~any(match)
   error(['map:' mfilename ':unrecognizedOp'], ...
         'Unrecognized set operation: ''%s''.', operation)
end

% If a match is found, return the value in column 2.
operation = strings{match, standard};

%-----------------------------------------------------------------------

function assertNonNan(c)
% Error if any element of the cell array C contains a NaN

assert(~any(cellfun(@(v) any(isnan(v(:))), c)), ...
    ['map:' mfilename ':cellNaNCombo'], ...
    ['%s no longer supports combining the cell array', ...
    ' and NaN-separated vector format.  Use %s if', ...
    ' necessary to create a cell array in which each cell', ...
    ' contains the coordinates for a single polygonal contour.'], ...            
    'POLYBOOL', 'POLYSPLIT')

%-----------------------------------------------------------------------

function [x3, y3, emptyInput] = handleEmptyInputs(operation, x1, y1, x2, y2)
% Assuming that x1 and y1, and x2 and y2, are pairs of inputs having
% consistent sizes, return the appropriate values for x3 and y3 in the
% event that x1 and/or x2 are empty (or contain only NaN), and set
% emptyInput to true. Otherwise, set x3 and y3 to empty and set
% emptyInput to false. Operation has been validated and equals one of
% the following strings: 'int','union','xor','diff'.

% NaN-only arrays should behave the same way as empty arrays, so filter
% them up-front. Be careful, because all(isnan([])) evaluates to true.
% Also, be careful to preserve shape: return 1-by-0 given a row
% vector of NaN and a 0-by-1 given a column vector of NaN.
if  all(isnan(x1)) && ~isempty(x1)
    x1(1:end) = [];
    y1(1:end) = [];
end

if all(isnan(x2)) && ~isempty(x2)
    x2(1:end) = [];
    y2(1:end) = [];
end

if isempty(x2)
    if strcmp(operation,'int')
        % Intersection is empty, but preserve shape
        % by using x2 and y2 rather than [].
        x3 = x2;
        y3 = y2;
    else
        % Union, exclusive or, or difference with
        % empty leaves x1 and y1 unaltered.
        x3 = x1;
        y3 = y1;
    end
    emptyInput = true;
elseif isempty(x1)
    if any(strcmp(operation,{'int','diff'}))
        % Intersection or difference is empty, but preserve
        % shape by using x1 and y1 rather than [].
        x3 = x1;
        y3 = y1;        
    else
        % Union or exclusive or with empty leaves x2 and y2 unaltered.
        x3 = x2;
        y3 = y2;
    end
    emptyInput = true;
else
    x3 = [];
    y3 = [];
    emptyInput = false;
end

%-----------------------------------------------------------------------

function errorOnObsoleteSyntax(arg6)

if isequal(arg6, 'cutvector')
    error(['map:' mfilename ':cutVectorSyntax'], ...
        ['Because the ''%s'' option does not handle some types of polygonal', ...
        ' regions well, it is no longer supported.  See the %s documentation', ...
        ' for examples illustrating how to use %s and %s to plot polygonal', ...
        ' regions with holes and disjoint regions.'], ...
        'cutvector', 'POLYBOOL', 'POLY2FV', 'PATCH')
elseif (isequal(arg6, 'cell') || isequal(arg6, 'vector'))
    error(['map:' mfilename ':oldSyntax'], ...
        ['%s no longer supports the ''%s'' or ''%s'' options.', ...
        ' Instead, %s returns the outputs in the same format as the', ...
        ' inputs.  Use %s and %s to convert between cell and', ...
        ' vector format for polygons.'], ...
        'POLYBOOL', 'cell', 'vector', 'POLYBOOL', 'POLYSPLIT', 'POLYSPLIT')
else
    error(['map:' mfilename ':wrongNumArgs'], ...
        'Incorrect number of input arguments.')
end
