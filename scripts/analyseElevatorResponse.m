clear;
clc;
close all;

%% Analisi dei risultati gia salvati, senza ripetere la simulazione
projectFolder = fileparts(fileparts(mfilename("fullpath")));
addpath(projectFolder);
setupProject();
resultsFolder = fullfile(projectFolder, "results");
load(fullfile(resultsFolder, "elevator_pulse_simulation.mat"), ...
    "simulation", "aircraft", "trim");
load(fullfile(projectFolder, "data", "polarNACA0012.mat"), "polar");
load(fullfile(projectFolder, "data", "liftCurveParameters.mat"), ...
    "a0", "alpha0L_rad");

t = simulation.time;
x = simulation.states;
x0 = simulation.state0;
alpha_deg = rad2deg(x(:, 3) - x(:, 2));
dAlpha_deg = alpha_deg - rad2deg(x0(3) - x0(2));
dTheta_deg = rad2deg(x(:, 3) - x0(3));
q_deg_s = rad2deg(x(:, 4));
gamma_deg = rad2deg(x(:, 2));
dV = x(:, 1) - x0(1);
dh = x(:, 5) - x0(5);

beforePulse = t < simulation.pulseStart;
early = t >= simulation.pulseEnd & t <= simulation.pulseEnd + 3;
late = t >= t(end) - 5;
firstPulseIndex = find(t > simulation.pulseStart, 1);

%% Linearizzazione numerica locale al trim
aWing = a0 / (1 + a0 / (pi * aircraft.e * aircraft.AR));
[A, eigenvalues, oscillatoryModes] = linearizeLongitudinal( ...
    x0, simulation.thrust, trim.deltaElevator_rad, ...
    aircraft, polar, aWing, alpha0L_rad);

%% Riepilogo numerico e salvataggio
report = sprintf("ANALISI DELLA RISPOSTA ALL'IMPULSO\n");
pitchRateTailScale = 0;
if isfield(aircraft, "pitchRateTailScale")
    pitchRateTailScale = aircraft.pitchRateTailScale;
end
report = [report sprintf("Fattore q_pitch della coda: %.3f\n", ...
    pitchRateTailScale)];
report = [report sprintf("Iyy: %.1f kg*m^2\n", aircraft.Iyy)];
report = [report sprintf("Durata analizzata: %.2f s\n", t(end))];
report = [report sprintf("Errore V prima dell'impulso: %.6e m/s\n", max(abs(dV(beforePulse))))];
report = [report sprintf("Errore alpha prima dell'impulso: %.6e deg\n", max(abs(dAlpha_deg(beforePulse))))];
report = [report sprintf("Prima velocita di beccheggio dopo il comando: %+.6f deg/s\n", q_deg_s(firstPulseIndex))];
report = [report sprintf("\nScostamenti finali:\n")];
report = [report sprintf("V: %+.9f m/s\nalpha: %+.9f deg\ntheta: %+.9f deg\ngamma: %+.9f deg\nq_pitch: %+.9f deg/s\nh: %+.9f m\n", ...
    dV(end), dAlpha_deg(end), dTheta_deg(end), gamma_deg(end), q_deg_s(end), dh(end))];
report = [report sprintf("\nMassimi assoluti dopo il ritorno al trim (%.1f-%.1f s):\nalpha: %.9f deg\nq_pitch: %.9f deg/s\n", ...
    simulation.pulseEnd, simulation.pulseEnd + 3, max(abs(dAlpha_deg(early))), max(abs(q_deg_s(early))))];
report = [report sprintf("\nMassimi assoluti negli ultimi 5 s:\nalpha: %.9f deg\nq_pitch: %.9f deg/s\n", ...
    max(abs(dAlpha_deg(late))), max(abs(q_deg_s(late))))];
report = [report sprintf("\nAutovalori del modello linearizzato al trim [1/s]:\n")];
for k = 1:numel(eigenvalues)
    report = [report sprintf("%+.9f %+.9fi\n", real(eigenvalues(k)), imag(eigenvalues(k)))];
end
for k = 1:numel(oscillatoryModes)
    lambda = oscillatoryModes(k);
    period = 2 * pi / abs(imag(lambda));
    report = [report sprintf("Modo %d: periodo %.6f s", k, period)];
    if real(lambda) < 0
        report = [report sprintf(", tempo di decadimento e-fold %.6f s\n", -1 / real(lambda))];
    else
        report = [report sprintf(", parte reale non negativa\n")];
    end
end
fprintf("%s", report);
fid = fopen(fullfile(resultsFolder, "elevator_response_summary.txt"), "w");
if fid < 0
    error("Impossibile salvare il riepilogo dell'analisi.");
end
fprintf(fid, "%s", report);
fclose(fid);
save(fullfile(resultsFolder, "elevator_response_analysis.mat"), ...
    "A", "eigenvalues", "oscillatoryModes");

%% Grafici: risposta iniziale e andamento lento
fig = figure("Name", "Analisi della risposta all'elevatore", ...
    "Position", [100, 100, 1200, 850]);
tiledlayout(3, 2);
nexttile;
plot(t, dAlpha_deg, "LineWidth", 1.4); grid on;
xlim([0, min(6, t(end))]);
xlabel("Tempo [s]"); ylabel("Delta alpha [deg]"); title("Angolo d'attacco: risposta iniziale");
nexttile;
plot(t, dV, "LineWidth", 1.4); grid on;
xlabel("Tempo [s]"); ylabel("Delta V [m/s]"); title("Variazione di velocita");
nexttile;
plot(t, q_deg_s, "LineWidth", 1.4); grid on;
xlim([0, min(6, t(end))]);
xlabel("Tempo [s]"); ylabel("q pitch [deg/s]"); title("Beccheggio: risposta iniziale");
nexttile;
plot(t, gamma_deg, "LineWidth", 1.4); grid on;
xlabel("Tempo [s]"); ylabel("Gamma [deg]"); title("Inclinazione della traiettoria");
nexttile;
plot(t, dTheta_deg, "LineWidth", 1.4); grid on;
xlim([0, min(6, t(end))]);
xlabel("Tempo [s]"); ylabel("Delta theta [deg]"); title("Assetto: risposta iniziale");
nexttile;
plot(t, dh, "LineWidth", 1.4); grid on;
xlabel("Tempo [s]"); ylabel("Delta h [m]"); title("Variazione di quota");
exportgraphics(fig, fullfile(resultsFolder, "elevator_response_analysis.png"), "Resolution", 180);
