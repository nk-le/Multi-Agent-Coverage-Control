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
comLink = Communication_Link(2);
comLink.upload(agentInfo);
rx = comLink.download(2);
rx.printValue();

% Region Config
maxX = 200;
maxY = 200;

bndVertexes_2d = [0, 0; 0,maxY; maxX, maxY; maxX, 0; 0, 0];
Vor2D_com = Voronoi2D_Handler(3);
Vor2D_com.setup(bndVertexes_2d);
Vor2D_com.partition([30,20;23,22;46,94])

