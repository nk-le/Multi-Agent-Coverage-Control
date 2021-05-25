function maptrim(varargin)
%MAPTRIM Customize map data sets
%
%  MAPTRIM(lat,long) will display the supplied data in a new
%  figure window.  Using the menu choices and interactive zooming,
%  a region of the map can be defined and the appropriate map data
%  variables saved in the workspace.  The inputs lat and long must
%  be vector map data.  If a patch map output is selected, then the
%  input lat and long must originally represent patch map data.
%
%  MAPTRIM(lat,long,'LineSpec') displays the vector map data using
%  the LineSpec.
%
%  MAPTRIM(Z,refvec) displays a regular data grid Z in a new figure
%  window and allows a subset of this map to be selected and saved.  The
%  output map will be a regular data grid.  Only even multiples of the
%  input map scale can be selected as output resolutions.
%
%  MAPTRIM(Z,refvec,'PropertyName',PropertyValue,...) displays the
%  data grid using the surface properties provided.  The 'Tag',
%  'UserData' and 'EdgeColor' properties can not be set.
%
%  See also GEOCROP, MAPTRIML, MAPTRIMP

% Copyright 1996-2020 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

narginchk(1, inf)

if nargin == 1
    action = varargin{1};
else
    if ischar(varargin{1})
	    action = varargin{1};  varargin(1)=[];
    else
        if isequal(size(varargin{1}),size(varargin{2}))  %  Vector maps
		     action = 'VectorInitialize';
	         lat = varargin{1};
			 lon = varargin{2};
             lat = lat(:);
             lon = lon(:);
		     varargin(1:2) = [];
        elseif ismatrix(varargin{1}) && min(size(varargin{1})) ~= 1 && ...
		       length(varargin{2}) == 3  %  Map/refvec usage
		     action = 'MatrixInitialize';
	         V = varargin{1};
			 refvec = varargin{2};
             refvec = refvec(:)';
		     varargin(1:2) = [];
        else
              error(['map:' mfilename ':incorrectInput'], ...
                  'Incorrect inputs.')
        end
    end
end


switch action
case 'VectorInitialize'    %  Plot the data in a new window
      h = figure('Name','Customize Map','CloseRequestFcn','maptrim(''close'')');
      if isempty(varargin)
	        plot(lon,lat,'Tag','OriginalLineMapData')
	  else
	        plot(lon,lat,varargin{:},'Tag','OriginalLineMapData')
	  end

	  xlabel('Longitude'); ylabel('Latitude')
      zoom(h,'on')

      hmenu = uimenu(h,'Label','Customize');   %  Add the menu items
	  uimenu(hmenu,'Label','Zoom Off','Callback','maptrim(''zoomoff'')')
	  uimenu(hmenu,'Label','Limits','Callback','maptrim(''limits'')')
	  hsub = uimenu(hmenu,'Label','Save As');
	  uimenu(hsub,'Label','Line',...
	              'Callback','maptrim(''vector'',''line'',char(who))')
	  uimenu(hsub,'Label','Patch',...
	              'Callback','maptrim(''vector'',''patch'',char(who))')
	  uimenu(hsub,'Label','Regular Surface',...
	              'Callback','maptrim(''surface'',char(who))')


case 'MatrixInitialize'    %  Plot the data in a new window
      h = figure('Name','Customize Map','CloseRequestFcn','maptrim(''close'')');
      R = internal.map.convertToGeoRasterRef( ...
          refvec, size(V), 'degrees', mfilename, 'R', 2);
      [lat,lon] = map.internal.graticuleFromRasterReference(R, size(V));

      m = pcolor(lon,lat,V);
      if ~isempty(varargin);   set(m,varargin{:});    end
	  set(m,'Tag','OriginalMatrixMapData','EdgeColor','none','UserData',refvec)

	  xlabel('Longitude'); ylabel('Latitude')
      zoom(h,'on')

      hmenu = uimenu(h,'Label','Customize');   %  Add the menu items
	  uimenu(hmenu,'Label','Zoom Off','Callback','maptrim(''zoomoff'')')
	  uimenu(hmenu,'Label','Limits','Callback','maptrim(''limits'')')
	  hsub = uimenu(hmenu,'Label','Save As');
	  uimenu(hsub,'Label','Regular Surface',...
	              'Callback','maptrim(''matrix'',char(who))')


