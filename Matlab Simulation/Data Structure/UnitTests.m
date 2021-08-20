% Agent Info
agentInfo = Agent_Coordinates_Report(1);
myVar3 = [1,9,1]';
myVar2 = [9,1]';
agentInfo.poseCoord_3d = myVar3;
agentInfo.poseVM_2d = myVar2;
agentInfo.printValue();
isa(agentInfo, 'Agent_Coordinates_Report')


% Voronoi Info
vorInfo = Agent_Voronoi_Report(2);
vorInfo.printValue();
isa(vorInfo, 'Agent_Coordinates_Report')


% Communication Link
bndVertexes_2d = [0, 0; 0,maxY; maxX, maxY; maxX, 0; 0, 0];
comLink = Communication_Link(2, bndVertexes_2d);
comLink.upload(agentInfo);

% Region Config
maxX = 200;
maxY = 200;

%Vor2D_com.exec_partition([30,20;23,22;46,94])

comLink.loop();

rx = comLink.download(2);
rx.printValue();
