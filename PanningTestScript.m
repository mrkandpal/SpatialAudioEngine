%% This scipt will aim to pan a 4th order ambisonic file in real time, based on the head position of the listener
%%A pre-decoded ambisonics file wll be used. It will be convolved with
%%HRTFs in real time, based on the head position of the listener. 
clear
close all

%% Set Up Audio Player System Object
targetFs = 48000;
AP = audioDeviceWriter;
AP.SampleRate = targetFs;
AP.BufferSize = 1024;

%% Load HRTF Database 
dataset = load('ReferenceHRTF.mat');

%% Get the HRTF Data in The Required Dimension of: [NumOfSourceMeasurements x 2 x LengthOfSamples]
hrtfData = dataset.hrtfData;
sourcePosition = dataset.sourcePosition(:,[1,2]);

%% Initialize n Speakers For Spatial Audio Output
%Generate A Spherical Layout of Speakers Based on The 39-Speaker Array in
%The 3d Hearing Lab. 
sphereAZ = [0 0 300 240 180 120 60 0 324 288 252 216 180 144 108 72 36 0 330 300 270 240 210 180 150 120 90 60 30 0 324 288 252 216 180 144 108 72 36];
sphereEL = [90 60 60 60 60 60 60 30 30 30 30 30 30 30 30 30 30 0 0 0 0 0 0 0 0 0 0 0 0 -30 -30 -30 -30 -30 -30 -30 -30 -30 -30];

%%Picked Sphere is a matrix that contains angles of elevation and azimuth
%%for each of the 39 speakers
pickedSphere  = [sphereAZ' sphereEL'];
nPoints = size(pickedSphere,1); %nPoints calculated as total number of virtual loudspeakers

%% Decoded Ambisonics File
extension = '.wav';
audioFileName = input('Enter the Ambisonics Audio File Name (Decoded B Format): ','s');
[HOA, fs] = audioread(strcat(audioFileName,extension));
%HOA = resample(HOA, targetFs, fs);

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
        
        % Segmentation of Decoded HOA File
         audioIn=HOA((q-1)*AP.BufferSize+1:(q-1)*AP.BufferSize+1+AP.BufferSize,:);
         
        %Compare Virtual Speaker Locations With Points On the HRTF Database
        for ii = 1:size(pickedSphere,1)
            for jj = 1:size(sourcePosition,1)
                % Calculate arc length
                     d(ii,jj) = acos( ...
                        sind(pickedSphere(ii,2))*sind(sourcePosition(jj,2)) + ...
                        cosd(pickedSphere(ii,2))*cosd(sourcePosition(jj,2)) * ... 
                        cosd(pickedSphere(ii,1) - sourcePosition(jj,1)));

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
        nOverrunAP=step(AP,[audioOutLeft*10 audioOutRight*10]);

        q=q+1;%increment buffer counter
        
        %%Add a condition to replay audio when end of file is reached
        if(q==floor(size(HOA,1)/AP.BufferSize))
            q=1;
            display('Replaying now');
        end
    
end








