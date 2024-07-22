function angle = calculateAngleWithOrigin_V2(point1, point2, point3)
    % Calculate vectors
    vector1 = point1 - point2;
    vector3 = point3 - point2;

    % Calculate angles in radians
    angle1 = atan2(vector1(2), vector1(1));
    angle3 = atan2(vector3(2), vector3(1));

    % Calculate relative angle
    angleRad = angle3 - angle1;

    % Convert angle to degrees and ensure it's in the range [0, 360)
    angle = mod(rad2deg(angleRad), 360);
end