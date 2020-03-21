FXSpotRates = readtable('Data/FX_Spot_Rates.xlsx', 'TreatAsEmpty',{'#N/A N/A','NA','N/A'});
FXFwdRates = readtable('Data/FX_1M_FWD_Rates.xlsx', 'TreatAsEmpty',{'#N/A N/A','NA','N/A'});

% FXSpotRates(:, 1) = datetime(FXSpotRates(:, 1));
% FXFwdRates(:, 1) = datetime(FXFwdRates(:, 1));

FXSpotRates = table2timetable(FXSpotRates);
FXFwdRates = table2timetable(FXFwdRates);

% Synchronize data, grab dates
allData = synchronize(FXFwdRates, FXSpotRates, 'Intersection');
if mod(size(allData, 2), 2) ~= 0
    disp('Check your data!')
    return
end

dates = yyyymmdd(allData.Date);

FXFwdRates = table2array(allData(:, 1 : 22));
FXSpotRates = table2array(allData(:, 23 : 44));

[firstDayList, lastDayList] = getFirstAndLastDayInPeriod(dates, 2);