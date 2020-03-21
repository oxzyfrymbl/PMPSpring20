clc
clear
close all

% Parameters
nLongs = 3;
nShorts = 3;

% Load FX data
PrepareFXData;

currencyCodes = ['CAD'; 'GBP'; 'EUR'; 'SEK'; 'CHF'; 'JPY'; 'HKD'; 'AUD'; 'BRL'; 'CLP'; 'CNY'; 'HUF'; 'MYR'; 'MXN'; 'NZD'; 'PLN'; 'ZAR'; 'KRW'; 'SGD'; 'TWD'; 'THB'; 'TRY'];

nCountries = size(FXFwdRates, 2);
nDays = size(FXFwdRates, 1);
nMonths = length(firstDayList);

monthlyFXFwdRates = [FXFwdRates(1, :); FXFwdRates(lastDayList, :)];
monthlyFXSpotRates = [FXSpotRates(1, :); FXSpotRates(lastDayList, :)];

% Calculate carry matrix
carry = (monthlyFXSpotRates - monthlyFXFwdRates) ./ monthlyFXFwdRates;
carry = carry(1 : end - 1, :); % we don't need the last one

% Calculate returns
monthlyXsReturns = monthlyFXFwdRates(1 : end - 1, :) ./ monthlyFXSpotRates(2 : end, :) - 1;

% Weights
carryWeights = zeros(nMonths, nCountries);

for i = 1 : nMonths
    carryWeights(i, :) = computeSortWeights(carry(i, :), nLongs, nShorts, 1);
end

currencyCarryXsReturns = nansum(-carryWeights .* monthlyXsReturns, 2);
currencyCarryNAV = cumprod(1 + currencyCarryXsReturns);

% Plot
dates4Fig = datetime(dates, 'ConvertFrom', 'yyyymmdd');
dates4FigMonthly = dates4Fig(lastDayList);
plot(dates4FigMonthly, currencyCarryNAV)