function [CL, CD, Cm] = airfoilCoefficients(alpha_deg, polar)

    % Limiti dei dati CFD
    alpha_min = min(polar.alpha_deg);
    alpha_max = max(polar.alpha_deg);

    % Tolleranza per piccoli errori numerici [gradi]
    tolerance = 1e-10;

    % Blocca gli angoli realmente fuori dall'intervallo
    outsideRange = ...
        alpha_deg < alpha_min - tolerance | ...
        alpha_deg > alpha_max + tolerance;

    if any(outsideRange, "all")
        error("Angolo d'attacco fuori dall'intervallo CFD [%.1f°, %.1f°].", ...
            alpha_min, alpha_max);
    end

    % Riporta sui limiti gli eventuali scostamenti di arrotondamento
    alpha_deg = max(alpha_min, min(alpha_max, alpha_deg));

    % Interpolazione dei coefficienti
    CL = interp1(polar.alpha_deg, polar.cl, alpha_deg, "linear");
    CD = interp1(polar.alpha_deg, polar.cd, alpha_deg, "linear");
    Cm = interp1(polar.alpha_deg, polar.cm, alpha_deg, "linear");

end