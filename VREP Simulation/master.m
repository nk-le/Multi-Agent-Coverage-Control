global sim; global clientID;
sim=remApi('remoteApi'); % using the prototype file (remoteApiProto.m)
sim.simxFinish(-1); % just in case, close all opened connections
clientID = sim.simxStart('127.0.0.1',19999,true,true,5000,5);

global dt;
dt = 1;

% Simulation Handle
ButtonHandle = uicontrol('Style', 'PushButton','String', 'Stop loop', 'Callback', 'delete(gcbf)');

stopFlag = false;
threshold = 1;

% Mission Manager
A = [-1   ,   0;  % x >= 0
     0   ,  -1;  % y >= 0
     -1   ,   1; % y <= x + 6  
     0.6  ,  1;
     0.6 , -1]; 
b = [0, 0, 6, 15.6, 3.6];

worldVertexes = [0,  0; 
                 0,  6;               
                 6,  12;
                 16,  6;
                 6,  0;
                 0,  0];
xrange = max(worldVertexes(:,1));
yrange = max(worldVertexes(:,2));

% Bot Configuration
amountAgent = 5;

vMax = 1;
wMax = 0.5;
v =  linspace(0.2,0.4, amountAgent) .* ones(1,amountAgent);
w0 = linspace(0.2, 0.2, amountAgent) .* ones(1,amountAgent);
K1 = 0.2;
K2 = 0.7;
k_inputScale = [K1 * ones(1, amountAgent)', K2 * ones(1,amountAgent)'];  

randLow = 2*pi; randUp  = 0; centerX = 40; centerY = 40; rXY = 1;
startTheta = randLow + rand(amountAgent,2)*(randUp-randLow);
startX = centerX + rXY * cos(0 : 2*pi/amountAgent : 2*pi);
startY = centerY + rXY * sin(0 : 2*pi/amountAgent : 2*pi );
startPose = [startX', startY', zeros(numel(startX),1)];

cuboidName = ['Cuboid1';'Cuboid2';'Cuboid3';'Cuboid4';'Cuboid5'];%;'Cuboid6'];
com = mission_Manager(amountAgent, worldVertexes(1:end-1,:), xrange, yrange);
com.updateHandle(cuboidName);
%com.setPoint = [0.5,0, 0.25; 
%                0.25, 0.25, 0.25];
com.setPoint = zeros(2,6);
com.displayTarget();

% Controller Handle and Sensor Handle
sensor_hanlde = sensor_Manager_WMR.empty(amountAgent, 0);
controller_handle = control_Manager_Lumi.empty(amountAgent, 0);
logging_hanlde = logging_Manager.empty(amountAgent,0);

sensorBodyHandle = ['lumibot_body1';'lumibot_body2';'lumibot_body3';...
                    'lumibot_body4';'lumibot_body5'];%;'lumibot_body6'];
controlLeftMotorHandle = ['lumibot_leftMotor1';'lumibot_leftMotor2';'lumibot_leftMotor3';...
                          'lumibot_leftMotor4';'lumibot_leftMotor5'];%'lumibot_leftMotor6'];
controlRightMotorHandle = ['lumibot_rightMotor1';'lumibot_rightMotor2';'lumibot_rightMotor3';...
                           'lumibot_rightMotor4';'lumibot_rightMotor5'];%'lumibot_rightMotor6'];
vmHandle = ['Disc1';'Disc2';'Disc3';'Disc4';'Disc5'];%'Disc6'];
poseVM = zeros(amountAgent, 3);

for i  = 1:amountAgent
   sensor_hanlde(i) = sensor_Manager_WMR(sensorBodyHandle(i,:));
   sensor_hanlde(i).updateVMHandle(vmHandle(i,:));
   
   controller_handle(i) = control_Manager_Lumi(controlLeftMotorHandle(i,:), controlRightMotorHandle(i,:)); 
   controller_handle(i).wMax = wMax;
   controller_handle(i).vMax = vMax;
   controller_handle(i).v = v(i);
   controller_handle(i).w0 = w0(i);
   controller_handle(i).K1 = k_inputScale(i,1);
   controller_handle(i).K2 = k_inputScale(i,2);
   
   logging_hanlde(i) = logging_Manager(sensor_hanlde(i), controller_handle(i));
   
   poseVM(i,:) = [sensor_hanlde(i).vmX, sensor_hanlde(i).vmY, sensor_hanlde(i).theta];
end

debugVM = zeros(amountAgent, 2, 100000);
debugW = zeros(amountAgent, 100000);
debugTarget = zeros(amountAgent, 2, 100000);
debugError = zeros(amountAgent, 100000);

start1 = [0.5,0.25,2.5*10^-2];
start2 = [0,0.25,2.5*10^-2];
start3 = [0.25,0.25,2.5*10^-2];

