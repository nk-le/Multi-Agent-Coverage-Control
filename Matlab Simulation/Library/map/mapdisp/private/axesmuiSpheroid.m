function [out1, out2] = axesmuiSpheroid(varargin)
%axesmuiSpheroid Manage spheroid properties for the AXESMUI GUI
%
%   [a, ecc] = axesmuiSpheroid(k) returns the semimajor axis a, in
%   kilometers, and eccentricity ecc of the k-th spheroid.
%
%   [spheroidList, index] = axesmuiSpheroid(ellipsoidVector, zone) returns
%   a standard list of spheroid names and the index to the spheroid, if
%   any, that matches the two-element ellipsoid vector.  If no match is
%   found, return an index to the last element in the list, 'user defined'.
%   If zone matches a UTM zone string, insert a '*' before the spheroid(s)
%   recommended by the utmgeoid function. Assume that ellipsoidVector is in
%   kilometers when zone is empty, and in meters otherwise.

% Copyright 2012 The MathWorks, Inc.

spheroidList = {
    'unit sphere', ...
    'earth: sphere', ...
    'earth: wgs84', ...
    'earth: airy1830', ...
    'earth: bessel', ...
    'earth: clarke66', ...
    'earth: clarke80', ...
    'earth: everest', ...
    'earth: grs80', ...
    'earth: iau65', ...
    'earth: iau68', ...
    'earth: international', ...
    'earth: krasovsky', ...
    'earth: wgs60', ...
    'earth: wgs66', ...
    'earth: wgs72', ...
    'sun: sphere', ...
    'moon: sphere', ...
    'mercury: sphere', ...
    'venus: sphere', ...
    'mars: sphere', ...
    'mars: ellipsoid', ...
    'jupiter: sphere', ...
    'jupiter: ellipsoid', ...
    'saturn: sphere', ...
    'saturn: ellipsoid', ...
    'uranus: sphere', ...
    'uranus: ellipsoid', ...
    'neptune: sphere', ...
    'neptune: ellipsoid', ...
    'pluto: sphere', ...
    'user defined'};

if nargin == 1
    [out1, out2] = lookupProperties(spheroidList, varargin{:});
else
    [out1, out2] = listAndIndex(spheroidList, varargin{:});
end

%--------------------------------------------------------------------------

function [a, ecc] = lookupProperties(spheroidList, k)
% Return the semimajor axis a, in kilometers, and eccentricity ecc of the
% k-th element in the spheroid list (a string cell encoding pairs of planet
% and parameter names), with special values (1,0) and (NaN,NaN) for the
% first and last elements, respectively.

n = size(spheroidList,2);
if k == 1
    % The first element of the spheroid list is a unit sphere.
    a   = 1;
    ecc = 0;
elseif 1 < k && k < n
    % Except for the first and last, each element of the spheroid list has
    % the form planet:parameter. Extract planet and parameter substrings
    % from elements 2 through n - 1, and use them to look construct
    % spheroid objects of class referenceSphere or referenceEllipsoid.
    c = textscan(spheroidList{k},'%s','Delimiter',':');
    planet    = c{1}{1};
    parameter = c{1}{2};
    if strcmp(parameter,'sphere')
        s = referenceSphere(planet,'kilometers');
    elseif strcmp(parameter,'ellipsoid')
        s = referenceEllipsoid(planet,'kilometers');
    elseif strcmp(planet,'earth')
        s = referenceEllipsoid(parameter,'kilometers');
    end
    a   = s.SemimajorAxis;
    ecc = s.Eccentricity;
else
    % The last element of the spheroid list is "user defined."
    a   = NaN;
    ecc = NaN;
end

%--------------------------------------------------------------------------

function [spheroidList, index] ...
    = listAndIndex(spheroidList, ellipsoidVector, zone)
% Return a standard list of spheroid names and the index to the spheroid,
% if any, that matches the two-element ellipsoid vector.

% Extract vectors of semimajor axes a and eccentricities ecc from the
% spheroid list.
n = length(spheroidList);
aList = ones( n - 1,1);
eList = zeros(n - 1,1);
for k = 1:n
    [aList(k), eList(k)] = lookupProperties(spheroidList, k);
end

% Extract semimajor axis and eccentricity from the input ellipsoid vector.
a = ellipsoidVector(1);
e = ellipsoidVector(2);

if ~isempty(zone)
    % Convert input semimajor axis from meters to kilometers
    a = a / 1000;
end

% Look for an element in the spheroid list that's an exact match for the
% input, and assign its position to index if found. Otherwise, set index to
% code for 'user defined'.
index = find(abs(a - aList) < 2*eps(a) & abs(e - eList) < 2*eps(e),1);
if isempty(index)
    index = n;
end

usingUTM = ~isempty(zone) && length(zone) <= 3;
if usingUTM
    % Insert a '*' before to each entry in the spheroid list that matches
    % an output from utmgeoid. (The second output of the utmgeoid function
    % is a string matrix that has one row in many cases, but not always.)
    [~,name] = utmgeoid(zone);
    utmSpheroids = [{'wgs84'}; cellstr(name)];
    for k = 1:size(utmSpheroids,1)
        i = cellfun(@(p) ~isempty(p), strfind(spheroidList, utmSpheroids{k}));
        if any(i)
            spheroidList{i} = ['*' spheroidList{i}];
        end
    end
end
