clear;
clc;

projectFolder = fileparts(fileparts(mfilename("fullpath")));
addpath(projectFolder);
setupProject();
load(fullfile(projectFolder, "data", "polarNACA0012.mat"), "polar");
load(fullfile(projectFolder, "data", "liftCurveParameters.mat"), "a0","alpha0L_rad");

aircraft = aircraftParameters();


aWing = a0 / (1 + a0 / (pi * aircraft.e * aircraft.AR));


alpha_deg = (-4:0.1:12);

alpha_rad = deg2rad(alpha_deg);

CL_wing = aWing * (alpha_rad-alpha0L_rad);

[cl_2D, cd_2D, cm_2D] = airfoilCoefficients(alpha_deg, polar);

cd_induced = (CL_wing.^2)/(pi*aircraft.e*aircraft.AR);

CD_wing = cd_2D + cd_induced;


[~, index5] = min(abs(alpha_deg - 5));

fprintf("Risultati dell'ala finita a %.1f gradi:\n", ...
    alpha_deg(index5));

fprintf("CL ala       = %.6f\n", CL_wing(index5));
fprintf("CD profilo   = %.6f\n", cd_2D(index5));
fprintf("CD indotta   = %.6f\n", cd_induced(index5));
fprintf("CD totale    = %.6f\n", CD_wing(index5));

figure("Name", "Confronto profilo 2D e ala finita");

tiledlayout(1, 2);

nexttile;
plot(alpha_deg, cl_2D, "--", "LineWidth", 1.5);
hold on;
plot(alpha_deg, CL_wing, "LineWidth", 1.5);
grid on;
xlabel("\alpha [deg]");
ylabel("C_L");
title("Portanza");
legend("Profilo CFD 2D", "Ala finita", ...
    "Location", "best");

nexttile;
plot(alpha_deg, cd_2D, "--", "LineWidth", 1.5);
hold on;
plot(alpha_deg, CD_wing, "LineWidth", 1.5);
grid on;
xlabel("\alpha [deg]");
ylabel("C_D");
title("Resistenza");
legend("Profilo CFD 2D", "Ala finita", ...
    "Location", "best");

exportgraphics(gcf, fullfile(projectFolder, "results", "finite_wing_comparison.png"), ...
    "Resolution", 200);
