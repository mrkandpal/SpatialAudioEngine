%%This script is used to encode a mono audio signal into higher order
%%ambisonics (B-format)
clear

%% Read Audio File
extension = '.wav';
fileName = input('Enter File Name (Mono Audio): ','s');
[monoSignal, fs] = audioread(strcat(fileName, extension));

%% Encode to HOA
azimuth = 45;
elevation = 0;
hoasig = encodeHOA_N3D(4, monoSignal, [azimuth elevation]);
%%The angle pair (azimuth, elevation) determines where the sound source is
%%placed

%% Write Audio File
audiowrite(strcat('BFormat', string(azimuth),'-', string(elevation), fileName, extension), hoasig, fs);