%%This scripts calibrates the head tracker and then sets up a UDP sender
%%system object to transmit head tracking data over the network to the
%%real-time audio processing script. 

clear
close all

%% Set Up UDP Sender System Object
hudps = dsp.UDPSender('RemoteIPPort',8085,'RemoteIPAddress','127.0.0.1','SendBufferSize',16);

%% Initial Head Tracker Calibration - Here the Listener is Asked to Calibrate The Head Tracker Based on The Starting Position of Their Head
calibrate = input('Enter Y/y To Calibrate Head Position Tracking: ', 's');
if calibrate == 'y' || calibrate == 'Y'
%%Start connection with the headtracker now    
    COM_PORT = 'COM7';
    SK7_Start( 'open' , COM_PORT );
    sk7config = SK7_Config;
    IDs = SK7_Get_Sensor_IDs();
    ang=0;
    while SK7_Data_Samples_Available(2) < 3
        pause( 0.01 ); % prevent busy waiting
    end
    
    while(1)
        try
            gyro1 = double(SK7_Get_Sensor_Data(6,1)); 
            if length(gyro1)>2
                calibrationAngles = gyro1([3 1])/10;
                break
            end
            q=1;
        catch error
            SK7_Start('close', COM_PORT);
            print("error handled");
        end
    end 
    
    %SK7_Start('close', COM_PORT);
    display('Head Tracker Calibrated');
    display('Starting Data Transmission..');
else 
    display('Calibration Cancelled, Exiting Now');
    q=0;
end

%% Real-Time loop for transmitting UDP packets

while q

     try
         
        % Read Headtracking Data
        gyro1 = double(SK7_Get_Sensor_Data(6,1));
        if length(gyro1)>2
            currentHeadPosition=gyro1([3 1])/10; % [elev, roll, az]
        end
        %Calculate current head position as an offset from the calibrated
        %head position
        finalHeadPosition(1) = calibrationAngles(1) - currentHeadPosition(1);
        finalHeadPosition(2) = calibrationAngles(2) - currentHeadPosition(2);

        %%Send over udp

        step(hudps,finalHeadPosition);
        
        
        display(finalHeadPosition);
       % toc
        
        %%A pause is added to synchronise the rate of transmission adn the
        %%rate of reception. A pause value of 0.02 seconds translates to a
        %%transmission rate of 50Hz.
        %pause(0.025)
        
     catch error
         
          SK7_Start('close', COM_PORT);
         
     end

end

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     