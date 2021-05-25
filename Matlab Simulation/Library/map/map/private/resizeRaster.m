function B = resizeRaster(A, xSample, ySample, method, antialiasing)
% Returns a resized raster using a resized raster reference object's size

% Copyright 2018 The MathWorks, Inc.
    
    % Convert binary image to uint8.
    if islogical(A)
        A = uint8(255) .* uint8(A);
    end
    
    % Calculate interpolation weights and indices for each dimension.
    weights = cell(1,2);
    indices = cell(1,2);
    allDimNearestNeighbor = true;
    
    outRasterSize = [length(ySample) length(xSample)];
    inRasterSize = size(A);
    sample = {ySample xSample};
    
    for k = 1:2
        [weights{k}, indices{k}] = contributions(inRasterSize(k), ...
            sample{k}, method, antialiasing);
        
        if ~matlab.images.internal.resize.isPureNearestNeighborComputation(weights{k})
            allDimNearestNeighbor = false;
        end
    end
    
    if allDimNearestNeighbor
        B = matlab.images.internal.resize.resizeAllDimUsingNearestNeighbor(A, indices);
    else
        % Determine which dimension to resize first.
        orderedDims = matlab.images.internal.resize.dimensionOrder(outRasterSize);
        B = A;
        for dim = orderedDims
            B = resizeAlongDim(B, dim, weights{dim}, indices{dim});
        end
    end
end


function [kernel, width] = kernelAndWidth(method)
% Select the kernel and kernel width corresponding to a method
    
    switch method
        case "cubic"
            kernel = @matlab.images.internal.resize.cubic;
            width = 4.0;
        case "bilinear"
            kernel = @matlab.images.internal.resize.triangle;
            width = 2.0;
        case "nearest"
            kernel = @matlab.images.internal.resize.box;
            width = 1.0;
    end
end


function [weights, indices] = contributions(in_length, u, method, antialiasing)
% Calculate the weights and indices vectors for a dimension
    
    scale = 1/(u(2)-u(1));
    [kernel, kernel_width] = kernelAndWidth(method);
    if (scale < 1) && (antialiasing)
        % Use a modified kernel to simultaneously interpolate and
        % anti-alias.
        h = @(x) scale * kernel(scale * x);
        kernel_width = kernel_width / scale;
    else
        % No anti-aliasing; use unmodified kernel.
        h = kernel;
    end

    % What is the left-most sample that can be involved in the computation?
    left = floor(u - kernel_width/2);

    % What is the maximum number of samples that can be involved in the
    % computation?  Note: it's OK to use an extra sample here; if the
    % corresponding weights are all zero, it will be eliminated at the end
    % of this function.
    P = ceil(kernel_width) + 2;

    % The indices of the input samples involved in computing the k-th output
    % sample are in row k of the indices matrix.
    indices = left + (0:P-1);

    % The weights used to compute the k-th output sample are in row k of the
    % weights matrix.
    weights = h(u - indices);

    % Normalize the weights matrix so that each row sums to 1.
    weights = weights ./ sum(weights, 2);

    % Mirror out-of-bounds indices; equivalent of doing symmetric padding
    aux = [1:in_length,in_length:-1:1];
    indices = aux(mod(indices-1,length(aux)) + 1);

    % If a column in weights is all zero, get rid of it.
    kill = find(~any(weights, 1));
    if ~isempty(kill)
        weights(:,kill) = [];
        indices(:,kill) = [];
    end
end


function out = resizeAlongDim(in, dim, weights, indices)
% Resize along a specified dimension
%
% in           - input array to be resized
% dim          - dimension along which to resize
% weights      - weight matrix; row k is weights for k-th output sample
% indices      - indices matrix; row k is indices for k-th output sample
    
    if matlab.images.internal.resize.isPureNearestNeighborComputation(weights)
        out = matlab.images.internal.resize.resizeAlongDimUsingNearestNeighbor(in, ...
            dim, indices);
    else
        % The 'out' will be uint8 if 'in' is logical
        % Otherwise 'out' datatype will be same as 'in' datatype
        out = matlab.images.internal.resize.imresizemex(in, weights', indices', dim);
    end
end