case 'limits'     %  Set the latitude or longitude limits of the display

%  Get the map limits

      prompt={'Latitude Limits (eg: [#, #]):','Longitude Limits (eg: [#, #]):'};
      answer={['[' num2str(get(gca,'Ylim'),'%5.2f  ') ']' ],['[' num2str(get(gca,'Xlim'),'%5.2f  ') ']' ]};
      title='Enter the Map limits';
      lineNo=1;

	  while ~isempty(answer)   %  Prompt until correct, or cancel
	      answer=inputdlg(prompt,title,lineNo,answer);

          if ~isempty(answer)   % OK button pushed
              if ~isempty(answer{1})   %  Valid latitude limits?
			       latlim = str2num(answer{1});
				   if isempty(latlim) | length(latlim) ~= 2
				       latlim = [];
		               uiwait(errordlg('Latitude limits must be a 2 element vector',...
			                       'Customize Error','modal'))
				   end
			  else
			       latlim = get(gca,'Ylim');
			  end

              if ~isempty(answer{2})   %  Valid longitude limits?
			       lonlim = str2num(answer{2});
				   if isempty(lonlim) | length(lonlim) ~= 2
				       lonlim = [];
		               uiwait(errordlg('Longitude limits must be a 2 element vector',...
			                       'Customize Error','modal'))
				   end
			  else
			       lonlim = get(gca,'Xlim');
			  end

			  if ~isempty(latlim) & ~isempty(lonlim)
			       break
		      end
		  end
      end

      if isempty(answer);   return;   end   %  Cancel pushed

%  Set the map limits

      set(gca,'Xlim',sort(lonlim),'Ylim',sort(latlim))


case 'vector'     %  Save map as line or patch variables

%  Get the variable name inputs

      prompt={'Latitude Variable:','Longitude Variable:',...
	          'Resolution (blank is default):',...
			  'Latitude Limits (Optional):', 'Longitude Limits (Optional):'};
      answer={'lat','long','','',''};
      lineNo=1;
      switch varargin{1}
	      case 'line',   title='Enter the Line Map variable names';
	      case 'patch',  title='Enter the Patch Map variable names';
	  end


	  while ~isempty(answer)  %  Prompt until correct, or cancel
	      answer=inputdlg(prompt,title,lineNo,answer);

          breakflag = 1;
		  if ~isempty(answer)   % OK button pushed
              if isempty(answer{1}) | isempty(answer{2})
		           breakflag = 0;
				   uiwait(errordlg('Variable names must be supplied',...
			                       'Customize Error','modal'))
		      elseif ~isempty(answer{3}) & ...
			         (isempty(str2num(answer{3})) | length(str2num(answer{3})) ~= 1)
		           breakflag = 0;
				   uiwait(errordlg('Resolution must be a scalar or blank',...
			                       'Customize Error','modal'))
			  else
                   latmatch = strmatch(answer{1},varargin{2});
                   lonmatch = strmatch(answer{2},varargin{2});
				   if ~isempty(answer{4})
                       latlimmatch = strmatch(answer{4},varargin{2});
				   else
				       latlimmatch = [];
				   end
				   if ~isempty(answer{5})
                       lonlimmatch = strmatch(answer{5},varargin{2});
				   else
				       lonlimmatch = [];
				   end

                   if ~isempty(latmatch)    | ~isempty(lonmatch) | ...
				      ~isempty(latlimmatch) | ~isempty(lonlimmatch)
                        Btn=questdlg('Replace existing variables?', ...
 	                                 'Save Map Data', 'Yes','No','No');
                        if strcmp(Btn,'No');   breakflag = 0;  end
				  end
		      end
		  end

		  if breakflag;  break;   end
      end

      if isempty(answer);   return;   end   %  Cancel pushed
      latname    = answer{1};
      lonname    = answer{2};
      resolution = str2num(answer{3});
	  latlimname = answer{4};
      lonlimname = answer{5};

