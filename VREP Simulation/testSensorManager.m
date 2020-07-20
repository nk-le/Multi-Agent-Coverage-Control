global sim; global clientID;
sim=remApi('remoteApi'); % using the prototype file (remoteApiProto.m)
sim.simxFinish(-1); % just in case, close all opened connections
clientID = sim.simxStart('127.0.0.1',19999,true,true,5000,5);

% Variables and Handle
SM = sensorManager();

if (clientID>-1)
    while(1)
       SM.getPosition();
       disp("Pos X: ");
       disp(SM.px);
       disp("Pos Y: ");
       disp(SM.py);
    end
end

sim.simxFinish(-1);
sim.delete();