function projectFolder = setupProject()
%SETUPPROJECT Configura i percorsi MATLAB senza cambiare cartella corrente.
% Eseguire dalla radice del progetto oppure richiamare dagli script.

    projectFolder = fileparts(mfilename("fullpath"));
    addpath(projectFolder);
    addpath(fullfile(projectFolder, "config"));
    addpath(fullfile(projectFolder, "src"));
    addpath(fullfile(projectFolder, "scripts"));
    addpath(fullfile(projectFolder, "examples"));

    if ~isfolder(fullfile(projectFolder, "results"))
        mkdir(fullfile(projectFolder, "results"));
    end

end
