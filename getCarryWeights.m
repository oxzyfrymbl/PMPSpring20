%Function computes weights for a carry strategy that goes long high carry
%assets and short low carry assets.
%The function always goes long and short an equal number of assets, and
%will always be self-financing
%Between max and min number of assets the function always goes long and
%short the maximum number of assets available to form pairs
%Function uses computesort weights to get carry weights

%The inputs are:
% 1) Matrix of monthly carry values for each asset
% 2) Max number of assets to be included (i.e) Long + Short (must be even)
% 3) Min number of assets to be included in portfolio, if available assets
% are lower than this number, function returns NAN for this entry


function Weights = getCarryWeights(CarryMonthly, maxAssets, minAssets)

nMonths = size(CarryMonthly, 1);
nAssets = size(CarryMonthly, 2);
CarryWeights = zeros(nMonths, nAssets);

for i = 1:nMonths
    Carry = CarryMonthly(i, :);             %Grab carry for one period
    nAvailable = sum(isfinite(Carry), 2);   %Check how many assets are available
    
    %Caps nLongs and nShorts at maxAssets / 2
    if nAvailable >= maxAssets                                                              
        nLongs   = maxAssets/2;
        nShorts  = maxAssets/2;
        CarryWeights(i, :) = computeSortWeights(Carry, nLongs, nShorts, 1);
        
    %Checks if min assets are fulfilled
    elseif nAvailable >= minAssets
        MaxEven = 2*floor(nAvailable/2); %Computes highest even integer
        nLongs = MaxEven / 2; 
        nShorts = MaxEven / 2;
        CarryWeights(i, :) = computeSortWeights(Carry, nLongs, nShorts, 1);

    %Returns NAN if nAssets are too low
    else
        CarryWeights(i, :) = NaN;   
    end

end

%Returns weights
Weights = CarryWeights;
