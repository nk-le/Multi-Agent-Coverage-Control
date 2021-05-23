function [logger] = main()
    global visualization;
    global nAgent;
    global dt;

    %% PARAMETER
    rng(4);
    nAgent = 6;
    dt = 0.001;

    
    % BOT & CONTROLLER
    vConstList =  linspace(50, 80, nAgent) .* ones(1,nAgent);
    wOrbitList = linspace(1, 1.6, nAgent) .* ones(1,nAgent);
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
    
    while(1)
        % Main process
        newPose = masterCom.loop();
        
        % Update Visualization
        env((1:nAgent), newPose');
        
        % Logging
        logger = masterCom;
    end
end