clear
close all
clc


image = imread('m31.ppm');
%image = imread('moon.pgm');

image = 0.6*image;

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

% reorder RGB pixels
image_line = []
for i = 1:63
    for(j = 1: 96)
        image_line = [ image_line image(i,j,1)]; % R  
        image_line = [ image_line image(i,j,2)]; % G  
        image_line = [ image_line image(i,j,3)]; % B  
    end    
end

fwrite(s,image_line);

processed_image = fread(s, 63*96);
processed_image = uint8( processed_image );
processed_image = reshape(processed_image, 96, 63)';

imshow(processed_image)

instrreset
%fclose(s);
