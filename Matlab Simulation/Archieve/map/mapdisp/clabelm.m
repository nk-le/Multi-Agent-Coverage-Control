function hText = clabelm(c, varargin)
%CLABELM Add contour labels to map contour display
%
%  CLABELM(C,H) adds value labels to the current map contour plot.  The
%  labels are rotated and inserted within the contour lines.  C and H are
%  the contour matrix and object handle outputs from CONTOURM or CONTOUR3M.
%
%  CLABELM(C,H,V) labels just those contour levels given in the vector V.
%  The default action is to label all known contours. The label positions
%  are selected randomly.
%
%  CLABELM(C,H,'manual') places contour labels at the locations determined
%  by a mouse click.  Pressing the return key terminates labeling.  Use the
%  space bar to enter contours and the arrow keys to move the crosshair if
%  no mouse is available.
%
%  CLABELM(C) or CLABELM(C,V) or CLABELM(C,'manual') places contour
%  labels as above, except that the labels are drawn as plus signs on the
%  contour with a nearby height value.
%
%  CLABELM(..., 'LabelSpacing', spacingInPoints) specifies the spacing
%  between labels on the same contour line, in units of points
%  (72 points equal one inch).
%
%  H = CLABELM(...) returns handles to the TEXT objects created.
%
%  Example
%  -------
%  worldmap world
%  R = georefpostings([-90 90],[0 360],1,1);
%  N = egm96geoid(R);
%  [c,h] = contourm(N,R);
%  clabelm(c,h)
%
%  See also CONTOURM, INPUTM

% Copyright 1996-2020 The MathWorks, Inc.

g = [];
v = [];
manual = false;
labelSpacing = [];

if numel(varargin) > 0
    if ishghandle(varargin{1},'hggroup')
        % Check the 2nd function argument (1st element of varargin) to
        % see if it's an hggroup handle.  If so, assign to g and remove.
        g = varargin{1};
        varargin(1) = [];
    end
    
    if numel(varargin) > 0
        % There's another element left in varargin, which can only be V
        % or 'manual' or 'LabelSpacing'.
        if isnumeric(varargin{1})
            v = varargin{1};
            labelSpacing = parseLabelSpacing(varargin(2:end));
        else
            s = validatestring(varargin{1},{'manual','LabelSpacing'},'clabelm');
            manual = strcmp(s,'manual');
            if manual
                labelSpacing = parseLabelSpacing(varargin(2:end));
            else
                labelSpacing = parseLabelSpacing(varargin);
            end
        end
    end
end

if ~isempty(g)
    % In-line labels; work via the GeoContourGroup object.
    
    % Update the GeoContourGroup object (with handle h).
    h = getappdata(g,'mapgraph');
    if ~isempty(labelSpacing)
        set(h,'LabelSpacing',labelSpacing)
    end
    if ~isempty(v)
        % CLABELM(C,H,V)
        set(h,'ContourLabels',v)
    elseif manual
        % CLABELM(C,H,'manual')
        set(h,'ContourLabels','manual')
    else
        % CLABELM(C,H)
        set(h,'ContourLabels','all')
    end
    h.refresh()
    
    % Get text label handles and set their properties.
    ht = getTextLabelHandles(h);
else
    % Plus labels; no hggroup handle was provided.
    
    % Save current view settings because clabel may change them.
    [az,el] = view;
    
    % Check that C is 2-by-N where N is at least 3 (for a minimum of 2
    % vertices).
    validateattributes(c,{'numeric'}, {'nonempty'}, mfilename, 'C')
    if size(c,1) ~= 2 || size(c,2) < 3
        error(id('InvalidContourMatrixInput'), ...
            'C must be a valid contour description matrix.');
    end
    
    cProjected = projectContourMatrix(c);
    if ~isempty(v)
        % CLABELM(C,V)
        ht = clabel_plus(cProjected,v);
    elseif manual
        % CLABELM(C,'manual')
        ht = clabel_plus(cProjected,'manual');
    else
        % CLABELM(C)
        ht = clabel_plus(cProjected);
    end
    
    % Restore view.
    view(az, el)
end

% Enable interaction with the contour labels.
set(ht,'ButtonDownFcn',@uimaptbx)

% Assign output if requested.
if nargout > 0
    hText = ht;
end

%---------------------------------------------------------------------------

function labelSpacing = parseLabelSpacing(args)
% We expect args to be a 2-element cell array of the form
% {'LabelSpacing',value}.

if isempty(args)
    labelSpacing = [];
else
    validatestring(args{1},{'LabelSpacing'},'clabelm','LabelSpacingName');
    if numel(args) < 2
        error('map:clabelm:missingLabelSpacingValue', ...
            'Expected %s to be followed by a value.', 'LabelSpacing')
    else
        labelSpacing = args{2};
        validateattributes(labelSpacing, {'double'}, ...
            {'real','positive','finite','scalar'}, ...
            'clabelm', 'value of LabelSpacing')
    end
