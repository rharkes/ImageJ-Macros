function [ h,xbins,ybins ] = hist2r( val )
%calculates a 2D histogram using integer bins.
% INPUT :
% -val N x 2 position values
%
% OUTPUT :
% - h histogram values
% - xbins
% - ybins

%# bin centers (integers)
xbins = floor(min(val(:,1))):1:ceil(max(val(:,1)));
ybins = floor(min(val(:,2))):1:ceil(max(val(:,2)));
xNumBins = numel(xbins); yNumBins = numel(ybins);

%# map val(:,1)/val(:,2) values to bin indices
Xi = round( interp1(xbins, 1:xNumBins, val(:,1), 'linear', 'extrap') );
Yi = round( interp1(ybins, 1:yNumBins, val(:,2), 'linear', 'extrap') );

%# limit indices to the range [1,numBins]
Xi = max( min(Xi,xNumBins), 1);
Yi = max( min(Yi,yNumBins), 1);

%# count number of elements in each bin
h = accumarray([Yi(:) Xi(:)], 1, [yNumBins xNumBins]);
end

