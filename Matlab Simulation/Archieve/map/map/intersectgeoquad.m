function [latlim, lonlim] ...
    = intersectgeoquad(latlim1, lonlim1, latlim2, lonlim2)
%INTERSECTGEOQUAD Intersection of two latitude-longitude quadrangles
%
%   [LATLIM, LONLIM] = INTERSECTGEOQUAD(LATLIM1, LONLIM1, LATLIM2, LONLIM2)
%   computes the intersection of the quadrangle defined by the latitude
%   and longitude limits LATLIM1 and LONLIM1 with the quadrangle defined
%   by the latitude and longitude limits LATLIM2 and LONLIM2.  LATLIM1
%   and LATLIM2 are two-element vectors of the form:
%
%                [southern-limit northern-limit]
%
%   Likewise LONLIM1 and LONLIM2 are two-element vectors of the form:
%
%                 [western-limit eastern-limit]
%
%   All input and output angles are in units of degrees.  The
%   intersection results are given in the output arrays LATLIM and
%   LONLIM.
%
%   Given an arbitrary pair of input quadrangles, there are three
%   possible results:
%
%   (1) The quadrangles fail to intersect.  In this case both
%   LATLIM and LONLIM are empty arrays.
%
%   (2) The intersection consists of a single quadrangle.  In this case
%   LATLIM (like LATLIM1 and LATLIM2) is a two-element vector which has
%   the form:
%
%                [southern-limit northern-limit]
%
%   where southern-limit and northern-limit represent scalar values.
%   LONLIM (like LONLIM1 and LONLIM2) is a two-element vector which has
%   the form:
%
%                 [western-limit eastern-limit]
%
%   with a pair of scalar limits.
%
%   (3) The intersection consists of a pair of quadrangles.  This can
%   happen when longitudes wrap around such that the eastern end of one
%   quadrangle overlaps the western end of the other and vice versa. For
%   example, if LONLIM1 = [-90 90] and LONLIM2 = [45 -45], then there
%   are two intervals of overlap: [-90 -45] and [45 90].  These limits
%   are returned in LONLIM in separate rows, forming a 2-by-2 array.  In
%   our example (assuming that the latitude limits overlap), LONLIM
%   would equal:
%
%                         [-90  -45;
%                           45   90]
%
%   It still has the form:
%
%                 [western-limit eastern-limit]
%
%   but western-limit and eastern-limit are 2-by-1 rather than scalar.
%   The two output quadrangles have the same latitude limits, but these
%   are replicated so that LATLIM is also 2-by-2.  To continue our
%   example, if LATLIM1 = [0 30] and LATLIM2 = [20 50], then LATLIM
%   would equal:
%
%                          [20 30;
%                           20 30]
%
%   The form is still:
%
%                [southern-limit northern-limit]
%
%   but in this case southern-limit and northern-limit are 2-by-1.
%
%   Notes
%   -----
%   The elements LATLIM1 and LATLIM2 should normally be given in order
%   of increasing numerical value.  No error will result if, for
%   example, LATLIM1(2) < LATLIM1(1), but the outputs will both be empty
%   arrays.
%   
%   No such restriction applies to LONLIM1 and LONLIM2.  The first
%   element is always interpreted as the western limit even if it
%   exceeds the second element (the eastern limit). Furthermore,
%   INTERSECTGEOQUAD correctly handles whatever longitude-wrapping
%   convention may have been applied to LONLIM1 and LONLIM2.
%
%   In terms of output, INTERSECTGEOQUAD wraps LONLIM such that all
%   elements fall in the closed interval [-180 180].  This means that if
%   (one of) the output quadrangle(s) crosses the 180-degree meridian
%   then its western limit will exceed its eastern limit.  The result
%   would be such that
%
%                     LONLIM(2) < LONLIM(1)
%
%   if the intersection comprises a single quadrangle or
% 
%                   LONLIM(k,2) < LONLIM(k,1)
%
%   where k = 1 or 2 if the intersection comprises a pair of
%   quadrangles.
%
%   If abs(diff(LONLIM1)) or abs(diff(LONLIM2)) equals 360, then its
%   quadrangle is interpreted as a latitudinal zone that fully encircles
%   the planet, bounded only by one parallel on the south and another
%   parallel on the north.  If two such quadrangles intersect, then
%   LONLIM is set to [-180 180].
%
%   Examples
%   --------
%   % Non-intersecting quadrangles
%   [latlim, lonlim] = intersectgeoquad( ...
%        [-40 -60], [-180 180], [40 60], [-180 180])
%   % latlim = [];
%   % lonlim = [];
%
%   % Intersection is a single quadrangle
%   [latlim, lonlim] = intersectgeoquad( ...
%        [-40 60], [-120 45], [-60 40], [160 -75])
%   % latlim = [ -40  40];
%   % lonlim = [-120 -75];
%
%   % Intersection is a pair of quadrangles
%   [latlim, lonlim] = intersectgeoquad( ...
%        [-30 90],[-10 -170],[-90 30],[170 10])
%   % latlim = [-30 30; -30   30];
%   % lonlim = [-10 10; 170 -170];
%
%   % Inputs and output fully encircle the planet
%   [latlim, lonlim] = intersectgeoquad( ...
%        [-30 90],[-180 180],[-90 30],[0 360])
%   % latlim = [ -30  30];
%   % lonlim = [-180 180];
%
%   See also INGEOQUAD, OUTLINEGEOQUAD.

