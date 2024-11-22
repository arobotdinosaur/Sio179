% Sea-Bird SBE37 Temperature + Conductivity Calibration
%
% T. Martz
% Last update: 7 Oct 2022
%
% Sensor Type: SBE-37SI
% Serial Number: 8102
% factory cal date: 17-Sep 2010
% subsequnet cal date: ??
%
% instrument-specific calib. coefficients.
% use factory coeffs provided with datasheet for comparison
% or use as default best-guess values for least squares fit below
%%temperature sensor factory calibration coefficients

a0 = -1.445471e-04;
a1 = 3.148805e-04;
a2 = -5.041369e-06;
a3 = 2.163541e-07;
%%conductivity sensor factory calibration coefficients
g = -9.905848e-01;
h = 1.371969e-01;
i = -1.679558e-04;
j = 3.014210e-05;
CPcor = -9.5700e-8;
CTcor = 3.2500e-6;
WBOTC = 0e0;
%best guess or use old factory cal
%a0_ = -7.365386e-005;
%a1_ = 2.991999e-004;
%a2_ = -3.854375e-006;
%a3_ = 1.859712e-007;
a0_ = -1.44547e-04;
a1_ = 3.148805e-04;
a2_ = -5.041369e-06;
a3_ = 2.163541e-07;
% a0_ = a0;
% a1_ = a1;
% a2_ = a2;
% a3_ = a3;
g_ = -9.905848e-01;
h_ = 1.371969e-01;
i_ = -1.679558e-04;
j_ = 3.014210e-05;
% g_ = g;
% h_ = h;
% i_ = i;
% j_ = j;
% calibration data measured
temp_std = [5,10,11.6,15,19.79]; %bath temp for thermistor cal (C)
therm_raw = []; %thermistor output
tc = temp_std; %bath temp for cond cal (C)
SP = [31.5434, 31.4018, 31.5547, 31.2121, 31.4284]; %practical salinity, measured independently (e.g. salinometer)
InstFreq = [5425.348,5703.180,5768.961,5963.699,6241.609]; %frequency output of sensor (Hz)
p=0; % pressure
for x = 1:length(tc)
f(x) = InstFreq(x)*sqrt(1+WBOTC*tc(x))/1000; % temp corr kHz
BC(x) = gsw_C_from_SP(SP(x),tc(x),p)/10; %S/m Bath Conductivity (BC) from salintiy bottle sample & PSS78 definition
y(x) = BC(x)*(1 + CTcor*tc(x) + CPcor*p); %
end

%BC is bath cond from salinometer & EOS/TEOS10 inversion
%IC is instrument (SBE37) conductivity
%using cal sheet convention, first measurement in array is in air or at
%zero cond, so set zero point accordingly...
BC(1) = 0; %set known cond (BC) to 0 for first datapoint (in air)
IC1(1) = 0; % set Instrument Conductivity (IC) to 0 at at first datapoint
IC2(1) = 0; %
% fit thermistor calibration data
s = fitoptions('Method','NonlinearLeastSquares','TolFun',1e-12,'TolX',1e-15,'MaxFunEvals',10000,'MaxIter',10000,'DiffMinChange',1e-12,'DiffMaxChange',1e-3,'Display','iter','Lower',[-.001,0,-.001,0],'Upper',[0,.001,0,.001],'Startpoint',[a0_,a1_,a2_,a3_]);
X = fittype('1/(a+b*log(x)+c*log(x)^2+d*log(x)^3)-273.15','coefficients',{'a','b','c','d'},'independent','x','options',s);
[c,gof] = fit(therm_raw',temp_std',X);
coeffs = coeffvalues(c);
a0_ = coeffs(1)
a1_ = coeffs(2)
a2_ = coeffs(3)
a3_ = coeffs(4)
gof
% fit conductivity calibration data
s = fitoptions('Method','NonlinearLeastSquares',...
'TolFun',1e-12,...
'TolX',1e-15,...
'MaxFunEvals',10000,...
'MaxIter',10000,...
'DiffMinChange',1e-12,...
'DiffMaxChange',1e-3,...
'Display','iter',...
'Startpoint',[g_,h_,i_,j_]); %best guess is old factory cal or all
zeros
X = fittype('a+b*x^2+c*x^3+d*x^4','coefficients',{'a','b','c','d'},'independent','x','options',s);
[d,gof] = fit(f',y',X);
coeffs = coeffvalues(d);
g_ = coeffs(1)
h_ = coeffs(2)
i_ = coeffs(3)
j_ = coeffs(4)
gof

%calculate temp based on old (1) and new (2) cal coeffs
%calculate instrument temperature
for x=1:length(temp_std)
IT1(x) = 1/(a0+a1*log(therm_raw(x))+a2*log(therm_raw(x))^2+a3*log(therm_raw(x))^3)-273.15;
IT2(x) = 1/(a0_+a1_*log(therm_raw(x))+a2_*log(therm_raw(x))^2+a3_*log(therm_raw(x))^3)-273.15;
end
%calculate Instrument Conductivity (x starts at 2 due to in-air meas)
for x=2:length(tc)
IC1(x) = (g+h*f(x)^2+i*f(x)^3+j*f(x)^4)/(1 + CTcor*tc(x) + CPcor*p);
IC2(x) = (g_+h_*f(x)^2+i_*f(x)^3+j_*f(x)^4)/(1 + CTcor*tc(x) + CPcor*p);
end
% ***** therm fit results *****
figure
subplot(2,1,1);
plot(therm_raw,temp_std,'o','MarkerFaceColor','g','MarkerSize',10)
hold on
plot(c)
hold on
plot(therm_raw,IT2,'x','MarkerEdgeColor','b','MarkerSize',10)
axis([1e5 7e5 0 35])
xlabel('thermistor response')
ylabel('T/C')
legend('standard temp','new fit','thermistor temp')
% ***** therm residuals *****
Tresid1 = IT1 - temp_std;
Tresid2 = IT2 - temp_std;
subplot(2,1,2)
plot(therm_raw,Tresid1,'o','MarkerEdgeColor','b','MarkerSize',10)
hold on
plot(therm_raw,Tresid2,'x','MarkerEdgeColor','r','MarkerSize',10);
axis([1e5 7e5 -0.01 0.01])
grid on
xlabel('thermistor response')
ylabel('temperature residual T/C')
legend('factory cal','new cal')
% ***** cond fit result *****
figure
subplot(2,1,1);
plot(f,BC,'o','MarkerFaceColor','g','MarkerSize',10)
hold on
plot(d)
hold on
plot(f,IC2,'x','MarkerEdgeColor','b','MarkerSize',10)
axis([2.5 7 0 7])
xlabel('frequency (kHz)')
ylabel('conductivity (S/m)')
legend('bottle','new fit','sensor cond')
% ***** cond residuals *****
Cresid1 = IC1 - BC;
Cresid2 = IC2 - BC;
subplot(2,1,2)
plot(f,Cresid1,'o','MarkerEdgeColor','b','MarkerSize',10)
hold on
plot(f,Cresid2,'x','MarkerEdgeColor','r','MarkerSize',10);
axis([2.5 7 -0.0001 0.0001])
grid on
xlabel('frequency (kHz)')
ylabel('conductivity residual (S/m)')
legend('factory cal','new cal')