%% This scipt will aim to pan a 4th order ambisonic file in real time, based on the head position of the listener
%%A pre-decoded ambisonics file wll be used. It will be convolved with
%%HRTFs in real time, based on the head position of the listener. 
clear
close all

%% Define Sample Rate, Buffer Size and Gain
targetFs = 48000;
bufferSize = 256;
gain = 40;
segmentsPerSecond = targetFs/bufferSize;
repeatFlag = 'y';

%% Set Up Audio Player System Object
AP = audioDeviceWriter;
AP.SampleRate = targetFs;
AP.BufferSize = bufferSize;
AP.Driver = 'ASIO';

%% Set up UDP Receiver System Object
hudpr = dsp.UDPReceiver('LocalIPPort',31003,'MessageDataType','double','RemoteIPAddress','127.0.0.1','ReceiveBufferSize',16);
setup(hudpr);

%% Load HRTF Database 
dataset = load('ReferenceHRTF.mat');

%% Get the HRTF Data in The Required Dimension of: [NumOfSourceMeasurements x 2 x LengthOfSamples]
hrtfData = dataset.hrtfData;
sourcePosition = dataset.sourcePosition(:,[1,2]);

%% Initialize 8 Speakers For Spatial Audio Output
%Generate A Spherical Layout of 8 Virtual Loudspeakers 
sphereAZ = [45 135 225 315];
sphereEL = [0 0 0 0];

%%Picked Sphere is a matrix that contains angles of elevation and azimuth
%%for each of the 8 speakers
pickedSphere  = [sphereAZ' sphereEL'];
nPoints = size(pickedSphere,1); %nPoints calculated as total number of virtual loudspeakers

%% Decoded Ambisonics File
% extension = '.wav';
% audioFileName = input('Enter the Ambisonics Audio File Name (Decoded B Format): ','s');
% [HOA, fs] = audioread(strcat(audioFileName,extension));
[HOA,fs] = audioread('C:\Users\User\Desktop\Devansh\Sound Samples\4 Channel Audio Files\Forest Scene 1\Combined.wav');

%% Create an Array of FIR Filters (HRTF Filters) to Perform Binaural HRTF Filtering Based on the Position of the Virtual Loudspeakers
for ii = 1:nPoints
    LeftFIR{ii} = dsp.FIRFilter('NumeratorSource','Input port');
    RightFIR{ii} = dsp.FIRFilter('NumeratorSource','Input port');
end

pick = zeros(1, nPoints);
d = zeros(size(pickedSphere,1), size(sourcePosition,1));

%% Real-Time Audio Processing Starts Now
%Establish connection with the head tracker before starting the main audio
%processing loop. Add a try/catch block inside the main loop to detect
%exceptions and disconnect serial communication port before exiting the program. 

display('Playing Audio Now');

q=1;
while q>0
   
        %Segmentation of Decoded HOA File
         audioIn=HOA((q-1)*AP.BufferSize+1:(q-1)*AP.BufferSize+1+AP.BufferSize - 1,:);
         
        %Read Headtracking Data
        try
        
            finalAngles = step(hudpr);
            if(~isempty(finalAngles))
                bufferValue = finalAngles;
            else
                bufferValue = bufferValue;
                finalAngles = bufferValue;
            end
            
            display(finalAngles);
            
        catch error
         
            display('error in transmission')
        
        end
        %Calculate current head position as an offset from the calibrated
        %head position
    
        %Compare Virtual Speaker Locations With Points On the HRTF Database
        for ii = 1:size(pickedSphere,1)
            for jj = 1:size(sourcePosition,1)
                % Calculate arc length
                     d(ii,jj) = acos( ...
                        (cosd(pickedSphere(ii,2) - sourcePosition(jj,2))) * ... 
                        cosd(pickedSphere(ii,1) - sourcePosition(jj,1) - finalAngles(1)));

            end
        [~,Idx] = sort(d(ii,:)); % Sort points
        pick(ii) = Idx(1);       % Pick the closest point
        end
        
        %Select the relevant HRIR's - Binauralisation
        %second index of audioIn refers to number of channels. use 1 for mono audio.
        %For multi-channel audio, use index ii with audio in. In this case,
        %the number of channels in the audio file and the number of
        %virtual loudspeakers should be the same.
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

        q=q+1;%increment buffer counter
        
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







