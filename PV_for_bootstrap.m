function price = PV_for_bootstrap( z, cf_schedule_2y, h_curve, ZC_curve, R )
% Computes the bootstrapped hazard rate from 1y to 2y

times = [0; cf_schedule_2y(:,1)];

% Get discount factors
idx = arrayfun(@(x)find(ZC_curve(:,1)==x,1),times(2:end));
Z = ZC_curve(:,2);
Z = Z(idx);
B = exp(-Z.*times(2:end)); 

idx2 = find(cf_schedule_2y(:,1)==h_curve(1,1),1);

% Compute price
fun = @(x) sum(cf_schedule_2y(1:idx2,2).*B(1:idx2).*exp(-h_curve(1,2).*times(2:idx2+1)) + cf_schedule_2y(idx2+1:end,2).*B(idx2+1:end).*exp( -h_curve(1,2) - x.*(times(idx2+2:end)-1) )) + ...
           R*sum( (exp(-h_curve(1,2).*times(1:idx2))-exp(-h_curve(1,2).*times(2:idx2+1))).*B(1:idx2) + (exp( -h_curve(1,2) - x.*times(idx2+1:end-1))- exp( -h_curve(1,2) - x.*times(idx2+2:end))).*B(idx2+1:end) );

price = fun(z);

end