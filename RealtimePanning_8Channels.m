%% This scipt will aim to pan a 4th order ambisonic file in real time, based on the head position of the listener
%%A pre-decoded ambisonics file wll be used. It will be convolved with
%%HRTFs in real time, based on the head position of the listener. 
clear
close all

%% Define Sample Rate, Buffer Size and Gain
targetFs = 48000;
bufferSize = 256;
gain = 600;
segmentsPerSecond = targetFs/bufferSize;
repeatFlag = 'y';

%% Initialise Unity Control Elements
%Coutner to keep track of number of activates sources
monoSourceCounter = 0;
%10 IP ports to read data for each possible mono source
monoSourcePortNumbers = [31000, 31001, 31002, 31003, 31004, 31005, 31006, 31007, 31008, 31009];
%2 IP ports to read data for each possible ambisonic scene
ambiSourcePortNumbers = [20000, 20001];
%IP port to read data from reset button
resetButtonPortNumber = 21000;
%IP port to read data from head tracker
headTrackerPortNumber = 8085;
%Matrix to store index and position of each active sound source
activeSourceData = zeros(2,4);

%% Set Up Audio Player System Object
AP = audioDeviceWriter;
AP.SampleRate = targetFs;
AP.BufferSize = bufferSize;
AP.Driver = 'ASIO';

%% Set up UDP Receiver System Object to read data from head tracker
hudpr = dsp.UDPReceiver('LocalIPPort',headTrackerPortNumber,'MessageDataType','double','RemoteIPAddress','127.0.0.1','ReceiveBufferSize',16);
setup(hudpr);

%% Set up cell array of UDP receivers to read mono source data
for i=1:10
   monoSourceReceivers{i,1} =  dsp.UDPReceiver('LocalIPPort',monoSourcePortNumbers(i),'RemoteIPAddress','127.0.0.1','ReceiveBufferSize',8);
   setup(monoSourceReceivers{i,1});
end

%% Set up cell array of UDP receivers to read ambisonic scene data
for i=1:2
    ambiSourceReceivers{i,1} = dsp.UDPReceiver('LocalIPPort',ambiSourcePortNumbers(i),'RemoteIPAddress','127.0.0.1','ReceiveBufferSize',8);
    setup(ambiSourceReceivers{i,1});
end

%% Set up UDP receiver to read data from reset button
resetButtonReceiver = dsp.UDPReceiver('LocalIPPort',resetButtonPortNumber,'RemoteIPAddress','127.0.0.1','ReceiveBufferSize',8);
setup(resetButtonReceiver);

%% Load HRTF Database 
dataset = load('ReferenceHRTF.mat');

%% Get the HRTF Data in The Required Dimension of: [NumOfSourceMeasurements x 2 x LengthOfSamples]
hrtfData = dataset.hrtfData;
sourcePosition = dataset.sourcePosition(:,[1,2]);

%% Initialize 8 Speakers For Spatial Audio Output
%Generate A Spherical Layout of 8 Virtual Loudspeakers 
sphereAZ = [0 45 90 135 180 225 270 315];
sphereEL = [0 0 0 0 0 0 0 0];

%%Picked Sphere is a matrix that contains angles of elevation and azimuth
%%for each of the 8 speakers
pickedSphere  = [sphereAZ' sphereEL'];
nPoints = size(pickedSphere,1); %nPoints calculated as total number of virtual loudspeakers

%% Master Audio File
% extension = '.wav';
% audioFileName = input('Enter the Ambisonics Audio File Name (Decoded B Format): ','s');
% [HOA, fs] = audioread(strcat(audioFileName,extension));
[HOA,fs] = audioread('C:\Users\User\Desktop\Devansh\Spatial Audio Engine\Sound Samples\Dynamic Spatial Audio Scene\Split and Mastered\Combined.wav');
HOA(:,size(HOA,2)+1) = 0;
activeChannels = [19 19 19 19 19 19 19 19];
activeMonoSources = activeChannels([2 4 6 8]);
spatialAudioGain = [0.01 1 0.01 1 0.01 1 0.01 1];

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
        
    monoSourceCounter = 0;
        %%Read data transmitted by mono sources in unity
        for i=1:10
            monoSourceData = step(monoSourceReceivers{i,1});
            if length(monoSourceData)>0
                textIn = split(char(monoSourceData)','|');
                %monoSourceCurrentStates(i) = 1; 
                monoSourceCounter = monoSourceCounter+1;
                activeChannels(monoSourceCounter*2) = str2double(textIn(3));
                pickedSphere(monoSourceCounter*2,1) = str2double(textIn(1));
                spatialAudioGain(monoSourceCounter*2) = 1/str2double(textIn(2));
                
            elseif length(monoSourceData) == 0
                
            end
        end
        
        if(monoSourceCounter ~= 4)
            sourcesToRemove = 4 - monoSourceCounter;
            if(sourcesToRemove == 1)
                %%Remove one audio source and one speaker from the end
                activeChannels(8) = 19;
                pickedSphere(8,1) = 0;
                
            elseif(sourcesToRemove == 2)
                %%Remove two audio sources and two speakers from the end
                activeChannels(8) = 19;
                pickedSphere(8,1) = 0;
                
                activeChannels(6) = 19;
                pickedSphere(6,1) = 0;
                
            elseif(sourcesToRemove == 3)
                %%Remove three audio source and three speakers from the end
                activeChannels(8) = 19;
                pickedSphere(8,1) = 0;
                
                activeChannels(6) = 19;
                pickedSphere(6,1) = 0;
                
                activeChannels(4) = 19;
                pickedSphere(4,1) = 0;
                
            elseif(sourcesToRemove == 4)
                %%Remove four audio source and four speakers from the end
                activeChannels(8) = 19;
                pickedSphere(8,1) = 0;
                
                activeChannels(6) = 19;
                pickedSphere(6,1) = 0;
                
                activeChannels(4) = 19;
                pickedSphere(4,1) = 0;
                
                activeChannels(2) = 19;
                pickedSphere(2,1) = 0;
                
            end
        end    
        
        %%Read data transmitted by ambisonic source buttons in Unity
        for i=1:2
            ambiSceneData = step(ambiSourceReceivers{i,1});
            if length(ambiSceneData) > 0
                if i == 1
                    activeChannels([1 3 5 7]) = [11 12 13 14];
                elseif i == 2
                    activeChannels([1 3 5 7]) = [15 16 17 18]; 
                else
                    activeChannels = activeChannels;
                end
            end
        end
        
        %%Read data from reset button
        resetStatus = step(resetButtonReceiver);
        if length(resetStatus) > 0
            activeChannels = [19 19 19 19 19 19 19 19];
        end
   
        %Segmentation of Decoded HOA File
         audioIn=HOA((q-1)*AP.BufferSize+1:(q-1)*AP.BufferSize+1+AP.BufferSize - 1,activeChannels);
         audioIn = audioIn .* spatialAudioGain;
         flag = 1;
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
        
        flag = 1;%for debugging 

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







