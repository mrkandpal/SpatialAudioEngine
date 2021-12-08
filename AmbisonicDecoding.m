%%This Script will be used to decode an ambisonic audio file (encoded in the
%%b-format) to the 39 speaker array in the 3-d hearing lab 
clear

%% Specify Loudspeaker Layout
%Azimuth Angles
sphereAZ = [0 0 300 240 180 120 60 0 324 288 252 216 180 144 108 72 36 0 330 300 270 240 210 180 150 120 90 60 30 0 324 288 252 216 180 144 108 72 36];
%Angles of Elevation
sphereEL = [90 60 60 60 60 60 60 30 30 30 30 30 30 30 30 30 30 0 0 0 0 0 0 0 0 0 0 0 0 -30 -30 -30 -30 -30 -30 -30 -30 -30 -30];
%Combining Angle Values into one matrix
speakerArray  = [sphereAZ' sphereEL'];

%% Obtain Decoding Matrix
[decodingMatrix, order] = ambiDecoder(speakerArray, 'MMD', 0, 4);

%% Read Audio File
targetFs = 48000;
extension = '.wav';
fileName = input('Enter File Name (B-Format Encoded): ','s');
[ambiAudio, Fs] = audioread(strcat(fileName, extension));
ambiAudio = resample(ambiAudio, targetFs, Fs);
a = 1;

%% Decode Audio File
decodedAudio = decodeHOA_N3D(ambiAudio, decodingMatrix);

%% Write Audio File
audiowrite(strcat('Decoded',fileName,extension),decodedAudio,targetFs);