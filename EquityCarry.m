%% Equity Carry Strategy PMP Semester Project
clc;
clear;

load EquityData

%Delete Greece
FrontMonthPrices(:, 17) = [];
AssetList(17)           = [];
SpotPrices(:, 17)       = [];
BackMonthPrices(:, 17)  = [];
Tickers(:, 17)          = [];
BackTickers(:, 17)      = [];

%Delete Brazil
FrontMonthPrices(:, 14) = [];
AssetList(14)           = [];
SpotPrices(:, 14)       = [];
BackMonthPrices(:, 14)  = [];
Tickers(:, 14)          = [];
BackTickers(:, 14)      = [];


%% Get 1-Month Futures for all indices

MonthCode = [{'F'}, {'G'}, {'H'}, {'J'}, {'K'}, {'M'}, {'N'}, {'Q'}, {'U'}, {'V'}, {'X'}, {'Z'}]';
MonthNum  = (1:12)';

%Check maturity for futures
BackTickers = string(BackTickers);
TickersNoMiss = BackTickers;
TickersNoMiss(ismissing(TickersNoMiss)) = 0;

nDays          = size(dates, 1);
nAssets        = size(AssetList, 2);

monthsToExpiry = zeros(nDays, nAssets);

%Run loop to identify the time to expiry for each future
%The loop will do the following:
% 1) Grab front tickers and back tickers for each day and each index
% 2) Get the month letter used in futures ticker
% 3) Find the month number corresponding to the letter
% 4) Take the difference between month index for front and back month fut
% for each day
% 5) Store the number for each day and contract in monthsToExpiry

for i = 1:nDays
    BackTickRow = string(BackTickers(i, :)); %grab back tickers
    FrontTickRow = string(Tickers(i, :));    %grab front tickers
    
    for j = 1:nAssets
        FrontTick = FrontTickRow(j);
        BackTick  = BackTickRow(j);

        if ismissing(FrontTick) == 1          %Check if ticker is missing
            monthsToExpiry(i, j) = NaN;
       
        else
            CharFront = char(FrontTick);       %Transform Ticker in to character array
            CharBack  = char(BackTick);
            
            if sum(string(CharFront(1:3)) == ["IPA", "IFB", "IDO", "KIW", "KRS"]) == 1 
               look = 4;
            else
               look = 3;
            end
            
            MonthCodeFront = CharFront(look); %Grab Month Code from Ticker
            MonthCodeBack  = CharBack(look);
            
            MonthNumFront  = find(strcmp(MonthCodeFront, MonthCode)); %Compare with month code array and find number
            MonthNumBack   = find(strcmp(MonthCodeBack, MonthCode));  %Compare with month code array and find number
            
                %Compare front and backmonth to find nMonths to expiry
                if MonthNumBack - MonthNumFront < 0 
                    monthsToExpiry(i, j) = MonthNumBack - MonthNumFront + 12; 
                else
                    monthsToExpiry(i, j) = MonthNumBack - MonthNumFront;
                end
        end
    end
end

%% Interpolate futures prices to get 1-Month Futures Price for all Assets        
OneMonthPrices = zeros(nDays, nAssets);

%Loop to interpolate to get one-month futures prices
%The loop will
% 1) Grab Front Prices and Spot Prices for 1 index at a given day
% 2) Do the following:
%       -Set to value to NAN if we dont have a price
%       -Interpolate between spot and 3-month if we have 3-month expiration
%       -Interpolate between spot and 2-month if we have 2-month expiration
%       -Do nothing if we have 1-month to expiration 
% 3) Store interpolated one month futures prices

