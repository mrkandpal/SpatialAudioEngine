%%This script provides the setup for interfacting MATLAB with the sound
%%card of the computer.

%% Write To Sound Card
audioReader = audioDeviceReader;
audioReader.Driver = 'ASIO';
audioReader.Device = 'ASIO Fireface USB';
audioReader.SampleRate = fs;
audioReader.ChannelMappingSource = 'Property';
audioReader.ChannelMapping = [3];
audioReader.SamplesPerFrame = samplesPerFrame;
audioReader.BitDepth = '24-bit integer';

%% Playback From Sound Card
audioWriter = audioDeviceWriter;
audioWriter.Driver = 'ASIO';
audioWriter.Device = 'ASIO Fireface USB';
audioWriter.SampleRate = fs;
audioWriter.ChannelMappingSource = 'Property';
audioWriter.ChannelMapping = [1 7 8];
audioWriter.BitDepth = '24-bit integer';