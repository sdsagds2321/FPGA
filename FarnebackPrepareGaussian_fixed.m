function G = FarnebackPrepareGaussian_fixed(n, sigma)
% FarnebackPrepareGaussian_fixed - Generate a Gaussian kernel for polynomial expansion
% 
% Inputs:
%   n     - Neighborhood size (e.g., 5 for a 5x5 window)
%   sigma - Standard deviation of the Gaussian
%
% Output:
%   G     - Gaussian kernel (n x n matrix)

    if nargin < 2
        sigma = 0.3 * ((n - 1) * 0.5 - 1) + 0.8;
    end
    
    % Create grid
    half = floor(n / 2);
    [x, y] = meshgrid(-half:half, -half:half);
    
    % Compute Gaussian
    G = exp(-(x.^2 + y.^2) / (2 * sigma^2));
    
    % Normalize
    G = G / sum(G(:));
end
