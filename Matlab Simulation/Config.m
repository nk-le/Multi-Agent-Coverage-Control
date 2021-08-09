function [simConfig, regionConfig, agentConfig] = Config()
    %% Simulation configuration 
    rng(4);
    simConfig.dt = 0.001;
    simConfig.maxIter = 40000;
    simConfig.nAgent = 6;
    simConfig.visualization = false;
    
    %% Region Config - Shape of the coverage region
    % Adjust the range to varying the region with the same shape
    regionConfig.maxX = 800;
    regionConfig.maxY = 600;
    % Adjust the edges of the coverage region. The using one is specific
    % for the rectangle shape
    regionConfig.bndVertexes = [0, 0; 0,regionConfig.maxY; regionConfig.maxX,regionConfig.maxY; regionConfig.maxX, 0; 0, 0];
    % The cooeficients of the convex region that satisfies 
    % A(j,1)x + A(j,2)y - b(j) < 0
    % NOTE:
    %   - Shift the region so that x, y > 0 for simplicity
    A = [-1 , 0; 1 , 0; 0 , 1; 0 , -1];
    b = [0, regionConfig.maxX, regionConfig.maxY, 0]';
    regionConfig.BoundariesCoeff = [A b];
    
    
    %% BOT & CONTROLLER Config - Initial Poses of agent.
    agentConfig.vConstList = 20 .* ones(1,simConfig.nAgent); % linspace(10, 20, nAgent) .* ones(1,nAgent);
    agentConfig.wOrbitList = 1.2 .* ones(1,simConfig.nAgent); % linspace(0.4, 0.8, nAgent) .* ones(1,nAgent);
    % Feel free to modify the [startX] and [startY]
    % The following example deploys a group of agents around the coord          
    % centerCoord initally
    centerCoord = [200, 100];    % deploy all agents near this coord
    rXY = 50;                   % agents formualates a circle at the beginning
    agentConfig.startPose = zeros(simConfig.nAgent,3);
    agentConfig.startPose(:,1) = centerCoord(1) + rXY.*rand(simConfig.nAgent,1); %x
    agentConfig.startPose(:,2) = centerCoord(2) + rXY.*rand(simConfig.nAgent,1); %y
    agentConfig.startPose(:,3) = zeros(simConfig.nAgent,1); %theta
end