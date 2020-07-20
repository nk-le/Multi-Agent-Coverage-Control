global sim; global clientID;
sim=remApi('remoteApi'); % using the prototype file (remoteApiProto.m)
sim.simxFinish(-1); % just in case, close all opened connections
clientID = sim.simxStart('127.0.0.1',19999,true,true,5000,5);

% Variables and Handle
CM = controlManager();
SM = sensorManager();

% Simulation Handle
ButtonHandle = uicontrol('Style', 'PushButton', ...
                         'String', 'Stop loop', ...
                         'Callback', 'delete(gcbf)');
wL = [];
wR = [];
if (clientID>-1)
    while(1)
       CM.setSpeed(0.8,0);
       wL = [wL CM.wL];
       wR = [wR CM.wR];
       
       % Safe Quit
        if ~ishandle(ButtonHandle)
            disp('Loop stopped by user');
            break;
        end
        pause(0.01); % A NEW LINE
    end
end

sim.simxFinish(-1);
sim.delete();