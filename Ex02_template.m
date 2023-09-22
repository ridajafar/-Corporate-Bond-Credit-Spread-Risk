%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Case 2 Template
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   INPUT data are stored as:
%
%   1. Market_data: table of ICAP quotes for the strip of IRS
%       Column #1: IRS maturity (year frac)
%       Column #2: MID rate
% 
%   2. cf_schedule_1y: table of cash flows of corp. bond with 1y maturity
%       Column #1: cash flow date(year frac)
%       Column #2: cash flow amount
% 
%   3. cf_schedule_2y: table of cash flows of corp. bond with 2y maturity
%       Column #1: cash flow date(year frac)
%       Column #2: cash flow amount
%
%   4. Q: Transition matrix for an elementary two-rating-grades Markov Process 
%           To ->         IG    HY     Def
%   From:           IG    74%   25%     1%
%                   HY    35%   60%     5%
%                   Def    0%    0%   100%
%   legend: IG = Investment Grade
%           HY = High Yield
%           Def= Defaulted
% 
%    OUTPUT data are stored as:
%
%   5. ZC_curve: Table of risk-free ZC rates (cont. comp. 30/360)
%      Maturities are year fractions
%   6. h_curve: Table of piece-wise constant hazard rates (30/360)
%      Maturities are year fractions
%   7. A set of scalar variable with self-explanatory names
%   
%   Required functions' template:
%   5.1. ZC_bootstrap_IRS_only: Analytical bootstrap of ZC curve from IRS
%   function [ZC_curve]=ZC_bootstrap_IRS_only(IRS_data,irs_fixed_coupon_freq)
%   2. Hazard rate (scalar) for a given bond (fixed recoovery rate R)
%   function [ h ] = hazard_rate(cf_schedule, Bond_dirty_price, ZC_curve, R)
%   3. Z-spread (scalar) for a given bond 
%   function [ spread ] = Z_spread(cf_schedule, Bond_dirty_price, ZC_curve)
%   4. PV (i.e. dirty price) for a given bond given a piece-wise
%       constant term structure for hazard rate
%   function [ PV ] = PV_for_bootstrap( z, cf_schedule_2y, h_curve, ZC_curve, R )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
clc;
% IRS quotes
market_data = [ 0.25 4.84; 0.50 5.10; 0.75 5.27; 1.00 5.43; 
            1.25 5.32; 1.50 5.22; 1.75 5.11; 2.00 5.00];
irs_fixed_coupon_freq = 4;  %Quarterly fixed coupons 
% One year bond
cf_schedule_1y = [0.5 2.5; 1.0 102.5];
Bond_dirty_price_1y = 99.00;                 % Market price of the bond
% Two year bond
cf_schedule_2y = [0.5 3.0; 1.0 3.0; 1.5 3.0; 2.0 103.0];
Bond_dirty_price_2y = 100.00;                % Market price of the bond
R = 0.4;                                     %Recovery rate (\pi according to Schonbucher)
% One Year Transition Matrix
Q = [0.74 0.25 0.01 ; 0.35 0.60 0.05 ; 0.00 0.00 1.00];

%%
% Bootstrap
[ZC_curve]=ZC_bootstrap_IRS_only(market_data,irs_fixed_coupon_freq);

%%
% Q1: Hazard rate (two scalars, each one corresponding to a bond) 
h_1y = hazard_rate(cf_schedule_1y, Bond_dirty_price_1y, ZC_curve, R);
h_2y = hazard_rate(cf_schedule_2y, Bond_dirty_price_2y, ZC_curve, R);
disp('––– Q1: HAZARD RATES –––')
fprintf('Hazard rate (bond 1Y): %.0fbps\n', 10000*h_1y)
fprintf('Hazard rate (bond 2Y): %.0fbps\n', 10000*h_2y)
disp(' ')
%%
% Q2: Unconditional Default Prob. from Intensity Model (i.e. derived from hazard rates)
% Unconditional Default Prob.
PD_1y = 1 - exp(-h_1y);      % One year PD
PD_2y = 1 - exp(-h_2y*2);    % Two years PD
disp('––– Q2: DEFAULT PROBABILITIES (constant hazard rates) –––')
fprintf('Default probability (bond 1Y): %.2f%%\n', 100*PD_1y)
fprintf('Default probability (bond 2Y): %.2f%%\n', 100*PD_2y)
disp(' ')
%%
% Q3: Z-spread (two scalars, each one corresponding to a bond)
z_1y = Z_spread(cf_schedule_1y, Bond_dirty_price_1y, ZC_curve);
z_2y = Z_spread(cf_schedule_2y, Bond_dirty_price_2y, ZC_curve);
disp('––– Q3: Z-SPREADS –––')
fprintf('Z-Spread (bond 1Y): %.0fbps\n', 10000*z_1y)
fprintf('Z-Spread (bond 2Y): %.0fbps\n', 10000*z_2y)
disp(' ')
%%
% Q4: Bootstrap of piece-wise hazard rate
% Initialize the vector of piece-wise hazard rate
h_curve(1,1) = cf_schedule_1y(length(cf_schedule_1y),1);
h_curve(2,1) = cf_schedule_2y(length(cf_schedule_2y),1);
h_curve(1,2) = h_1y;
h_curve(2,2) = h_2y;

% Bootstrap of second-year hazard rate (usage of fzero() not compulsory)
fun = @(z) PV_for_bootstrap( z, cf_schedule_2y, h_curve, ZC_curve, R ) - Bond_dirty_price_2y;
h_curve(2,2) = fzero(fun,h_2y);
disp('––– Q4: PIECEWISE CONSTANT HAZARD RATES –––')
fprintf('Hazard rate (0Y-1Y): %.0fbps\n', 10000*h_curve(1,2))
fprintf('Hazard rate (1Y-2Y): %.0fbps\n', 10000*h_curve(2,2))
disp(' ')

% Unconditional default probabilities (from bootstrap and risk-neutral)
PD_1y_h = 1 - exp(-h_curve(1,2));       % One year PD
PD_2y_h = 1 - exp(-h_curve(1,2) -h_curve(2,2));       % Two years PD
fprintf('Default probability (1Y): %.2f%%\n', 100*PD_1y_h)
fprintf('Default probability (2Y): %.2f%%\n', 100*PD_2y_h)
disp(' ')
%%
% Q5: Default Probability from Rating Transition Matrix (real-world)
PD_1y_Q = Q(1,3);                                   % One year PD
PD_2y_Q = Q(1,3) + Q(1,1)*Q(1,3) + Q(1,2)*Q(2,3);   % Two years PD
disp('––– Q5: RATING TRANSITION MATRIX –––')
fprintf('Default probability (1Y): %.2f%%\n', 100*PD_1y_Q)
fprintf('Default probability (2Y): %.2f%%\n', 100*PD_2y_Q)
disp(' ')

