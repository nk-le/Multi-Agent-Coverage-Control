function hndlout = lcolorbar(varargin)
%LCOLORBAR Append colorbar with text labels
%
%   LCOLORBAR(labels) appends a colorbar with text labels.  The
%   labels input is a cell array of label strings. The colorbar 
%   is constructed using the current colormap with the label
%   strings applied at the centers of the color bands.
%
%   LCOLORBAR(labels,'property',value,...) controls the colorbar's 
%   properties. The location of the colorbar is controlled by the 
%   'Location' property. Valid entries for Location are 'vertical' 
%   (the default) or 'horizontal'. Properties 'TitleString', 
%   'XLabelString', 'YLabelString' and 'ZLabelString' set the 
%   respective strings. Property 'ColorAlignment' controls whether 
%   the colorbar labels are centered on the color bands or the color 
%   breaks. Valid values for ColorAlignment are 'center' or 'ends'. 
%   Other valid property-value pairs are any properties and values 
%   that can be applied to the title and labels of the colorbar axes.
%
%   hcb = LCOLORBAR(...) returns a handle to the colorbar axes.
% 
%   Examples:
%
%         figure; colormap(jet(5))
%         labels = {'apples','oranges','grapes','peaches','melons'};
%         lcolorbar(labels,'fontweight','bold');
%
%   See also CONTOURCMAP, CMAPUI

% Copyright 1996-2019 The MathWorks, Inc.
% Written by: L. Job, W. Stumpf, 4-30-98

narginchk(1,inf)

% input error checking
if mod(nargin,2) ~= 1
   error(message('map:lcolorbar:notNameValuePairs'))
end

[varargin{:}] = convertStringsToChars(varargin{:});
labels = varargin{1};
varargin(1) = [];

% Defaults
fs = 10;
titlestr = {};

loc = 'vertical';
coloralignment = 'center';
titlestring = '';
xlabelstring = '';
ylabelstring = '';
zlabelstring = '';

h = gca;
hfig = ancestor(h,'figure');

% Check for special properties (not properties of the axes labels or title)
todelete = false(size(varargin));
if nargin > 1
   
   for i=1:2:length(varargin)
      
      varargin{i} = canonicalProps(varargin{i});
      
      switch varargin{i}
      case 'location'
         loc = canonicalvals(varargin{i+1});
         todelete([i i+1]) = true;
      case 'coloralignment'
         coloralignment = canonicalvals(varargin{i+1});
         todelete([i i+1]) = true;
      case 'titlestring'
         titlestring = varargin{i+1};
         todelete([i i+1]) = true;
      case 'xlabelstring'
         xlabelstring = varargin{i+1};
         todelete([i i+1]) = true;
      case 'ylabelstring'
         ylabelstring = varargin{i+1};
         todelete([i i+1]) = true;
      case 'zlabelstring'
         zlabelstring = varargin{i+1};
         todelete([i i+1]) = true;
      end
      
   end
   
   varargin(todelete) = [];
   
end

% check values for special properties
switch loc
    case{'vertical','horizontal'}
    otherwise
        error(message('map:lcolorbar:invalidLocation', ...
            'location','vertical','horizontal'))
end

switch coloralignment
    case{'center','ends'}
    otherwise
        error(message('map:lcolorbar:invalidColorAlignment', ...
            'coloralignment','center','ends'))
end


% test to see if current object is axes
objtest = 0;
axesobjs = findobj(gcf,'type','axes');
for i = 1:size(axesobjs,1)
	if isequal(h,axesobjs(i))
		objtest = 1;
	end	
end	
if objtest == 0
	error(message('map:lcolorbar:notAnAxes'))
end	

% get the axes units and change them to normalized
axesunits = get(h,'units');
set(h,'units','normalized')

