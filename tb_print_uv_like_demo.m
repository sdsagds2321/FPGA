%% tb_print_uv_like_demo.m - Test script for Farneback optical flow
% This script validates the Farneback optical flow implementation with
% multiple test cases including synthetic and edge cases.

clear all;
close all;
clc;

fprintf('=== Farneback Optical Flow Test Suite ===\n\n');

%% Test 1: Uniform horizontal motion
fprintf('Test 1: Uniform horizontal motion\n');
fprintf('----------------------------------\n');

% Create synthetic test images
img_size = 64;
img0 = zeros(img_size, img_size);
img1 = zeros(img_size, img_size);

% Create a pattern that moves horizontally
[X, Y] = meshgrid(1:img_size, 1:img_size);
pattern = sin(2*pi*X/16) .* sin(2*pi*Y/16);
img0 = pattern;

% Shift pattern by 5 pixels to the right
shift = 5;
img1(:, shift+1:end) = img0(:, 1:end-shift);
img1(:, 1:shift) = img0(:, end-shift+1:end);  % Wrap around

% Set parameters
params = struct();
params.polyN = 5;
params.polySigma = 1.1;
params.winSize = 13;
params.numIters = 3;
params.pyrScale = 0.5;
params.numLevels = 1;

% Compute optical flow
[u, v, mag, ang] = calcOpticalFlowFarneback_step2_hdl_wrapper(img0, img1, params);

% Display results
fprintf('Expected flow: u = %.1f, v = 0\n', shift);
fprintf('Mean computed flow: u = %.3f, v = %.3f\n', mean(u(:)), mean(v(:)));
fprintf('Flow magnitude range: [%.3f, %.3f]\n', min(mag(:)), max(mag(:)));
fprintf('Non-zero flow pixels: %d / %d\n', sum(mag(:) > 0.1), numel(mag));

if mean(mag(:)) > 0.5
    fprintf('✓ Test 1 PASSED: Flow detected\n\n');
else
    fprintf('✗ Test 1 FAILED: Flow magnitude too small\n\n');
end

%% Test 2: Uniform vertical motion
fprintf('Test 2: Uniform vertical motion\n');
fprintf('--------------------------------\n');

% Create pattern that moves vertically
img0 = pattern;
shift_v = 3;
img1(shift_v+1:end, :) = img0(1:end-shift_v, :);
img1(1:shift_v, :) = img0(end-shift_v+1:end, :);  % Wrap around

% Compute optical flow
[u, v, mag, ang] = calcOpticalFlowFarneback_step2_hdl_wrapper(img0, img1, params);

fprintf('Expected flow: u = 0, v = %.1f\n', shift_v);
fprintf('Mean computed flow: u = %.3f, v = %.3f\n', mean(u(:)), mean(v(:)));
fprintf('Flow magnitude range: [%.3f, %.3f]\n', min(mag(:)), max(mag(:)));

if mean(mag(:)) > 0.5
    fprintf('✓ Test 2 PASSED: Flow detected\n\n');
else
    fprintf('✗ Test 2 FAILED: Flow magnitude too small\n\n');
end

%% Test 3: Diagonal motion
fprintf('Test 3: Diagonal motion\n');
fprintf('-----------------------\n');

% Create pattern that moves diagonally
img0 = pattern;
shift_h = 3;
shift_v = 3;

img1_temp = zeros(size(img0));
for i = 1:img_size
    for j = 1:img_size
        i_new = mod(i + shift_v - 1, img_size) + 1;
        j_new = mod(j + shift_h - 1, img_size) + 1;
        img1_temp(i_new, j_new) = img0(i, j);
    end
end
img1 = img1_temp;

% Compute optical flow
[u, v, mag, ang] = calcOpticalFlowFarneback_step2_hdl_wrapper(img0, img1, params);

fprintf('Expected flow: u = %.1f, v = %.1f\n', shift_h, shift_v);
fprintf('Mean computed flow: u = %.3f, v = %.3f\n', mean(u(:)), mean(v(:)));
fprintf('Flow magnitude range: [%.3f, %.3f]\n', min(mag(:)), max(mag(:)));

if mean(mag(:)) > 0.5
    fprintf('✓ Test 3 PASSED: Flow detected\n\n');
else
    fprintf('✗ Test 3 FAILED: Flow magnitude too small\n\n');
end

%% Test 4: Expanding motion (zoom out)
fprintf('Test 4: Expanding motion\n');
fprintf('------------------------\n');

% Create radial pattern
[X, Y] = meshgrid(linspace(-1, 1, img_size), linspace(-1, 1, img_size));
R = sqrt(X.^2 + Y.^2);
img0 = sin(10*pi*R);

% Create zoomed out version
scale = 0.9;
[X1, Y1] = meshgrid(linspace(-1/scale, 1/scale, img_size), linspace(-1/scale, 1/scale, img_size));
R1 = sqrt(X1.^2 + Y1.^2);
img1 = sin(10*pi*R1);

% Compute optical flow
[u, v, mag, ang] = calcOpticalFlowFarneback_step2_hdl_wrapper(img0, img1, params);

fprintf('Mean computed flow magnitude: %.3f\n', mean(mag(:)));
fprintf('Flow magnitude range: [%.3f, %.3f]\n', min(mag(:)), max(mag(:)));

