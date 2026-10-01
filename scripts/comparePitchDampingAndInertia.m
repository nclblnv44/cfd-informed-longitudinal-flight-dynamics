clear;
clc;
close all;

%% 1. Dati comuni e casi di sensibilita
projectFolder = fileparts(fileparts(mfilename("fullpath")));
addpath(projectFolder);
setupProject();

load(fullfile(projectFolder, "data", "longitudinalTrim.mat"), "trim");
load(fullfile(projectFolder, "data", "polarNACA0012.mat"), "polar");
load(fullfile(projectFolder, "data", "liftCurveParameters.mat"), ...
    "a0", "alpha0L_rad");

nominalAircraft = aircraftParameters();
aWing = a0 / (1 + a0 / (pi * nominalAircraft.e * nominalAircraft.AR));
pitchScales = [0; 0.5; 1; 1.5; 1; 1];
inertias = [1000; 1000; 1000; 1000; 750; 1250];
caseResults = struct([]);

%% 2. Stesso trim e stesso impulso per ogni caso
for k = 1:numel(pitchScales)
    aircraft = nominalAircraft;
    aircraft.pitchRateTailScale = pitchScales(k);
    aircraft.Iyy = inertias(k);

    simulation = simulateElevatorPulseCase( ...
        aircraft, trim, polar, aWing, alpha0L_rad);
    [A, eigenvalues, oscillatoryModes] = linearizeLongitudinal( ...
        simulation.state0, simulation.thrust, trim.deltaElevator_rad, ...
        aircraft, polar, aWing, alpha0L_rad);

    if any(~isfinite(simulation.states), "all")
        error("Stati non finiti nel caso %d.", k);
    end
    joinError = max(abs(simulation.segmentEndStates(1:2, :) - ...
        simulation.segmentStartStates(2:3, :)), [], "all");
    if joinError > 1e-12
        error("Discontinuita dello stato nel caso %d.", k);
    end

    states = simulation.states;
    dAlpha_deg = simulation.alpha_deg - trim.alpha_deg;
    q_deg_s = rad2deg(states(:, 4));

    caseResults(k).pitchRateTailScale = pitchScales(k);
    caseResults(k).Iyy = inertias(k);
    caseResults(k).simulation = simulation;
    caseResults(k).A = A;
    caseResults(k).eigenvalues = eigenvalues;
    caseResults(k).oscillatoryModes = oscillatoryModes;
    caseResults(k).maxAbsAlpha_deg = max(abs(dAlpha_deg));
    caseResults(k).maxAbsPitchRate_deg_s = max(abs(q_deg_s));
    caseResults(k).maxAbsV_m_s = max(abs(states(:, 1) - trim.V));
    caseResults(k).maxAbsTheta_deg = max(abs( ...
        rad2deg(states(:, 3) - simulation.state0(3))));
    caseResults(k).maxAbsH_m = max(abs(states(:, 5)));
    caseResults(k).deltaH20_m = states(end, 5);
    caseResults(k).maxRealEigenvalue_s = max(real(eigenvalues));
    caseResults(k).joinError = joinError;
end

%% 3. Il caso senza effetto q riproduce il riferimento documentato
baseline = caseResults(1);
reference = [0.346080, 0.514421, 0.991739, 2.408130, 1.834362];
observed = [baseline.maxAbsV_m_s, baseline.maxAbsAlpha_deg, ...
    baseline.maxAbsTheta_deg, baseline.maxAbsPitchRate_deg_s, ...
    baseline.maxAbsH_m];
if any(abs(observed - reference) > 5e-5)
    error("Il caso kq=0 non riproduce il riferimento dell'impulso.");
end

%% 4. Riepilogo dei risultati, senza assumere stabilita
report = sprintf("CONFRONTO SMORZAMENTO DI BECCHEGGIO E IYY\n");
report = [report sprintf( ...
    "Impulso -0.5 deg tra 2 e 2.5 s; osservazione 20 s.\n")];
report = [report sprintf( ...
    "kq=1: stima geometrica quasi stazionaria della coda, non derivata CFD.\n")];
report = [report sprintf( ...
    "Cmq = -2*kq*eta_t*VH*a_t*(lt/c_bar), con qhat=q_pitch*c_bar/(2*V).\n")];
