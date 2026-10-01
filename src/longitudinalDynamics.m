function stateDot = longitudinalDynamics( ...
    t, state, thrust, deltaElevator_rad, ...
    aircraft, polar, aWing, alpha0L_rad)
%LONGITUDINALDYNAMICS Equazioni del moto nel piano verticale.
%
% STATO:
%   state(1) = V          velocita [m/s]
%   state(2) = gamma      angolo della traiettoria [rad]
%   state(3) = theta      angolo di assetto [rad]
%   state(4) = pitchRate  velocita di beccheggio [rad/s]
%   state(5) = h          quota [m]
%
% INPUT:
%   t                  = tempo [s], previsto per l'uso con ode45
%   thrust             = spinta lungo la traiettoria [N]
%   deltaElevator_rad  = deflessione elevatore [rad]
%
% IPOTESI:
%   Volo nel piano verticale, densita costante.
%   Spinta lungo la traiettoria e senza momento di beccheggio.
%   Aerodinamica quasi stazionaria.

    %% Estrazione dello stato
    V = state(1);
    gamma = state(2);
    theta = state(3);
    pitchRate = state(4);

    if V <= 0
        error("Il modello richiede una velocita positiva.");
    end

    %% Angolo d'attacco
    alpha_rad = theta - gamma;

    %% Forze e momento aerodinamici
    [L, D, M] = aircraftAerodynamics( V, alpha_rad, deltaElevator_rad, ...
        aircraft, polar, aWing, alpha0L_rad, pitchRate);

    %% Equazioni del moto
    Vdot = (thrust - D) / aircraft.mass - aircraft.g * sin(gamma);

    gammaDot = (L - aircraft.weight * cos(gamma)) / (aircraft.mass * V);

    thetaDot = pitchRate;

    pitchRateDot = M / aircraft.Iyy;

    hDot = V * sin(gamma);

    %% Vettore colonna delle derivate
    stateDot = [
        Vdot;
        gammaDot;
        thetaDot;
        pitchRateDot;
        hDot
    ];

end