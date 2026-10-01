function trim = computeLongitudinalTrim( ...
    aircraft, polar, aWing, alpha0L_rad)
%COMPUTELONGITUDINALTRIM Trim a volo orizzontale per il modello selezionato.
% La portanza della coda richiesta annulla il momento solo durante la
% ricerca del trim. In dinamica la coda dipende da alpha ed elevatore.

    V = aircraft.V0;
    W = aircraft.weight;
    qbar = 0.5 * aircraft.rho * V^2;
    incidenceTail_rad = deg2rad(aircraft.i_t_deg);

    residual = @(alpha_rad) verticalForceResidual( ...
        alpha_rad, qbar, W, aircraft, polar, aWing, alpha0L_rad);
    limits_rad = deg2rad([min(polar.alpha_deg), max(polar.alpha_deg)]);
    lowerResidual = residual(limits_rad(1));
    upperResidual = residual(limits_rad(2));
    if lowerResidual * upperResidual > 0
        error(["Nessun cambio di segno dell'errore verticale " ...
            "nell'intervallo CFD."]);
    end

    options = optimset("Display", "off", "TolX", 1e-12);
    [alpha_rad, residualAtRoot, exitflag] = ...
        fzero(residual, limits_rad, options);
    if exitflag <= 0
        error("La ricerca dell'angolo di trim non e convergente.");
    end

    CL_wing = wingLiftCoefficient( ...
        alpha_rad, aircraft, polar, aWing, alpha0L_rad);
    [~, ~, Cm_wing] = airfoilCoefficients(rad2deg(alpha_rad), polar);
    CL_tail_required = Cm_wing / (aircraft.eta_t * aircraft.VH);
    alphaTailRequired_rad = CL_tail_required / aircraft.a_t;
    deltaElevator_rad = (alphaTailRequired_rad ...
        - (1 - aircraft.downwashGradient) * alpha_rad ...
        - incidenceTail_rad) / aircraft.tau_e;

    alphaTail_rad = (1 - aircraft.downwashGradient) * alpha_rad ...
        + incidenceTail_rad + aircraft.tau_e * deltaElevator_rad;
    CL_tail = aircraft.a_t * alphaTail_rad;
    L_wing = qbar * aircraft.S * CL_wing;
    L_tail = qbar * aircraft.eta_t * aircraft.St * CL_tail;
    [L_total, D_total, M_total] = aircraftAerodynamics( ...
        V, alpha_rad, deltaElevator_rad, ...
        aircraft, polar, aWing, alpha0L_rad);

    model = "linear";
    if isfield(aircraft, "wingLiftModel")
        model = string(aircraft.wingLiftModel);
    end
    trim.wingLiftModel = model;
    trim.V = V;
    trim.rho = aircraft.rho;
    trim.q = qbar;
    trim.alpha_rad = alpha_rad;
    trim.alpha_deg = rad2deg(alpha_rad);
    trim.deltaElevator_rad = deltaElevator_rad;
    trim.deltaElevator_deg = rad2deg(deltaElevator_rad);
    trim.CL_wing = CL_wing;
    trim.CL_tail = CL_tail;
    trim.Cm_wing = Cm_wing;
    trim.Cm_total = M_total / (qbar * aircraft.S * aircraft.c_bar);
    trim.L_wing = L_wing;
    trim.L_tail = L_tail;
    trim.L_total = L_total;
    trim.D_total = D_total;
    trim.M_total = M_total;
    trim.thrust = D_total;
    trim.liftError = L_total - W;
    trim.residualAtRoot = residualAtRoot;
    trim.aWing = aWing;
end

function residual = verticalForceResidual( ...
    alpha_rad, qbar, W, aircraft, polar, aWing, alpha0L_rad)
    CL_wing = wingLiftCoefficient( ...
        alpha_rad, aircraft, polar, aWing, alpha0L_rad);
    [~, ~, Cm_wing] = airfoilCoefficients(rad2deg(alpha_rad), polar);
    CL_tail = Cm_wing / (aircraft.eta_t * aircraft.VH);
    L_wing = qbar * aircraft.S * CL_wing;
    L_tail = qbar * aircraft.eta_t * aircraft.St * CL_tail;
    residual = L_wing + L_tail - W;
end