%{
% Bot 1
SM1 = sensor_Manager_WMR('lumibot_body1');
SM1.updateVMHandle('Disc1');
start1 = [0.25,0,2.5*10^-2];

CM1 = control_Manager_Lumi('lumibot_leftMotor1','lumibot_rightMotor1');
CM1.wMax = 0.5;
CM1.vMax = 1;
CM1.w0 = 0.2;
CM1.K1 = 0.3;
CM1.K2 = 0.18;
vConst1 = 0.4;%0.255;

LM1 = logging_Manager(SM1, CM1);

% Bot 2
SM2 = sensor_Manager_WMR('lumibot_body2');
SM2.updateVMHandle('Disc2');
start2 = [0,0.25,2.5*10^-2];

CM2 = control_Manager_Lumi('lumibot_leftMotor2','lumibot_rightMotor2');
CM2.wMax = 0.5;
CM2.vMax = 1;
CM2.w0 = 0.25;
CM2.K1 = 0.25;
CM2.K2 = 0.20;
vConst2 = 0.255;

LM2 = logging_Manager(SM2, CM2);

% Bot 3
SM3 = sensor_Manager_WMR('lumibot_body3');
SM3.updateVMHandle('Disc3');
start3 = [0.25,0.25,2.5*10^-2];

CM3 = control_Manager_Lumi('lumibot_leftMotor3','lumibot_rightMotor3');
CM3.wMax = 0.5;
CM3.vMax = 1;
CM3.w0 = 0.25;
CM3.K1 = 0.25;
CM3.K2 = 0.20;
vConst3 = 0.255;

LM3 = logging_Manager(SM3, CM3);

pose = [SM1.vmX, SM1.vmY, SM1.theta;
        SM2.vmX, SM2.vmY, SM2.theta;
        SM3.vmX, SM3.vmY, SM3.theta;];
%}

% Logging Data
pose1 = [];
poseVM1 = [];
vel1 = [];
wheelRPM1 = [];

% Loop Handling
cnt = 0;

%figure
%hold on; grid on;
%xlim([0,xrange]);
%ylim([0,yrange]);

if (clientID>-1)
    disp('Connected to remote API server');   
    % Setup everything
    % Init and draw at the beginning
    pause(1);
 
    for i  = 1:amountAgent
        sensor_hanlde(i).update();
        sensor_hanlde(i).updateVM(controller_handle(i).v, controller_handle(i).w0)
    end
    %{
    SM1.update();
    SM2.update();
    SM3.update();
    SM1.updateVM(vConst1, CM1.w0);
    SM2.updateVM(vConst2, CM2.w0);   
    SM3.updateVM(vConst3, CM3.w0);   
    %}
    while 1  
        % Control Loop ==========================================================================================
        % Update Mission
        cnt = cnt + 1;
        com.computeTarget(poseVM);
        %com.displayTarget();

        for i  = 1:amountAgent
            % Update Sensor
            sensor_hanlde(i).update();
            sensor_hanlde(i).updateVM(controller_handle(i).v, controller_handle(i).w0)
            tmpPose = [sensor_hanlde(i).vmX, sensor_hanlde(i).vmY, sensor_hanlde(i).theta];
            
            % Control =========================================================================
            controller_handle(i).update_target(com.setPoint(:,i),tmpPose);
            controller_handle(i).BLF_Controller_Log(controller_handle(i).v, A, b, 0.2);
            
            % Logging Data =========================================================================
            poseVM(i,:) = [sensor_hanlde(i).vmX, sensor_hanlde(i).vmY, sensor_hanlde(i).theta];
            logging_hanlde(i).log();
        end
        
        %{
        % Update Data
        SM1.update();
        SM2.update();
        SM3.update();
        
        % Draw virtual Mass
        SM1.updateVM(vConst1, CM1.w0);
        SM2.updateVM(vConst2, CM2.w0);
        SM3.updateVM(vConst3, CM3.w0);
        poseVM = [SM1.vmX, SM1.vmY, SM1.theta;
                SM2.vmX, SM2.vmY, SM2.theta;
                SM3.vmX, SM3.vmY, SM3.theta];
        
        % Update Controller 
        CM1.orbitingControlWithConstraint(vConst1, CM1.w0, SM1.vmX, SM1.vmY, SM1.theta, com.setPoint(1,1), com.setPoint(2,1));
        CM2.orbitingControlWithConstraint(vConst2, CM2.w0, SM2.vmX, SM2.vmY, SM2.theta, com.setPoint(1,2), com.setPoint(2,2));
        CM3.orbitingControlWithConstraint(vConst3, CM3.w0, SM3.vmX, SM3.vmY, SM3.theta, com.setPoint(1,3), com.setPoint(2,3));
      
        % Logging Data ==========================================================================================       
        LM1.log();
        LM2.log();
        LM3.log();
          %}
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


