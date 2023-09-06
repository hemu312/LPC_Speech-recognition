%For scenario 2 
%used LPC method
% run in s2 directory
%% cleaning
clear
close all
clc

%% setup
ss=[{'Yes'},{'No'}];%Sample space of all possible outcomes
usr=[{'M'},{'F'}]; % User male or female
nos=40; %number of sample
n=10; %Number of samples for unique word
fs=8000; %frequency
T=2; %duration of audio in seconds
dirName='../Audio Samples/'; %Name of data directory
%we did a 80/20 split
% LPC parameters
NoOfLPCFilters = 5;
lpccoeff = zeros(size(ss,2),size(usr,2)*8,NoOfLPCFilters+1);

%% noise generation
% single tone noise with frequency 2500 Hz
fs_noise=2500; %frequency of noise
A=2; %Amplitude of noise
t=linspace(0,2,16000); %Time series for noise signal
f=linspace(0,8000,16000); %Frequency series
noise=A*sin(2*pi*fs_noise*t);
%fftnoise=fft(noise); %fft of noise
%plot(f,abs(fftnoise)); %plot fft of noise

%% FIR filter Design
N   = 50;        % FIR filter order
fp  = 600;       % 500 Hz passband-edge frequency
fs  = 8000;       % 8 kHz sampling frequency
rp  = 0.00057565; % Corresponds to 0.01 dB peak-to-peak ripple
rst = 1e-4;       % Corresponds to 80 dB stopband attenuation

eqnum = firceqrip(N,fp/(fs/2),[rp rst],'passedge'); % eqnum = vec of coeffs
lowpassFIR = dsp.FIRFilter('Numerator',eqnum); %or eqNum200 or numMinOrder

%% Training
for i=1:size(ss,2)
    m=1;
    for j=1:size(usr,2)
        l=1;
        for k=1:8
            if k==4||k==8
                l=l+1;
            end
            fileName=strcat(dirName,usr(j),{' '},ss(i),' (',int2str(l),').wav');
            [y,~]=audioread(char(fileName));
            %plot(f,abs(fft(y))); %fft of signal before noise
            y=y+noise';
            %plot(f,abs(fft(y))); %fft of signal after adding noise
            y=lowpassFIR(y); %applying fir filter to the signal
            zz=(find(y)<max(y)/3); %Threshold speech
            y(zz)=0;
            zz=find(y);
            %plot(y); %plot filtered signal
            speechRegion=y(zz)/norm(y(zz));
            lpccoeff(i,m,:)=lpc(speechRegion,NoOfLPCFilters);
            m=m+1;
            l=l+1;
        end
    end
end

%Performing Gaussian Modelling for lpc
tempStorage = zeros(size(usr,2)*8,NoOfLPCFilters);
tempStorage(:,:) = lpccoeff(1,:,2:end);
obj_Yes = gmdistribution.fit(tempStorage,1);
tempStorage(:,:) = lpccoeff(2,:,2:end);
obj_No = gmdistribution.fit(tempStorage,1);

%% Testing
% calculate lpc for testing data
for i=1:size(ss,2)
    for j=1:size(usr,2)
        for k=1:2
            fileName=strcat(dirName,usr(j),{' '},ss(i),' (',int2str(k*4),').wav');
            disp(char(strcat('Actual value: ',ss(i))));
            [y,~]=audioread(char(fileName));
            zz=(find(y)<max(y)/3); %Threshold speech
            y(zz)=0;
            zz=find(y);
            speechRegion=y(zz)/norm(y(zz));
            lpc_test = lpc(speechRegion,NoOfLPCFilters);
            %classify lpc of test data on Mahanalobis distance
            d(1)=mahal(obj_Yes,lpc_test(2:end));
            d(2)=mahal(obj_No,lpc_test(2:end));
            [~,ind]=min(d);
            disp(char(strcat('Predicted value: ',ss(ind))));
        end
    end
end
