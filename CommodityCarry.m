%% Commodity carry
clc;
clear;

load CommodityData

%% Get 1-Month Futures for all indices
monthsToExpiry = getFuturesMonthsToExpiry(FrontTickers, BackTickers, dates);

%% Compute Carry 
%Get carry from interpolation formula
Carry = (FrontMonthPrices - BackMonthPrices) ./ (BackMonthPrices .* monthsToExpiry);
[firstDayList, lastDayList] = getFirstAndLastDayInPeriod(dates, 2); %Get first and last day

CarryMonthly = Carry(firstDayList, :);

%Compute C_1-12 Cary Factor (Moving 12-month average)
nMonths  = length(firstDayList);
nAssets  = size(AssetList, 2);
C112     = zeros(nMonths, nAssets);
lookback = 12;

for i = 12:nMonths
    C112(i, :) = mean(CarryMonthly(i - lookback + 1: i, :));
end


%% Adjust for rollovers
dailyXsReturns = rolloverFutures(FrontMonthPrices, BackMonthPrices, FrontTickers);


%% Compound monthly futures returns
[monthlyTotalReturns, monthlyXsReturns, RfMonthly] = aggregateFutXsReturns(dailyXsReturns, RfDaily, dates, 2);


%% Trim and align data
dates4fig           = dates_time(firstDayList);
dates4fig           = dates4fig(lookback:end, :);
monthlyTotalReturns = monthlyTotalReturns(lookback:end, :);
monthlyXsReturns    = monthlyXsReturns(lookback:end, :);
RfMonthly           = RfMonthly(lookback:end, :);
CarryMonthly        = CarryMonthly(lookback:end, :);
C112                = C112(lookback:end, :);

%% Strategy Weights
%Compute weights
nMonthsTr        = length(RfMonthly);         %Get dimensions of trimmed data
nAssets          = length(AssetList);         %Preallocate

CarryWeights     = getCarryWeights(CarryMonthly, 10, 6);  %get regular carry weights
C112Weights      = getCarryWeights(C112, 10, 6);          %get C112 carry weights
nAvailableAssets = sum(isfinite(CarryMonthly), 2);        %get available assets


%% Strategy Returns
%Compute Strategy Returns
EqualWeights   = isfinite(CarryMonthly) * 1./nAvailableAssets;
EqualXsReturns = nansum(EqualWeights .* monthlyXsReturns, 2);
CarryXsReturns = nansum(CarryWeights .* monthlyXsReturns, 2);
C112XsReturns  = nansum(C112Weights  .* monthlyXsReturns, 2);

%Find Strategy Starting Point 
%(Where number of assets is sufficiently large to build first portfolio)
NonZeroIndex  = find((C112XsReturns ~= 0));
StrategyStart = NonZeroIndex(1);

% EndDate = 20121001;
% EndDates = dates(firstDayList);
% EndIndex = find(EndDates == EndDate);

%Align Data (Get rid of NaN values at beginning of Carry strategy)
CarryXsReturns = CarryXsReturns(StrategyStart:end, :);
EqualXsReturns = EqualXsReturns(StrategyStart:end, :);
C112XsReturns  = C112XsReturns(StrategyStart:end, :);
RfMonthly      = RfMonthly(StrategyStart:end, :);
dates4fig      = dates4fig(StrategyStart:end, :);

%Compute total Returns
CarryTotalReturns = CarryXsReturns + RfMonthly;
C112TotalReturns  = C112XsReturns + RfMonthly;
EqualTotalReturns = EqualXsReturns + RfMonthly;

%Sharpe Arithmetic
sharpeC112  = sqrt(12) * (mean(C112TotalReturns) - mean(RfMonthly))./ std(C112XsReturns);
sharpeCarry = sqrt(12) * (mean(CarryTotalReturns) - mean(RfMonthly))./ std(CarryXsReturns);
sharpeEqual = sqrt(12) * (mean(EqualTotalReturns) - mean(RfMonthly))./std(EqualXsReturns);

%Compute Equity Lines
EqualNAV  = cumprod(1 + EqualXsReturns);
CarryNAV  = cumprod(1 + CarryXsReturns);
C112NAV   = cumprod(1 + C112XsReturns);


%Plot Results
figure(5)
semilogy(dates4fig, EqualNAV, 'k--', dates4fig, CarryNAV, 'b', dates4fig, C112NAV, 'r')
title('Global Commodity Carry vs Equal Weights')
ylabel('Cumulative Excess Returns');
legend('Equal Weights', 'Carry', 'C112', 'location', 'northwest')
str = strcat({'Sharpe C112: '}, string(sharpeC112));
dim = [.65 .34 .3 .0];
annotation('textbox',dim,'String',str,'FitBoxToText','on');
str = strcat({'Sharpe Carry: '}, string(sharpeCarry));
dim = [.65 .27 .3 .0];
annotation('textbox',dim,'String',str,'FitBoxToText','on');
str = strcat({'Sharpe Equal: '}, string(sharpeEqual));
dim = [.65 .2 .3 .0];
annotation('textbox',dim,'String',str,'FitBoxToText','on');