%  Extract and trim the map data
%  If a resolution is provided, extract a slightly larger region, then
%  ensure the resolution and then trim to the desired limits.  This will
%  prevent drop-offs at the edge of the map when a resolution is given

      hline = findobj(gca,'Type','line','Tag','OriginalLineMapData');
      lon = get(hline,'Xdata');   lonlim = get(gca,'Xlim');
      lat = get(hline,'Ydata');   latlim = get(gca,'Ylim');

      if ~isempty(resolution)
          latlim1 = latlim + [-10 10]*resolution;
          lonlim1 = lonlim + [-10 10]*resolution;
      else
          latlim1 = latlim;   lonlim1 = lonlim;
      end

      switch varargin{1}   %  Trim map, rough cut if resolution given
         case 'line',    [lat,lon] = maptriml(lat,lon,latlim1,lonlim1);
	     case 'patch',   [lat,lon] = maptrimp(lat,lon,latlim1,lonlim1);
      end

      if ~isempty(resolution)   %  Interpolate and retrim if necessary
          [lat,lon]= interpm(lat,lon,resolution);
          switch varargin{1}
             case 'line',    [lat,lon] = maptriml(lat,lon,latlim,lonlim);
	         case 'patch',   [lat,lon] = maptrimp(lat,lon,latlim,lonlim);
          end
      end

%  Save as variables in the base workspace

      assignin('base',latname,lat)
      assignin('base',lonname,lon)
      if ~isempty(latlimname);  assignin('base',latlimname,latlim);  end
      if ~isempty(lonlimname);  assignin('base',lonlimname,lonlim);  end

case 'surface'     %  Save map as regular surface map from vector data input

%  Get the variable name inputs

      prompt={'Map Variable:','Map Legend Variable:',...
	          'Scale (cells/degree):',...
			  'Latitude Limits (Optional):', 'Longitude Limits (Optional):'};
      answer={'map','maplegend','1','',''};
      lineNo=1;
      title='Enter the Surface Map variable names';


	  while ~isempty(answer)   %  Prompt until correct, or cancel
	      answer=inputdlg(prompt,title,lineNo,answer);

          breakflag = 1;
		  if ~isempty(answer)   % OK button pushed
              if isempty(answer{1}) | isempty(answer{2})
		           breakflag = 0;
				   uiwait(errordlg('Variable names must be supplied',...
			                       'Customize Error','modal'))
		      elseif isempty(str2num(answer{3})) | ...
			         length(str2num(answer{3})) ~= 1
		           breakflag = 0;
				   uiwait(errordlg('Scale must be a scalar',...
			                       'Customize Error','modal'))
			  else
                   mapmatch = strmatch(answer{1},varargin{1});
                   legmatch = strmatch(answer{2},varargin{1});

				   if ~isempty(answer{4})
                       latlimmatch = strmatch(answer{4},varargin{1});
				   else
				       latlimmatch = [];
				   end
				   if ~isempty(answer{5})
                       lonlimmatch = strmatch(answer{5},varargin{1});
				   else
				       lonlimmatch = [];
				   end

                   if ~isempty(mapmatch)    | ~isempty(legmatch) | ...
				      ~isempty(latlimmatch) | ~isempty(lonlimmatch)
                        Btn=questdlg('Replace existing variables?', ...
 	                                 'Save Map Data', 'Yes','No','No');
                        if strcmp(Btn,'No');   breakflag = 0;  end
				  end
		      end
		  end

		  if breakflag;  break;   end
      end

      if isempty(answer);   return;   end   %  Cancel pushed
      mapname    = answer{1};
	  legendname = answer{2};
      scale      = str2num(answer{3});
	  latlimname = answer{4};
      lonlimname = answer{5};

%  Extract and trim the map data
%  Trim to a region larger than the desired map (rough cut).  Then
%  interpolate to the desired resolution (1/scale).  Finally trim to
%  the specified map.  This prevents segments from terminating before
%  the edge of the map.  And it provides for connected segments throughout
%  the data grid.

      hline = findobj(gca,'Type','line','Tag','OriginalLineMapData');
      lon = get(hline,'Xdata');   lonlim = get(gca,'Xlim');
      lat = get(hline,'Ydata');   latlim = get(gca,'Ylim');

      latlim1 = latlim + [-10 10]*(1/scale);
      lonlim1 = lonlim + [-10 10]*(1/scale);

      [lat,lon] = maptriml(lat,lon,latlim1,lonlim1);
      [lat,lon] = interpm(lat,lon,(0.9/scale));

      [nrows, ncols, refvec] = sizem(latlim1, lonlim1, scale);
      V = zeros(nrows, ncols);
      V = imbedm(lat,lon,1,V,refvec);
	  [V,refvec] = maptrims(V,refvec,latlim,lonlim);

