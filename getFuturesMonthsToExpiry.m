% Function computes, for every future and every day the months to expiry of front month contract
%It computes this by comparing the ticker of the front month to the first
%back month

%Inputs are:
% 1) Front Month Tickers
% 2) Back Month Tickers
% 3) Optional Input of array including exeptions

%ExceptionArray: Cell Array containing tickers for where month code is not the third letter in ticker
%By default, the function will assume the fourth letter is month code


function expMat = getFuturesMonthsToExpiry(FrontTickers, BackTickers, dates, ExceptionArray)

%Futures Month Code
MonthCode = [{'F'}, {'G'}, {'H'}, {'J'}, {'K'}, {'M'}, {'N'}, {'Q'}, {'U'}, {'V'}, {'X'}, {'Z'}]';
MonthNum  = (1:12)';

if ~exist('ExceptionArray', 'var')
    ExceptionArray = 'Nothing';
end

nDays          = size(dates, 1);
nAssets        = size(FrontTickers, 2);
monthsToExpiry = zeros(nDays, nAssets);


for i = 1:nDays
    BackTickRow = string(BackTickers(i, :));      %grab back tickers
    FrontTickRow = string(FrontTickers(i, :));    %grab front tickers
    
    for j = 1:nAssets
        FrontTick = FrontTickRow(j);    %Grab one front ticker
        BackTick  = BackTickRow(j);     %Grab corresponing back ticker

        if ismissing(FrontTick) == 1          %Check if ticker is missing
            monthsToExpiry(i, j) = NaN;
       
        else
            CharFront = char(FrontTick);       %Transform Ticker in to character array
            CharBack  = char(BackTick);
            
            if sum(string(CharFront(1:3)) == ExceptionArray) == 1 
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

expMat = monthsToExpiry;
