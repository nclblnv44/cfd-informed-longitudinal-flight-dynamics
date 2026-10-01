function aircraft = aircraftParameters()
%AIRCRAFTPARAMETERS Parametri del velivolo concettuale.

    %% Massa, gravita e inerzia
    aircraft.mass = 600;         % [kg]
    aircraft.g = 9.81;           % [m/s^2]
    aircraft.weight = aircraft.mass * aircraft.g;

    % Stima provvisoria per il modello didattico
    aircraft.Iyy = 1000;         % inerzia di beccheggio [kg*m^2]

    %% Ala
    aircraft.S = 14;             % [m^2]
    aircraft.b = 8;              % [m]
    aircraft.c_bar = 1.75;       % [m]
    aircraft.e = 0.80;
    aircraft.AR = aircraft.b^2 / aircraft.S;

    % "linear" riproduce il modello corrente; "cfd" usa la polare cl
    % con la correzione implicita di ala finita.
    aircraft.wingLiftModel = "linear";

    %% Condizione di volo
    aircraft.V0 = 52;            % [m/s]
    aircraft.rho = 1.225;        % [kg/m^3]

    %% Piano di coda
    aircraft.St = 3;             % [m^2]
    aircraft.lt = 3;             % [m]
    aircraft.eta_t = 0.9;
    aircraft.a_t = 4;            % [rad^-1]
    aircraft.i_t_deg = 0;        % [deg]
    aircraft.tau_e = 0.5;
    aircraft.downwashGradient = 0.35;

    % Fattore della stima quasi stazionaria del moto della coda.
    % 1 = effetto geometrico completo; 0 = modello precedente.
    aircraft.pitchRateTailScale = 1;

    aircraft.VH = aircraft.St * aircraft.lt / ...
        (aircraft.S * aircraft.c_bar);

end