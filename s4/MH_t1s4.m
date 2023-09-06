%For scenario 4 
%used curve fitting
% run in s4 directory
%% cleaning
clear
close all
clc

%% setup
ss=[{'Yes'},{'No'},{'Go'},{'Left'},{'Right'},{'Stop'}];%Sample space of all possible outcomes
usr=[{'M'},{'F'}]; % User male or female
nos=120; %number of sample
n=10; %Number of samples for unique word
fs=8000; %frequency
dirName='../Audio Samples/'; %Name of data directory
%we did a 80/20 split
% curve fitting
type='poly2';
%prediction value 0 for male and 1 for female
traindata=zeros(nos,2); %first column is of avrage pitch and second column of 0,1 male or female

%% Training
m=1;
for i=1:size(usr,2)
    for j=1:size(ss,2)
        l=1;
        for k=1:8
            if k==4||k==8
                l=l+1;
            end
            fileName=strcat(dirName,usr(i),{' '},ss(i),' (',int2str(l),').wav');
            [y,~]=audioread(char(fileName));
            zz=(find(y)<max(y)/3); %Threshold speech
            y(zz)=0;
            zz=find(y);
            speechRegion=y(zz)/norm(y(zz));
            avg_pitch=sum(pitch(y,fs))/numel(pitch(y,fs));
            traindata(m,:)=[avg_pitch,i-1];
            l=l+1;
            m=m+1;
        end
    end
end

%Performing curve fitting
f=fit(traindata(:,1),traindata(:,2),type);

%% Testing
for i=1:size(usr,2)
    for j=1:size(ss,2)
        for k=1:2
            fileName=strcat(dirName,usr(i),{' '},ss(j),' (',int2str(k*4),').wav');
            disp(char(strcat('Actual value: ',usr(i))));
            [y,~]=audioread(char(fileName));
            zz=(find(y)<max(y)/3); %Threshold speech
            y(zz)=0;
            zz=find(y);
            speechRegion=y(zz)/norm(y(zz));
            avg_pitch=sum(pitch(y,fs))/numel(pitch(y,fs));
            prv=round(f(avg_pitch)+0.04); %after curve fitting value ware very low so added 0.04
            disp(char(strcat('Predicted value: ',usr(prv+1))));
        end
    end
end
