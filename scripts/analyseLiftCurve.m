clear;
clc;
close all;

%% Caricamento della polare CFD
projectFolder = fileparts(fileparts(mfilename("fullpath")));
addpath(projectFolder);
setupProject();
load(fullfile(projectFolder, "data", "polarNACA0012.mat"), "polar");

%% Selezione della zona lineare della curva di portanza
% Usiamo solo i punti tra -4 e +4 gradi, prima della zona non lineare.
linearRows = polar.alpha_deg >= -4 & polar.alpha_deg <= 4;
alpha_deg = polar.alpha_deg(linearRows);
cl_cfd = polar.cl(linearRows);

% La pendenza aerodinamica viene espressa rispetto ai radianti.
alpha_rad = deg2rad(alpha_deg);

%% Adattamento della retta cl = a0 * alpha + b
fitCoefficients = polyfit(alpha_rad, cl_cfd, 1);
a0 = fitCoefficients(1);       % pendenza della portanza [rad^-1]
b = fitCoefficients(2);        % cl previsto a alpha = 0
alpha0L_rad = -b / a0;         % angolo di portanza nulla [rad]
alpha0L_deg = rad2deg(alpha0L_rad);

% Valori della retta calcolati negli stessi punti CFD.
cl_linear = polyval(fitCoefficients, alpha_rad);

%% Controllo numerico della qualita dell'adattamento
residuals = cl_cfd - cl_linear;
SS_res = sum(residuals.^2);
SS_tot = sum((cl_cfd - mean(cl_cfd)).^2);
R2 = 1 - SS_res / SS_tot;

fprintf("Analisi della curva di portanza 2D\n");
fprintf("a0              = %.6f rad^-1\n", a0);
fprintf("b               = %.8f\n", b);
fprintf("alpha portanza 0 = %.6f deg\n", alpha0L_deg);
fprintf("R^2             = %.8f\n", R2);

%% Confronto grafico
alpha_plot_deg = linspace(min(alpha_deg), max(alpha_deg), 200);
alpha_plot_rad = deg2rad(alpha_plot_deg);
cl_plot = polyval(fitCoefficients, alpha_plot_rad);

figure("Name", "Curva di portanza lineare");
plot(alpha_deg, cl_cfd, "o", "MarkerSize", 7, ...
    "MarkerFaceColor", "auto", "DisplayName", "Dati CFD");
hold on;
plot(alpha_plot_deg, cl_plot, "-", "LineWidth", 1.5, ...
    "DisplayName", "Adattamento lineare");
grid on;
xlabel("\alpha [deg]");
ylabel("c_l");
title("Pendenza della curva di portanza del profilo 2D");
legend("Location", "best");

%% Salvataggio dei risultati utili per i passaggi successivi
resultsFolder = fullfile(projectFolder, "results");
if ~isfolder(resultsFolder)
    mkdir(resultsFolder);
end

save(fullfile(projectFolder, "data", "liftCurveParameters.mat"), ...
    "a0", "b", "alpha0L_rad", "alpha0L_deg", "R2");

exportgraphics(gcf, fullfile(resultsFolder, "lift_curve_fit.png"), ...
    "Resolution", 300);
