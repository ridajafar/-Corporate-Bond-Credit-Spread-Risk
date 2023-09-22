function h = hazard_rate(cf_schedule, Bond_dirty_price, ZC_curve, R)
% Compute constant hazard rate 

times = [0; cf_schedule(:,1)];

% Get discount factors
idx = arrayfun(@(x)find(ZC_curve(:,1)==x,1),times(2:end));
Z = ZC_curve(:,2);
Z = Z(idx);
B = exp(-Z.*times(2:end)); 

% Invert the formula for h
fun = @(x) sum(cf_schedule(:,2).*B.*exp(-x.*times(2:end))) + R*sum((exp(-x.*times(1:end-1))-exp(-x.*times(2:end))).*B) - Bond_dirty_price;

options = optimset('Display','off');
h0 = 1;
h = fsolve(fun,h0,options);

end