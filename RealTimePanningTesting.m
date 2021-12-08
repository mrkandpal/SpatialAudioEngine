 %% This scipt will aim to pan a 4th order ambisonic file in real time, based on the head position of the listener
%%A pre-decoded ambisonics file wll be used. It will be convolved with
%%HRTFs in real time, based on the head position of the listener. 
clear
close all

%% Define Sample Rate, Buffer Size and Gain
targetFs = 48000;
bufferSize = 96;
gain = 10;
segmentsPerSecond = targetFs/bufferSize;
audioInCorr = 0;
audioOutCorr = 0;

%% Set Up Audio Player System Object
AP = audioDeviceWriter;
AP.SampleRate = targetFs;
AP.BufferSize = bufferSize;
AP.Driver = 'ASIO';
% AP.ChannelMappingSource = 'Property';
% AP.ChannelMapping = [1 2];
% AP.BitDepth = '24-bit integer';

%% Set up Audio Recorder Object
% AR = audioDeviceReader;
% AR.SampleRate = targetFs;
% AR.SamplesPerFrame = bufferSize;
% AR.Driver = 'ASIO';
% AR.ChannelMappingSource = 'Property';
% AR.ChannelMapping = [1];
% AR.BitDepth = '24-bit integer';

%% Load HRTF Database 
dataset = load('ReferenceHRTF.mat');

%% Get the HRTF Data in The Required Dimension of: [NumOfSourceMeasurements x 2 x LengthOfSamples]
hrtfData = dataset.hrtfData;
sourcePosition = dataset.sourcePosition(:,[1,2]);

%% Initialize n Speakers For Spatial Audio Output
%Generate A Spherical Layout of Speakers Based on The 39-Speaker Array in
%The 3d Hearing Lab. 
% sphereAZ = [0 0 300 240 180 120 60 0 324 288 252 216 180 144 108 72 36 0 330 300 270 240 210 180 150 120 90 60 30 0 324 288 252 216 180 144 108 72 36];
% sphereEL = [90 60 60 60 60 60 60 30 30 30 30 30 30 30 30 30 30 0 0 0 0 0 0 0 0 0 0 0 0 -30 -30 -30 -30 -30 -30 -30 -30 -30 -30];

sphereAZ = [45 135 225 315];
sphereEL = [0 0 0 0];

%%Picked Sphere is a matrix that contains angles of elevation and azimuth
%%for each of the 39 speakers
pickedSphere  = [sphereAZ' sphereEL'];
nPoints = size(pickedSphere,1); %nPoints calculated as total number of virtual loudspeakers

%% Generate a sequence of angles spaced by 0.5 degrees, ranging from 0 to 360
%%degrees. These will be used to hard-code the differences in azimuth angles, to identify how
%%different azimuth values affect the panning of the ambisonic soound field
testStartValue = 0;
testEndValue = 360;
testAzimuthAngles = (testStartValue:2:testEndValue)';
testArraySize = size(testAzimuthAngles,1);

%% Decoded Ambisonics File
% extension = '.wav';
% audioFileName = input('Enter the Ambisonics Audio File Name (Decoded B Format): ','s');
% [HOA, fs] = audioread(strcat(audioFileName,extension));

%Uncomment the following section to enable only one loudpspeaker from the
%virutal speaker array
% temp=HOA(:,21);
% HOA=zeros(size(HOA,1),size(HOA,2));
% HOA(:,21)=temp;

%%Uncomment the following section to read only the first channel from the
%%encoded ambisonics (zero order)
% [HOA,fs] = audioread('BFormat45-0BeethovenSample.wav');
% HOA = HOA(:,1);

%%Uncomment the following section to read a mono audio file as input (no
%%ambisonics)
[HOA,fs] = audioread('BirdsAndForest.wav');
HOA(:,3) = HOA(:,1);
HOA(:,4) = HOA(:,2);
HOA(:,2) = HOA(:,1);
HOA(:,3) = HOA(:,4);


%%Uncomment the following section to 
% rng('default');
% HOA = rand(480000,1);
% HOA(:,2) = zeros();

%% Create an Array of FIR Filters (HRTF Filters) to Perform Binaural HRTF Filtering Based on the Position of the Virtual Loudspeakers
for ii = 1:nPoints
    LeftFIR{ii} = dsp.FIRFilter('NumeratorSource','Input port');
    RightFIR{ii} = dsp.FIRFilter('NumeratorSource','Input port');
end

pick = zeros(1, nPoints);
d = zeros(size(pickedSphere,1), size(sourcePosition,1));

%% Real-Time Audio Processing Starts Now

display('Playing Audio Now');
%SK7_Start( 'open' , COM_PORT );

q=1;
while q>0
        
         %Segmentation of Decoded HOA File
         audioIn=HOA((q-1)*AP.BufferSize+1:(q-1)*AP.BufferSize+1+AP.BufferSize - 1,:);
       
         %Calculate Index of Testing Angle
         testAngleIndex = mod(q,testArraySize);
         if testAngleIndex == 0
             testAngleIndex = 1;
         end
         
         panningChoice = 'n';
         
        %Compare Virtual Speaker Locations With Points On the HRTF Database
        for ii = 1:size(pickedSphere,1)
            for jj = 1:size(sourcePosition,1)
                
                if panningChoice == 'y'
                    % Calculate arc length 
                     d(ii,jj) = acos( ...
                        (cosd(pickedSphere(ii,2) - sourcePosition(jj,2))) * ... 
                        (cosd(pickedSphere(ii,1) - sourcePosition(jj,1) - testAzimuthAngles(testAngleIndex))));
                else 
                    % Calculate arc length
                     d(ii,jj) = acos( ...
                        (cosd(pickedSphere(ii,2) - sourcePosition(jj,2))) * ... 
                        (cosd(pickedSphere(ii,1) - sourcePosition(jj,1))));
                end
  
            end
        [~,Idx] = sort(d(ii,:)); % Sort points
        pick(ii) = Idx(1);       % Pick the closest point
        end
        
    % Select the relevant HRIR's - Binauralisation
    %second index of audioIn controls number of active speakers. use 'ii' for all 
        for ii = 1:nPoints
                audioFilteredLeft(:,ii) = step(LeftFIR{ii}, audioIn(:,ii),double(hrtfData(:,pick(ii),1)')); % Left
                audioFilteredRight(:,ii) = step(RightFIR{ii}, audioIn(:,ii),double(hrtfData(:,pick(ii),2)')); % Right
        end
        
        % Sum the signals for each HRIR
        audioOutLeft = sum(audioFilteredLeft,2);
        audioOutRight = sum(audioFilteredRight,2);
        
        a = 1;%for debugging 

        % Play
        nOverrunAP=step(AP,[audioOutLeft*gain audioOutRight*gain]);
        
        % Latency Measuring Starts Now
%         [recSig,nOverrunRec]=step(AR);
%         
%         if q==1
%             audioInCorr = audioIn;
%             audioOutCorr = recSig;
%         end
%         
%         audioInCorr = vertcat(audioInCorr,audioIn);
%         audioOutCorr = vertcat(audioOutCorr,recSig);     
                
        
        q=q+1;%increment buffer counter

        repeatFlag = 'n';
        %%Add a condition to replay audio when end of file is reached
        if(q==floor(size(HOA,1)/AP.BufferSize))
            if repeatFlag == 'y'
                display('Replaying now');
                q=1;
            else
                display('Audio Playback Stopped');
                break
            end
        end
    
end



