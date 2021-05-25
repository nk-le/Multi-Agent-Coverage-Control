function varargout = mappickerfunc(action,idname,inputnames,inputvals)
%PLOTPICKERFUNC  Support function for Plot Picker component.

% Copyright 2010 The MathWorks, Inc.

% Default display functions for MATLAB plots
if strcmp(action,'defaultshow')
    n = length(inputvals);
    toshow = false;
    % A single empty should always return false
    if isempty(inputvals) ||  isempty(inputvals{1})
        varargout{1} = false;
        return
    end
    fname = idname(1:7);
    switch lower(idname)
        case {'mapshow_point','mapshow_line','mapshow_poly','geoshow_point',...
                'geoshow_line','geoshow_poly'}
            % 2 vector variables (X,Y) selected with equal length and NaNs
            % is matching positions and either no current axes or the current
            % axes is not a map axes (~ismapped(gca)) 
            if n==2
                x = inputvals{1};
                y = inputvals{2};
                % Matrix/vector with same number of rows
                if isnumeric(x) && isnumeric(y) && isreal(x) && isreal(y) && ...
                    isvector(x) && isvector(y) && length(x)==length(y) && isequal(isnan(x),isnan(y))
                    [axesExists,isMapping] = localIsMapAxes;
                    toshow = ~axesExists || ((strcmp(fname,'mapshow') && ...
                        ~isMapping) || (strcmp(fname,'geoshow') && isMapping));
                end
            end
        case 'mapshow_s'
            % mapstruct with X,Y fields and not Lat, Lon fields 
            if n==1
                S = inputvals{1};             
                if isMapStruct(S)
                    [axesExists,isMapping] = localIsMapAxes;
                    toshow = ~axesExists || ~isMapping;
                end
            end
        case 'mapshow_symbolspec'
            % mapstruct with X,Y fields and not Lat, Lon fields and
            % shapetype array, in either order
            if n==2
                S = inputvals{1};
                spec = inputvals{2};
                % mapstruct with X,Y fields and not Lat, Lon fields
                if isstruct(spec) && isMapStruct(S) && isfield(spec,'ShapeType')
                    [axesExists,isMapping] = localIsMapAxes;
                    toshow = ~axesExists || ~isMapping;
                end
            end
        case {'mapshow_texturemap','geoshow_texture'}
            % 2 variables must be selected: Z must be a matrix with size
            % M-by-N and R must be 1-by-3 or 3-by-2 
            if n==2
                Z = inputvals{1};
                R = inputvals{2};
                if ndims(Z)==2 && ~isvector(Z) && ((isvector(R) && size(R,1)==1 && ...
                    size(R,2)==3) || (ndims(R)==2 && size(R,1)==3 && size(R,2)==2))
                    [axesExists,isMapping] = localIsMapAxes;
                    toshow = ~axesExists || ((strcmp(fname,'mapshow') && ...
                        ~isMapping) || (strcmp(fname,'geoshow') && isMapping));
                end
            end
        case {'mapshow_surface','geoshow_surface'}
            % 2 variables: Z must be a matrix with size
            % M-by-N and R must be 1-by-3 or 3-by-2 
            % 3 variables: The first and second variables (X,Y) must be 
            % double vectors and the third variable (Z) must be a double 
            % M-by-N matrix where M and N are the lengths of X and Y 
            if n==2
                Z = inputvals{1};
                R = inputvals{2};
                if isa(Z,'double') && ndims(Z)==2 && ~isvector(Z) && ((isvector(R) && size(R,1)==1 && ...
                    size(R,2)==3) || (ndims(R)==2 && size(R,1)==3 && size(R,2)==2))
                    [axesExists,isMapping] = localIsMapAxes;
                    toshow = ~axesExists || ((strcmp(fname,'mapshow') && ...
                        ~isMapping) || (strcmp(fname,'geoshow') && isMapping));
                end
            elseif n==3
                X = inputvals{1};
                Y = inputvals{2};   
                Z = inputvals{3};
                if isvector(X) && isvector(Y) && isnumeric(X) && isnumeric(Y) && ...
                        isnumeric(Z) && ndims(Z)==2 && size(Z,1)==length(X) && ...
                        size(Z,2)==length(Y)
                    [axesExists,isMapping] = localIsMapAxes;
                    toshow = ~axesExists || ((strcmp(fname,'mapshow') && ...
                        ~isMapping) || (strcmp(fname,'geoshow') && isMapping));
                end
            end
        case {'mapshow_image','geoshow_image'}
            % Enabling conditions for 2 selected variables: 
            % The first variable (Z) must either be a M-by-N-by-3 uint8 array or a M-by-N double matrix 
            % The second variable (R) must be either a 1-by-3 vector or 3-by-2 matrix 
            % Either no current axes or the current axes is not a map axes (~ismapped(gca)) 
            % Enabling conditions for 3 selected variables: 
            % The first variable (A) must be an M-by-N double matrix 
            % The second variable (CMAP) must by 3 column matrix 
            % The third variable (R) must be either a 1-by-3 vector or 3-by-2 matrix 
            % Either no current axes or the current axes is not a map axes (~ismapped(gca)) 
            if n==2
                Z = inputvals{1};
                R = inputvals{2};
                if ((isfloat(Z) && ndims(Z)==2 && ~isvector(Z)) || ...
                    (isa(Z,'uint8') && ndims(Z)==3 && size(Z,3)==3)) && ...        
                    ((isvector(R) && size(R,1)==1 && ...
                    size(R,2)==3) || (ndims(R)==2 && size(R,1)==3 && size(R,2)==2))
                        [axesExists,isMapping] = localIsMapAxes;
                        toshow = ~axesExists || ((strcmp(fname,'mapshow') && ...
                            ~isMapping) || (strcmp(fname,'geoshow') && isMapping));
                end 
            elseif n==3 
                A = inputvals{1};
                CMAP = inputvals{2}; 
                R = inputvals{3};
                if isfloat(A) && ndims(A)==2 && ~isvector(A) && ...
                        isnumeric(CMAP) && ndims(CMAP)==2 && ...
                        size(CMAP,2)==3 && ((isvector(R) && size(R,1)==1 && ...
                        size(R,2)==3) || (ndims(R)==2 && size(R,1)==3 && size(R,2)==2))
                            [axesExists,isMapping] = localIsMapAxes;
                            toshow = ~axesExists || ((strcmp(fname,'mapshow') && ...
                                ~isMapping) || (strcmp(fname,'geoshow') && isMapping));
                end
            end  
        case 'geoshow_s'
            % geostruct with X,Y fields and not Lat, Lon fields 
            if n==1           
                if isGeoStruct(inputvals{1})
                    [axesExists,isMapping] = localIsMapAxes;
                    toshow = ~axesExists || isMapping;
                end
            end                    
        case 'geoshow_symbolspec'
            % geostruct with X,Y fields and not Lat, Lon fields and
            % string
            if n==2
                S = inputvals{1};
                spec = inputvals{2};
                % geostruct with X,Y fields and not Lat, Lon fields
                if isstruct(spec) && isGeoStruct(S) && isfield(spec,'ShapeType')
                    [axesExists,isMapping] = localIsMapAxes;
                    toshow = ~axesExists || isMapping;
                end                
            end
    end
    varargout{1} = toshow;
