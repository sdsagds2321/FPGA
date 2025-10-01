function img_out = simple_imfilter(img_in, kernel, mode)
% simple_imfilter - Simple 2D convolution filter (replacement for imfilter)
%
% Inputs:
%   img_in - Input image
%   kernel - Filter kernel
%   mode   - Boundary handling mode ('replicate' or 'symmetric')
%
% Output:
%   img_out - Filtered image

    if nargin < 3
        mode = 'replicate';
    end
    
    [H, W] = size(img_in);
    [kH, kW] = size(kernel);
    
    half_h = floor(kH / 2);
    half_w = floor(kW / 2);
    
    % Pad image
    img_pad = zeros(H + 2*half_h, W + 2*half_w);
    img_pad(half_h+1:half_h+H, half_w+1:half_w+W) = img_in;
    
    % Replicate borders
    img_pad(1:half_h, half_w+1:half_w+W) = repmat(img_in(1, :), half_h, 1);
    img_pad(half_h+H+1:end, half_w+1:half_w+W) = repmat(img_in(end, :), half_h, 1);
    img_pad(:, 1:half_w) = repmat(img_pad(:, half_w+1), 1, half_w);
    img_pad(:, half_w+W+1:end) = repmat(img_pad(:, half_w+W), 1, half_w);
    
    % Apply convolution
    img_out = zeros(H, W);
    for i = 1:H
        for j = 1:W
            region = img_pad(i:i+kH-1, j:j+kW-1);
            img_out(i, j) = sum(sum(region .* kernel));
        end
    end
end
