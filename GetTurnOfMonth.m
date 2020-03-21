%Function get the days where we should trade for TOM

function TurnOfMonth = GetTurnOfMonth(dates)

dateVec     = datevec(dates);
monthIndex  = dateVec(:, 2);
nDays       = length(monthIndex);
TurnOfMonth = zeros(nDays, 1);

for i = 1:nDays-1
     if monthIndex(i) ~= monthIndex(i + 1)     %Identify month change
        TurnOfMonth(i: i + min(end-i, 4)) = 1; %Trade during the next 5 days or as long as sample lets you
     end
 end
 