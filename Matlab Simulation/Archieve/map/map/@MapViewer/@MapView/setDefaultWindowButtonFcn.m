function setDefaultWindowButtonFcn(viewer)
%

% Copyright 2006-2008 The MathWorks, Inc.
    
set(viewer.Figure,'WindowButtonMotionFcn',@updateXYDisplay)
set(viewer.Figure,'WindowButtonUpFcn','');

   function updateXYDisplay(hSrc,event) %#ok<INUSD>
   
       hHit = hittest(viewer.Figure);
       isOverAxes = ~isempty(ancestor(hHit,'axes'));
   
       if isOverAxes
           p = get(viewer.getAxes(),'CurrentPoint');
           set(viewer.XDisplay,'String',num2str(p(1),'%0.2f'));
           set(viewer.YDisplay,'String',num2str(p(3),'%0.2f'));
       else
           set([viewer.XDisplay,viewer.YDisplay],'String','');
       end
   end % updateXYDisplay

end %setDefaultWindowButtonMotionFcn
