clear;
clc;
close all;

%% Percorsi
projectFolder = fileparts(fileparts(mfilename("fullpath")));
addpath(projectFolder);
setupProject();
dataFile = fullfile(projectFolder, "data", "cfd_results.csv");

%% Lettura del CSV
data = readtable(dataFile);

%% Selezione della mesh consigliata
selectedMesh = "449x129";

rows = string(data.mesh) == selectedMesh;
polar = data(rows, :);

%% Ordinamento per angolo d'attacco
polar = sortrows(polar, "alpha_deg");

%% Controlli
if height(polar) ~= 9
    error("Numero inatteso di punti CFD: %d", height(polar));
end

if any(isnan(polar.cl)) || any(isnan(polar.cd)) || any(isnan(polar.cm))
    error("La polare contiene valori mancanti.");
end

fprintf("Mesh selezionata: %s\n", selectedMesh);
fprintf("Numero di punti: %d\n", height(polar));
fprintf("Intervallo: %.1f° ≤ alpha ≤ %.1f°\n", ...
    min(polar.alpha_deg), max(polar.alpha_deg));

disp(polar(:, ["alpha_deg", "cl", "cd", "cm"]));

%% Grafici
figure("Name", "Polare CFD NACA 0012");

tiledlayout(1, 4);

nexttile;
plot(polar.alpha_deg, polar.cl, "o-", "LineWidth", 1.5, "MarkerFaceColor", "auto");
xlabel("\alpha [deg]");
ylabel("c_l");
title("Lift");
grid on;

nexttile;
plot(polar.alpha_deg, polar.cd, "o-", "LineWidth", 1.5, "MarkerFaceColor", "auto");
xlabel("\alpha [deg]");
ylabel("c_d");
title("Drag");
grid on;

nexttile;
plot(polar.alpha_deg, polar.cm, "o-", "LineWidth", 1.5, "MarkerFaceColor", "auto");
xlabel("\alpha [deg]");
ylabel("c_m");
title("Momentum at C/4");
grid on;

nexttile;
plot(polar.cl, polar.cd, "o-", "LineWidth", 1.5, "MarkerFaceColor","auto");
xlabel("c_l");
ylabel("c_d");
title("Drag vs Lift");
grid on;

%% Salvataggio dei dati MATLAB
outputFile = fullfile(projectFolder, "data", "polarNACA0012.mat");

save(outputFile, "polar");

fprintf("\nPolare salvata in:\n%s\n", outputFile);

exportgraphics(gcf, fullfile(projectFolder, "results", "cfd_polar.png"), ...
    "Resolution", 200);
