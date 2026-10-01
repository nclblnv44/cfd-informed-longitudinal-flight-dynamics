function [A, eigenvalues, oscillatoryModes] = linearizeLongitudinal( ...
    state0, thrust, deltaElevator_rad, aircraft, polar, aWing, alpha0L_rad)
%LINEARIZELONGITUDINAL Linearizzazione numerica locale al trim.
% Le prime quattro variabili formano la matrice dinamica. La quota non
% influenza le forze nel modello a densita costante.

    dynamics = @(state) longitudinalDynamics( ...
        0, state, thrust, deltaElevator_rad, ...
        aircraft, polar, aWing, alpha0L_rad);

    A = zeros(4);
    steps = [1e-4; 1e-6; 1e-6; 1e-6];
    for k = 1:4
        xp = state0;
        xm = state0;
        xp(k) = xp(k) + steps(k);
        xm(k) = xm(k) - steps(k);
        fp = dynamics(xp);
        fm = dynamics(xm);
        A(:, k) = (fp(1:4) - fm(1:4)) / (2 * steps(k));
    end

    eigenvalues = eig(A);
    oscillatoryModes = eigenvalues(imag(eigenvalues) > 1e-8);
    [~, order] = sort(abs(imag(oscillatoryModes)), "descend");
    oscillatoryModes = oscillatoryModes(order);
end