end

%---------------------------------------------------------------------------

function p = projectContourMatrix(c)
% Project the geographic contour matrix c.

mstruct = gcm;

if strcmp(mstruct.mapprojection,'globe')
    error('map:clabelm:globeProjection', ...
        '%s can not apply labels when using globe projection.','CLABELM')
end
  
% Output will rarely be much larger than input.
p = zeros(size(c));

n = 1;
j = 1;

while n < size(c,2)
 	z_level = c(1,n);
    m = n + abs(c(2,n));
    n = n + 1;
    lon = c(1,n:m);
    lat = c(2,n:m);
    n = m + 1;

    [x,y] = feval(mstruct.mapprojection, ...
        mstruct, lat, lon, 'geoline','forward');
    
    [first, last] = internal.map.findFirstLastNonNan(x);
    
    % After trimming, x and y might have multiple parts, which need to be
    % inserted separately into the output (projected) contour matrix, p.
    for i = 1:numel(first)
        s = first(i);
        e = last(i);
        count = e - s + 1;
        p(1,j) = z_level;
        p(2,j) = count;
        k = j + count;
        j = j + 1;
        p(1,j:k) = x(s:e);
        p(2,j:k) = y(s:e);
        j = k + 1;
    end
end

% Removed unused columns.
p(:,j:end) = [];

%---------------------------------------------------------------------------

function hh = clabel_plus(cs, varargin)
%CLABEL Contour plot elevation labels.
%   CLABEL(CS, H) adds height labels to the contour plot specified by H.
%   The labels are rotated and inserted within the contour lines.  CS and H
%   are the contour matrix output and object handle outputs from CONTOUR,
%   CONTOUR3, or CONTOURF.
%
%   CLABEL(CS, H, V) labels just those contour levels given in
%   vector V.  The default action is to label all known contours.
%   The label positions are selected randomly.
%
%   CLABEL(CS, H, 'manual') places contour labels at the locations
%   clicked on with a mouse.  Pressing the return key terminates
%   labeling.  Use the space bar to enter contours and the arrow
%   keys to move the crosshair if no mouse is available.
%
%   CLABEL(CS) or CLABEL(CS, V) or CLABEL(CS, 'manual') places
%   contour labels as above, except that the labels are drawn as
%   plus signs on the contour with a nearby height value.
%
%   H = CLABEL(...) returns handles to the TEXT (and possibly LINE)
%   objects in H.  The UserData property of the TEXT objects contain
%   the height value for each label.
%
%   CLABEL(..., 'text property', property_value, ...) allows arbitrary
%   TEXT property/value pairs to specified for the label strings.
%
%   One special property ('LabelSpacing') is also available to specify
%   the spacing between labels (in points). This defaults to 144, or
%   2 inches.

%   Adapted from the following version of clabel.m
%     Revision: 5.38.4.18.4.1  Date: 2010/03/09 14:54:37

% Check that CS is 2-by-N where N is at least 3 (for a minimum of 2
% vertices).
if size(cs,1) ~= 2 || size(cs,2) < 3 
    error(id('InvalidContourMatrixInput'), ...
        'C must be a valid contour description matrix.');
end

cax = gca;
threeD = IsThreeD(cax);

if nargin == 1
    h = plus_labels(cax, threeD, cs);
else
    h = plus_labels(cax, threeD, cs, varargin{:});
end

if ishghandle(cax) && ~ishold(cax)
    if threeD
        view(cax, 3);
    else
        view(cax, 2);
    end
end

if nargout > 0
    hh = h;
end
% end

