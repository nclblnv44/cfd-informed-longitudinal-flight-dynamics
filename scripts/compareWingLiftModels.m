clear;
clc;
close all;

%% 1. Dati comuni e verifica della correzione CFD
projectFolder = fileparts(fileparts(mfilename("fullpath")));
addpath(projectFolder);
setupProject();
load(fullfile(projectFolder, "data", "polarNACA0012.mat"), "polar");
load(fullfile(projectFolder, "data", "liftCurveParameters.mat"), ...
    "a0", "alpha0L_rad");

nominalAircraft = aircraftParameters();
aWing = a0 / (1 + a0 / (pi * nominalAircraft.e * nominalAircraft.AR));
cfdAircraft = nominalAircraft;
cfdAircraft.wingLiftModel = "cfd";

alphaGrid_rad = deg2rad(linspace(-4, 12, 81));
CL_grid = wingLiftCoefficient( ...
    alphaGrid_rad, cfdAircraft, polar, aWing, alpha0L_rad);
CL_linear_grid = wingLiftCoefficient( ...
    alphaGrid_rad, nominalAircraft, polar, aWing, alpha0L_rad);
deltaCL_grid = CL_grid - CL_linear_grid;
effectiveAlpha_rad = alphaGrid_rad - ...
    CL_grid / (pi * cfdAircraft.e * cfdAircraft.AR);
[clCheck, ~, ~] = airfoilCoefficients(rad2deg(effectiveAlpha_rad), polar);
closureError = max(abs(CL_grid - clCheck), [], "all");
if closureError > 1e-12
    error("La correzione CFD di ala finita non soddisfa la relazione implicita.");
end

try
    wingLiftCoefficient(deg2rad(12.01), ...
        cfdAircraft, polar, aWing, alpha0L_rad);
    error("Il modello CFD ha accettato un angolo fuori intervallo.");
catch exception
    if ~strcmp(exception.identifier, "wingLiftCoefficient:OutOfRange")
        rethrow(exception);
    end
end

