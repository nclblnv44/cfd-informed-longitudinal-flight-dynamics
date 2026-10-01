function [L,D,M,CL,CD,Cm] = aerodynamicForces(alpha_deg, V, rho, S, c_bar, polar)

[CL, CD, Cm] = airfoilCoefficients(alpha_deg, polar);

q = 0.5*rho*V.^2;

L = q .* S .* CL;
D = q .* S .* CD;
M = q .* S .* c_bar .* Cm;

end
