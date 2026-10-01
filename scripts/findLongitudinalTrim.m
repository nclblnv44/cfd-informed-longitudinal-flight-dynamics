clear;
clc;
close all;

%% 1. Caricamento dei dati e parametri
projectFolder = fileparts(fileparts(mfilename("fullpath")));
addpath(projectFolder);
setupProject();

load(fullfile(projectFolder, "data", "polarNACA0012.mat"), "polar");
load(fullfile(projectFolder, "data", "liftCurveParameters.mat"), ...
    "a0", "alpha0L_rad");
aircraft = aircraftParameters();
aWing = a0 / (1 + a0 / (pi * aircraft.e * aircraft.AR));

%% 2. Trim del modello nominale lineare
trim = computeLongitudinalTrim( ...
    aircraft, polar, aWing, alpha0L_rad);
CL_required = aircraft.weight / (trim.q * aircraft.S);
alphaInitial_rad = alpha0L_rad + CL_required / aWing;

fprintf("TRIM LONGITUDINALE DEL MODELLO LINEARE\n");
fprintf("-----------------------------------------\n");
fprintf("Velocita:                  %.2f m/s\n", trim.V);
fprintf("Peso:                      %.2f N\n", aircraft.weight);
fprintf("Pressione dinamica:        %.2f Pa\n", trim.q);
fprintf("Pendenza ala finita:       %.6f rad^-1\n", aWing);
fprintf("Volume di coda:            %.6f\n", aircraft.VH);

fprintf("\nConfronto degli angoli:\n");
fprintf("Angolo con sola ala:       %.6f deg\n", rad2deg(alphaInitial_rad));
fprintf("Angolo con ala e coda:     %.6f deg\n", trim.alpha_deg);
fprintf("Deflessione elevatore:     %.6f deg\n", trim.deltaElevator_deg);

fprintf("\nCoefficienti al trim:\n");
fprintf("CL ala:                    %.8f\n", trim.CL_wing);
fprintf("CL coda:                   %.8f\n", trim.CL_tail);
fprintf("Cm ala:                   %.8f\n", trim.Cm_wing);
fprintf("Cm totale:                 %.10e\n", trim.Cm_total);

fprintf("\nVerifica degli equilibri:\n");
fprintf("Portanza ala:              %.6f N\n", trim.L_wing);
fprintf("Forza coda:                %.6f N\n", trim.L_tail);
fprintf("Portanza totale:           %.6f N\n", trim.L_total);
fprintf("Errore sulla portanza:     %.10e N\n", trim.liftError);
fprintf("Momento totale:            %.10e N*m\n", trim.M_total);
fprintf("Spinta di equilibrio:      %.6f N\n", trim.thrust);

%% 3. Salvataggio della condizione nominale
outputFile = fullfile(projectFolder, "data", "longitudinalTrim.mat");
save(outputFile, "trim", "aircraft");
fprintf("\nCondizione di trim salvata in:\n%s\n", outputFile);
