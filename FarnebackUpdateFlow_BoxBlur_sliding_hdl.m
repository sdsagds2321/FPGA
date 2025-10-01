function flow_out = FarnebackUpdateFlow_BoxBlur_sliding_hdl(matM, flow_in, n, num_iter)
% FarnebackUpdateFlow_BoxBlur_sliding_hdl - Update optical flow using iterative refinement
%
% This function solves the linear system at each pixel to update the flow field,
% with optional iterative refinement and smoothing.
%
% Inputs:
%   matM     - Structure with fields A and b from FarnebackUpdateMatrices
%              matM.A: (H x W x 2 x 2)
%              matM.b: (H x W x 2)
%   flow_in  - Initial flow estimate (H x W x 2)
%   n        - Box filter size for smoothing (default: 5)
%   num_iter - Number of iterations for refinement (default: 1)
%
% Output:
%   flow_out - Updated flow field (H x W x 2)

    if nargin < 3
        n = 5;
    end
    if nargin < 4
        num_iter = 1;
    end
    
    [H, W, ~] = size(flow_in);
    flow_out = flow_in;
    
    % Iterative refinement
    for iter = 1:num_iter
        delta_flow = zeros(H, W, 2);
        
        % Solve for flow update at each pixel
        for i = 1:H
            for j = 1:W
                % Extract 2x2 matrix A and 2x1 vector b
                A = squeeze(matM.A(i, j, :, :));
                b = squeeze(matM.b(i, j, :));
                
                % Normalize for better conditioning
                scale = max(abs(A(:)));
                if scale > 1e-6
                    A = A / scale;
                    b = b / scale;
                end
                
                % Add regularization for stability
                reg = 1e-3;
                A(1,1) = A(1,1) + reg;
                A(2,2) = A(2,2) + reg;
                
                % Check for singularity and solve
                det_A = A(1,1)*A(2,2) - A(1,2)*A(2,1);
                
                if abs(det_A) > 1e-9
                    % Solve A * delta = b using matrix inversion
                    delta = A \ b;
                    % Clamp delta to reasonable values
                    delta = max(min(delta, 10), -10);
                    delta_flow(i, j, :) = delta;
                end
            end
        end
        
        % Update flow
        flow_out = flow_out + delta_flow;
        
        % Apply box blur smoothing
        if n > 1
            h_box = ones(n, n) / (n*n);
            flow_out(:,:,1) = simple_imfilter(flow_out(:,:,1), h_box, 'replicate');
            flow_out(:,:,2) = simple_imfilter(flow_out(:,:,2), h_box, 'replicate');
        end
    end
end