switch loc % colorbar location
	case 'vertical'
		obj = findobj(gcf,'tag','LCOLORBAR','type','image');
		if isempty(obj)
            % colorbar does not exist
			% get the limits
			axesinfo.clim = get(h,'clim');
			axesinfo.origpos = get(h,'Position');
			axesinfo.h = h;
			axesinfo.units = axesunits;
			axesinfo.figh = get(h,'parent');
			cm = colormap;
			% shrink length by 10 percent
			pos = axesinfo.origpos;
			pos(3) = axesinfo.origpos(3)*0.90;
			set(h,'Position',pos)
			% create colorbar axis
			len = axesinfo.origpos(3)*0.05;
			width = axesinfo.origpos(4);
			axes('Position',[axesinfo.origpos(1)+axesinfo.origpos(3)*0.95 axesinfo.origpos(2) len width])
			% create image
			xlimits = [0 1];
			ylimits = [1,size(cm,1)];
			hndl = image(xlimits,ylimits,(1:size(cm,1))','tag','LCOLORBAR',...
			   		  'DeleteFcn',@deleteim);
			% set gca properties
			set(gca,'xtick',[],'ydir','normal','yaxislocation','right')
        else
            % colorbar does exist
            obj = obj(1);
            delete(ancestor(obj,'axes'));
			% get the limits
			axesinfo.clim = get(h,'clim');
			axesinfo.origpos = get(h,'Position');
			axesinfo.h = h;
			axesinfo.units = axesunits;
			axesinfo.figh = get(h,'parent');
			cm = colormap;
			% shrink length by 10 percent
			pos = axesinfo.origpos;
			pos(3) = axesinfo.origpos(3)*0.90;
			set(h,'Position',pos)
			% create colorbar axis
			len = axesinfo.origpos(3)*0.05;
			width = axesinfo.origpos(4);
			axes('Position',[axesinfo.origpos(1)+axesinfo.origpos(3)*0.95 axesinfo.origpos(2) len width])
			% create image
			xlimits = [0 1];
			ylimits = [1,size(cm,1)];
			hndl = image(xlimits,ylimits,(1:size(cm,1))','tag','LCOLORBAR',...
			   		  'DeleteFcn',@deleteim);
			% set gca properties
			set(gca,'xtick',[],'ydir','normal','yaxislocation','right')
		end	
	
		switch coloralignment
			case 'ends'
				lowerlim = 1-0.5;
				upperlim = size(cm,1)+0.5;
				delta = 1;
				ytickloc = lowerlim:delta:upperlim;
				lowerlabel = floor(axesinfo.clim(1));
				upperlabel = ceil(axesinfo.clim(2));
				yticklabels = lowerlabel:(upperlabel-lowerlabel)/(size(cm,1)):upperlabel;
				% round yticklabel points
				yticklabels = round(yticklabels);
				% find cases where label is less than epsilon
				yticklabels(abs(yticklabels) < eps) = 0;
				% apply labels if provided
				if isempty(labels) == 0
					numberrequired = size(yticklabels,2);
					numberlabels = size(labels,2);
					if numberlabels ~= numberrequired
						warning(message('map:lcolorbar:invalidLabel', ...
                            numberrequired))
					end
					yticklabels = labels;
				end	
				set(gca,'ytick',ytickloc,'yticklabel',yticklabels);
			case 'center'	
				lowerlim = 1;
				upperlim = size(cm,1);
				delta = 1;
				ytickloc = lowerlim:delta:upperlim;
				lowerlabel = floor(axesinfo.clim(1));
				upperlabel = ceil(axesinfo.clim(2));
				yticklabels = lowerlabel:(upperlabel-lowerlabel)/(size(cm,1)-1):upperlabel;
				% round yticklabel points
				yticklabels = round(yticklabels);
				% find cases where label is less than epsilon
				yticklabels(abs(yticklabels) < eps) = 0;
				% apply labels if provided
				if isempty(labels) == 0
					numberrequired = size(yticklabels,2);
					numberlabels = size(labels,2);
					if numberlabels ~= numberrequired
						warning(message('map:lcolorbar:invalidLabel', ...
                            numberrequired))
					end
					yticklabels = labels;
				end	
				set(gca,'ytick',ytickloc,'yticklabel',yticklabels)
		end
        set(gca,'FontSize',fs)
		% set delete function for gca
        setAxesDeleteFcn(gca, axesinfo)
		% set the title if requested
		if isempty(titlestr) == 0
			title = get(gca,'title');
			set(title,'string',titlestr,'fontweight','bold','fontsize',fs)
		end	
	
	case 'horizontal'
		obj = findobj(gcf,'tag','LCOLORBAR','type','image');
		if isempty(obj)
            % colorbar does not exist
			% get the limits
			axesinfo.clim = get(h,'clim');
			axesinfo.origpos = get(h,'Position');
			axesinfo.h = h;
			axesinfo.units = axesunits;			
			axesinfo.figh = get(h,'parent');
			cm = colormap;
			% shrink width by 10 percent
			pos = axesinfo.origpos;
			pos(4) = axesinfo.origpos(4)*0.90;
			pos(2) = axesinfo.origpos(2) + axesinfo.origpos(4)*0.10;
			set(h,'Position',pos)
			% create colorbar axis
			width = axesinfo.origpos(4)*0.05;
			len = axesinfo.origpos(3);
			axes('Position',[axesinfo.origpos(1) axesinfo.origpos(2) len width])
			% create image
			xlimits = [1,size(cm,1)];
			ylimits = [0 1];
			hndl = image(xlimits,ylimits,(1:size(cm,1)),'tag','LCOLORBAR',...
			   		  'DeleteFcn',@deleteim);
			% set gca properties
			set(gca,'ytick',[],'xdir','normal','xaxislocation','bottom')
        else
            % colorbar does exist
            obj = obj(1);
            delete(ancestor(obj,'axes'));
			% get the limits
			axesinfo.clim = get(h,'clim');
			axesinfo.origpos = get(h,'Position');
			axesinfo.h = h;
			axesinfo.units = axesunits;
			axesinfo.figh = get(h,'parent');
			cm = colormap;
			% shrink width by 10 percent
			pos = axesinfo.origpos;
			pos(4) = axesinfo.origpos(4)*0.90;
			pos(2) = axesinfo.origpos(2) + axesinfo.origpos(4)*0.10;
			set(h,'Position',pos)
			% create colorbar axis
			width = axesinfo.origpos(4)*0.05;
			len = axesinfo.origpos(3);
			axes('Position',[axesinfo.origpos(1) axesinfo.origpos(2) len width])
			% create image
			xlimits = [1,size(cm,1)];
			ylimits = [0 1];
			hndl = image(xlimits,ylimits,(1:size(cm,1)),'tag','LCOLORBAR',...
			   		  'DeleteFcn',@deleteim);
			% set gca properties
			set(gca,'ytick',[],'xdir','normal','xaxislocation','bottom')
		end	
	
		switch coloralignment
			case 'ends'
				lowerlim = 1-0.5;
				upperlim = size(cm,1)+0.5;
				delta = 1;
				xtickloc = lowerlim:delta:upperlim;
				lowerlabel = floor(axesinfo.clim(1));
				upperlabel = ceil(axesinfo.clim(2));
				xticklabels = lowerlabel:(upperlabel-lowerlabel)/(size(cm,1)):upperlabel;
				% round yticklabel points
				xticklabels = round(xticklabels);
				% find cases where label is less than epsilon
				xticklabels(abs(xticklabels) < eps) = 0;
				% apply labels if provided
				if isempty(labels) == 0
					numberrequired = size(xticklabels,2);
					numberlabels = size(labels,2);
					if numberlabels ~= numberrequired
						warning(message('map:lcolorbar:invalidLabel',...
                            numberrequired))
					end
					xticklabels = labels;
				end	
				set(gca,'xtick',xtickloc,'xticklabel',xticklabels);
			case 'center'	
				lowerlim = 1;
				upperlim = size(cm,1);
				delta = 1;
				xtickloc = lowerlim:delta:upperlim;
				lowerlabel = floor(axesinfo.clim(1));
				upperlabel = ceil(axesinfo.clim(2));
				xticklabels = lowerlabel:(upperlabel-lowerlabel)/(size(cm,1)-1):upperlabel;
				% round yticklabel points
				xticklabels = round(xticklabels);
				% find cases where label is less than epsilon
				xticklabels(abs(xticklabels) < eps) = 0;
				% apply labels if provided
				if isempty(labels) == 0
					numberrequired = size(xticklabels,2);
					numberlabels = size(labels,2);
					if numberlabels ~= numberrequired
						warning(message('map:lcolorbar:invalidLabel', ...
                            numberrequired))
					end
					xticklabels = labels;
				end	
				set(gca,'xtick',xtickloc,'xticklabel',xticklabels)
		end
        set(gca,'FontSize',fs)
		% set delete function for gca
        setAxesDeleteFcn(gca, axesinfo)
		% set the title if requested
		if isempty(titlestr) == 0
			title = get(gca,'title');
			set(title,'string',titlestr,'fontweight','bold','fontsize',fs)
		end	
	