cmqNominal = -2 * nominalAircraft.eta_t * nominalAircraft.VH * ...
    nominalAircraft.a_t * nominalAircraft.lt / nominalAircraft.c_bar;
report = [report sprintf("Cmq stimato per kq=1: %.6f\n", cmqNominal)];
report = [report sprintf("Riferimento kq=0: scostamento dai massimi precedenti < 5e-5.\n\n")];
report = [report sprintf( ...
    "kq    Iyy    max|dAlpha|   max|q|      max|dV|     dH(20s)    max Re(lambda)\n")];
report = [report sprintf( ...
    "      kg*m^2 deg           deg/s       m/s         m          1/s\n")];
for k = 1:numel(caseResults)
    result = caseResults(k);
    report = [report sprintf( ...
        "%-5.1f %-6.0f %-13.6f %-11.6f %-11.6f %-11.6f %+.6f\n", ...
        result.pitchRateTailScale, result.Iyy, ...
        result.maxAbsAlpha_deg, result.maxAbsPitchRate_deg_s, ...
        result.maxAbsV_m_s, result.deltaH20_m, ...
        result.maxRealEigenvalue_s)];
end
report = [report sprintf("\nAutovalori locali [1/s]:\n")];
for k = 1:numel(caseResults)
    result = caseResults(k);
    report = [report sprintf("kq=%.1f, Iyy=%.0f:\n", ...
        result.pitchRateTailScale, result.Iyy)];
    for j = 1:numel(result.eigenvalues)
        lambda = result.eigenvalues(j);
        report = [report sprintf("  %+.9f %+.9fi\n", ...
            real(lambda), imag(lambda))];
    end
end

resultsFolder = fullfile(projectFolder, "results");
fprintf("%s", report);
fid = fopen(fullfile(resultsFolder, ...
    "pitch_damping_inertia_summary.txt"), "w");
if fid < 0
    error("Impossibile salvare il riepilogo del confronto.");
end
fprintf(fid, "%s", report);
fclose(fid);
save(fullfile(resultsFolder, "pitch_damping_inertia_comparison.mat"), ...
    "caseResults", "cmqNominal", "reference");

%% 5. Grafici della risposta: kq e Iyy separati
fig = figure("Name", "Sensibilita a q_pitch e Iyy", ...
    "Position", [100, 100, 1200, 800]);
tiledlayout(2, 2);

nexttile;
hold on;
for k = 1:4
    result = caseResults(k);
    s = result.simulation;
    plot(s.time, s.alpha_deg - trim.alpha_deg, "LineWidth", 1.3);
end
grid on; xlabel("Tempo [s]"); ylabel("Delta alpha [deg]");
title("Effetto di kq sull'angolo d'attacco");
legend("kq=0", "kq=0.5", "kq=1", "kq=1.5", ...
    "Location", "best");

nexttile;
hold on;
for k = 1:4
    s = caseResults(k).simulation;
    plot(s.time, rad2deg(s.states(:, 4)), "LineWidth", 1.3);
end
grid on; xlabel("Tempo [s]"); ylabel("q_{pitch} [deg/s]");
title("Effetto di kq sulla velocita di beccheggio");
legend("kq=0", "kq=0.5", "kq=1", "kq=1.5", ...
    "Location", "best");

inertiaCases = [5, 3, 6];
nexttile;
hold on;
for k = inertiaCases
    s = caseResults(k).simulation;
    plot(s.time, s.alpha_deg - trim.alpha_deg, "LineWidth", 1.3);
end
grid on; xlabel("Tempo [s]"); ylabel("Delta alpha [deg]");
title("Effetto di Iyy sull'angolo d'attacco");
legend("750", "1000", "1250 kg*m^2", "Location", "best");

nexttile;
hold on;
for k = inertiaCases
    s = caseResults(k).simulation;
    plot(s.time, rad2deg(s.states(:, 4)), "LineWidth", 1.3);
end
grid on; xlabel("Tempo [s]"); ylabel("q_{pitch} [deg/s]");
title("Effetto di Iyy sulla velocita di beccheggio");
legend("750", "1000", "1250 kg*m^2", "Location", "best");

exportgraphics(fig, fullfile(resultsFolder, ...
    "pitch_damping_inertia_comparison.png"), "Resolution", 180);
