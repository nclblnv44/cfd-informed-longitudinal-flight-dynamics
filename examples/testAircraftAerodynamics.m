projectFolder = fileparts(fileparts(mfilename("fullpath")));
addpath(projectFolder);
setupProject();

load(fullfile(projectFolder, "data", "longitudinalTrim.mat"), "trim", "aircraft");
load(fullfile(projectFolder, "data", "polarNACA0012.mat"), "polar");
load(fullfile(projectFolder, "data", "liftCurveParameters.mat"), "alpha0L_rad");

[L, D, M] = aircraftAerodynamics( ...
    trim.V, trim.alpha_rad, trim.deltaElevator_rad, ...
    aircraft, polar, trim.aWing, alpha0L_rad);

fprintf("Portanza:   %.6f N\n", L);
fprintf("Resistenza: %.6f N\n", D);
fprintf("Momento:    %.10e N*m\n", M);