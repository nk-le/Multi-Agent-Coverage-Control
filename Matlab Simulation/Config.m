function [nAgent, vConstList, wOrbitList, bndVertexes, bndCoeff, startPose, visualizationOn, maxIter] = Config()
    %% Simulation configuration
    global dt;                  % Global simulation time to avoid undefined behaviour    
    dt = 0.005;
    maxIter = 50000;            % Maximum iteration of simulation

    %% SIMULATION CONFIGURATION
    rng(4);
    nAgent = 6;

    %% COVERAGE CONFIGURATION
    % BOT & CONTROLLER
    vConstList =  linspace(10, 20, nAgent) .* ones(1,nAgent);
    wOrbitList = linspace(0.4, 0.8, nAgent) .* ones(1,nAgent);
    vConstList = 30 .* ones(1,nAgent);
    wOrbitList = 1.2 .* ones(1,nAgent);
    wMax = 3.2;
    K1 = wMax - wOrbitList;
    K2 = 1;
   
    %% Region Config - Shape of the coverage region
    % Adjust the range to varying the region with the same shape
    maxX = 100;
    maxY = 200;
    % Adjust the edges of the coverage region. The using one is specific
    % for the rectangle shape
    bndVertexes = [0, 0; 0,maxY; maxX,maxY; maxX, 0; 0, 0];
    % The cooeficients of the convex region that satisfies 
    % A(j,1)x + A(j,2)y - b(j) < 0
    % NOTE:
    %   - Shift the region so that x, y > 0 for simplicity
    A = [-1 , 0; 1 , 0; 0 , 1; 0 , -1];
    b = [0, maxX, maxY, 0];

    %% Initial state - Initial Poses of agent.
    % Feel free to modify the [startX] and [startY]
    % The following example deploys a group of agents around the coord          
    % [50,50] initally
    centerCoord = [50, 50];    % deploy all agents near this coord
    rXY = 10;                   % agents formualates a circle at the beginning
    startX = centerCoord(1) + rXY * cos(0 : 2*pi/nAgent : 2*pi);
    startY = centerCoord(2) + rXY * sin(0 : 2*pi/nAgent : 2*pi);
    
    %% DEFAULT - Assign the configured variables into objects and return
    visualizationOn = false;
    bndCoeff = [A, b'];
    startPose = [startX', startY', zeros(numel(startX),1)];
end