for i = 1:nDays
    for j = 1:nAssets
        FrontPrice = FrontMonthPrices(i, j); %Grab front price
        SpotPrice  = SpotPrices(i, j);       %Grab spot price
        
        if  isnan(monthsToExpiry(i, j)) == 1
            OneMonthPrices(i, j) = NaN;
       
        elseif  monthsToExpiry(i, j) == 3
                OneMonthCarry = (FrontPrice/SpotPrice).^(1/3);       %Get 1 Month Carry
                OneMonthPrices(i, j) = SpotPrice .* OneMonthCarry;   %Compute One Month Price  
        
        elseif monthsToExpiry(i, j) == 2
                OneMonthCarry = (FrontPrice/SpotPrice).^(1/2);       %Get 1 Month Carry
                OneMonthPrices(i, j) = SpotPrice .* OneMonthCarry;   %Compute One Month Price  
        
        elseif monthsToExpiry(i, j) == 1
                OneMonthPrices(i, j) = FrontPrice;                   %Compute One Month Price  
        
        end
    end
end


%% Compute Carry
[firstDayList, lastDayList] = getFirstAndLastDayInPeriod(dates, 2);      %Get first and last day

SpotMonthly  = [SpotPrices(1, :); SpotPrices(lastDayList, :)];           %Get monthly spot prices
FrontMonthly = [OneMonthPrices(1,:); OneMonthPrices(lastDayList, :)] ;   %Get monthly futures prices

CarryMonthly = (SpotMonthly - FrontMonthly)./FrontMonthly; %Compute carry observed at start of month
CarryMonthly = CarryMonthly(1:end-1,:); %Kill last signal

%Compute C_1-12 Cary Factor (Moving 12-month average)
nMonths  = length(firstDayList);
C112     = zeros(nMonths, nAssets);
lookback = 12;

for i = 12:nMonths
    C112(i, :) = mean(CarryMonthly(i - lookback + 1: i, :));
end

%CarryDaily
CarryDaily = (SpotPrices - OneMonthPrices) ./OneMonthPrices;
%SpotReturnsDaily = SpotPrices(2:end, :) / SpotPrices(1:end-1,:) - 1;

%% Adjust for rollovers
dailyXsReturns = rolloverFutures(FrontMonthPrices, BackMonthPrices, Tickers);


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


%% Analysing Carry as a predictor of returms
%Scatterplots
%{
n = 8;
figure(1)
for i = 1:8
    subplot(4, 2, i)
    scatter(C112(:, i), monthlyXsReturns(:, i), '.');
    title(AssetList(i));
end
   
figure(2)
for i = 9:16
    subplot(4, 2, i - 8)
    scatter(C112(:, i), monthlyXsReturns(:, i), '.');
    title(AssetList(i));
end

figure(3)
for i = 17:24
    subplot(4, 2, i - 16)
    scatter(C112(:, i), monthlyXsReturns(:, i), '.');
    title(AssetList(i));
end

figure(4)
for i = 25:31
    subplot(4, 2, i - 24)
    scatter(C112(:, i), monthlyXsReturns(:, i), '.');
    title(AssetList(i));
end
%}

%Regressions
%{
%Regressions
regTable = zeros(6, nAssets);

for  i = 1:nAssets
    regC112 = C112(:, i);             %Grab carry
    regRet  = monthlyXsReturns(:, i); %Grab returns
    
    %Find starting value (first without NAN)
    finiteIndex  = find(isfinite(regC112));
    regStart = finiteIndex(1);
    
    regC112 = regC112(regStart:end);
    regRet  = regRet(regStart:end);
    
    reg = fitlm(regC112, regRet);
        
    %Save results from regression in regTable
    regTable(1, i) = reg.Coefficients.Estimate(1);
    regTable(2, i) = reg.Coefficients.tStat(1);
    regTable(3, i) = reg.Coefficients.Estimate(2);
    regTable(4, i) = reg.Coefficients.tStat(2);
    regTable(5, i) = reg.Coefficients.pValue(2);
    regTable(6, i) = reg.Rsquared.Adjusted;
end
    
    %Modify saved results
    regTable = array2table(regTable); %Create table from regression result array
    regTable.Properties.VariableNames = string(AssetList); %Set variable names to countryList
    regTable.Statistics = [{'Intercept','Int_t_stat', 'Estimate' , 'Est_t_stat', 'p_value', 'R_squared_adjusted'}]'; %Add column of statistics
    
%}

%% Strategy Weights
%Compute Monthly Weights
nMonthsTr        = length(RfMonthly);         %Get dimensions of trimmed data
nAssets          = length(AssetList);         %Preallocate