%% 2. Trim, impulso e modi locali per ciascun modello
models = ["linear"; "cfd"];
caseResults = struct([]);
for k = 1:numel(models)
    aircraft = nominalAircraft;
    aircraft.wingLiftModel = models(k);
    trim = computeLongitudinalTrim( ...
        aircraft, polar, aWing, alpha0L_rad);
    if abs(trim.liftError) > 1e-5 || abs(trim.M_total) > 1e-5
        error("Trim non equilibrato per il modello %s.", models(k));
    end

    simulation = simulateElevatorPulseCase( ...
        aircraft, trim, polar, aWing, alpha0L_rad);
    [A, eigenvalues, oscillatoryModes] = linearizeLongitudinal( ...
        simulation.state0, simulation.thrust, trim.deltaElevator_rad, ...
        aircraft, polar, aWing, alpha0L_rad);

    if any(~isfinite(simulation.states), "all")
        error("Stati non finiti per il modello %s.", models(k));
    end
    joinError = max(abs(simulation.segmentEndStates(1:2, :) - ...
        simulation.segmentStartStates(2:3, :)), [], "all");
    if joinError > 1e-12
        error("Discontinuita dello stato per il modello %s.", models(k));
    end

    % Con comando costante, lo stato di trim deve restare fermo per 20 s.
    dynamics = @(t, state) longitudinalDynamics( ...
        t, state, simulation.thrust, trim.deltaElevator_rad, ...
        aircraft, polar, aWing, alpha0L_rad);
    options = odeset("RelTol", 1e-8, "AbsTol", 1e-10, "MaxStep", 0.1);
    [~, noPulseStates] = ode45( ...
        dynamics, [0, 20], simulation.state0, options);
    holdError = max(abs(noPulseStates - simulation.state0.'), [], "all");
    if holdError > 1e-6
        error("Il modello %s non mantiene il trim senza impulso.", models(k));
    end

    states = simulation.states;
    caseResults(k).model = models(k);
    caseResults(k).aircraft = aircraft;
    caseResults(k).trim = trim;
    caseResults(k).simulation = simulation;
    caseResults(k).A = A;
    caseResults(k).eigenvalues = eigenvalues;
    caseResults(k).oscillatoryModes = oscillatoryModes;
    caseResults(k).maxAbsAlpha_deg = max(abs( ...
        simulation.alpha_deg - trim.alpha_deg));
    caseResults(k).maxAbsPitchRate_deg_s = max(abs( ...
        rad2deg(states(:, 4))));
    caseResults(k).maxAbsV_m_s = max(abs(states(:, 1) - trim.V));
    caseResults(k).deltaH20_m = states(end, 5);
    caseResults(k).joinError = joinError;
    caseResults(k).holdError = holdError;
end

%% 3. Il modello lineare nominale deve riprodurre il risultato precedente
baseline = caseResults(1);
reference = [3.572781, -4.821444, 330.350994, ...
    0.306579, 0.346727, 1.639474];
observed = [baseline.trim.alpha_deg, baseline.trim.deltaElevator_deg, ...
    baseline.trim.thrust, baseline.maxAbsV_m_s, ...
    baseline.maxAbsAlpha_deg, baseline.maxAbsPitchRate_deg_s];
if any(abs(observed - reference) > 5e-5)
    error("Il modello lineare non riproduce il riferimento nominale.");
end

%% Differenza della risposta su una griglia temporale comune
commonTime = linspace(0, 20, 1001).';
linearSimulation = caseResults(1).simulation;
cfdSimulation = caseResults(2).simulation;
linearDeltaAlpha = interp1(linearSimulation.time, ...
    linearSimulation.alpha_deg - caseResults(1).trim.alpha_deg, ...
    commonTime, "linear");
cfdDeltaAlpha = interp1(cfdSimulation.time, ...
    cfdSimulation.alpha_deg - caseResults(2).trim.alpha_deg, ...
    commonTime, "linear");
alphaResponseDifference_deg = cfdDeltaAlpha - linearDeltaAlpha;
maxAbsAlphaResponseDifference_deg = ...
    max(abs(alphaResponseDifference_deg));
%% 4. Riepilogo e dati del confronto
report = sprintf("CONFRONTO PORTANZA LINEARE E CFD NON LINEARE\n");
report = [report sprintf( ...
    "Ala finita: alpha = alpha_eff + CL/(pi*e*AR).\n")];
report = [report sprintf( ...
    "cd e cm restano valutati all'angolo geometrico per entrambi i modelli.\n")];
report = [report sprintf( ...
    "Impulso relativo: -0.5 deg tra 2 e 2.5 s; osservazione 20 s.\n")];
report = [report sprintf( ...
    "Errore massimo relazione implicita: %.3e\n", closureError)];
report = [report sprintf( ...
    "Differenza CL_CFD-CL_lineare nel dominio [-4, 12] deg: min %+.6f, max %+.6f\n", ...
    min(deltaCL_grid), max(deltaCL_grid))];
report = [report sprintf( ...
    "Max differenza fra Delta alpha CFD e lineare: %.9f deg\n\n", ...
    maxAbsAlphaResponseDifference_deg)];
report = [report sprintf( ...
    "Modello  alpha_trim  delta_e_trim  T_trim     max|dAlpha|  max|q|     max|dV|   dH(20s)\n")];
report = [report sprintf( ...
    "         deg         deg           N          deg          deg/s      m/s       m\n")];
for k = 1:numel(caseResults)
    result = caseResults(k);
    report = [report sprintf( ...
        "%-7s  %10.6f  %12.6f  %9.6f  %11.6f  %9.6f  %9.6f  %+9.6f\n", ...
        char(result.model), result.trim.alpha_deg, ...
        result.trim.deltaElevator_deg, result.trim.thrust, ...
        result.maxAbsAlpha_deg, result.maxAbsPitchRate_deg_s, ...
        result.maxAbsV_m_s, result.deltaH20_m)];
end
report = [report sprintf("\nControlli e autovalori locali:\n")];
for k = 1:numel(caseResults)
    result = caseResults(k);
    report = [report sprintf( ...
        "%s: L-W=%+.3e N, M=%+.3e N*m, tenuta=%.3e, raccordo=%.3e\n", ...
        char(result.model), result.trim.liftError, result.trim.M_total, ...
        result.holdError, result.joinError)];
    for j = 1:numel(result.eigenvalues)
        lambda = result.eigenvalues(j);
        report = [report sprintf("  lambda=%+.9f %+.9fi [1/s]\n", ...
            real(lambda), imag(lambda))];
    end
end

resultsFolder = fullfile(projectFolder, "results");
fprintf("%s", report);
fid = fopen(fullfile(resultsFolder, "wing_lift_model_summary.txt"), "w");
if fid < 0
    error("Impossibile salvare il riepilogo del confronto.");
end
fprintf(fid, "%s", report);
fclose(fid);
save(fullfile(resultsFolder, "wing_lift_model_comparison.mat"), ...
    "caseResults", "closureError", "reference", "alphaGrid_rad", ...
    "CL_grid", "CL_linear_grid", "deltaCL_grid");

%% 5. Grafici delle leggi di portanza e delle risposte
fig = figure("Name", "Confronto portanza lineare e CFD", ...
    "Position", [100, 100, 1200, 900]);
tiledlayout(3, 2);

nexttile;
plot(rad2deg(alphaGrid_rad), CL_linear_grid, "LineWidth", 1.4);
hold on;
plot(rad2deg(alphaGrid_rad), CL_grid, "LineWidth", 1.4);
grid on; xlabel("Alpha geometrico [deg]"); ylabel("C_L ala");
title("Portanza dell'ala finita");
legend("Lineare", "CFD non lineare", "Location", "best");

nexttile;
hold on;
for k = 1:numel(caseResults)
    result = caseResults(k);
    s = result.simulation;
    plot(s.time, s.alpha_deg - result.trim.alpha_deg, "LineWidth", 1.3);
end
grid on; xlabel("Tempo [s]"); ylabel("Delta alpha [deg]");
title("Risposta dell'angolo d'attacco");
legend("Lineare", "CFD non lineare", "Location", "best");

nexttile;
hold on;
for k = 1:numel(caseResults)
    s = caseResults(k).simulation;
    plot(s.time, rad2deg(s.states(:, 4)), "LineWidth", 1.3);
end
grid on; xlabel("Tempo [s]"); ylabel("q pitch [deg/s]");
title("Velocita di beccheggio");
legend("Lineare", "CFD non lineare", "Location", "best");

nexttile;
hold on;
for k = 1:numel(caseResults)
    s = caseResults(k).simulation;
    plot(s.time, s.states(:, 1) - s.state0(1), "LineWidth", 1.3);
end
grid on; xlabel("Tempo [s]"); ylabel("Delta V [m/s]");
title("Risposta della velocita");
legend("Lineare", "CFD non lineare", "Location", "best");

nexttile;
hold on;
for k = 1:numel(caseResults)
    s = caseResults(k).simulation;
    plot(s.time, s.states(:, 5), "LineWidth", 1.3);
end
grid on; xlabel("Tempo [s]"); ylabel("Delta h [m]");
title("Variazione di quota");
legend("Lineare", "CFD non lineare", "Location", "best");

nexttile;
plot(commonTime, alphaResponseDifference_deg, "LineWidth", 1.3);
grid on; xlabel("Tempo [s]");
ylabel("Differenza Delta alpha [deg]");
title("CFD meno lineare: risposta dell'angolo d'attacco");

exportgraphics(fig, fullfile(resultsFolder, ...
    "wing_lift_model_comparison.png"), "Resolution", 180);


%% 6. Scarto statico della portanza su tutto il dominio disponibile
staticFig = figure("Name", "Scarto statico della portanza", ...
    "Position", [100, 100, 900, 450]);
plot(rad2deg(alphaGrid_rad), deltaCL_grid, "LineWidth", 1.7);
hold on;
xline(mean([caseResults(1).trim.alpha_deg, caseResults(2).trim.alpha_deg]), "--", ...
    "Both trims: 3.57 deg", "LabelOrientation", "horizontal", ...
    "LabelVerticalAlignment", "bottom", "LabelHorizontalAlignment", "right");
yline(0, "k:");
grid on;
xlim([-4, 12]);
xlabel("Geometric alpha [deg]");
ylabel("C_{L,CFD} - C_{L,linear}");
title("Finite-wing lift difference");
exportgraphics(staticFig, fullfile(resultsFolder, ...
    "wing_lift_static_difference.png"), "Resolution", 180);
