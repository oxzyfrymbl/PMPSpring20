clc;
clear;

%Load and clean data
FrontMonthPrices = readtable('EquityIndexFuturesData.xlsx', 'Sheet', 'FrontMonthPrices', 'TreatAsEmpty',{'#N/A N/A','NA','N/A'});
AssetList = FrontMonthPrices.Properties.VariableNames;
AssetList = AssetList(2:end);

dates_time = table2array(FrontMonthPrices(:, 1));
dates      = yyyymmdd(dates_time);
datenum    = datenum(dates_time);

FrontMonthPrices = table2array(FrontMonthPrices(:, 2:end));

SpotPrices       = xlsread('EquityIndexFuturesData.xlsx', 'SpotPrices');
BackMonthPrices  = xlsread('EquityIndexFuturesData.xlsx', 'BackMonthPrices');

Tickers = readtable('EquityIndexFuturesData.xlsx', 'Sheet', 'FrontMonthTickers','TreatAsEmpty',{'#N/A N/A','.NA.','N/A'});
Tickers = table2array(Tickers(:, 2:end));
NanIndex = strcmp(string(Tickers), '.NA.');
Tickers(NanIndex) = {NaN};

BackTickers = readtable('EquityIndexFuturesData.xlsx', 'Sheet', 'BackMonthTickers','TreatAsEmpty',{'#N/A N/A','.NA.','N/A'});
BackTickers = table2array(BackTickers(:, 2:end));
BackNanIndex = strcmp(string(BackTickers), '.NA.');
BackTickers(BackNanIndex) = {NaN};


FFDaily    = readtable('FFDaily.xlsx');
FFdates    = table2array(FFDaily(:, 1));
StartDate  = dates(1);
StartIndex = find(FFdates == StartDate + 1);
RfDaily    = table2array(FFDaily(StartIndex:end, end));
nPlugs     = length(dates) - length(RfDaily);
Plug       = ones(nPlugs, 1) * RfDaily(end);
RfDaily    = [RfDaily; Plug] ./ 100; 


save EquityData