end

% reset the axes units 
set(h,'units',axesunits)

% activate the initial axes
set(hfig,'CurrentAxes',h)

% set text properties of colorbar axes and title if provided
if ~isempty(hndl)
   set(get(get(hndl,'Parent'),'Title'),'String',titlestring); 
   set(get(get(hndl,'Parent'),'Xlabel'),'String',xlabelstring); 
   set(get(get(hndl,'Parent'),'Ylabel'),'String',ylabelstring); 
   set(get(get(hndl,'Parent'),'Zlabel'),'String',zlabelstring); 
   
   if ~isempty(varargin)
      set(get(get(hndl,'Parent'),'Title'),varargin{:}); 
      set(get(hndl,'Parent'),varargin{:});   
   end
   
end


% output arguments
if nargout > 0 
   if isempty(hndl)
      hndlout = hndl;
   else
      hndlout = get(hndl,'parent'); % return axes handle
   end
end
end

%-------------------------------------------------------------------------

function setAxesDeleteFcn(ax, axesinfo)

set(ax, 'DeleteFcn', @deleteax)

    function deleteax(~, ~)
        % DeleteFcn callback for the axes holding the colorbar.
        
        if ~isempty(axesinfo) && isfield(axesinfo,'h')
            hDataAxes = axesinfo.h;
            if ishghandle(hDataAxes,'axes')
                % Restore the data axes to its original position.
                set(hDataAxes,'Units','normalized')
                set(hDataAxes,'Position',axesinfo.origpos)
                set(hDataAxes,'Units',axesinfo.units)
            end
        end
    end
