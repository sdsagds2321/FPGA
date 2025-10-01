function [flow, R0, R1] = calcOpticalFlowFarneback_step2_hdl(img0, img1, params)
% calcOpticalFlowFarneback_step2_hdl - Main Farneback optical flow computation
%
% This function implements the Farneback optical flow algorithm, computing
% dense flow fields between two consecutive frames.
%
% Inputs:
%   img0   - Previous frame (grayscale, double or uint8)
%   img1   - Current frame (grayscale, double or uint8)
%   params - Structure with algorithm parameters:
%            .polyN: polynomial neighborhood size (default: 5)
%            .polySigma: polynomial expansion sigma (default: 1.1)
%            .winSize: averaging window size (default: 13)
%            .numIters: number of iterations at each level (default: 3)
%            .pyrScale: pyramid scale factor (default: 0.5)
%            .numLevels: number of pyramid levels (default: 1)
%
% Outputs:
%   flow   - Optical flow field (H x W x 2), where flow(:,:,1) is u and flow(:,:,2) is v
%   R0     - Polynomial expansion of img0 (for debugging)
%   R1     - Polynomial expansion of img1 (for debugging)

    % Set default parameters
    if nargin < 3
        params = struct();
    end
    if ~isfield(params, 'polyN'), params.polyN = 5; end
    if ~isfield(params, 'polySigma'), params.polySigma = 1.1; end
    if ~isfield(params, 'winSize'), params.winSize = 5; end
    if ~isfield(params, 'numIters'), params.numIters = 1; end
    if ~isfield(params, 'pyrScale'), params.pyrScale = 0.5; end
    if ~isfield(params, 'numLevels'), params.numLevels = 1; end
    
    % Convert to double
    img0 = double(img0);
    img1 = double(img1);
    
    % Normalize to [0, 1] if needed
    if max(img0(:)) > 1
        img0 = img0 / 255;
    end
    if max(img1(:)) > 1
        img1 = img1 / 255;
    end
    
    [H, W] = size(img0);
    
    % Build image pyramids if multiple levels requested
    if params.numLevels > 1
        pyr0 = cell(params.numLevels, 1);
        pyr1 = cell(params.numLevels, 1);
        
        pyr0{1} = img0;
        pyr1{1} = img1;
        
        for level = 2:params.numLevels
            pyr0{level} = simple_imresize(pyr0{level-1}, params.pyrScale);
            pyr1{level} = simple_imresize(pyr1{level-1}, params.pyrScale);
        end
        
        % Start from coarsest level
        [H_coarse, W_coarse] = size(pyr0{end});
        flow = zeros(H_coarse, W_coarse, 2);
        
        % Process each pyramid level
        for level = params.numLevels:-1:1
            % Get images at current level
            I0 = pyr0{level};
            I1 = pyr1{level};
            
            % Upsample flow if not at coarsest level
            if level < params.numLevels
                scale_factor = 1 / params.pyrScale;
                flow_u = simple_imresize(flow(:,:,1), size(I0)) * scale_factor;
                flow_v = simple_imresize(flow(:,:,2), size(I0)) * scale_factor;
                flow = cat(3, flow_u, flow_v);
            end
            
            % Compute polynomial expansions
            R0 = FarnebackPolyExp_core(I0, params.polyN, params.polySigma);
            R1 = FarnebackPolyExp_core(I1, params.polyN, params.polySigma);
            
            % Iteratively update flow
            for iter = 1:params.numIters
                % Compute update matrices
                matM = FarnebackUpdateMatrices(R0, R1, flow, params.winSize);
                
                % Update flow
                flow = FarnebackUpdateFlow_BoxBlur_sliding_hdl(matM, flow, params.winSize, 1);
            end
        end
    else
        % Single level processing
        % Compute polynomial expansions
        R0 = FarnebackPolyExp_core(img0, params.polyN, params.polySigma);
        R1 = FarnebackPolyExp_core(img1, params.polyN, params.polySigma);
        
        % Initialize flow to zero
        flow = zeros(H, W, 2);
        
        % Iteratively update flow
        for iter = 1:params.numIters
            % Compute update matrices
            matM = FarnebackUpdateMatrices(R0, R1, flow, params.winSize);
            
            % Update flow
            flow = FarnebackUpdateFlow_BoxBlur_sliding_hdl(matM, flow, params.winSize, 1);
        end
    end
end