if mean(mag(:)) > 0.3
    fprintf('✓ Test 4 PASSED: Flow detected\n\n');
else
    fprintf('✗ Test 4 FAILED: Flow magnitude too small\n\n');
end

%% Test 5: Edge case - identical images
fprintf('Test 5: Edge case - identical images\n');
fprintf('------------------------------------\n');

img0 = pattern;
img1 = pattern;

% Compute optical flow
[u, v, mag, ang] = calcOpticalFlowFarneback_step2_hdl_wrapper(img0, img1, params);

fprintf('Mean computed flow: u = %.3f, v = %.3f\n', mean(u(:)), mean(v(:)));
fprintf('Max flow magnitude: %.3f\n', max(mag(:)));

if max(mag(:)) < 0.1
    fprintf('✓ Test 5 PASSED: Zero flow for identical images\n\n');
else
    fprintf('✗ Test 5 FAILED: Non-zero flow for identical images\n\n');
end

%% Test 6: Component validation
fprintf('Test 6: Component validation\n');
fprintf('---------------------------\n');

% Test polynomial expansion
img_test = rand(32, 32);
[R, basis] = FarnebackPolyExp_core(img_test, 5, 1.1);

fprintf('Polynomial expansion output size: %dx%dx%d\n', size(R, 1), size(R, 2), size(R, 3));
fprintf('Polynomial basis size: %dx%d\n', size(basis, 1), size(basis, 2));

if size(R, 3) == 6 && size(basis, 2) == 6
    fprintf('✓ Test 6 PASSED: Polynomial expansion correct\n\n');
else
    fprintf('✗ Test 6 FAILED: Polynomial expansion incorrect\n\n');
end

%% Test 7: Multi-level pyramid
fprintf('Test 7: Multi-level pyramid\n');
fprintf('--------------------------\n');

% Use larger image for pyramid test
img_size = 128;
[X, Y] = meshgrid(1:img_size, 1:img_size);
pattern_large = sin(2*pi*X/32) .* sin(2*pi*Y/32);
img0_large = pattern_large;

% Shift pattern
shift = 8;
img1_large = circshift(pattern_large, [0, shift]);

% Set parameters with multiple levels
params_pyr = params;
params_pyr.numLevels = 3;

% Compute optical flow
[u, v, mag, ang] = calcOpticalFlowFarneback_step2_hdl_wrapper(img0_large, img1_large, params_pyr);

fprintf('Expected flow: u = %.1f, v = 0\n', shift);
fprintf('Mean computed flow: u = %.3f, v = %.3f\n', mean(u(:)), mean(v(:)));
fprintf('Flow magnitude range: [%.3f, %.3f]\n', min(mag(:)), max(mag(:)));

if mean(mag(:)) > 1.0
    fprintf('✓ Test 7 PASSED: Multi-level flow detected\n\n');
else
    fprintf('✗ Test 7 FAILED: Multi-level flow magnitude too small\n\n');
end

%% Visualization
fprintf('Test 8: Visualization\n');
fprintf('--------------------\n');

% Create a test with clear motion for visualization
img_size = 64;
img0 = zeros(img_size, img_size);
img0(20:40, 20:40) = 1;  % White square

img1 = zeros(img_size, img_size);
img1(20:40, 25:45) = 1;  % Shifted white square

% Compute flow
[u, v, mag, ang] = calcOpticalFlowFarneback_step2_hdl_wrapper(img0, img1, params);

% Display
figure('Name', 'Optical Flow Visualization');
subplot(2, 3, 1);
imagesc(img0);
colormap gray;
title('Frame 0');
axis equal tight;

subplot(2, 3, 2);
imagesc(img1);
colormap gray;
title('Frame 1');
axis equal tight;

subplot(2, 3, 3);
imagesc(mag);
colorbar;
title('Flow Magnitude');
axis equal tight;

subplot(2, 3, 4);
imagesc(u);
colorbar;
title('Horizontal Flow (u)');
axis equal tight;

subplot(2, 3, 5);
imagesc(v);
colorbar;
title('Vertical Flow (v)');
axis equal tight;

subplot(2, 3, 6);
% Plot flow vectors (downsampled for clarity)
step = 4;
[X, Y] = meshgrid(1:step:img_size, 1:step:img_size);
u_down = u(1:step:end, 1:step:end);
v_down = v(1:step:end, 1:step:end);
quiver(X, Y, u_down, v_down, 2);
title('Flow Vectors');
axis equal tight;
set(gca, 'YDir', 'reverse');

fprintf('Flow visualization created\n');
fprintf('Mean flow in square region: u = %.3f, v = %.3f\n', mean(mean(u(20:40, 20:40))), mean(mean(v(20:40, 20:40))));

if mean(mean(u(20:40, 20:40))) > 2.0
    fprintf('✓ Test 8 PASSED: Flow in expected direction\n\n');
else
    fprintf('✗ Test 8 FAILED: Flow magnitude or direction incorrect\n\n');
end

%% Summary
fprintf('=== Test Suite Complete ===\n');
fprintf('All components have been tested.\n');
fprintf('Check the figure window for flow visualization.\n');
