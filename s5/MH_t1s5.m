%For scenario 5 
%used LPC method
% run in s5 directory
%% cleaning
clear
close all
clc

%% setup
ss=[{'Go'},{'Stop'},{'Left'},{'Right'}];%Sample space of all possible outcomes
usr=[{'M'},{'F'}]; % User male or female
nos=80; %number of sample
n=10; %Number of samples for unique word
fs=8000; %frequency
dirName='../Audio Samples/'; %Name of data directory
%we did a 80/20 split
% LPC parameters
NoOfLPCFilters = 10;
lpccoeff = zeros(size(ss,2),size(usr,2)*8,NoOfLPCFilters+1);

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
            zz=(find(y)<max(y)/3); %Threshold speech
            y(zz)=0;
            zz=find(y);
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
obj_Go = gmdistribution.fit(tempStorage,1);
tempStorage(:,:) = lpccoeff(2,:,2:end);
obj_Stop = gmdistribution.fit(tempStorage,1);
tempStorage(:,:) = lpccoeff(3,:,2:end);
obj_Left = gmdistribution.fit(tempStorage,1);
tempStorage(:,:) = lpccoeff(4,:,2:end);
obj_Right = gmdistribution.fit(tempStorage,1);

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
            d(1)=mahal(obj_Go,lpc_test(2:end));
            d(2)=mahal(obj_Stop,lpc_test(2:end));
            d(3)=mahal(obj_Left,lpc_test(2:end));
            d(4)=mahal(obj_Right,lpc_test(2:end));
            [~,ind]=min(d);
            disp(char(strcat('Predicted value: ',ss(ind))));
        end
    end
end

%% accuracy is 11/16