% Copyright 2007-2016 The MathWorks, Inc.

latlim = intersectlim(latlim1, latlim2);
if isempty(latlim)
    lonlim = [];
else
    lonlim = intersectlon(lonlim1, lonlim2);
    if isempty(lonlim)
        latlim = [];
    elseif size(lonlim,1) == 2
        % lonlim is 2-by-2, so replicate latlim in the row dimension
        latlim = latlim([1 1],:);
    end
end

%-----------------------------------------------------------------------    
function lim = intersectlim(lim1, lim2)

% Intersect a pair of closed intervals on the real line, given their
% limits as 2-vectors.  (Always returns a row vector.)

if ((lim2(2) < lim1(1)) || (lim1(2) < lim2(1)))
    lim = [];
else
    lim(2) = min(lim1(2), lim2(2));
    lim(1) = max(lim1(1), lim2(1));
end

%-----------------------------------------------------------------------

function lonlim = intersectlon(lonlim1, lonlim2)

% Intersect longitude limits, accounting for the fact that they can wrap
% around the Earth.

full1 = abs(lonlim1(2) - lonlim1(1)) == 360;
full2 = abs(lonlim2(2) - lonlim2(1)) == 360;
if full1 && full2
    % Both inputs span a full 360 degrees
    lonlim = [-180 180];
elseif full1
    % First input spans a full 360 degrees; wrap and return second
    % (Make sure it's a row vector.)
    lonlim = wrapTo180(lonlim2(:)');
elseif full2
    % Second input spans a full 360 degrees; wrap and return first
    % (Make sure it's a row vector.)
    lonlim = wrapTo180(lonlim1(:)');
else
    % Neither input spans a full 360 degrees
    lonlim1 = wrapTo180(lonlim1);
    lonlim2 = wrapTo180(lonlim2);
    w1 = lonlim1(1);
    w2 = lonlim2(1);
    e1 = lonlim1(2);
    e2 = lonlim2(2);
    wrap1 = (e1 < w1);
    wrap2 = (e2 < w2);
    if wrap1 && wrap2
        % Both inputs wrap across the 180-degree meridian
        if (e1 > w2) || (e2 > w1)
            % Intersection comprises two quadrangles
            lonlim = [min(w1, w2)  max(e1, e2);
                      max(w1, w2)  min(e1, e2)];
        else
            % Intersection comprises one quadrangle
            lonlim = [max(w1, w2)  min(e1, e2)];
        end
    elseif wrap1
        % Only the first input crosses the 180-degree meridian
        lonlim = combinelim( ...
            intersectlim(lonlim2, [-180  e1]), ...
            intersectlim(lonlim2, [w1   180]));
    elseif wrap2
        % Only the second input crosses the 180-degree meridian
        lonlim = combinelim( ...
            intersectlim(lonlim1, [-180  e2]), ...
            intersectlim(lonlim1, [w2   180]));
    else
        % Neither input crosses the 180-degree meridian
        lonlim = intersectlim(lonlim1, lonlim2);
    end
end

%-----------------------------------------------------------------------

function lim = combinelim(lim1, lim2)

% Combine a pair of limit vectors, returning:
%
%    * Empty if both are empty
%
%    * The non-empty one if only one is empty
%
%    * Their vertical concatenation if neither is empty.

if ~isempty(lim1) && ~isempty(lim2)
    lim = [lim1; lim2];
elseif ~isempty(lim1)
    lim = lim1;
elseif ~isempty(lim2)
    lim = lim2;
else
    lim = [];
end
