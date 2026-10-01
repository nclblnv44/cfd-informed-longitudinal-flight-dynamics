function runProject()
%RUNPROJECT Rigenera in ordine dati derivati, simulazioni e grafici.
% I risultati generati con gli stessi nomi vengono sovrascritti.
% Non avvia Fluent: usa il CSV CFD gia disponibile.

    projectFolder = setupProject();
    steps = [
        "importPolar.m"
        "analyseLiftCurve.m"
        "analyseFiniteWing.m"
        "findLevelFlight.m"
        "findLongitudinalTrim.m"
        "simulateLongitudinal.m"
        "simulateElevatorPulse.m"
        "analyseElevatorResponse.m"
        "comparePitchDampingAndInertia.m"
        "compareWingLiftModels.m"
    ];

    for k = 1:numel(steps)
        fprintf("\nEsecuzione: %s\n", steps(k));
        runStep(fullfile(projectFolder, "scripts", steps(k)));
    end

    fprintf("\nProcedura completata. Risultati in:\n%s\n", ...
        fullfile(projectFolder, "results"));
end

function runStep(scriptPath)
% Ogni script lavora in un workspace separato: clear non cancella il runner.
    run(scriptPath);
end
