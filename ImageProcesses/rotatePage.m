function [pageColor] = rotatePage(pageColor,oriImage)

    % Store size of page and location of orientation line
    [h w nC] = size(pageColor);
    [hTemp wTemp] = find(oriImage);
    maskInd = [hTemp wTemp];

    % Find index of farthest away points 
    D = pdist2(maskInd,maskInd);
    [D,hInd] = max(D); 
    [Dist,wLoc] = max(D); 
    hLoc = hInd(wLoc);
    
    % Store points
    point1 = [maskInd(hLoc,2),maskInd(wLoc,2)];
    point2 = [maskInd(hLoc,1),maskInd(wLoc,1)];

    % Calculate page orientation based on points
    ori = atan((point2(2)-point2(1))/(point1(2)-point1(1)));
    ori = ori*180/pi;
    if point2(1)>point2(2)
        ori = ori-90;
    elseif point2(1)<point2(2)
        ori = ori+90;
    end

    % Rotate original image and find translational offest
    oriImage = imrotate(oriImage,ori);
    s = regionprops(oriImage,'Centroid');
    offset = s(1).Centroid;

    % Rotate color image and offset it based on location of line
    pageColor = imrotate(pageColor,ori);
    [h w nC] = size(pageColor);
    if offset(1)>w/2
        pageColor = imtranslate(pageColor,[w-offset(1) 0]);
    else
        pageColor = imtranslate(pageColor,[-offset(1) 0]);
    end
end