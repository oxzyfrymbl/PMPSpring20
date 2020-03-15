%Function finds index of start and end points of sample given prespecified start and end dates
%Dates has to be on format yyyyMMdd
%SampleDates must be of format double and must be datetime object
%If Start date is only a month, nDigits = 2

function [StartIndex, EndIndex] = findStartAndEndIndex(SampleDates, DesiredStartDate, DesiredEndDate, nDigits)
    %DatesArray   = table2array(SampleDates);         %Grab dates and convert to array
                %Get dates to right format 
    if nDigits == 0
       dates = SampleDates; 
   
    elseif nDigits == 2 %Match month
       dates = round(SampleDates./100);
       DesiredStartDate = round(DesiredStartDate ./100);
       DesiredEndDate  = round(DesiredEndDate ./100);
       
    elseif nDigits == 4 %Match year
       dates = round(SampleDates./10000);
       DesiredStartDate = round(DesiredStartDate ./10000);
       DesiredEndDate  = round(DesiredEndDate ./10000);
    end
        
    StartList    = find(dates == DesiredStartDate);  %Find index of dates matching start date
    EndList      = find(dates == DesiredEndDate);    %Find index of dates matching end date
    StartIndex   = StartList(1);                     %Grab first index
    EndIndex     = EndList(end);                     %Grab end index
end
