clear
close all
clc

cd /net/e/amouhagir/Documents


[mus1,Fs]= audioread('coq-2.wav');
mus1=mus1*(2^7);
 
mus=int8(mus1');

%a=bitget(mus(1),9:15);

% [dauphin,Fs]=audioread('dauphin-2.wav');
% 
% dauphin=floor(dauphin*100000);
% mus=dauphin(1:18000);

%audiowrite('test.wav',mus,Fs);



instrreset

s = serial('/dev/ttyUSB1');
s.Baudrate=115200;
s.StopBits=1;
s.Parity='none';
s.FlowControl='none';
s.TimeOut = 10;
s.OutputBufferSize = 1000000;
s.InputBufferSize = 5000000;

fopen(s);

fwrite(s,mus);

instrreset

%fclose(s);
