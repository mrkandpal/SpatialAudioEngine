%%This script will combine multiple mono audio files into the same
%%multi-channel audio file

function combineAudioChannels(directory, numChannels)
    
    %Specify Sampling Frequency
    targetFs = 48000;
    
    %Specify final Filename
    targetFilename = 'Combined';
    
    %Specify File extension
    extension = '.wav';
    
    %Combine All Channels
    for i=1:numChannels
        combinedAudio(:,i) = audioread(strcat(directory,string(i),extension));
    end
    
    %Write Multi-Channel Audio File at Destination
    audiowrite(strcat(directory,targetFilename,extension),combinedAudio,targetFs); 
    
end