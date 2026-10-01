clear;
clc;

projectFolder = fileparts(fileparts(mfilename("fullpath")));
addpath(projectFolder);
setupProject();



load(fullfile(projectFolder, "data","polarNACA0012.mat"),"polar");

alpha_test = linspace(1,10,10);

cl_vec = [];
cd_vec = [];
cm_vec = [];

for i = 1:length(alpha_test)
    alpha = alpha_test(i);
    [cl,cd,cm] = airfoilCoefficients(alpha,polar);
    cl_vec = [cl_vec,cl];
    cd_vec = [cd_vec,cd];
    cm_vec = [cm_vec,cm];
    fprintf("Risultati interpolati a alpha = %.1f gradi:\n", alpha_test(i));
    fprintf("CL = %.6f\n", cl_vec(i));
    fprintf("CD = %.6f\n", cd_vec(i));
    fprintf("Cm = %.6f\n", cm_vec(i));
end
