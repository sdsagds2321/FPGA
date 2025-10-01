function [R, basis] = FarnebackPolyExp_core(img, n, sigma)
% FarnebackPolyExp_core - Polynomial expansion of an image
%
% This function computes a polynomial expansion of each pixel's neighborhood
% using a quadratic polynomial model: f(x) = x'*A*x + b'*x + c
%
% Inputs:
%   img   - Input image (grayscale, double)
%   n     - Neighborhood size (should be odd, e.g., 5)
%   sigma - Standard deviation for Gaussian weighting
%
% Outputs:
%   R     - Polynomial coefficients (H x W x 6), where each pixel has [r1, r2, r3, r4, r5, r6]
%           representing [A11, A12, A22, b1, b2, c]
%   basis - Basis matrix used for polynomial fitting

    % Ensure image is double
    img = double(img);
    [H, W] = size(img);
    
    % Get Gaussian kernel
    G = FarnebackPrepareGaussian_fixed(n, sigma);
    
    % Create polynomial basis
    half = floor(n / 2);
    [x, y] = meshgrid(-half:half, -half:half);
    
    % Basis functions: [x^2, xy, y^2, x, y, 1]
    % Build basis in column-major order to match MATLAB's (:) operator
    basis = zeros(n*n, 6);
    x_vec = x(:);  % Column-major vectorization
    y_vec = y(:);
    for idx = 1:n*n
        basis(idx, :) = [x_vec(idx)^2, x_vec(idx)*y_vec(idx), y_vec(idx)^2, x_vec(idx), y_vec(idx), 1];
    end
    
    % Apply Gaussian weighting to basis
    G_vec = G(:);
    basis_weighted = basis .* sqrt(G_vec);
    
    % Pre-compute (B'*B)^-1 * B'
    AtA_inv = inv(basis_weighted' * basis_weighted);
    solve_mat = AtA_inv * basis_weighted';
    
    % Initialize output
    R = zeros(H, W, 6);
    
    % Pad image for boundary handling (manual implementation)
    img_pad = zeros(H + 2*half, W + 2*half);
    img_pad(half+1:half+H, half+1:half+W) = img;
    
    % Replicate borders
    img_pad(1:half, half+1:half+W) = repmat(img(1, :), half, 1);
    img_pad(half+H+1:end, half+1:half+W) = repmat(img(end, :), half, 1);
    img_pad(:, 1:half) = repmat(img_pad(:, half+1), 1, half);
    img_pad(:, half+W+1:end) = repmat(img_pad(:, half+W), 1, half);
    
    % Process each pixel
    for i = 1:H
        for j = 1:W
            % Extract neighborhood
            neighborhood = img_pad(i:i+n-1, j:j+n-1);
            f_vec = neighborhood(:);
            
            % Apply Gaussian weighting
            f_weighted = f_vec .* sqrt(G_vec);
            
            % Solve for polynomial coefficients
            coeffs = solve_mat * f_weighted;
            R(i, j, :) = coeffs;
        end
    end
end
