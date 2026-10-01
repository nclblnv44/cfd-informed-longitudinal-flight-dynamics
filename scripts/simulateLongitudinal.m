clear;
clc;
close all;

%% 1. Percorsi e caricamento
projectFolder = fileparts(fileparts(mfilename("fullpath")));
addpath(projectFolder);
setupProject();

load(fullfile(projectFolder, "data", "longitudinalTrim.mat"), ...
    "trim");

load(fullfile(projectFolder, "data", "polarNACA0012.mat"), ...
    "polar");

load(fullfile(projectFolder, "data", "liftCurveParameters.mat"), ...
    "a0", "alpha0L_rad");

aircraft = aircraftParameters();

aWing = a0 / ...
    (1 + a0 / (pi * aircraft.e * aircraft.AR));

%% 2. Comandi costanti al trim
deltaElevator_rad = trim.deltaElevator_rad;

% La spinta equilibra la resistenza al trim.
[L_trim, D_trim, M_trim] = aircraftAerodynamics( ...
    trim.V, trim.alpha_rad, deltaElevator_rad, ...
    aircraft, polar, aWing, alpha0L_rad);

thrust = D_trim;

%% 3. Condizione iniziale
V0 = trim.V;
gamma0 = 0;                    % traiettoria orizzontale [rad]
theta0 = trim.alpha_rad;        % theta = alpha quando gamma = 0
pitchRate0 = 0;                 % [rad/s]
h0 = 0;                        % quota rispetto al riferimento [m]

state0 = [
    V0;
    gamma0;
    theta0;
    pitchRate0;
    h0
];

%% 4. Funzione delle derivate
dynamics = @(t, state) longitudinalDynamics( ...
    t, state, thrust, deltaElevator_rad, ...
    aircraft, polar, aWing, alpha0L_rad);

%% 5. Verifica iniziale del trim
initialDerivative = dynamics(0, state0);

fprintf("VERIFICA DELLA CONDIZIONE INIZIALE\n");
fprintf("---------------------------------\n");
fprintf("Portanza:              %.6f N\n", L_trim);
fprintf("Peso:                  %.6f N\n", aircraft.weight);
fprintf("Spinta:                %.6f N\n", thrust);
fprintf("Momento:               %.6e N*m\n", M_trim);

fprintf("\nDerivate iniziali:\n");
fprintf("Vdot:                  %.6e m/s^2\n", initialDerivative(1));
fprintf("gammaDot:              %.6e rad/s\n", initialDerivative(2));
fprintf("thetaDot:              %.6e rad/s\n", initialDerivative(3));
fprintf("pitchRateDot:          %.6e rad/s^2\n", initialDerivative(4));
fprintf("hDot:                  %.6e m/s\n", initialDerivative(5));

if any(abs(initialDerivative) > 1e-6)
    error(["La condizione iniziale non e in equilibrio. " ...
        "Rieseguire findLongitudinalTrim e controllare i parametri."]);
end

%% 6. Integrazione nel tempo
simulationTime = [0, 20];       % [s]

options = odeset( ...
    "RelTol", 1e-8, ...
    "AbsTol", 1e-10, ...
    "MaxStep", 0.1);

[time, states] = ode45( ...
    dynamics, simulationTime, state0, options);

%% 7. Estrazione delle variabili
V = states(:, 1);
gamma_rad = states(:, 2);
theta_rad = states(:, 3);
pitchRate_rad_s = states(:, 4);
h = states(:, 5);

alpha_rad = theta_rad - gamma_rad;

gamma_deg = rad2deg(gamma_rad);
theta_deg = rad2deg(theta_rad);
pitchRate_deg_s = rad2deg(pitchRate_rad_s);
alpha_deg = rad2deg(alpha_rad);

%% 8. Controllo del mantenimento del trim
fprintf("\nVARIAZIONI MASSIME DURANTE LA SIMULAZIONE\n");
fprintf("---------------------------------------\n");
fprintf("Velocita:              %.6e m/s\n", max(abs(V - V0)));
fprintf("Angolo traiettoria:    %.6e deg\n", ...
    max(abs(gamma_deg - rad2deg(gamma0))));
fprintf("Angolo di assetto:     %.6e deg\n", ...
    max(abs(theta_deg - rad2deg(theta0))));
fprintf("Velocita beccheggio:   %.6e deg/s\n", ...
    max(abs(pitchRate_deg_s)));
fprintf("Quota:                 %.6e m\n", max(abs(h - h0)));

%% 9. Grafici
fig = figure("Name", "Volo longitudinale al trim");
tiledlayout(3, 2);

nexttile;
plot(time, V, "LineWidth", 1.5);
xlabel("Tempo [s]");
ylabel("V [m/s]");
title("Velocita");
grid on;

nexttile;
plot(time, alpha_deg, "LineWidth", 1.5);
xlabel("Tempo [s]");
ylabel("\alpha [deg]");
title("Angolo d'attacco");
grid on;

nexttile;
plot(time, theta_deg, "LineWidth", 1.5);
xlabel("Tempo [s]");
ylabel("\theta [deg]");
title("Assetto");
grid on;

nexttile;
plot(time, gamma_deg, "LineWidth", 1.5);
xlabel("Tempo [s]");
ylabel("\gamma [deg]");
title("Angolo della traiettoria");
grid on;

nexttile;
plot(time, pitchRate_deg_s, "LineWidth", 1.5);
xlabel("Tempo [s]");
ylabel("q_{pitch} [deg/s]");
title("Velocita di beccheggio");
grid on;

nexttile;
plot(time, h, "LineWidth", 1.5);
xlabel("Tempo [s]");
ylabel("h [m]");
title("Quota relativa");
grid on;

%% 10. Salvataggio
resultsFolder = fullfile(projectFolder, "results");

if ~isfolder(resultsFolder)
    mkdir(resultsFolder);
end

save(fullfile(resultsFolder, "longitudinal_trim_simulation.mat"), ...
    "time", "states", "state0", "thrust", ...
    "deltaElevator_rad", "aircraft");

exportgraphics(fig, ...
    fullfile(resultsFolder, "longitudinal_trim_simulation.png"), ...
    "Resolution", 200);

fprintf("\nRisultati salvati nella cartella:\n%s\n", resultsFolder);