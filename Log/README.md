# Optimal Constrained Control of a Multi-Unicycle System

## Evaluation 
An example of plotting script is in file "plot_log_file.m"

Declare the Log file name 
```
logFile = "Parsed_TRO_LogSim2.log.mat";
```

The parsing function ProcessLogFile() returns the Logger handle
```
Logger = ProcessLogFile(logFile)
```

Logger handles contains the plotting functions, which use the similarly plotting format for the simulation and the real experiments 
```
Logger.plot_VM_trajectories();
Logger.plot_BLF_all();
Logger.plot_control_output();
```

## Custom Evaluation
User can create their own plots by getting the data from the Logger, then plot them
The Logger instance contains the class to get the necessary data. Particularly

```
[botPose, botZ, botCz, botCost, botInput] = Logger.get_logged_data();
botCost = sum(botCost)';
t_scale = Logger.get_time_axis();
```


## License

MIT

**Free Software, Hell Yeah!**
