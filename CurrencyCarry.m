clc
clear
close all

% Parameters
nLongs = 3;
nShorts = 3;

% Load FX data
PrepareFXData;

% Define currencies
currencyCodes = {'CAD', 'GBP', 'EUR', 'SEK', 'CHF', 'JPY', 'HKD', 'AUD', 'BRL', 'CLP', 'CNY', 'HUF', 'MYR', 'MXN', 'NZD', 'PLN', 'ZAR', 'KRW', 'SGD', 'TWD', 'THB', 'TRY'};

% Exclude currencies
excludedCurrencies = {}; % Add currencies to exclude here
usedCurrencies = ~ismember(currencyCodes, excludedCurrencies);
FXFwdRates = FXFwdRates(:, usedCurrencies);
FXSpotRates = FXSpotRates(:, usedCurrencies);

% Switch to price notation (USD price of 1 unit foreign currency)
FXFwdRates = 1 ./ FXFwdRates;
FXSpotRates = 1 ./ FXSpotRates;

nCountries = size(FXFwdRates, 2);
nDays = size(FXFwdRates, 1);
nMonths = length(firstDayList);

monthlyFXFwdRates = [FXFwdRates(1, :); FXFwdRates(lastDayList, :)];
monthlyFXSpotRates = [FXSpotRates(1, :); FXSpotRates(lastDayList, :)];

% Calculate carry matrix
carry = (monthlyFXSpotRates - monthlyFXFwdRates) ./ monthlyFXFwdRates;
carry = carry(1 : end - 1, :); % we don't need the last one

% Calculate returns
monthlyXsReturns = monthlyFXSpotRates(2 : end, :) ./ monthlyFXFwdRates(1 : end - 1, :) - 1;

% Weights
carryWeights = zeros(nMonths, nCountries);
equalWeights = zeros(nMonths, nCountries);

for i = 1 : nMonths
    carryWeights(i, :) = computeSortWeights(carry(i, :), nLongs, nShorts, 1);
    equalWeights(i, :) = computeSortWeights(carry(i, :), 1000, 0, 1);
end

% All selected assets have equal weights
currencyCarryXsReturns = nansum(carryWeights .* monthlyXsReturns, 2);
currencyCarryNAV = cumprod(1 + currencyCarryXsReturns);

% Selected assets' weights are scaled by size of carry


% All available assets have equal weights
EWXsReturns = nansum(equalWeights .* monthlyXsReturns, 2);
EWNAV = cumprod(1 + EWXsReturns);

% %Regressions
% regTable = zeros(6, nCountries);
% 
% for  i = 1 : nCountries
%     regCarry = carry(:, i);             %Grab carry
%     regRet  = monthlyXsReturns(:, i); %Grab returns
%     
%     %Find starting value (first without NAN)
%     finiteIndex  = find(isfinite(regCarry));
%     regStart = finiteIndex(1);
%     
%     regCarry = regCarry(regStart:end);
%     regRet  = regRet(regStart:end);
%     
%     reg = fitlm(regCarry, regRet);
%         
%     %Save results from regression in regTable
%     regTable(1, i) = reg.Coefficients.Estimate(1);
%     regTable(2, i) = reg.Coefficients.tStat(1);
%     regTable(3, i) = reg.Coefficients.Estimate(2);
%     regTable(4, i) = reg.Coefficients.tStat(2);
%     regTable(5, i) = reg.Coefficients.pValue(2);
%     regTable(6, i) = reg.Rsquared.Adjusted;
% end
%     
% %Modify saved results
% regTable = array2table(regTable); %Create table from regression result array
% regTable.Properties.VariableNames = currencyCodes; %Set variable names to countryList
% regTable.Statistics = [{'Intercept','Int_t_stat', 'Estimate' , 'Est_t_stat', 'p_value', 'R_squared_adjusted'}]'; %Add column of statistics

% Plot
dates4Fig = datetime(dates, 'ConvertFrom', 'yyyymmdd');
dates4FigMonthly = dates4Fig(lastDayList);
plot(dates4FigMonthly, currencyCarryNAV, dates4FigMonthly, EWNAV)
title('Currency carry vs. equally weighted FX')
legend('Carry', 'Equal weights')