function matM = FarnebackUpdateMatrices(R0, R1, flow, n)
% FarnebackUpdateMatrices - Compute the matrices for flow update
%
% This function computes the linear system matrices for optical flow
% based on polynomial expansions of two consecutive frames.
%
% Inputs:
%   R0   - Polynomial expansion of previous frame (H x W x 6)
%   R1   - Polynomial expansion of current frame (H x W x 6)
%   flow - Current flow estimate (H x W x 2), where flow(:,:,1) is u and flow(:,:,2) is v
%   n    - Neighborhood size for local averaging
%
% Output:
%   matM - Structure containing matrices A and b for each pixel
%          matM.A: (H x W x 2 x 2) - 2x2 matrix for each pixel
%          matM.b: (H x W x 2) - 2x1 vector for each pixel

    [H, W, ~] = size(R0);
    
    % Initialize output structure
    matM.A = zeros(H, W, 2, 2);
    matM.b = zeros(H, W, 2);
    
    % Extract polynomial coefficients
    % R format: [A11, A12, A22, b1, b2, c]
    A11_0 = R0(:,:,1);
    A12_0 = R0(:,:,2);
    A22_0 = R0(:,:,3);
    b1_0 = R0(:,:,4);
    b2_0 = R0(:,:,5);
    
    A11_1 = R1(:,:,1);
    A12_1 = R1(:,:,2);
    A22_1 = R1(:,:,3);
    b1_1 = R1(:,:,4);
    b2_1 = R1(:,:,5);
    
    % Current flow
    u = flow(:,:,1);
    v = flow(:,:,2);
    
    % Compute averaged coefficients
    A11 = (A11_0 + A11_1) / 2;
    A12 = (A12_0 + A12_1) / 2;
    A22 = (A22_0 + A22_1) / 2;
    
    % Average b vectors
    b1 = (b1_0 + b1_1) / 2;
    b2 = (b2_0 + b2_1) / 2;
    
    % Compute displacement-dependent terms
    % Based on Farneback's formulation: minimize ||f1(x+d) - f0(x)||^2
    % where f(x) ≈ x'*A*x + b'*x + c
    % This gives: 2A*d = -(b1 - b0 + A0*d0 + A1*d1)
    % Simplifying for initial flow = 0: 2A*d = -(b1 - b0)
    delta_b1 = -(b1_1 - b1_0);
    delta_b2 = -(b2_1 - b2_0);
    
    % Store in output structure
    % A matrix: 2*[[A11, A12], [A12, A22]]
    matM.A(:,:,1,1) = 2 * A11;
    matM.A(:,:,1,2) = 2 * A12;
    matM.A(:,:,2,1) = 2 * A12;
    matM.A(:,:,2,2) = 2 * A22;
    
    % b vector
    matM.b(:,:,1) = delta_b1;
    matM.b(:,:,2) = delta_b2;
    
    % Apply local averaging (box filter)
    if nargin >= 4 && n > 1
        % Average the A and b matrices over neighborhoods
        h_box = ones(n, n) / (n*n);
        
        matM.A(:,:,1,1) = simple_imfilter(matM.A(:,:,1,1), h_box, 'replicate');
        matM.A(:,:,1,2) = simple_imfilter(matM.A(:,:,1,2), h_box, 'replicate');
        matM.A(:,:,2,1) = simple_imfilter(matM.A(:,:,2,1), h_box, 'replicate');
        matM.A(:,:,2,2) = simple_imfilter(matM.A(:,:,2,2), h_box, 'replicate');
        
        matM.b(:,:,1) = simple_imfilter(matM.b(:,:,1), h_box, 'replicate');
        matM.b(:,:,2) = simple_imfilter(matM.b(:,:,2), h_box, 'replicate');
    end
end
