%% Prepare Commodity Data
clear;
clc;

%Load and clean data
FrontMonthPricesTable = readtable('CommodityFuturesData.xlsx', 'Sheet', 'FrontMonthPrices', 'TreatAsEmpty',{'#N/A N/A','NA','N/A'});
AssetList = FrontMonthPricesTable.Properties.VariableNames;
AssetList = AssetList(2:end);
CommodityList = readtable('CommodityFuturesData.xlsx', 'Sheet', 'BBGTickers');
CommodityList = table2array(CommodityList(:, 1))';

dates_time = table2array(FrontMonthPricesTable(:, 1));
dates      = yyyymmdd(dates_time);
datenum    = datenum(dates_time);

FrontMonthPrices = table2array(FrontMonthPricesTable(:, 2:end));

BackMonthPrices  = xlsread('CommodityFuturesData.xlsx', 'BackMonthPrices');
SecondBackMonthPrices  = xlsread('CommodityFuturesData.xlsx', 'SecondBackMonthPrices');

FrontTickers = readtable('CommodityFuturesData.xlsx', 'Sheet', 'FrontMonthTickers','TreatAsEmpty',{'#N/A N/A','.NA.','N/A'});
FrontTickers = table2array(FrontTickers(:, 2:end));
NanIndex = strcmp(string(FrontTickers), '.NA.');
FrontTickers(NanIndex) = {NaN};

BackTickers = readtable('CommodityFuturesData.xlsx', 'Sheet', 'BackMonthTickers','TreatAsEmpty',{'#N/A N/A','.NA.','N/A'});
BackTickers = table2array(BackTickers(:, 2:end));
BackNanIndex = strcmp(string(BackTickers), '.NA.');
BackTickers(BackNanIndex) = {NaN};

FFDaily      = readtable('FFDaily.xlsx');
FFDaily.Var1 = datetime(FFDaily.Var1, 'ConvertFrom', 'yyyyMMdd');

%% Synchronize rf to rest of data set
FrontTT = table2timetable(FrontMonthPricesTable);
FFTT    = table2timetable(FFDaily);
TTSync  = synchronize(FrontTT, FFTT, 'union', 'previous');
TTSync  = timetable2table(TTSync);
TTSyncDates = yyyymmdd(table2array(TTSync(:, 1)));
TTSync  = table2array(TTSync(:, 2:end));

%Save Factors in own array
StartDate  = dates(1);
StartIndex = find(TTSyncDates == StartDate);
FFDaily    = [TTSyncDates(StartIndex:end, 1), TTSync(StartIndex:end, end-3: end)];
RfDaily    = FFDaily(:, end) ./ 100;

%Clear variables not needed
clear BackNanIndex
clear FFTT
clear FrontMonthPricesTable
clear FrontTT
clear NanIndex
clear StartDate
clear StartIndex
clear TTSync
clear TTSyncDates

save CommodityData 



