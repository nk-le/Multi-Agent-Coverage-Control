# Optimal Constrained Control of a Multi-Unicycle System
Folder Structure:

- Latex Thesis
This folder contains source code for the final report and the presentation.

- Matlab Simulation
Contains matlab codes of the project. There are 3 main parts:
The dynamic of the wheeled mobile robot 
The controller class, which contains the proposed control method and can be added more controllers for test and evaluation.
The mission computer class, which compute the Voronoi partition. This class is motivated by the code of "Aaron Becker"

Run "Master.m" to start the programm and "Evaluation.m" to assess the controller afterwards. The parameters of WMR and the shape of coverage region 
can be justified directly in "Master.m" by following the comments.

Other Codes are used to help design the controller, such as "xxx_BLF.m" was implemented to design the Barrier Lyapunov Function.

- VRep Simulation
Contains codes to test the designed controller within VREP Environment. There are 3 main parts:
control_Manager_Lumi: send control input from matlab to vrep, designed only for Lumi_bot in VREP environment
logging_Manager: save data, such as control input, position, velocity of WMR
sensor_Manager_WMR: Send measured signals to controller
mission_Manager: Compute Voronoi Tessellation and target.

Start VREP environment and run simpleTest to test connection with VREP, run testControlManager, testSensorManager to test the signals sent and received
Start VREP environment and run master to simulate the coverage control

- Simulation Video
Recored video and pictures of the simulation.


 