% Default execution strings for mapping plots
elseif strcmp(action,'defaultdisplay') 
    % mapshow(X, Y, 'DisplayType', 'point');shg
    n = length(inputnames);
    dispStr = '';
    fname = idname(1:7);
    switch lower(idname)
        case 'mapshow_point'
           if n==2
               axesExists = localIsMapAxes;
               if ~axesExists
                   dispStr = sprintf('figure(''Color'',''w'');mapshow(%s,%s,''DisplayType'',''point'');shg;',...
                       inputnames{1},inputnames{2});
               else
                   dispStr = sprintf('mapshow(%s,%s,''DisplayType'',''point'');shg;',...
                       inputnames{1},inputnames{2});
               end
           end
         case 'mapshow_line'
           if n==2
               axesExists = localIsMapAxes;
               if ~axesExists
                   dispStr = sprintf('figure(''Color'',''w'');mapshow(%s,%s,''DisplayType'',''line'');shg;',...
                       inputnames{1},inputnames{2});
               else
                   dispStr = sprintf('mapshow(%s,%s,''DisplayType'',''line'');shg;',...
                       inputnames{1},inputnames{2});
               end
           end
         case 'mapshow_poly'
           if n==2
               axesExists = localIsMapAxes;
               if ~axesExists
                   dispStr = sprintf('figure(''Color'',''w'');mapshow(%s,%s,''DisplayType'',''polygon'');shg;',...
                       inputnames{1},inputnames{2});
               else
                   dispStr = sprintf('mapshow(%s,%s,''DisplayType'',''polygon'');shg;',...
                       inputnames{1},inputnames{2});
               end
           end
         case 'mapshow_s'
           if n==1
               axesExists = localIsMapAxes;
               if ~axesExists
                   dispStr = sprintf('figure(''Color'',''w'');mapshow(%s);shg',...
                       inputnames{1});
               else
                   dispStr = sprintf('mapshow(%s);shg;',inputnames{1});
               end
           end
        case 'mapshow_symbolspec'
           if n==2
               axesExists = localIsMapAxes;
               if ~axesExists
                   dispStr = sprintf('figure(''Color'',''w'');mapshow(%s,''SymbolSpec'',%s);shg;',...
                       inputnames{1},inputnames{2});
               else
                   dispStr = sprintf('mapshow(%s,''SymbolSpec'',%s);shg;',...
                       inputnames{1},inputnames{2});
               end
           end    
         case 'mapshow_texturemap'
           if n==2
               axesExists = localIsMapAxes;
               if ~axesExists
                   dispStr = sprintf('figure(''Color'',''w'');mapshow(%s,%s,''DisplayType'',''texturemap'');shg;',...
                       inputnames{1},inputnames{2});
               else
                   dispStr = sprintf('mapshow(%s,%s,''DisplayType'',''texturemap'');shg;',...
                       inputnames{1},inputnames{2});
               end
           end
        case 'mapshow_surface'
               if n==2
                  axesExists = localIsMapAxes;
                  if ~axesExists
                      dispStr = sprintf('figure(''Color'',''w'');mapshow(%s,%s,''DisplayType'',''surface'');view(3);shg;',...
                         inputnames{1},inputnames{2});
                  else
                      dispStr = sprintf('mapshow(%s,%s,''DisplayType'',''surface'');view(3);shg;',...
                         inputnames{1},inputnames{2});
                  end
               elseif n==3
                  axesExists = localIsMapAxes;
                  if ~axesExists
                      dispStr = sprintf('figure(''Color'',''w'');mapshow(%s,%s,%s,''DisplayType'',''surface'');view(3);shg;',...
                         inputnames{1},inputnames{2},inputnames{3});
                  else
                      dispStr = sprintf('mapshow(%s,%s,%s,''DisplayType'',''surface'');view(3);shg;',...
                         inputnames{1},inputnames{2},inputnames{3});
                  end    
               end
         case {'mapshow_image','geoshow_image'}
               if n==2
                  axesExists = localIsMapAxes;
                  if ~axesExists
                      dispStr = sprintf('figure(''Color'',''w'');%s(%s,%s,''DisplayType'',''image'');view(3);shg;',...
                          fname,inputnames{1},inputnames{2});
                  else
                      dispStr = sprintf('%s(%s,%s,''DisplayType'',''image'');view(3);shg;',...
                          fname,inputnames{1},inputnames{2});
                  end
               elseif n==3
                  axesExists = localIsMapAxes;
                  if ~axesExists
                      dispStr = sprintf('figure(''Color'',''w'');%s(%s,%s,%s,''DisplayType'',''image'');view(3);shg;',...
                          fname,inputnames{1},inputnames{2},inputnames{3});
                  else
                      dispStr = sprintf('%s(%s,%s,%s,''DisplayType'',''image'');view(3);shg;',...
                           fname,inputnames{1},inputnames{2},inputnames{3});
                  end    
               end
               
        case 'geoshow_point'
               if n==2
                   axesExists = localIsMapAxes;
                   if ~axesExists
                       dispStr = sprintf('figure(''Color'',''w'');worldmap([min(%s) max(%s)],[min(%s) max(%s)]);geoshow(%s,%s,''DisplayType'',''point'');shg;',inputnames{1},...
                           inputnames{1},inputnames{2},inputnames{2},inputnames{1},inputnames{2});
                   else
                       dispStr = sprintf('geoshow(%s,%s,''DisplayType'',''point'');shg;',...
                           inputnames{1},inputnames{2});
                   end
               end
        case 'geoshow_line'
               if n==2
                   axesExists = localIsMapAxes;
                   if ~axesExists
                       dispStr = sprintf('figure(''Color'',''w'');worldmap([min(%s) max(%s)],[min(%s) max(%s)]);geoshow(%s,%s,''DisplayType'',''line'');shg;',inputnames{1},...
                           inputnames{1},inputnames{2},inputnames{2},inputnames{1},inputnames{2});
                   else
                       dispStr = sprintf('geoshow(%s,%s,''DisplayType'',''line'');shg;',...
                           inputnames{1},inputnames{2});
                   end
               end
        case 'geoshow_poly'
               if n==2
                   axesExists = localIsMapAxes;
                   if ~axesExists
                       dispStr = sprintf('figure(''Color'',''w'');worldmap([min(%s) max(%s)],[min(%s) max(%s)]);geoshow(%s,%s,''DisplayType'',''polygon'');shg;',inputnames{1},...
                           inputnames{1},inputnames{2},inputnames{2},inputnames{1},inputnames{2});
                   else
                       dispStr = sprintf('geoshow(%s,%s,''DisplayType'',''polygon'');shg;',...
                           inputnames{1},inputnames{2});
                   end
               end
         case 'geoshow_s'
           if n==1
               axesExists = localIsMapAxes;
               if ~axesExists
                   dispStr = sprintf('figure(''Color'',''w'');worldmap([min([%s.Lat]) max([%s.Lat])],[min([%s.Lon]) max([%s.Lon])]); geoshow(%s);shg;',...
                       inputnames{1},inputnames{1},inputnames{1},inputnames{1},inputnames{1});
               else
                   dispStr = sprintf('geoshow(%s);shg;',...
                       inputnames{1});
               end
           end
         case 'geoshow_symbolspec'
           if n==2         
               axesExists = localIsMapAxes;
               if ~axesExists
                   dispStr = sprintf('figure(''Color'',''w'');worldmap([min([%s.Lat]) max([%s.Lat])],[min([%s.Lon]) max([%s.Lon])]);geoshow(%s,''SymbolSpec'',%s);shg;',...
                       inputnames{1},inputnames{1},inputnames{1},...
                       inputnames{1},inputnames{1},inputnames{2});
               else
                   dispStr = sprintf('geoshow(%s,''SymbolSpec'',%s);shg;',...
                       inputnames{1},inputnames{2});
               end
               
           end           
         case 'geoshow_texture'
           if n==2
               axesExists = localIsMapAxes;
               if ~axesExists
                   dispStr = sprintf('figure(''Color'',''w'');worldmap(%s,%s);geoshow(%s,%s,''DisplayType'',''texturemap'');shg;',...
                       inputnames{1},inputnames{2},inputnames{1},inputnames{2});
               else
                   dispStr = sprintf('geoshow(%s,%s,''DisplayType'',''texturemap'');shg;',...
                       inputnames{1},inputnames{2});
               end
           end 
           
         case 'geoshow_surface'
               if n==2
                  axesExists = localIsMapAxes;
                  if ~axesExists
                      dispStr = sprintf('figure(''Color'',''w'');worldmap(%s,%s);geoshow(%s,%s,''DisplayType'',''surface'');view(3);shg;',...
                         inputnames{1},inputnames{2},inputnames{1},inputnames{2});
                  else
                      dispStr = sprintf('geoshow(%s,%s,''DisplayType'',''surface'');view(3);shg;',...
                         inputnames{1},inputnames{2});
                  end
               elseif n==3  
                  axesExists = localIsMapAxes;
                  if ~axesExists
                      dispStr = sprintf('figure(''Color'',''w'');worldmap world;geoshow(%s,%s,%s,''DisplayType'',''surface'');view(3);shg;',...
                         inputnames{1},inputnames{2},inputnames{3});
                  else
                      dispStr = sprintf('geoshow(%s,%s,%s,''DisplayType'',''surface'');view(3);shg;',...
                          inputnames{1},inputnames{2},inputnames{3});
                  end    
               end
               

    end                   
    varargout{1} = dispStr;
