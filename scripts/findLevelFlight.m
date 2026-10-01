clear;
clc;

projectFolder = fileparts(fileparts(mfilename("fullpath")));
addpath(projectFolder);
setupProject();
load(fullfile(projectFolder, "data", "polarNACA0012.mat"), "polar");
load(fullfile(projectFolder, "data", "liftCurveParameters.mat"), "a0","alpha0L_rad");

aircraft = aircraftParameters();


aWing = a0 / (1 + a0 / (pi * aircraft.e * aircraft.AR));

W = aircraft.weight;
q = 0.5*aircraft.rho*(aircraft.V0)^2;

fprintf("Peso: %.2f N\n", W);
fprintf("Pressione dinamica: %.2f Pa\n", q);

CL_required = W/(q*aircraft.S);

alphaTrim_rad = alpha0L_rad + CL_required / aWing;
alphaTrim_deg = rad2deg(alphaTrim_rad);

fprintf("Pendenza profilo 2D: %.4f rad^-1\n", a0);
fprintf("Pendenza ala finita: %.4f rad^-1\n", aWing);
fprintf("Angolo di trim: %.4f gradi\n", alphaTrim_deg);

%% Check

CL_check = aWing * (alphaTrim_rad - alpha0L_rad);

L_check = q * aircraft.S * CL_check;

liftError = L_check - W;

fprintf("Portanza calcolata: %.2f N\n", L_check);
fprintf("Peso:               %.2f N\n", W);
fprintf("Errore:             %.6f N\n", liftError);

[cl_2D_trim, cd_2D_trim, cm_2D_trim] = airfoilCoefficients(alphaTrim_deg, polar);

CD_induced_trim = (CL_check^2)/(pi*aircraft.e*aircraft.AR);
CD_total_trim = CD_induced_trim + cd_2D_trim;

D_trim = q*aircraft.S*CD_total_trim;

T_required = D_trim;

fprintf("\nCondizione di volo orizzontale:\n");
fprintf("Velocità:              %.2f m/s\n", aircraft.V0);
fprintf("CL richiesto:          %.4f\n", CL_required);
fprintf("Angolo d'attacco:      %.4f gradi\n", alphaTrim_deg);
fprintf("CD profilo 2D:         %.6f\n", cd_2D_trim);
fprintf("CD indotto:            %.6f\n", CD_induced_trim);
fprintf("CD totale:             %.6f\n", CD_total_trim);
fprintf("Portanza:              %.2f N\n", L_check);
fprintf("Resistenza:            %.2f N\n", D_trim);
fprintf("Spinta richiesta:      %.2f N\n", T_required);
fprintf("Errore sulla portanza: %.6f N\n", liftError);
