%%This scripts sets up a UDp recevier system object and uses it to receive
%%data from the head tracker.

clear
close all

%% Set Up the UDP Receiver System Object

hudpr = dsp.UDPReceiver('LocalIPPort',31003,'MessageDataType','double','RemoteIPAddress','127.0.0.1','ReceiveBufferSize',16);
setup(hudpr);

%% Initialise Unity Control Elements
monoSourceCounter = 0;
activeChannels = [11 1 12 1 13 2 14 2];
monoSourcePortNumbers = [31000, 31001, 31002, 31003, 31004, 31005, 31006, 31007, 31008, 31009];
ambiSourcePortNumbers = [20000, 20001];

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



%% Real-Time loop to receive UDP data packets and process audio

q=1;

while q>0
    
    try
           monoSourceCounter = 0;
       for i=1:10
            a = step(monoSourceReceivers{i,1});
            if length(a)>0
                monoSourceCounter = monoSourceCounter + 1;
                textIn = split(char(a)','|');
                checkFlag = 1;
                if monoSourceCounter == 1
                    %%Reposition and change output of the first mono
                    %%speaker
                    display(str2double(textIn(1)));
                    display(str2double(textIn(3)));
                    
                elseif monoSourceCounter == 2
                    %%Reposition and change audio of the second mono
                    %%speaker
                    display(str2double(textIn(1)));
                    display(str2double(textIn(3)));
                    
                elseif monoSourceCounter == 3
                    %%Repostion and change the output of the third mono
                    %%speaker
                    display(str2double(textIn(1)));
                    display(str2double(textIn(3)));
                    
                elseif monoSourceCounter == 4
                    %%Reposition and change the output of the fourth mono
                    %%speaker
                    display(str2double(textIn(1)));
                    display(str2double(textIn(3)));
                    
                else
                    monoSourceCounter = monoSourceCounter;
                end
                
            else
                monoSourceCounter = monoSourceCounter;
            end
        end
        
    catch error
         
        display(error.message)
        
        continue
        
    end
    q=q+1;
end