function z = Z_spread(cf_schedule, Bond_dirty_price, ZC_curve)
% Computes the constant z-spread

% Get discount factors
idx = arrayfun(@(x)find(ZC_curve(:,1)==x,1),cf_schedule(:,1));
Z = ZC_curve(:,2);
Z = Z(idx);
B = exp(-Z.*cf_schedule(:,1));
B_hat = @(x) B.*exp(-x.*cf_schedule(:,1));

% Invert the formula for z
fun = @(x) sum(cf_schedule(:,2).*B_hat(x)) - Bond_dirty_price;

options = optimset('Display','off');
z0 = 1;
z = fsolve(fun,z0,options);

end