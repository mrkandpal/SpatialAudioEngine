clear all
close all

%% Headtracker Shake_SK7
COM_PORT = 'COM7';
SK7_Start( 'open' , COM_PORT );
sk7config = SK7_Config;
IDs = SK7_Get_Sensor_IDs();
ang=0;
while SK7_Data_Samples_Available(2) < 3
    pause( 0.01 ); % prevent busy waiting
end

%% Get position coordinates from head tracker
%%Use try/catch block to capture any
%%exceptions. Improper ending of MATLAB script causes program to end
%%without releasing serial port, which then gets blocked and cannot be
%%accesed again without restarting the system. 

while(1)
    try
        %%Argument format - (sensorID, numberOfSamples). This function
        %%returns a matrix of 'numberOfSamples' rows and 4 coulmns of data.
        gyro1 = double(SK7_Get_Sensor_Data(6,1))
        flag = 1;
        if length(gyro1)>3
            a = size(gyro1);
            ang0 = gyro1([3 1])/10;
            
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