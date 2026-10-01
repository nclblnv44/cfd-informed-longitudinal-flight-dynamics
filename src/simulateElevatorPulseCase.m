function simulation = simulateElevatorPulseCase( ...
    aircraft, trim, polar, aWing, alpha0L_rad)
%SIMULATEELEVATORPULSECASE Stesso impulso per modelli e inerzie diversi.
% Impulso di -0.5 deg tra 2 e 2.5 s, simulazione fino a 20 s.
% La divisione in tre intervalli applica i cambi di comando esattamente.

    pulseStart = 2;
    pulseEnd = 2.5;
    simulationEnd = 20;
    pulseAmplitude_deg = -0.5;
    deltaTrim_rad = trim.deltaElevator_rad;
    deltaPulse_rad = deltaTrim_rad + deg2rad(pulseAmplitude_deg);

    [~, thrust] = aircraftAerodynamics( ...
        trim.V, trim.alpha_rad, deltaTrim_rad, ...
        aircraft, polar, aWing, alpha0L_rad);

    state0 = [trim.V; 0; trim.alpha_rad; 0; 0];
    stateDot0 = longitudinalDynamics( ...
        0, state0, thrust, deltaTrim_rad, ...
        aircraft, polar, aWing, alpha0L_rad);
    if any(abs(stateDot0) > 1e-6)
        error("La condizione iniziale non e in equilibrio.");
    end

    timeBoundaries = [0; pulseStart; pulseEnd; simulationEnd];
    elevatorBySegment = [deltaTrim_rad; deltaPulse_rad; deltaTrim_rad];
    options = odeset( ...
        "RelTol", 1e-8, "AbsTol", 1e-10, "MaxStep", 0.02);

    time = [];
    states = [];
    segmentInitialState = state0;
    segmentStartStates = zeros(3, 5);
    segmentEndStates = zeros(3, 5);

    for segment = 1:3
        deltaSegment_rad = elevatorBySegment(segment);
        segmentStartStates(segment, :) = segmentInitialState.';
        dynamics = @(t, state) longitudinalDynamics( ...
            t, state, thrust, deltaSegment_rad, ...
            aircraft, polar, aWing, alpha0L_rad);
        segmentTime = timeBoundaries(segment:segment + 1).';
        [timeSegment, statesSegment] = ode45( ...
            dynamics, segmentTime, segmentInitialState, options);
        segmentInitialState = statesSegment(end, :).';
        segmentEndStates(segment, :) = segmentInitialState.';

        if segment > 1
            timeSegment = timeSegment(2:end);
            statesSegment = statesSegment(2:end, :);
        end
        time = [time; timeSegment]; %#ok<AGROW>
        states = [states; statesSegment]; %#ok<AGROW>
    end

    deltaElevator_rad = deltaTrim_rad * ones(size(time));
    duringPulse = time >= pulseStart & time < pulseEnd;
    deltaElevator_rad(duringPulse) = deltaPulse_rad;

    simulation.time = time;
    simulation.states = states;
    simulation.state0 = state0;
    simulation.alpha_deg = rad2deg(states(:, 3) - states(:, 2));
    simulation.gamma_deg = rad2deg(states(:, 2));
    simulation.deltaElevator_deg = rad2deg(deltaElevator_rad);
    simulation.thrust = thrust;
    simulation.pulseStart = pulseStart;
    simulation.pulseEnd = pulseEnd;
    simulation.pulseAmplitude_deg = pulseAmplitude_deg;
    simulation.segmentStartStates = segmentStartStates;
    simulation.segmentEndStates = segmentEndStates;
end
