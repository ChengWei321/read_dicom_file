close all;clear all
clc

%% File directory
srcFile= dir('*.dcm');

fp = fopen('ETA.DAT', 'wt');
fp1 = fopen('ETA_Pre.DAT', 'wt');
fp2 = fopen('dicom_information.DAT', 'wt');
fp3 = fopen('AreaChange.DAT','wt');

%% Waiting Bar
h=waitbar(0,'please wait');

%% Domain variables

x1=231;x2=381;
y1=358;y2=473;
z1=112;z2=341;

xx=x2-x1+1;
yy=y2-y1+1;
zz=z2-z1+1;

image_thresholded=zeros(yy,xx);
%% Tecplot title

fprintf(fp1, 'VARIABLES = "x","y","z","eta"\n ZONE i=   %g ,j=	%g, k= %g\n',xx,yy,zz);

%% shape variables
avgArea=0;
avgPerim=0;
inletArea=0;
outletArea=0;
miniArea=10000;
airwayVolume=0;
tempA=0;tempP=0;
MaxA=0;MaxP=0;
MinP=1000;

count=0;
zcount=0;


%% loop for reading info.
for i=z2:-1:z1
    zcount=zcount+1;
    Area=0;

    %% Header info
    filename = strcat(srcFile(i).name);
    info= dicominfo(filename);
    SL= info.SliceLocation;
    originalI= dicomread(filename);

    if i==z1||i==z2
    
    dist = info.PixelSpacing;

    z = info.SliceThickness;
    end
    
    %% extract from origianl image
    extractI=double(originalI(y1:y2, x1:x2));

    %% thresholding & sub-grid

       for b=1:yy
            for a=1:xx
            if extractI(b,a) < -450
                image_thresholded(b,a) = 0;
                
                
             elseif extractI(b,a) <= -350 && extractI(b,a) >= -450
                 image_thresholded(b,a) = ((extractI(b,a) +450)/100);
            else
                image_thresholded(b,a) = 1;
            end
%% clean inlet boundary
            if b >=1 && b<= 5 && zcount < 60
                image_thresholded(b,a) = 1;
            end
           
%% Write ETA files            
           fprintf(fp1, '%g %g %g %g \n',a,b,zcount,image_thresholded(b,a)); %for pre-view
           fprintf(fp, '%g \n',image_thresholded(b,a)); % for simulations
           
 %% Cross-Section Area  
          if image_thresholded(b,a)<=0.5
              Area=Area+(1-image_thresholded(b,a));
          end
          Area=Area*dist(1)*dist(2);
          fprintf(fp3, '%g %g\n',zcount,Area);
%%  Inlet Area
          
          if b==1 && image_thresholded(b,a)<=0.5
              inletArea=inletArea+(1-image_thresholded(b,a));
          end
          
           
          %% Outlet Area
           
          if i==z2 && image_thresholded(b,a)<=0.5
              outletArea=outletArea+(1-image_thresholded(b,a));
          end
          
          %% Airway Volume
          if image_thresholded(b,a)==0
            airwayVolume=airwayVolume+1;
          elseif image_thresholded(b,a)<=0.5
            airwayVolume=airwayVolume+(1-image_thresholded(b,a));
          end
           
end   %end of a loop
end    %end of b loop
        
 %% Find minimun cross-section
        if zcount<140&&zcount>30&&Area < miniArea
            miniArea=Area
            minA_position=zcount;
        end
      
        Area=0;           
            
 %% perform dilation
    se= strel('sphere',4);
    dilatedI= imdilate(image_thresholded,se);
    
 %% perform erodtion  
    erodeI= imerode(dilatedI,se);

 %% edge detection
    b= edge(erodeI);
    perimeter(zcount) = sum(b(:));
    perimeter(zcount) = perimeter(zcount)*dist(1);

%% Hydraulic Diameter Change
if zcount<165
    Dh(zcount)=4*Area/perimeter(zcount);
end
%% dislplay results

%figure(i)
     
        %subplot(1,3,1)
        %imshow(originalI,[])
        %title('original image')
        % 
        %subplot(1,3,2);
        %imshow(b,[])
        %title('extract image')
        %      
        %subplot(1,3,3);
        %imshow(image_thresholded,[])
        %title('threshold image')

        %subplot(1,4,3);
        %imshow(I2, [])
        %title('ETA')

        %subplot(1,1,1); imshow(dilatedI,[])
        %yitle('edge detected')
        %end

%% Waiting Bar        
    str=['Runing...',num2str(round((i-z1)/(z2-z1)*100)),'%'];
    waitbar(((i-z1)/(z2-z1)),h,str)

end  %end of i loop

%% calculations
%    cal_Re=dicomread(strcat('SE3/',srcFile(z1+minA_position-1).name));
%    Perim=sum(sum(bwperim(cal_Re)));
%    Dh=4*inletArea/Perim;
%airwayVolume=airwayVolume*dist(1)*dist(2)*z;
inletArea=inletArea*dist(2)*z;
outletArea=outletArea*dist(2)*dist(1);
miniArea=miniArea*dist(2)*z;
minAPerimeter=perimeter(minA_position);
minADh=Dh(minA_position);
% mmtom=1e-3;
% mltom3=1e-6;
% PEFR=5800 % ml/s
%inletArea=inletArea*mmtom*mmtom;
%inletVel=0.0083/inletArea;
% avgArea=avgArea/(z2-z1+1);
% avgArea=avgArea*dist(1)*dist(2);
% avgPerim=avgPerim/(z2-z1+1);
% avgPerim=avgPerim*dist(1);
%%
delete(h);

%% Write information
 fprintf(fp2, ' Grid Number = %g, %g, %g \n\n', xx, yy, zcount);
 fprintf(fp2, ' Domain Size = %g, %g, %g (mm)\n\n', xx*dist(1), yy*dist(2), (z2-z1+1)*z);
 fprintf(fp2, ' Pixel Spacing = %g %g(mm)\n\n', dist(1));
 fprintf(fp2, ' Slice Thickness = %g (mm)\n\n', z);
 fprintf(fp2, ' Inlet Area = %g (mm^2)\n\n', inletArea);
 fprintf(fp2, ' Airway Volume = %g (mm^3)\n\n', airwayVolume*z*dist(1)*dist(2));
 fprintf(fp2, ' Average Area = %g (mm^2)\n\n', avgArea);
 fprintf(fp2, ' Average Perimeter = %g (mm)\n\n', avgPerim);
 fprintf(fp2, ' Average Hydraulic Diameter = %g (mm)\n\n', 4*avgArea/avgPerim);
 fprintf(fp2, ' Maximum Hydraulic Diameter = %g (mm)\n\n', 4*MaxA/MaxP*dist(1));
 fprintf(fp2, ' Minimum Hydraulic Diameter = %g (mm)\n\n', 4*MinA/MinP*dist(1));
% 
%  
fclose(fp); 
fclose(fp1); 
fclose(fp2);
fclose(fp3); 