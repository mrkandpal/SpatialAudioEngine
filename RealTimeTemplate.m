clear all
close all
 
fs=44100;
 
% Audio player
AP=audioDeviceWriter;
AP.SampleRate=fs;
AP.BufferSize=96;
 

% HOA
Nsources=25; % number of virtual speakers e.g 25
HOA=randn(fs*10,Nsources); % put your decoded ambisonics here as a matrix where columns are channels.
 
% Setup FIR filter objects for HRIR's
for n=1:Nsources
    mp_L_obj{n} = dsp.FIRFilter('NumeratorSource','Input port'); % Minimum phase HRTF's
    mp_R_obj{n} = dsp.FIRFilter('NumeratorSource','Input port');
end
 
%% Head Tracker Setup 
COM_PORT = 'COM7';
SK7_Start( 'open' , COM_PORT );
sk7config = SK7_Config;
IDs = SK7_Get_Sensor_IDs();
ang=0;
while SK7_Data_Samples_Available(2) < 3
    pause( 0.01 ); % prevent busy waiting
end

%%Get position coordinates from head tracker
%%Use try/catch block to capture any
%%exceptions. Improper ending of MATLAB script causes program to end
%%without releasing serial port, which then gets blocked and cannot be
%%accesed again without restarting the system. 

while(1)
    try
        %%Argument format - (sensorID, numberOfSamples). This function
        %%returns a matrix of 'numberOfSamples' rows and 4 coulmns of data.
        gyro1 = double(SK7_Get_Sensor_Data(6,10)); 
        if length(gyro1)>3
            ang0 = gyro1([3 1])/10;
            break
        end
        
    catch error
    %%Exception Handling block - catch errors and release serial
    %%communications port before program ends
    SK7_Start('close', COM_PORT);
    print("error handled");
    end

end 

SK7_Start('close', COM_PORT);
display('Head tracking calibrated') 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Here comes the main loop
q=1;
while q>0
   
    
    
    % cut the Ambisonics into small segments
    audioIn=HOA((q-1)*AP.BufferSize+1:(q-1)*AP.BufferSize+1+AP.BufferSize,:);
   
    
    % Read Headtracking data
    gyro1 = double(SK7_Get_Sensor_Data(6,1));
    if length(gyro1)>2
        ang=gyro1([3 1])/10-ang0; % [elev, roll, az]
    end
   
    
    % Select the relevant HRIR's (HRTF in time domain)
    % TH2 is the angle to each HRIR
    % Note that you have to write this code your self.
    for n=1:Nsources
        [mp_L_int(:,n), mp_R_int(:,n)]=find_HRIR_3D(Th2(n,:),HRIR_L,HRIR_R);
    end
   
    
    for n=1:Nsources
        % filter audio with relevant HRIR
        y1L=step(mp_L_obj{n},audioIn(:,n),mp_L_int(:,n)');
        y1R=step(mp_R_obj{n},audioIn(:,n),mp_R_int(:,n)');
    end
   
    % and sum the signals for each HRIR
    audioOutL=sum(y1L,2);
    audioOutR=sum(y1R,2);
   
    % Play
    nOverrunAP=step(AP,[audioOutL audioOutR]);
   
        
    q=q+1;
end