CarryWeights     = getCarryWeights(CarryMonthly, 10, 6);  %get regular carry weights
C112Weights      = getCarryWeights(C112, 10, 6);          %get C112 carry weights
nAvailableAssets = sum(isfinite(CarryMonthly), 2);        %get available assets

%Compute Daily Weights
CarryWeightsDaily = getCarryWeights(CarryDaily, 10, 6);
nAvailableDaily   = sum(isfinite(CarryDaily), 2);


%% Strategy Returns
%Compute Monthly Strategy Returns
EqualWeights   = isfinite(CarryMonthly) * 1./nAvailableAssets;
EqualXsReturns = nansum(EqualWeights .* monthlyXsReturns, 2);
CarryXsReturns = nansum(CarryWeights .* monthlyXsReturns, 2);
C112XsReturns  = nansum(C112Weights .* monthlyXsReturns, 2);

%Compute Daily Strategy Returns
EqualWeightsDaily = isfinite(CarryDaily) * 1./nAvailableDaily;
EqualDailyXsReturns = nansum(EqualWeightsDaily .* dailyXsReturns, 2);
CarryDailyXsReturns = nansum(CarryWeightsDaily .* dailyXsReturns, 2);


%% Find Strategy Starting Point 
%(Where number of assets is sufficiently large to build first portfolio)
%Monthly Strategy
NonZeroIndex  = find((C112XsReturns ~= 0));
StrategyStart = NonZeroIndex(1);

%Daily Strategy
NonZeroIndex  = find((CarryDailyXsReturns ~= 0));
DailyStart    = NonZeroIndex(1);

%Align Data (Get rid of NaN values at beginning of Carry strategy)
%Monthly Strategy
CarryXsReturns = CarryXsReturns(StrategyStart:end, :);
EqualXsReturns = EqualXsReturns(StrategyStart:end, :);
C112XsReturns  = C112XsReturns(StrategyStart:end, :);
RfMonthly      = RfMonthly(StrategyStart:end, :);
dates4fig      = dates4fig(StrategyStart:end, :);

%Daily Strategy
CarryDailyXsReturns = CarryDailyXsReturns(DailyStart:end, :);
EqualDailyXsReturns = EqualDailyXsReturns(DailyStart:end, :);
dailyDates4fig      = dates_time(DailyStart:end, :);

%% Compute total Returns
CarryTotalReturns = CarryXsReturns + RfMonthly;
C112TotalReturns  = C112XsReturns + RfMonthly;
EqualTotalReturns = EqualXsReturns + RfMonthly;

%Sharpe Arithmetic
sharpeC112  = sqrt(12) * (mean(C112TotalReturns) - mean(RfMonthly))./ std(C112XsReturns);
sharpeCarry = sqrt(12) * (mean(CarryTotalReturns) - mean(RfMonthly))./ std(CarryXsReturns);
sharpeEqual = sqrt(12) * (mean(EqualTotalReturns) - mean(RfMonthly))./std(EqualXsReturns);

%Compute Equity Lines
%Monthly Strategy
EqualNAV  = cumprod(1 + EqualXsReturns);
CarryNAV  = cumprod(1 + CarryXsReturns);
C112NAV   = cumprod(1 + C112XsReturns);

%Daily Strategy
EqualDailyNAV = cumprod(1 + EqualDailyXsReturns);
CarryDailyNAV = cumprod(1 + CarryDailyXsReturns);

%Plot Results
%Monthly
figure(5)
semilogy(dates4fig, EqualNAV, 'k--', dates4fig, CarryNAV, 'b', dates4fig, C112NAV, 'r')
title('Global Equity Carry vs Equal Weights')
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


figure(6)
semilogy(dailyDates4fig, EqualDailyNAV, 'k--', dailyDates4fig, CarryDailyNAV, 'b')
title('Global Equity Carry vs Equal Weights (Daily Rebalancing)')
ylabel('Cumulative Excess Returns');
legend('Equal Weights', 'Carry', 'location', 'northwest')

