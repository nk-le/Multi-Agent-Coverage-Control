function project(h,option)
%PROJECT Project displayed map graphics object
%
%  PROJECT will be removed in a future release.
%
%  PROJECT(h) will take existing displayed graphics objects (lines,
%  surfaces, etc) specified by the input handles h and project the
%  data onto a map axes.  The existing objects must be displayed on a
%  valid map axes, but not projected using the map definition data.
%  For example, PROJECT will take data displayed using the PLOT command
%  and re-display it on a map as if it were plotted using the PLOTM
%  command.  If a scalar axis handle is provided, then all the children
%  of the axes are projected.
%
%  PROJECT(h,'option') uses the option string to specify the relationship
%  between x,y data and latitude, longitude data.  'xy' defines x
%  data as longitude and y data as latitude.  'yx' defines x data as
%  latitude and x data as longitude (which occurs with accidental use of
%  a non-mapping MATLAB display command, such as PLOT instead of PLOTM).
%  If omitted, option = 'xy' is assumed.

% Copyright 1996-2020 The MathWorks, Inc.
% Written by:  E. Byrns, W. Stumpf, E. Brown

narginchk(1,2)
if nargin == 1
    option = [];
end

%  Empty argument tests
if isempty(option)
    option = 'xy';
else
    option = validatestring(option, {'xy','yx'}, 'PROJECT', 'OPTION', 2);
end

%  Test for valid handles

if any(~ishghandle(h))
   error(message('map:validate:expectedHGHandles','H'))
end

%  If h is an axes, then project all the children of the axes

if isscalar(h) && ishghandle(h,'axes')
    h = get(h,'Children');
end

%  Project each valid object

for i = 1:length(h)


    %  Test parent of current object for a map axes

    parent = get(h(i),'Parent');
    if ~strcmp(get(parent,'Type'),'axes')
        error(message('map:project:expectedChildOfAxes'))
    end
    gcm(parent);
    projectflag = 1;    %  Assume it is possible to project object

    type = get(h(i),'Type');     %  Graphic object type

    if ~any(strcmp(type,{'line','surface','patch','text'}))
        warning(message('map:project:cannotProjectObject',type))
        projectflag = 0;    %  Skip the projection calculations
    end


    if projectflag

        switch type
            case 'patch'
                vertices = get(h(i),'Vertices');
                lat = vertices(:,1);
                lon = vertices(:,2);
                if size(vertices,2) == 3
                    z = vertices(:,3);
                else
                    z = [];
                end
                oldz = z;
                FVCD = get(h(i),'FaceVertexCData');
            case 'text'
                position = get(h(i),'Position');
                lat = position(:,1);
                lon = position(:,2);
                if size(position,2) == 3
                    z = position(:,3);
                else
                    z = [];
                end
            otherwise % line or surface
                lat = get(h(i),'Xdata');
                lon = get(h(i),'Ydata');
                z   = get(h(i),'Zdata');
        end

        % Make some necessary adjustments to the data

        switch option       %  Reverse current x, y data
            case 'xy'
                temp = lat;
                lat = lon;
                lon = temp;
        end

        % Necessary for making lines (w/clips) work right.

        if isempty(z);  z = zeros(size(lat));  end

        % Project the data


        % Reset the appropriate property fields

        switch type
            case 'patch'
                [x,y,z,savepts] = map.crs.internal.mfwdtran(lat,lon,z,type);
                if length(lat) == 1		% point data; undo closure of patch
                    x = x(1); y = y(1); z = z(1);
                    set(h(i),'Vertices',[x y z],'UserData',savepts);
                else
                    if  length(FVCD)+2 == length(x) % general patches, not clipped. SETFACES won't handle this either
                        [x,y,z,savepts] = map.crs.internal.mfwdtran(lat,lon,oldz,'surface');
                        set(h(i),'Vertices',[x y z],'UserData',savepts);
                    elseif isempty(FVCD) || length(FVCD) == 1 % standard mapping toolbox patches
                        [x,y,z,userdata] = projectpatch(gcm,lat,lon,z);
                        faces = setfaces(x,y);	%  Determine the vertices of the faces for this map
                        set(h(i),'Faces',faces,'Vertices',[x y z],'UserData',userdata);
                    else   % general patches, clipped. Can't clip them yet, so try to do as much right as possible
                        [x,y,~,savepts] = map.crs.internal.mfwdtran(lat,lon,z,'none');
                        set(h(i),'Vertices',[x y oldz],'UserData',savepts);
                    end
                end
            case 'text'
                [x,y,z,savepts] = map.crs.internal.mfwdtran(lat,lon,z,type);
                set(h(i),'Position',[x y z],'UserData',savepts);
            otherwise % line or surface
                [x,y,z,savepts] = map.crs.internal.mfwdtran(lat,lon,z,type);
                set(h(i),'Xdata',x,'Ydata',y,'Zdata',z,'UserData',savepts);
        end


    end
end
