dyna@#define indivisible_labor=1

@#if indivisible_labor==1
    title_string='Economy with indivisble labor' 
@#else
    title_string='Economy with divisble labor' 
@#endif

var c $c$ (long_name='consumption')
    w $w$ (long_name='real wage')
    r $r$ (long_name='real interest rate')
    y $y$ (long_name='output')
    h $h$ (long_name='hours')
    k $k$ (long_name='capital stock')
    invest $i$ (long_name='investment')
    lambda $\lambda$ (long_name='TFP')
    productivity ${\frac{y}{h}}$ (long_name='Productivity');
    
varexo eps_a;

parameters beta $\beta$ (long_name='discount factor')
    delta $\delta$ (long_name='depreciation rate')
    theta $\theta$ (long_name='capital share')
    gamma $\gamma$ (long_name='AR coefficient TFP')
    A $A$ (long_name='labor disutility parameter')
    h_0 ${h_0}$ (long_name='full time workers in steady state')
    sigma_eps $\sigma_e$ (long_name='TFP shock volatility')
    B $B$ (long_name ='composite labor disutility parameter');
    

//Calibration, p. 319
beta = 0.99;
delta = 0.025;
theta = 0.36;
gamma = 0.95;
A = 2;
sigma_eps=0.00712;
h_0=0.53;
B=1.237;
model;
//1. Euler Equation
1/c = beta*((1/c(+1))*(r(+1) +(1-delta)));
//2. Labor FOC
@#if indivisible_labor
    (1-theta)*(y/h) = B*c;
@#else
    (1-theta)*(y/h) = A/(1-h)*c;
@#endif
//3. Resource constraint
c = y +(1-delta)*k(-1) - k;
//4. LOM capital
k= (1-delta)*k(-1) + invest;
//5. Production function
y = lambda*k(-1)^(theta)*h^(1-theta);
//6. Real wage
r = theta*(y/k(-1));
//7. Real interest rate
w = (1-theta)*(y/h);
//8. LOM TFP
log(lambda)=gamma*log(lambda(-1))+eps_a;
//9. Productivity
productivity= y/h;
end;

steady_state_model;
B= -A*(log(1-h_0))/h_0; 
lambda = 1;
@#if indivisible_labor
    h = (1-theta)*(1/beta -(1-delta))/(B*(1/beta -(1-delta)-theta*delta));
@#else
    h = (1+(A/(1-theta))*(1 - (beta*delta*theta)/(1-beta*(1-delta))))^(-1);
@#endif
k = h*((1/beta -(1-delta))/(theta*lambda))^(1/(theta-1));
invest = delta*k;
y = lambda*k^(theta)*h^(1-theta);
c = y-delta*k;
r =  1/beta - (1-delta);
w = (1-theta)*(y/h);
productivity = y/h;
end;

steady;

shocks;
var eps_a; stderr sigma_eps;
end;

check;
steady;
stoch_simul(order=1,irf=20,loglinear,hp_filter=1600) y c invest k h productivity;

stoch_simul(order=1,irf=20,loglinear,hp_filter=1600,simul_replic=100,periods=115) y c invest k h productivity;

%read out simulations
simulated_series_raw=get_simul_replications(M_,options_);

%filter series
simulated_series_filtered=NaN(size(simulated_series_raw));
for ii=1:options_.simul_replic
    [trend, cycle]=sample_hp_filter(simulated_series_raw(:,:,ii)',1600);
    simulated_series_filtered(:,:,ii)=cycle';
end

%get variable positions
y_pos=strmatch('y',M_.endo_names,'exact');
c_pos=strmatch('c',M_.endo_names,'exact');
i_pos=strmatch('invest',M_.endo_names,'exact');
k_pos=strmatch('k',M_.endo_names,'exact');
h_pos=strmatch('h',M_.endo_names,'exact');
productivity_pos=strmatch('productivity',M_.endo_names,'exact');

var_positions=[y_pos; c_pos; i_pos; k_pos; h_pos; productivity_pos];
%get variable names
var_names=M_.endo_names_long(var_positions,:);

%Compute standard deviations
std_mat=std(simulated_series_filtered(var_positions,:,:),0,2)*100;

%Compute correlations
for ii=1:options_.simul_replic
    corr_mat(1,ii)=corr(simulated_series_filtered(y_pos,:,ii)',simulated_series_filtered(y_pos,:,ii)');
    corr_mat(2,ii)=corr(simulated_series_filtered(y_pos,:,ii)',simulated_series_filtered(c_pos,:,ii)');
    corr_mat(3,ii)=corr(simulated_series_filtered(y_pos,:,ii)',simulated_series_filtered(i_pos,:,ii)');
    corr_mat(4,ii)=corr(simulated_series_filtered(y_pos,:,ii)',simulated_series_filtered(k_pos,:,ii)');
    corr_mat(5,ii)=corr(simulated_series_filtered(y_pos,:,ii)',simulated_series_filtered(h_pos,:,ii)');
    corr_mat(6,ii)=corr(simulated_series_filtered(y_pos,:,ii)',simulated_series_filtered(productivity_pos,:,ii)');
end

%Print table with results
fprintf('\n%-40s \n',title_string)
fprintf('%-20s \t %11s \t %11s \n','','std(x)','corr(y,x)')
for ii=1:size(corr_mat,1)
    fprintf('%-20s \t %3.2f (%3.2f) \t %3.2f (%3.2f) \n',var_names(ii,:),mean(std_mat(ii,:,:),3),std(std_mat(ii,:,:),0,3),mean(corr_mat(ii,:),2),std(corr_mat(ii,:),0,2))
end