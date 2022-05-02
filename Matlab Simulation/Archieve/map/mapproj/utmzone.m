function varargout = utmzone(varargin)
%UTMZONE  Select UTM zone given latitude and longitude
%
%   ZONE = UTMZONE selects a Universal Transverse Mercator (UTM) zone with
%   a graphical user interface.
%
%   ZONE = UTMZONE(LAT, LON) returns a UTM zone designation for the
%   zone containing the points specified by coordinates LAT and LON, in
%   units of degrees.  If LAT and LON are vectors, the zone containing the
%   geographic mean of the data set is determined.
%
%   [LATLIM, LONLIM] = UTMZONE(ZONE), where ZONE is a valid UTM zone
%   designation, returns the geographic limits of the zone, LATLIM
%   and LONLIM, in units of degrees.  Valid UTM zones designations are
%   numbers (such as '31') , or numbers followed by a single letter (such
%   as '31L'.
%
%   Limitations
%   -----------
%   The UTM zone system is based on a regular division of the globe, with
%   the exception of a few zones in northern Europe.  utmzone does not
%   account for these exceptions, which involve zones 31-32 V (southern
%   Norway) and zones 31-37 X (Svalbard).
%
%   See also UTMZONEUI, UTMGEOID.

% Copyright 1996-2017 The MathWorks, Inc.

% Syntaxes to be removed. These are supported for now, but not encouraged.
%
%   ZONE = UTMZONE(MAT), where MAT has the form [LAT LON].
%   LIM = UTMZONE(ZONE) returns the limits in a single 1-by-4 vector.

narginchk(0, 2)
if nargin == 0
    nargoutchk(0, 1)
    
    if nargout < 2
        % ZONE = UTMZONE();
        varargout{1} = utmzoneui;
    else
        % [ZONE, MSG] = UTMZONE();
        varargout{1} = utmzoneui;
        varargout{2} = '';
        warnObsoleteMSGSyntax
    end
elseif ischar(varargin{1}) || isstring(varargin{1})
    narginchk(1, 1)
    nargoutchk(0, 3)
    
    zone = convertStringsToChars(upper(varargin{1}));
    [latlim, lonlim] = zoneLimits(zone);
    
    if nargout < 2
        % LIM = UTMZONE(ZONE)
        varargout{1} = [latlim lonlim];
    elseif nargout == 2
        % [LATLIM, LONLIM] = UTMZONE(ZONE)
        varargout{1} = latlim;
        varargout{2} = lonlim;
    else
        % [LATLIM, LONLIM, MSG] = UTMZONE(ZONE)
        varargout{1} = latlim;
        varargout{2} = lonlim;
        varargout{3} = '';
        warnObsoleteMSGSyntax
    end
else
    nargoutchk(0, 2)
    if nargin == 2
        % UTMZONE(LAT,LON)
        lat = varargin{1};
        lon = varargin{2};
    else
        % UTMZONE(MAT)
        mat = varargin{1};
        map.internal.assert(size(mat,2) == 2, ...
            'map:utm:expectedLatLonColumns','MAT')
        lat = mat(:,1);
        lon = mat(:,2);
    end
    
    if nargout < 2
        % ZONE = UTMZONE(...)
        varargout{1} = findZone(lat, lon);
    else
        % [ZONE, MSG] = UTMZONE(...)
        varargout{1} = findZone(lat, lon);
        varargout{2} = '';
        warnObsoleteMSGSyntax
    end
end

%--------------------------------------------------------------------------

function zone = findZone(lat, lon)

checklatlon(lat, lon, 'UTMZONE', 'LAT', 'LON', 1, 2)

% Use geographic mean if lat and lon are non-scalar.
if ~isscalar(lat)
    lat = lat(~isnan(lat));
    lon = lon(~isnan(lon));
    [lat, lon] = meanm(lat, lon);
end

inBounds = (-80 <= lat && lat <= 84) ...
    && (-180 <= lon && lon <= 180);

if inBounds
    lts = [-80:8:72 84]';
    lns = (-180:6:180)';
    latzones = char([67:72 74:78 80:88]');
    
    indx = find(lts <= lat);
    ltindx = indx(max(indx));
    
    indx = find(lns <= lon);
    lnindx = indx(max(indx));
    
    if ltindx < 1 || ltindx > 21
        ltindx = [];
    elseif ltindx == 21
        ltindx = 20;
    end
    
    if lnindx < 1 || lnindx > 61
        lnindx = [];
    elseif lnindx == 61
        lnindx = 60;
    end
    
    zone = [num2str(lnindx) latzones(ltindx)];
else
    error(message('map:utm:outsideLimits'))
end

%--------------------------------------------------------------------------

function [latlim, lonlim] = zoneLimits(zone)
% The input, ZONE, is a UTM zone.

if ischar(zone) && 1 <= numel(zone) && numel(zone) <= 3
    latzones = char([67:72 74:78 80:88]');
    switch(numel(zone))
        case 1
            lnindx = str2double(zone);
            ltindx = nan;
        case 2
            num = str2double(zone);
            if isnan(num)
                lnindx = str2double(zone(1));
                ltindx = find(zone(2) == latzones);
            else
                lnindx = num;
                ltindx = nan;
            end
        case 3
            lnindx = str2double(zone(1:2));
            ltindx = find(zone(3) == latzones);
    end
    
    if ~isempty(ltindx) && ~isempty(lnindx) ...
            && 1 <= lnindx && lnindx <= 60
        latlims = [(-80:8:64)' (-72:8:72)'; 72 84];
        lonlims = [(-180:6:174)' (-174:6:180)'];
        
        if isnan(ltindx)
            latlim = [-80 84];
        else
            latlim = latlims(ltindx,:);
        end
        lonlim = lonlims(lnindx,:);
    else
        error(message('map:utm:invalidZoneDesignation', zone))
    end
else
    error(message('map:utm:invalidZoneDesignation', zone))
end

%--------------------------------------------------------------------------

function warnObsoleteMSGSyntax

warning(message('map:removed:messageStringOutput',...
    'UTMZONE', 'MSG', 'MSG', 'UTMZONE', 'UTMZONE'))
