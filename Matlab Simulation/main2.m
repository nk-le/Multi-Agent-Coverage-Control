function [logger] = main()
    global visualization;
    global nAgent;
    global dt;

    %% PARAMETER
    rng(4);
    nAgent = 3;
    dt = 0.0001;

    
    % BOT & CONTROLLER
    vConstList =  linspace(10, 20, nAgent) .* ones(1,nAgent);
    wOrbitList = linspace(0.2, 0.4, nAgent) .* ones(1,nAgent);
    wMax = 3.2;
    K1 = wMax - wOrbitList;
    K2 = 1;

   
    %% Region Config
    offset = 20;
    maxX = 100;
    maxY = 200;

    A = [-1 , 0; 1 , 0; 0 , 1; 0 , -1];
    b = [0, maxX, maxY, 0];
    bndCoeff = [A, b'];
    worldVertexes = [0, 0; 0,maxY; maxX,maxY; maxX, 0; 0, 0];

     %% Initial state
    centerX = 50;
    centerY = 50;
    rXY = 1;
    startX = centerX + rXY * cos(0 : 2*pi/nAgent : 2*pi);
    startY = centerY + rXY * sin(0 : 2*pi/nAgent : 2*pi);
    startPose = [startX', startY', zeros(numel(startX),1)];
    
    
    %% Simulation handler
    masterCom = Centralized_Controller(nAgent, bndCoeff, worldVertexes, startPose, vConstList, wOrbitList);
    % TODO
    %masterCom.setupControlParameter(0,1,2,3);
    
    %% Visualization handler
    env = MultiRobotEnv(nAgent);
    env((1:nAgent), startPose');
    hold on; grid on; axis equal
    xlim([0 - offset, maxX + offset]);
    ylim([0 - offset, maxY + offset]);
    while(1)
        % Main process
        newPose = masterCom.loop();
        
        % Update Visualization
        % env((1:nAgent), newPose');
        
        % Logging
        logger = masterCom;
    end
end