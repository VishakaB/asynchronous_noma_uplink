%date: 10/05/2022
%version 7 of optimization problem
%maximize the number of users
%subject to sinr and channel gain constraints
%constraint to constrict the optimal variable to a binary variable
clc;
clear all;
close all;

%% initialization
%number of users 
K = 4;

%use stochastic gradient descent to converge
nbiter      = 1000;%maximum number of iterations to converge

%initialize the optimizing variables
lam_opt(1)  = 0;%lambda 
up_opt(1)   = 0;%upsilon
beta(1)     = 2;%dinkelbach parameter
user_opt(1) = 0;%optimizing variable

E_circuit   = 5.0; %fixed circuit power consumption
B           = 10^6;%channel bandwidth
E_dec       = 0.1;% decoding energy per symbol

ep_userk    = 1;%epsilon 1
ep_lamk     = 1;%epsilon 2
ep_upk      = 1;%epsilon 2

grad_u      = zeros(K,nbiter);%gradient of lagrangian function
t           = 0.4; %fixed learning rate

%% environmnet
N=10^3;  % Number of Bits
d4 = 10; d3 = 9; d2 = 4; d1 = 3;    %Distances of users from rx
communication_radius = d4;
eta = 4;            % Path loss exponent

noisepower   = 1.0;
max_tx_power = 100;

%transmission power of each user
transmitpow_k = max_tx_power*abs(randn(K,1));% unsorted transmit power vector

tx_pow_k = sort(transmitpow_k,'descend'); %sorted transmit power vector %descending 

p1 =tx_pow_k(1);%nearest user
p2 =tx_pow_k(2);
p3 =tx_pow_k(3);
p4 =tx_pow_k(4);%farthest user

%channel coefficients of each user 
h1 = sqrt(d1^-eta)*sqrt(p1/2)*(randn(1,N)+1i*randn(1,N))/sqrt(2);
h2 = sqrt(d2^-eta)*sqrt(p2/2)*(randn(1,N)+1i*randn(1,N))/sqrt(2);
h3 = sqrt(d3^-eta)*sqrt(p3/2)*(randn(1,N)+1i*randn(1,N))/sqrt(2);
h4 = sqrt(d4^-eta)*sqrt(p4/2)*(randn(1,N)+1i*randn(1,N))/sqrt(2);

h_th = sqrt(communication_radius^-eta)*sqrt(max_tx_power/2)*(randn(1,N)+1i*randn(1,N))/sqrt(2);

%channel gains
g1 = (abs(h1)).^2;
g2 = (abs(h2)).^2;
g3 = (abs(h3)).^2;
g4 = (abs(h4)).^2;
g_th = (abs(h_th)).^2;

%% throughput of each user
%considering synchronous uplink noma
SNR = 20:2:40;
snr = db2pow(SNR);

%add the symbol duration????????????????
C1 = B*(log2(1 +g1*p1./(g2.*p2+g3.*p3+g4.*p4+1)));
C2 = B*(log2(1 +g2.*p2./(g3.*p3+g4.*p4+1)));
C3 = B*(log2(1 +g3.*p3./(g4.*p4+1)));
C4 = B*(log2(1 +g4.*p4));

%% optimization problem
n = 3;

lam1(1)     = 1;
lam2(1)     = 1;
lam3(1)     = 1;
lam4(1)     = 1;
lam5(1)     = 1;

uk(1)       = 0; %optimizing variable
uk(2)       = 0; %optimizing variable
uk(3)       = 0; %optimizing variable
uk(4)       = 0; %optimizing variable

%symbols
s1   = 0.5;
s2   = 0.4;
s3   = 0.2;
s4   = 0.1;

%vectors
interf_vec  = zeros(K,1);
sym_dur_vec = [s1;s2;s3;s4];
power_vec   = [p1;p2;p3;p4];
g_vec       = [g1;g2;g3;g4];%channel gain vector
g_th        = communication_radius.^g_th;
rate_th     = log2( 1 + max_tx_power*g_th/noisepower);
desired_id  = 1;

for k =1:K
    if k ~= desired_id
        interf_vec(k) = power_vec(k)*g_vec(k)*sym_dur_vec(k) + interf_vec(k);
    end   
end

grad_uk = zeros(K,1);
uk      = zeros(K,1);

uk(:,n) = ones(K,1);

%% iterations
%consider the grad of the objective function 
for iter =1:nbiter
    n =iter;
    disp(n)
    %define u vector and give an initial value to it
    uk(:,n+1)       = uk(:,n) + t*grad_uk(:,n);
    grad_uk(:,n+1)= K^2 - lam1*K - lam2*K - 2*lam2*uk(n)*K ...
              -lam3*mean(g_th)*K - lam3*mean(g_vec,2) - ...
              lam4*max_tx_power*mean(g_th,2)*(noisepower^2+(interf_vec))...
              - lam5 - lam5;
    %u(:,n+1)  = u(:,n+1) >0;%convert to binary
    if(n >1 & uk(:,n+1)==uk(:,n))
        disp('yes');
        disp(uk(:,n+1));
        disp(uk(:,n));
        break;
    end
    
end