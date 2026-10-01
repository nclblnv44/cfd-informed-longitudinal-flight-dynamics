clear;
clc;
close all;

%% 1. Percorsi e dati del modello
projectFolder = fileparts(fileparts(mfilename("fullpath")));
addpath(projectFolder);
setupProject();

load(fullfile(projectFolder, "data", "longitudinalTrim.mat"), "trim");
load(fullfile(projectFolder, "data", "polarNACA0012.mat"), "polar");
load(fullfile(projectFolder, "data", "liftCurveParameters.mat"), ...
    "a0", "alpha0L_rad");

aircraft = aircraftParameters();
aWing = a0 / (1 + a0 / (pi * aircraft.e * aircraft.AR));

%% 2. Simulazione con i parametri nominali
simulation = simulateElevatorPulseCase( ...
    aircraft, trim, polar, aWing, alpha0L_rad);
time = simulation.time;
states = simulation.states;
state0 = simulation.state0;
alpha_deg = simulation.alpha_deg;
gamma_deg = simulation.gamma_deg;
deltaElevator_deg = simulation.deltaElevator_deg;
thrust = simulation.thrust;

V = states(:, 1);
theta_deg = rad2deg(states(:, 3));
pitchRate_deg_s = rad2deg(states(:, 4));
h = states(:, 5);

[L0, ~, M0] = aircraftAerodynamics( ...
    trim.V, trim.alpha_rad, trim.deltaElevator_rad, ...
    aircraft, polar, aWing, alpha0L_rad);

fprintf("ESPERIMENTO: IMPULSO SULL'ELEVATORE\n");
fprintf("---------------------------------\n");
fprintf("Velocita iniziale:         %.3f m/s\n", trim.V);
fprintf("Portanza iniziale:         %.3f N\n", L0);
fprintf("Momento iniziale:          %.6e N*m\n", M0);
fprintf("Spinta costante:           %.3f N\n", thrust);
fprintf("Elevatore al trim:         %.3f deg\n", trim.deltaElevator_deg);
fprintf("Elevatore durante impulso: %.3f deg\n", ...
    trim.deltaElevator_deg + simulation.pulseAmplitude_deg);
fprintf("Intervallo impulso:        %.2f - %.2f s\n", ...
    simulation.pulseStart, simulation.pulseEnd);

fprintf("\nSCOSTAMENTI MASSIMI DAL TRIM\n");
fprintf("---------------------------\n");
fprintf("Velocita:             %.6f m/s\n", max(abs(V - state0(1))));
fprintf("Angolo d'attacco:     %.6f deg\n", ...
    max(abs(alpha_deg - trim.alpha_deg)));
fprintf("Assetto:              %.6f deg\n", ...
    max(abs(theta_deg - rad2deg(state0(3)))));
fprintf("Velocita beccheggio:  %.6f deg/s\n", max(abs(pitchRate_deg_s)));
fprintf("Quota:                %.6f m\n", max(abs(h - state0(5))));

%% 3. Grafici della risposta
fig = figure("Name", "Risposta all'impulso di elevatore");
tiledlayout(3, 2);
timeBoundaries = [0; simulation.pulseStart; ...
    simulation.pulseEnd; time(end)];
deltaTrim_deg = trim.deltaElevator_deg;
deltaPulse_deg = deltaTrim_deg + simulation.pulseAmplitude_deg;

nexttile;
stairs(timeBoundaries, ...
    [deltaTrim_deg; deltaPulse_deg; deltaTrim_deg; deltaTrim_deg], ...
    "LineWidth", 1.5);
xlabel("Tempo [s]"); ylabel("\delta_e [deg]");
title("Comando dell'elevatore"); grid on; xlim([0, time(end)]);

nexttile;
plot(time, alpha_deg, "LineWidth", 1.5);
yline(trim.alpha_deg, "--", "Trim");
xlabel("Tempo [s]"); ylabel("\alpha [deg]");
title("Angolo d'attacco"); grid on;

nexttile;
plot(time, theta_deg, "LineWidth", 1.5);
yline(rad2deg(state0(3)), "--", "Trim");
xlabel("Tempo [s]"); ylabel("\theta [deg]");
title("Assetto"); grid on;

nexttile;
plot(time, pitchRate_deg_s, "LineWidth", 1.5);
yline(0, "--");
xlabel("Tempo [s]"); ylabel("q_{pitch} [deg/s]");
title("Velocita di beccheggio"); grid on;

nexttile;
plot(time, V, "LineWidth", 1.5);
yline(trim.V, "--", "Trim");
xlabel("Tempo [s]"); ylabel("V [m/s]");
title("Velocita"); grid on;

nexttile;
plot(time, h, "LineWidth", 1.5);
yline(state0(5), "--", "Quota iniziale");
xlabel("Tempo [s]"); ylabel("h [m]");
title("Quota relativa"); grid on;

%% 4. Salvataggio
resultsFolder = fullfile(projectFolder, "results");
save(fullfile(resultsFolder, "elevator_pulse_simulation.mat"), ...
    "simulation", "aircraft", "trim");
exportgraphics(fig, fullfile(resultsFolder, "elevator_pulse_response.png"), ...
    "Resolution", 200);

fprintf("\nCONDIZIONE FINALE A %.2f SECONDI\n", time(end));
fprintf("---------------------------------\n");
fprintf("Scostamento velocita:          %+.6f m/s\n", V(end) - trim.V);
fprintf("Scostamento angolo d'attacco:  %+.6f deg\n", ...
    alpha_deg(end) - trim.alpha_deg);
fprintf("Scostamento assetto:           %+.6f deg\n", ...
    theta_deg(end) - rad2deg(state0(3)));
fprintf("Angolo della traiettoria:      %+.6f deg\n", gamma_deg(end));
fprintf("Velocita di beccheggio:        %+.6f deg/s\n", ...
    pitchRate_deg_s(end));
fprintf("Variazione di quota:           %+.6f m\n", h(end) - state0(5));
