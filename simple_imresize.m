function img_out = simple_imresize(img_in, scale_or_size)
% simple_imresize - Simple image resize (replacement for imresize)
%
% Inputs:
%   img_in        - Input image
%   scale_or_size - Either a scale factor (e.g., 0.5) or target size [H, W]
%
% Output:
%   img_out - Resized image

    [H_in, W_in] = size(img_in);
    
    if length(scale_or_size) == 1
        % Scale factor
        scale = scale_or_size;
        H_out = round(H_in * scale);
        W_out = round(W_in * scale);
    else
        % Target size
        H_out = scale_or_size(1);
        W_out = scale_or_size(2);
    end
    
    % Use nearest neighbor interpolation for simplicity
    img_out = zeros(H_out, W_out);
    
    for i = 1:H_out
        for j = 1:W_out
            % Map output pixel to input pixel
            i_in = min(max(round(i * H_in / H_out), 1), H_in);
            j_in = min(max(round(j * W_in / W_out), 1), W_in);
            img_out(i, j) = img_in(i_in, j_in);
        end
    end
end
