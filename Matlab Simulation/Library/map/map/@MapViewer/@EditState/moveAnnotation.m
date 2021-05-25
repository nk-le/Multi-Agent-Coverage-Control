function moveAnnotation(this, obj)
%

% Copyright 2005-2008 The MathWorks, Inc.

hFig = ancestor(obj(1),'Figure');
hAnnotationAxes = this.AnnotationAxes;

prevWinBtnDwnFcn = get(hFig,'WindowButtonDownFcn');
prevWinBtnUpFcn = get(hFig,'WindowButtonUpFcn');
prevWinBtnMtnFcn = get(hFig,'WindowButtonMotionFcn');

set(hFig,'WindowButtonMotionFcn',@startMoveAnnotation,...
    'WindowButtonUpFcn',@endMoveAnnotation);

iptPointerManager(hFig,'disable');
prevPtr = get(hFig,'Pointer');

set(hFig,'Pointer','fleur');

startPnt = get(hAnnotationAxes,'CurrentPoint');


    %----------------------------------------------------------------------
    function startMoveAnnotation(hSrc, evt) %#ok

        currentPnt = get(hAnnotationAxes,'CurrentPoint');
        moveXY = currentPnt([1,3]) - startPnt([1,3]);
        numOfObj = length(obj);

        for n = 1:numOfObj
            h = obj(n);
            if ishghandle(h,'line')
                newXData = get(h,'XData') + moveXY(1);
                newYData = get(h,'YData') + moveXY(2);
                set(h,'XData',newXData,'YData',newYData);
            elseif ishghandle(h,'text')
                newPos = get(h,'Position') + [moveXY 0];
                set(h,'Position',newPos);
            end
        end
        startPnt = currentPnt;
    end % startMoveAnnotation

    %----------------------------------------------------------------------
    function endMoveAnnotation(hSrc,evt) %#ok
      fig = hSrc;
      set(fig,'WindowButtonDownFcn',prevWinBtnDwnFcn,...
            'WindowButtonUpFcn',prevWinBtnUpFcn,...
            'WindowButtonMotionFcn',prevWinBtnMtnFcn,...
            'Pointer',prevPtr);
        
     iptPointerManager(fig,'enable');   
        
    end % endMoveAnnotation

end % moveAnnotation