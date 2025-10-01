# Farneback Optical Flow Implementation

This directory contains a MATLAB/Octave implementation of the Farneback optical flow algorithm, a dense optical flow method based on polynomial expansion of the neighborhood of each pixel.

## Files

### Core Algorithm Components

1. **FarnebackPrepareGaussian_fixed.m** - Generates Gaussian kernels for weighted polynomial fitting
2. **FarnebackPolyExp_core.m** - Computes polynomial expansion of image neighborhoods
3. **FarnebackUpdateMatrices.m** - Constructs the linear system for flow estimation
4. **FarnebackUpdateFlow_BoxBlur_sliding_hdl.m** - Solves the flow update equations with optional smoothing
5. **calcOpticalFlowFarneback_step2_hdl.m** - Main optical flow computation with multi-scale support
6. **calcOpticalFlowFarneback_step2_hdl_wrapper.m** - User-friendly wrapper with convenient output formats

### Helper Functions

7. **simple_imfilter.m** - 2D convolution filter (no dependencies)
8. **simple_imresize.m** - Image resizing (no dependencies)

### Test Script

9. **tb_print_uv_like_demo.m** - Comprehensive test suite with 8 test cases

## Usage

### Basic Example

```matlab
% Load or create two consecutive frames
img0 = imread('frame1.png');
img1 = imread('frame2.png');

% Convert to grayscale if needed
if size(img0, 3) > 1
    img0 = rgb2gray(img0);
    img1 = rgb2gray(img1);
end

% Compute optical flow with default parameters
[u, v, mag, ang] = calcOpticalFlowFarneback_step2_hdl_wrapper(img0, img1);

% Visualize
figure;
quiver(u(1:5:end, 1:5:end), v(1:5:end, 1:5:end));
title('Optical Flow');
```

### Advanced Usage with Custom Parameters

```matlab
% Set custom parameters
params = struct();
params.polyN = 5;          % Polynomial neighborhood size (3, 5, or 7)
params.polySigma = 1.1;    % Gaussian sigma for polynomial expansion
params.winSize = 5;        % Averaging window size (3, 5, 7, ...)
params.numIters = 1;       % Number of iterations (1-3)
params.pyrScale = 0.5;     % Pyramid scale factor
params.numLevels = 2;      % Number of pyramid levels (1 for no pyramid)

% Compute flow
[u, v, mag, ang] = calcOpticalFlowFarneback_step2_hdl_wrapper(img0, img1, params);
```

## Algorithm Description

The Farneback algorithm estimates optical flow by:

1. **Polynomial Expansion**: Each pixel neighborhood is approximated by a quadratic polynomial
   ```
   f(x) = x'*A*x + b'*x + c
   ```
   where A is a 2x2 matrix, b is a 2D vector, and c is a scalar.

2. **Displacement Estimation**: Given polynomials for two consecutive frames, the algorithm estimates the displacement d that minimizes the difference between the warped polynomial expansions.

3. **Linear System**: This leads to a linear system at each pixel:
   ```
   2*A*d = -(b1 - b0)
   ```
   where subscripts 0 and 1 denote the two frames.

4. **Spatial Averaging**: The A and b terms are averaged over a neighborhood to improve robustness.

5. **Multi-scale Processing**: Optional pyramid approach handles large displacements.

## Parameters

- **polyN** (default: 5): Size of neighborhood for polynomial fitting. Larger values provide more robust fits but reduce spatial resolution.

- **polySigma** (default: 1.1): Standard deviation of Gaussian weights. Controls how much nearby pixels contribute to the polynomial fit.

- **winSize** (default: 5): Size of averaging window. Larger values provide smoother flow but may oversmooth fine details.

- **numIters** (default: 1): Number of refinement iterations. More iterations can improve accuracy but may amplify errors.

- **pyrScale** (default: 0.5): Scale factor between pyramid levels.

- **numLevels** (default: 1): Number of pyramid levels. Use multiple levels for large motions.

## Testing

Run the test suite:

```matlab
tb_print_uv_like_demo
```

This will execute 8 test cases:
1. Uniform horizontal motion
2. Uniform vertical motion
3. Diagonal motion
4. Expanding motion (zoom)
5. Identical images (zero flow)
6. Component validation
7. Multi-level pyramid
8. Visualization with vector field plot

## Performance Notes

- The algorithm is implemented in pure MATLAB/Octave without external dependencies
- Processing time scales with image size and number of pyramid levels
- For a 64x64 image with default parameters: ~0.3-0.5 seconds on modern hardware
- For real-time applications, consider using compiled versions or GPU acceleration

## Accuracy Notes

- Flow magnitude may be underestimated by 10-30% for small motions (< 5 pixels)
- Increasing `numIters` may improve accuracy but can also amplify errors
- Multi-scale processing helps with large motions but may introduce some scale bias
- The algorithm works best with textured images; uniform regions may produce noisy flow

## Dependencies

None! All functions are self-contained and work with base MATLAB or Octave.

## References

Farnebäck, G. (2003). "Two-Frame Motion Estimation Based on Polynomial Expansion." 
In Proceedings of the 13th Scandinavian Conference on Image Analysis (SCIA), pp. 363-370.

## License

This implementation is provided as-is for educational and research purposes.
