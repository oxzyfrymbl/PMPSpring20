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
            MonthNumBack   = find(strcmp(MonthCodeBack, MonthCode)); %Compare with month code array and find number
            
                if MonthNumBack - MonthNumFront < 0 
                    monthsToExpiry(i, j) = MonthNumBack - MonthNumFront + 12; %Compare with current month to find nMonths to expiry
                else
                    monthsToExpiry(i, j) = MonthNumBack - MonthNumFront;
                end
        end
    end
end

%% Interpolate futures prices to get 1-Month Futures Price for all Assets        
OneMonthPrices = zeros(nDays, nAssets);

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




%{
for i = 1:nReits %number of reiterations
   
    rowInd = RollMat(i, 1); %Get row index for rollover
    colInd = RollMat(i, 2); %Get col index for rollover
    
    CurrentMonth = MonthVector(rowInd);    %Grab month for given day
    Tick         = BackTickers(rowInd, colInd); %Grab ticker to che
    
        if ismissing(Tick) == 1          %Check if ticker is missing
            monthsToExpiry(rowInd, colInd) = NaN;
        else
            CharTick = char(Tick);       %Transform Ticker in to character array
            MonthCodeTick = CharTick(3); %Grab Month Code from Ticker
            MonthNumTick  = find(strcmp(MonthCodeTick, MonthCode)); %Compare with month code array and find number
        end
        
        if MonthNumTick - CurrentMonth < 0
                monthsToExpiry(rowInd, colInd) = MonthNumTick - CurrentMonth + 12; %Compare with current month to find nMonths to expiry
        else
                monthsToExpiry(rowInd, colInd) = MonthNumTick - CurrentMonth + 1;
        end
end


%}

%{
for i = 1:nDays
   
    CurrentMonth = MonthVector(i); %Grab month for given day
    CheckTickers = Tickers(i, :);  %Grab tickers for given day

    
    for j = 1:nAssets
        Tick = string(CheckTickers(j));  %Grab ticker
   
        if ismissing(Tick) == 1          %Check if ticker is missing
            monthsToExpiry(i, j) = NaN;
        else
            CharTick = char(Tick);       %Transform Ticker in to character array
            MonthCodeTick = CharTick(3); %Grab Month Code from Ticker
            MonthNumTick  = find(strcmp(MonthCodeTick, MonthCode)); %Compare with month code array and find number
            if MonthNumTick - CurrentMonth < 0 
                monthsToExpiry(i, j) = MonthNumTick - CurrentMonth + 12; %Compare with current month to find nMonths to expiry
            else
                monthsToExpiry(i, j) = MonthNumTick - CurrentMonth + 1;
            end
        end
    end

end
%}                

%% Compute Carry
[firstDayList, lastDayList] = getFirstAndLastDayInPeriod(dates, 2); %Get first and last day

SpotMonthly  = SpotPrices(firstDayList, :);                %Get monthly spot prices
FrontMonthly = OneMonthPrices(firstDayList, :);            %Get monthly futures prices
CarryMonthly = (SpotMonthly - FrontMonthly)./FrontMonthly; %Compute carry observed at start of month

%% Adjust for rollovers
dailyXsReturns = rolloverFutures(FrontMonthPrices, BackMonthPrices, Tickers);

%% Compound monthly futures returns
[monthlyTotalReturns, monthlyXsReturns, RfMonthly] = aggregateFutXsReturns(dailyXsReturns, RfDaily, dates, 2);

%% Scatter plots
%Carry timing

%{
n = 8;
figure(1)
for i = 1:8
    subplot(4, 2, i)
    scatter(CarryMonthly(:, i), monthlyXsReturns(:, i), '.');
    title(AssetList(i));
end
   
figure(2)
for i = 9:16
    subplot(4, 2, i - 8)
    scatter(CarryMonthly(:, i), monthlyXsReturns(:, i), '.');
    title(AssetList(i));
end

figure(3)
for i = 17:24
    subplot(4, 2, i - 16)
    scatter(CarryMonthly(:, i), monthlyXsReturns(:, i), '.');
    title(AssetList(i));
end

figure(4)
for i = 25:31
    subplot(4, 2, i - 24)
    scatter(CarryMonthly(:, i), monthlyXsReturns(:, i), '.');
    title(AssetList(i));
end
%}

%Compute weights
nMonths = length(RfMonthly);             %Preallocate
nAssets = length(AssetList);             %Preallocate
CarryWeights = zeros(nMonths, nAssets);  %Preallocate
nAvailableAssets = zeros(nMonths, 1);

for i = 1:nMonths
    Carry = CarryMonthly(i, :);             %Grab carry for one period
    nAvailable = sum(isfinite(Carry), 2);   %Check how many assets are available
    nAvailableAssets(i, 1) = nAvailable;    %Store nAvailable Assets
    
    %Cap nLongs and nShorts at 5, and lower limit of 3.
    if nAvailable > 10                                                              
        nLongs   = 5;
        nShorts  = 5;
        CarryWeights(i, :) = computeSortWeights(Carry, nLongs, nShorts, 1);
        
    elseif nAvailable >= 8
        nLongs = 4;
        nShorts = 4;
        CarryWeights(i, :) = computeSortWeights(Carry, nLongs, nShorts, 1);
    
    elseif nAvailable >= 6
        nLongs = 3;
        nShorts = 3;
        CarryWeights(i, :) = computeSortWeights(Carry, nLongs, nShorts, 1);

    else
        CarryWeights(i, :) = NaN;   
    end

end

%Compute Strategy Returns
EqualWeights   = isfinite(CarryMonthly) * 1./nAvailableAssets;
EqualXsReturns = nansum(EqualWeights .* monthlyXsReturns, 2);
CarryXsReturns = nansum(CarryWeights .* monthlyXsReturns, 2);

%Align Data (Get rid of NaN values at beginning of Carry strategy)
CarryXsReturns = CarryXsReturns(23:end, :);
EqualXsReturns = EqualXsReturns(23:end, :);
RfMonthly      = RfMonthly(23:end, :);
dates4fig      = dates_time(firstDayList);
dates4fig      = dates4fig(23:end, :);

%Compute total Returns
CarryTotalReturns = CarryXsReturns + RfMonthly;
EqualTotalReturns = EqualXsReturns + RfMonthly;

%Sharpe Arithmetic
sharpeCarry = sqrt(12) * (mean(CarryTotalReturns) - mean(RfMonthly))./ std(CarryXsReturns);
sharpeEqual = sqrt(12) * (mean(EqualTotalReturns) - mean(RfMonthly))./std(EqualXsReturns);


%Compute Equity Lines
EqualNAV = cumprod(1 + EqualXsReturns);
CarryNAV  = cumprod(1 + CarryXsReturns);


%Plot Results
figure(5)
plot(dates4fig, EqualNAV, 'r--', dates4fig, CarryNAV, 'b')
title('Global Equity Carry vs Equal Weights')
ylabel('Cumulative Excess Returns');
legend('Equal Weights', 'Carry', 'location', 'northwest')
str = strcat({'Sharpe Carry: '}, string(sharpeCarry));
dim = [.65 .27 .3 .0];
annotation('textbox',dim,'String',str,'FitBoxToText','on');
str = strcat({'Sharpe Equal: '}, string(sharpeEqual));
dim = [.65 .2 .3 .0];
annotation('textbox',dim,'String',str,'FitBoxToText','on');



%  dates4fig = dates_time(firstDayList);
%  plot(dates4fig, EqualNAV, 'r--')
%  legend('Equal Weights', 'location', 'northwest')



