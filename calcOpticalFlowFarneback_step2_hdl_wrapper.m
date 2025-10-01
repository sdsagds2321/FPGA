function [u, v, mag, ang] = calcOpticalFlowFarneback_step2_hdl_wrapper(img0, img1, params)
% calcOpticalFlowFarneback_step2_hdl_wrapper - Wrapper for Farneback optical flow
%
% This wrapper function provides a convenient interface to the Farneback algorithm,
% handling edge cases and providing additional output formats.
%
% Inputs:
%   img0   - Previous frame (grayscale)
%   img1   - Current frame (grayscale)
%   params - Optional parameters structure (see calcOpticalFlowFarneback_step2_hdl)
%
% Outputs:
%   u      - Horizontal flow component (H x W)
%   v      - Vertical flow component (H x W)
%   mag    - Flow magnitude (H x W)
%   ang    - Flow angle in degrees (H x W)

    % Handle default parameters
    if nargin < 3
        params = struct();
        params.polyN = 5;
        params.polySigma = 1.1;
        params.winSize = 5;
        params.numIters = 1;
        params.pyrScale = 0.5;
        params.numLevels = 1;
    end
    
    % Validate inputs
    if size(img0, 3) > 1
        img0 = rgb2gray(img0);
    end
    if size(img1, 3) > 1
        img1 = rgb2gray(img1);
    end
    
    % Check if images have the same size
    if ~isequal(size(img0), size(img1))
        error('Input images must have the same dimensions');
    end
    
    % Handle edge case: identical images
    if isequal(img0, img1)
        [H, W] = size(img0);
        u = zeros(H, W);
        v = zeros(H, W);
        mag = zeros(H, W);
        ang = zeros(H, W);
        return;
    end
    
    % Call main optical flow function
    flow = calcOpticalFlowFarneback_step2_hdl(img0, img1, params);
    
    % Extract components
    u = flow(:,:,1);
    v = flow(:,:,2);
    
    % Compute magnitude and angle
    mag = sqrt(u.^2 + v.^2);
    ang = atan2d(v, u);
end
