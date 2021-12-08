%%This script provides a template that can be used to establish a
%%non-persistent (UDP based) connection to exchange data with low latency.
%%A working implementation of this approach will require two MATLAB scripts
%%running concurrently - one for UDP transmission and one for audio
%%processing and UDP reception

%% Set Up UDP Sender System Object
hudps = dsp.UDPSender('RemoteIPPort',31003);


%% Loop 1
%%The first real-time loop handles transmission of UDP packets. This loop
%%also handles head-tracker calibration. As a result, the script for
%%real-time audio processing can run with lesser load.
q=1;

while q

%%Read headtracker data here

%%Send over udp

step(hudps,headtracking_data);

%You might also need a pause here

pause(0.01)

end

%% Set Up the UDP Receiver System Object

hudpr = dsp.UDPReceiver('LocalIPPort',31003,'MessageDataType','double');

setup(hudpr);

%% Loop 2
%%This Real-Time Loop Handles Audio Processing and Reception of UDP Packets

q=1

while q


headtracking_data =step(hudpr);

 
end