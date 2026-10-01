clear;
clc;

projectFolder = fileparts(fileparts(mfilename("fullpath")));
addpath(projectFolder);
setupProject();



load(fullfile(projectFolder, "data","polarNACA0012.mat"),"polar");

alpha_deg = 5;
V = 52;
rho = 1.225;
S = 14;
c_bar = 1.75;

[L,D,M,CL,CD,Cm] = aerodynamicForces(alpha_deg, V, rho, S, c_bar, polar);

fprintf("Angolo d'attacco: %.1f gradi\n", alpha_deg);
fprintf("CL = %.6f\n", CL);
fprintf("CD = %.6f\n", CD);
fprintf("Cm = %.6f\n", Cm);

fprintf("\nPortanza:    %.2f N\n", L);
fprintf("Resistenza:  %.2f N\n", D);
fprintf("Momento:     %.2f N*m\n", M);