%%This script contains a function to write each channel of an audio file as
%%an individual audio file

%% Function to separate channels starts now
function SplitAudioChannels(audioInput)
    
    %Set target sampling frequency
    targetFs = 48000;
    
    %Determine total audio channels in the input file
    numChannels = size(audioInput,2);
    
    %Accept filename as input from the user
    fileName = input('Enter Target Filename: ', 's');
    
    %Set target directory and file extension 
    targetDirectory = 'C:\Users\User\Desktop\Devansh\Spatial Audio Engine\Sound Samples\Split Ambisonics\ThunderAmbisonics\';
    extension = '.wav';
    
    for i=1:numChannels
        splitAudio = audioInput(:,i);
        audiowrite(strcat(targetDirectory,fileName,'-channel',string(i),extension),splitAudio,targetFs);    
    end

end
