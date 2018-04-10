%% MATLAB Number Plate Detection
%% author @naruarjun
% -----------------------------------------------------------------------------------------------------------------
% 
% The basic algorithm being followed here in brief is as follows:-
% 
% # Preprocessing(Grascaling,Gaussian blurring,Adaptive Histogram Equalisation)                                      
% # Morphological Opening and image subtraction.
% # Image Binarisation.
% # Canny edge detection.
% # Dilation and Filling holes in the edge detected image.
% # Another set of Morphological opening,closing,dilation operations.
% # Making the image 0 wherever dilated image id 0.
% # Draw Bounding Boxes and place constraints on the area and relationship between 
% height and width to filter out the bounding box with the Number plate.                                                                                                                                                            
%% *Loading the image into the variable img*

img = imread('download3.jpg');
imshow(img)
%% 
%% Grayscaling the image and filtering it using Gaussian Filter to remove noise
% This is really useful later as a lot of the noise in the image is removed.

img = rgb2gray(img);
img_bf = imgaussfilt(img,0.6);
img_bf = uint8(img_bf);
imshow(img_bf)
%% Doing Adaptive Histogram Equalisation to increase contrast and then perform opening operation and then subtract the contrasted image and opened image
% Increasing the contrast helps in getting great results in the opened image. 
% So that when we subtract the two the output that we get is really close to isolating 
% the area with the number plate.

img_bf_contrast=adapthisteq(img_bf);
se = strel('disk',15);
img_bf_opened = imopen(img_bf_contrast,se);
img_subtracted = imsubtract(img_bf_contrast,img_bf_opened);
imshow(img_subtracted)
%% 
%% Binarize the image(convert it to 0 and 1) based on a threshhold computed by graythresh
% This helps in getting great results while we do edge detection.

level = graythresh(img_subtracted)
img_binarized = imbinarize(img_subtracted,level+0.4);
imshow(img_binarized);
%% Detect the edges(Canny edge detection) in the binarized image and then dilate to increase the thickness of these edges and then fill the holes in the image
% The subtraction will still have some regions other than the number plate. 
% The abundance of edges inside a number plate comes to our aid. The edges are 
% dilated and as the edges in a number plate are really closed together and concentrated, 
% When we fill holes almost the entire number plate becomes white.This therefore 
% filters out some more regions that are nor part of the numberplate.

img_edge = edge(img_binarized,'Canny');
imshow(img_edge);
se = strel('line',5,17);
img_dilate = imdilate(img_edge,se);
img_dilate = imdilate(img_dilate,se);
img_fill = imfill(img_dilate,'holes');
for i = 1:20
    img_fill = imfill(img_fill,'holes');
end
imshow(img_fill)
%% Another set of opening,dilation,erosion operations
% This helps in removing small white areas that might have remained until now.

se = strel('line',11,21);
img_open = imopen(img_fill,se);
se = strel('line',11,90);
img_erode = imerode(img_open,se);
se = strel('disk',7);
img_dilated2 = imdilate(img_erode,se);
imshow(img_dilated2)
%% The dilated image contains all the important points in the image, So wherever img_dilated2 is 0, assign the same value to the original image, then binarize the obtained image.
% There are still some points that are not part of the numberplate but are still 
% white in the binarized image. But these points are easy to filter out using 
% bounding boxes and putting constraints on them.

img(img_dilated2==0)=0;
level = graythresh(img);
img_final_inverted = imbinarize(img,level+0.2);
img_copy = img_final_inverted;
imshow(img_copy);
%% Use the regionprops() function to get boundingboxes over the prominent areas left in img_copy, These bounding boxes are used to extract the numberplate, before that reload the original image into img and we project the bounding boxes obtained in img_copy into img

s  = regionprops(img_copy,'BoundingBox','Area');
v = [];
a=[0,0,0,0];
j=1;
subimage{1} = {img(1:2,1:2)};
img = imread('download3.jpg');
%% 
%% 
%% Project every bounding box with area greater than 800 and area<30000 and those bounding boxes whose width is greater than height, Apply median filters and the show the final output
% As we can see the numberplates are isolated with great accuracy.

for index=1:length(s)
    if (s(index).Area > 800 && s(index).BoundingBox(3)*s(index).BoundingBox(4) < 30000 ...
        &&s(index).BoundingBox(3)>s(index).BoundingBox(4))
      x = ceil(s(index).BoundingBox(1));
      y= ceil(s(index).BoundingBox(2));
      widthX = floor(s(index).BoundingBox(3)-1);
      widthY = floor(s(index).BoundingBox(4)-1);
      subimage(index) = {img_bf(y:y+widthY,x:x+widthX)};
      subimage{index}= imresize(subimage{index},9);
      level = graythresh(subimage{index});
      img_binarized_final = imbinarize(subimage{index},level);
      img_binarized_final = ~img_binarized_final;
      %img_binarized_final = medfilt2(img_binarized_final);
      imshow(img_binarized_final);
      end
end
%% Scope For Improvement
% # Inbuilt matlab OCR(Optical Character Recognition) can be used here to do 
% character recognition. OCR does pattern matching and therefore has terrible 
% accuracy. A deep learning approach will give almost perfect results in the recognition 
% of the digits and characters in the numberplate images i am able to extract. 
% The main aim of my project was the isolation of the number plate and not the 
% character recognition inside the number plate.
% # The algorithm can be made more robust through more filtering or by devising 
% a better algorithm itself.