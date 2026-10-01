function [L, D, M] = aircraftAerodynamics( V, alpha_rad, deltaElevator_rad, ...
    aircraft, polar, aWing, alpha0L_rad, pitchRate_rad_s)
%AIRCRAFTAERODYNAMICS Forze e momento del velivolo semplificato.
%
% INPUT:
%   V                 = velocita [m/s]
%   alpha_rad         = angolo d'attacco [rad]
%   deltaElevator_rad = deflessione elevatore [rad]
%   aircraft          = struttura dei parametri del velivolo
%   polar             = tabella dei coefficienti CFD
%   aWing             = pendenza portanza ala finita [rad^-1]
%   alpha0L_rad       = angolo di portanza nulla [rad]
%   pitchRate_rad_s   = velocita di beccheggio [rad/s], 0 se omessa
%
% OUTPUT:
%   L = portanza totale di ala e coda [N]
%   D = resistenza [N]
%   M = momento di beccheggio rispetto al baricentro [N*m]
%
% CONVENZIONI:
%   L positiva verso l'alto rispetto alla traiettoria.
%   D positiva come intensita della resistenza.
%   M positivo tende ad alzare il muso.
%   Elevatore positivo aumenta la portanza della coda.
%
% IPOTESI:
%   Baricentro al quarto di corda.
%   Portanza dell'ala lineare o CFD secondo aircraft.wingLiftModel.
%   cd e cm del profilo restano all'angolo geometrico in entrambi i
%   modelli, per isolare la legge di portanza. La coda resta lineare.
%   Resistenza di coda e fusoliera trascurata.
%   Effetto di q_pitch stimato dal moto verticale della coda; non e una
%   derivata dinamica ottenuta dalla CFD. Momento della spinta trascurato.
%   Coefficienti CFD utilizzati al Reynolds di riferimento.

    if nargin < 8
        pitchRate_rad_s = 0;
    end

    % Compatibilita con strutture aircraft salvate prima di questo modello.
    pitchRateTailScale = 0;
    if isfield(aircraft, "pitchRateTailScale")
        pitchRateTailScale = aircraft.pitchRateTailScale;
    end

    %% 1. Pressione dinamica e conversione degli angoli
    qbar = 0.5 * aircraft.rho * V.^2;

    alpha_deg = rad2deg(alpha_rad);
    incidenceTail_rad = deg2rad(aircraft.i_t_deg);

    %% 2. Coefficienti dell'ala
    % Dalla CFD recuperiamo resistenza del profilo e momento.
    [~, cd_profile, Cm_wing] = ...
        airfoilCoefficients(alpha_deg, polar);

    % Portanza dell'ala finita
    CL_wing = wingLiftCoefficient( ...
        alpha_rad, aircraft, polar, aWing, alpha0L_rad);

    % Resistenza indotta dell'ala
    CD_induced = CL_wing.^2 ./ ...
        (pi * aircraft.e * aircraft.AR);

    % Coefficiente di resistenza dell'ala
    CD_wing = cd_profile + CD_induced;

    %% 3. Portanza della coda
    % Angolo efficace: downwash, incidenza ed elevatore
    alphaTail_rad = ...
        (1 - aircraft.downwashGradient) .* alpha_rad ...
        + incidenceTail_rad ...
        + aircraft.tau_e .* deltaElevator_rad ...
        + pitchRateTailScale .* aircraft.lt .* pitchRate_rad_s ./ V;

    CL_tail = aircraft.a_t .* alphaTail_rad;

    %% 4. Forze aerodinamiche
    L_wing = qbar .* aircraft.S .* CL_wing;

    L_tail = qbar .* aircraft.eta_t .* aircraft.St .* CL_tail;

    L = L_wing + L_tail;

    D = qbar .* aircraft.S .* CD_wing;

    %% 5. Momento di beccheggio
    Cm_total = Cm_wing ...
        - aircraft.eta_t .* aircraft.VH .* CL_tail;

    M = qbar .* aircraft.S .* aircraft.c_bar .* Cm_total;

end