end

%-------------------------------------------------------------------------

function deleteim(h, ~)
% DeleteFcn callback for the image object used in the colorbar.

% Double check that h is an 'lcolorbar' image, then delete parent axes.
% Let the axes' delete function do the actual work.
if ishghandle(h,'image') && strcmpi(get(h,'Tag'),'lcolorbar')
    ax = get(h,'Parent');
    delete(ax)
end

end

%-------------------------------------------------------------------------

function out = canonicalProps(in)
% CANONICALPROPS expand property names to canonical names

try
    out = validatestring(in, ...
        {'location','coloralignment','sourceobject','titlestring',...
        'xlabelstring','ylabelstring','zlabelstring','colorbar'}, ...
        'lcolorbar');
catch e
    if strcmp(e.identifier,'MATLAB:lcolorbar:unrecognizedStringChoice') ...
            && ~isempty(e.cause)
        rethrow(e)
    else
        out = in;
    end
end
end

%-------------------------------------------------------------------------

function out = canonicalvals(in)
% CANONICALVALS expand value names to canonical names

try
    out = validatestring(in, ...
        {'horizontal','vertical','none','center','ends','on','off'}, ...
        'lcolorbar');
catch e
    if strcmp(e.identifier,'MATLAB:lcolorbar:unrecognizedStringChoice') ...
            && ~isempty(e.cause)
        rethrow(e)
    else
        out = in;
    end
end
end