function h = plus_labels(cax, threeD, cs, varargin)
    %
    % Draw the labels as plus symbols next to text (v4 compatible)
    %
    
    %    RP - 14/5/97
    %    Clay M. Thompson 6-7-96
    %    Charles R. Denham, MathWorks, 1988, 1989, 1990.
    manual = 0;
    choice = 0;
    
    if nargin > 3
        if ischar(varargin{1}) || isstring(varargin{1})
            if strcmp(varargin{1}, 'manual')
                varargin(1) = [];
                manual = 1;
            end
        else
            choice = 1;
            v = sort(varargin{1}(:));
            varargin(1) = [];
        end
    end
    
    ncs = size(cs, 2);
    
    % Find range of levels.
    k = 1;
    i = 1;
    while k <= ncs
        levels(i) = cs(1, k); %#ok<AGROW>
        i = i + 1;
        k = k + cs(2, k) + 1;
    end
    crange = max(abs(levels));
    cdelta = abs(diff(levels));
    cdelta = min(cdelta(cdelta > eps)) / max(eps, crange); % Minimum significant change
    if isempty(cdelta)
        cdelta = 0;
    end
    
    % Decompose contour data structure if manual mode.
    
    if manual
        disp(' ')
        disp('    Please wait a moment...')
        x = [];
        y = [];
        clist = [];
        k = 0;
        n = 0;
        while (1)
            k = k + n + 1;
            if k > ncs
                break
            end
            c = cs(1, k);
            n = cs(2, k);
            nn = 2 .* n - 1;
            xtemp = zeros(nn, 1);
            ytemp = zeros(nn, 1);
            xtemp(1 : 2 : nn) = cs(1, k + 1 : k + n);
            xtemp(2 : 2 : nn) = (xtemp(1 : 2 : nn - 2) + xtemp(3 : 2 : nn)) ./ 2;
            ytemp(1 : 2 : nn) = cs(2, k + 1 : k + n);
            ytemp(2 : 2 : nn) = (ytemp(1 : 2 : nn - 2) + ytemp(3 : 2 : nn)) ./ 2;
            x = [x; xtemp]; %#ok<AGROW>
            y = [y; ytemp]; %#ok<AGROW>
            clist = [clist; c .* ones(2 * n - 1, 1)]; %#ok<AGROW>
        end
        ax = axis;
        xmin = ax(1);
        xmax = ax(2);
        ymin = ax(3);
        ymax = ax(4);
        xrange = xmax - xmin;
        yrange = ymax - ymin;
        xylist = (x .* yrange + sqrt(-1) .* y .* xrange);
        view(cax, 2);
        disp(' ')
        disp('   Carefully select contours for labeling.')
        disp('   When done, press RETURN while the Graph window is the active window.')
    end
    
    k = 0;
    n = 0;
    flip = 0;
    h = gobjects(0);
    
    while (1)
        
        % Use GINPUT and select nearest point if manual.
        
        if manual
            try
                [xx, yy, button] = ginput(1);
            catch err %#ok<NASGU>
                return
            end
            if isempty(button) || isequal(button, 13)
                break
            end
            if xx < xmin || xx > xmax
                break
            end
            if yy < ymin || yy > ymax
                break
            end
            xy = xx .* yrange + sqrt(-1) .* yy .* xrange;
            dist = abs(xylist - xy);
            [~, f] = min(dist);
            if ~isempty(f)
                f = f(1);
                xx = x(f);
                yy = y(f);
                c = clist(f);
                okay = 1;
            else
                okay = 0;
            end
        end
        
        % Select a labeling point randomly if not manual.
        
        if ~manual
            k = k + n + 1;
            if k > ncs
                break
            end
            c = cs(1, k);
            n = cs(2, k);
            if choice
                f = find(abs(c - v) / max(eps + abs(v)) < .00001, 1);
                okay = ~isempty(f);
            else
                okay = 1;
            end
            if okay
                r = rands(1);
                j = fix(r .* (n - 1)) + 1;
                if flip
                    j = n - j;
                end
                flip = ~flip;
                if n == 1    % if there is only one point
                    xx = cs(1, j + k);
                    yy = cs(2, j + k);
                else
                    x1 = cs(1, j + k);
                    y1 = cs(2, j + k);
                    x2 = cs(1, j + k + 1);
                    y2 = cs(2, j + k + 1);
                    xx = (x1 + x2) ./ 2;
                    yy = (y1 + y2) ./ 2;  % Test was here; removed.
                end
            end
        end
        
        % Label the point.
        
        if okay
            % Set tiny labels to zero.
            if abs(c) <= 10 * eps * crange
                c = 0;
            end
            % Determine format string number of digits
            if cdelta > 0
                ndigits = max(3, ceil(-log10(cdelta)));
            else
                ndigits = 3;
            end
            s = num2str(c, ndigits);
            hl = line('XData', xx, 'YData', yy, 'Marker', '+');
            
            %  Restack to ensure standard child order in the map axes.
            map.graphics.internal.restackMapAxes(hl)                
            
            ht = text(xx, yy, s, ...
                'Parent', cax, ...
                'VerticalAlignment',   'bottom', ...
                'HorizontalAlignment', 'left', ...
                'Clipping', 'on', 'UserData', c, ...
                'Tag', ['contour label: ' s], varargin{:});
            if threeD
                set(hl, 'ZData', c);
                set(ht, 'Position', [xx, yy, c]);
            end
            h = [h; hl]; %#ok<AGROW>
            h = [h; ht]; %#ok<AGROW>
        end
    end
% end

function threeD = IsThreeD(cax)
    %ISTHREED  True for a contour3 plot
    hp = findobj(cax, 'Type', 'patch');
    if isempty(hp)
        hp = findobj(cax, 'Type', 'line');
    end
    if ~isempty(hp)
        % Assume a contour3 plot if z data not empty
        threeD = ~isempty(get(hp(1), 'ZData'));
    else
        threeD = 0;
    end
% end

function r = rands(sz)
    %RANDS Uniform random values without affecting the global stream
    dflt = RandStream.getGlobalStream();
    savedState = dflt.State;
    r = rand(sz);
    dflt.State = savedState;
% end

function str = id(str)
    str = ['MATLAB:clabel:' str];
% end