%  Save as variables in the base workspace

      assignin('base',mapname,V)
      assignin('base',legendname,refvec)
      if ~isempty(latlimname);  assignin('base',latlimname,latlim);  end
      if ~isempty(lonlimname);  assignin('base',lonlimname,lonlim);  end

case 'matrix'     %  Save map as regular surface map from matrix data input

%  Extract the map data.  Maplegend(1) needed as a default input to
%  the dialog box

              hmap = findobj(gca,'Type','surface','Tag','OriginalMatrixMapData');
              lon = get(hmap,'Xdata');   lonlim = get(gca,'Xlim');
              lat = get(hmap,'Ydata');   latlim = get(gca,'Ylim');
              V = get(hmap,'Cdata');   refvec = get(hmap,'UserData');

%  Get the variable name inputs

      prompt={'Map Variable:','Map Legend Variable:',...
	          'Scale (cells/degree):',...
			  'Latitude Limits (Optional):', 'Longitude Limits (Optional):'};
      answer={'map','maplegend',num2str(refvec(1)),'',''};
      lineNo=1;
      title='Enter the Surface Map variable names';


	  while 1   %  Prompt until correct, or cancel
	      answer=inputdlg(prompt,title,lineNo,answer);

          trimflag = 1;
		  if ~isempty(answer)   % OK button pushed
              if isempty(answer{1}) | isempty(answer{2})
		           trimflag = 0;
				   uiwait(errordlg('Variable names must be supplied',...
			                       'Customize Error','modal'))
		      elseif isempty(str2num(answer{3})) | ...
			         length(str2num(answer{3})) ~= 1
		           trimflag = 0;
				   uiwait(errordlg('Scale must be a scalar',...
			                       'Customize Error','modal'))
			  else
                   mapmatch = strmatch(answer{1},varargin{1});
                   legmatch = strmatch(answer{2},varargin{1});
				   if ~isempty(answer{4})
                       latlimmatch = strmatch(answer{4},varargin{1});
				   else
				       latlimmatch = [];
				   end
				   if ~isempty(answer{5})
                       lonlimmatch = strmatch(answer{5},varargin{1});
				   else
				       lonlimmatch = [];
				   end

                   if ~isempty(mapmatch)    | ~isempty(legmatch) | ...
				      ~isempty(latlimmatch) | ~isempty(lonlimmatch)
                        Btn=questdlg('Replace existing variables?', ...
 	                                 'Save Map Data', 'Yes','No','No');
                        if strcmp(Btn,'No');   trimflag = 0;  end
				  end
		      end
		  end

		  if trimflag
              if isempty(answer);   return;   end   %  Cancel pushed
              
              try
                  mapname    = answer{1};
                  legendname = answer{2};
                  scale      = str2num(answer{3});
                  latlimname = answer{4};
                  lonlimname = answer{5};
                  
                  %  Trim the map data
                  [submap,sublegend] = maptrims(V,refvec,latlim,lonlim,scale);
                  break;
                  
              catch e
                  uiwait(errordlg(e.message));
              end
		  end
      end

%  Save as variables in the base workspace

      assignin('base',mapname,submap)
      assignin('base',legendname,sublegend)
      if ~isempty(latlimname);  assignin('base',latlimname,latlim);  end
      if ~isempty(lonlimname);  assignin('base',lonlimname,lonlim);  end

case 'zoomoff'     %  Turn zoom off
      f = get(0,'CurrentFigure');
      hmenu = findobj(f,'type','uimenu','label','Zoom Off');
	  zoom(f,'off')
	  set(hmenu,'Label','Zoom On','Callback','maptrim(''zoomon'')')

case 'zoomon'      %  Turn zoom on
      f = get(0,'CurrentFigure');
      hmenu = findobj(f,'type','uimenu','label','Zoom On');
	  zoom(f,'on')
	  set(hmenu,'Label','Zoom Off','Callback','maptrim(''zoomoff'')')

case 'close'         %  Close figure
     ButtonName = questdlg('Are You Sure?','Confirm Closing','Yes','No','No');
     if strcmp(ButtonName,'Yes');   delete(get(0,'CurrentFigure'));   end
end
