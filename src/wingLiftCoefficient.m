function CL_wing = wingLiftCoefficient( ...
    alpha_rad, aircraft, polar, aWing, alpha0L_rad)
%WINGLIFTCOEFFICIENT Portanza dell'ala finita lineare o dalla polare CFD.
% Nel caso CFD, alpha = alpha_eff + CL/(pi*e*AR). I punti della polare
% definiscono una mappa monotona da alpha_eff ad alpha geometrico: la
% sua interpolazione inversa risolve esattamente la relazione con cl
% interpolato linearmente, senza iterazioni durante l'integrazione.

    model = "linear";
    if isfield(aircraft, "wingLiftModel")
        model = string(aircraft.wingLiftModel);
    end

    switch model
        case "linear"
            CL_wing = aWing .* (alpha_rad - alpha0L_rad);
        case "cfd"
            sectionAlpha_rad = deg2rad(polar.alpha_deg);
            geometricNodes_rad = sectionAlpha_rad + ...
                polar.cl ./ (pi * aircraft.e * aircraft.AR);
            if any(diff(geometricNodes_rad) <= 0)
                error("wingLiftCoefficient:NonMonotone", "La mappa di ala finita CFD non e monotona.");
            end

            % Manteniamo anche il dominio geometrico originale: cd e cm
            % del profilo sono ancora richiesti a questo angolo.
            lower = max(min(sectionAlpha_rad), min(geometricNodes_rad));
            upper = min(max(sectionAlpha_rad), max(geometricNodes_rad));
            tolerance = deg2rad(1e-10);
            if any(alpha_rad < lower - tolerance | ...
                    alpha_rad > upper + tolerance, "all")
                error("wingLiftCoefficient:OutOfRange", ...
                    "Angolo fuori dal dominio CFD di ala finita [%.6f, %.6f] deg.", ...
                    rad2deg(lower), rad2deg(upper));
            end
            alphaClamped_rad = max(lower, min(upper, alpha_rad));
            CL_wing = interp1(geometricNodes_rad, polar.cl, ...
                alphaClamped_rad, "linear");
        otherwise
            error("wingLiftCoefficient:UnknownModel", ...
                "Modello di portanza dell'ala sconosciuto: %s", model);
    end
end