% Custom label for ident plots
elseif strcmp(action,'defaultlabel')
    n = length(inputnames);  
    inames = cell(3,1);
    inames(1:n) = inputnames;
    fname = idname(1:7);
    lblStr = '';
    switch lower(idname)
        case {'mapshow_point','geoshow_point'}       
            lblStr = sprintf('%s(%s,%s,''DisplayType'',''point'')',...
                fname,inames{1},inames{2});
        case {'mapshow_line','geoshow_line'}           
                lblStr = sprintf('%s(%s,%s,''DisplayType'',''line'')',...
                    fname,inames{1},inames{2}); 
        case {'mapshow_poly','geoshow_poly'}        
                lblStr = sprintf('%s(%s,%s,''DisplayType'',''polygon'')',...
                    fname,inames{1},inames{2});
        case 'mapshow_symbolspec'
               lblStr =  sprintf('mapshow(%s,''SymbolSpec'',%s)',...
                    inames{1},inames{2});
        case 'geoshow_symbolspec'
               lblStr =  sprintf('geoshow(%s,''SymbolSpec'',%s)',...
                    inames{1},inames{2});
        case {'mapshow_texturemap','geoshow_texture'}
                lblStr = sprintf('%s(%s,%s,''DisplayType'',''texturemap'')',...
                     fname,inames{1},inames{2});
        case {'mapshow_surface','geoshow_surface'}
            if n<=2
                lblStr = sprintf('%s(%s,%s,''DisplayType'',''surface'')',...
                     fname,inames{1},inames{2});
            else
                lblStr = sprintf('%s(%s,%s,%s,''DisplayType'',''surface'')',...
                     fname,inames{1},inames{2},inames{3});
            end
        case {'mapshow_image','geoshow_image'}
            if n<=2
                lblStr = sprintf('%s(%s,%s,''DisplayType'',''image'')',...
                     fname,inames{1},inames{2});
            else
                lblStr = sprintf('%s(%s,%s,%s,''DisplayType'',''image'')',...
                    fname,inames{1},inames{2},inames{3});
            end
    end
    varargout{1} = lblStr;    
end


function [axesExists,isMapping] = localIsMapAxes

f = get(0,'CurrentFigure');
if isempty(f)
    axesExists = false;
    isMapping = false;
    return
end
ax = get(f,'CurrentAxes');
if isempty(ax)
    axesExists = false;
    isMapping = false;
    return
end
axesExists = true;
isMapping = ismap(gca);

function ismapstruct = isMapStruct(S)

ismapstruct = isstruct(S) && isfield(S,'X') && ...
                  isfield(S,'Y') &&  ~isfield(S,'Lat') && ~isfield(S,'Lon') && ...
                  isfield(S,'Geometry');
              
         
function isgeostruct = isGeoStruct(S)
        
isgeostruct = isstruct(S) && isfield(S,'Lat') && ...
                        isfield(S,'Lon') &&  ~isfield(S,'X') && ~isfield(S,'Y') && ...
                        isfield(S,'Geometry');
                    