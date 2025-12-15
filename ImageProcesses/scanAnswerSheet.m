%% scanAnswerSheets.m
% Cody Langston
% This module focuses on scanning .png files for student bubbles and
% assigning values to them. TODO: preallocate memory for indexes in
% process... functions

function [studentNumberSpatial, studentNumberNetwork, studentVersion, studentAnswerSpatial, studentAnswerNetwork, dashLoc, pageColor, blank]...
          = scanAnswerSheet(app, filename, answerNetwork, numberNetwork, numQuestions)

    %% Read filename
    % Read file and resize it so calibration works
    pageColor = imread(filename);
    pageColor = imresize(pageColor,[3299 2550]);
    
    % Normalize orientation incase page gets rotated during scanning
    pageColor = normalizeOrientation(pageColor);
    
    % Swap from rgb to value map
    pageVal = rgb2hsv(pageColor);
    pageVal = pageVal(:,:,3);
    [h w] = size(pageVal);

    %% Process Student Marks
    [studentNumberSpatial, studentNumberNetwork, numberLoc, blank] = processStudentNumber(pageVal, numberNetwork);

    [studentVersion, versionLoc, blank] = processStudentVersion(pageVal, blank); 

    [studentAnswerSpatial, studentAnswerNetwork, answerLoc, blank] = processStudentAnswers(pageVal, blank, numQuestions, answerNetwork);

    % Store location of dashes for writing text later on
    dashLoc = {numberLoc, versionLoc, answerLoc};
end

%% normalizeOrientation
% Sometimes the page gets rotated in the printer and needs to be rotated
% back to vertical. This function looks for the edges of the paper and if
% detected, rotates the page so that that edge stands vertically.

function pageColor = normalizeOrientation(pageColor)

    % Threshold HSV map
    pageOri = rgb2hsv(pageColor);
    pageOri = pageOri(:,:,3);
    pageOri = pageOri<=0.95;
    pageOri = imfill(pageOri,"holes");
    
    [pageLabel, points] = bwlabel(pageOri);
    s = regionprops(pageLabel,'BoundingBox');
    
    % Find longest blob and label it as orientation line
    for i = 1:points
        blobDim(i,:) = [s(i).BoundingBox(3) s(i).BoundingBox(4)];
    end
    [~,ind] = max(blobDim(:,2));
    
    % Rotate image so orientation line is vertical and on edge of image
    if blobDim(ind,2)>=500
        oriLine = pageLabel==ind;
        [pageColor] = rotatePage(pageColor,oriLine);
    end
end

%% Rotate Page
% Rotates the page by oriImage radians.
% Used to normalize the orientation of the pages
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

%% processStudentNumber
% This function takes in a brightness map of the page and outputs the
% bubbled in student number. The spatial classification detects the dashes 
% and student marks, then compares their location with eachother. The
% network classification fits a grid onto the student number section, crops
% individual answers, and uses a CNN to label them as bubbled or unbubbled

function [indexNumSpatial, indexNumNetwork, textLoc, blank] = processStudentNumber(pageVal,net)

    % Scan for student number dashes
    thresh = 0.8;
    reqBoundsDash = [250 750; 1410 1550];
    reqCent = [1410 1550];
    reqPixel = 10;
    maxHeight = 15;
    strelDiam = 2;
    [numDash,blank] = scanArea(pageVal,thresh,reqBoundsDash,reqPixel,'noiseReduction',strelDiam,'requiredCentroid',reqCent,'maxHeight',maxHeight);
    
    if isempty(numDash)
        % Don't process if the scanned area is blank
        indexNumSpatial = zeros(10,7);
        indexNumNetwork = zeros(10,7);
        dashCent = [];
        textLoc = cell(1,2);
    else
        %% Index Student Numbers Spatially
        % Scan for student numbers
        thresh = 0.95;
        reqBoundsBlob = [250 750; 1 1500];
        reqPixel = 10;
        reqSize = [90 0];
        [numBlob,blank] = scanArea(pageVal,thresh,reqBoundsBlob,reqPixel,'requiredSize',reqSize,'addBlank',blank);
        
        % Compare numbers to dashes
        numBins = [510 660 800 930 1080 1230 1350];
        centOffset = [reqBoundsBlob(2,1)-1,reqBoundsBlob(1,1)-reqBoundsDash(1,1)];
        [indexNumSpatial] = indexClosest(numDash,numBlob,numBins,centOffset);
        indexNumSpatial = logical(indexNumSpatial);
    
        %% Index Student Numbers with Network
        % Find the dash centroids to make an initial guess for optimization
        dashCent = vertcat(numDash.Centroid);
        dashCent = [dashCent(:,1)+reqBoundsDash(2,1), dashCent(:,2)+reqBoundsDash(1,1)];
        [~, indSort] = sort(dashCent(:,2),"ascend");
        dashCent = dashCent(indSort,:);
    
        % Crop and threshold values
        pageCropNum = floor([dashCent(1,2)-50, dashCent(1,2)+400, mean(dashCent(:,1))-1050, mean(dashCent(:,1))-50]);
        numCrop = pageVal(pageCropNum(1):pageCropNum(2), pageCropNum(3):pageCropNum(4));
        numCrop = numCrop<=0.25;
        [row, col] = find(numCrop);
        
        % Set parameters for line fitting
        % initialGuessHorLeft = [0 dashCent(1,2)-pageCropNum(1) mean(dashCent(2:end,2)-dashCent(1:end-1,2))];
        initialGuessHorLeft = [0 dashCent(1,2)-pageCropNum(1) 38];
        nHorNum = 10; 
        points = [row, col];
        % initialGuessVert = [0 70 140];
        nVertNum = 7; 
        pointsVert = [col, row];
        
        % Fit a grid to the number section to find centers of all answers
        guessParameters = [50 80 20;
                           100 140 35];
        [optCoeffHorNum, optCoeffVertNum] = fitEquidistantGrid(points,nHorNum,nVertNum);
    
        xStore = zeros(1,nVertNum);
        n = [70 20];
        for j = 1:nVertNum
            for i = 1:nHorNum
                xCoord = floor(optCoeffVertNum(1)+optCoeffVertNum(2)*(j-1)+pageCropNum(3));
                yCoord = floor(optCoeffHorNum(1)+optCoeffHorNum(2)*(i-1)+pageCropNum(1));
                currentNum = pageVal(yCoord-n(2):yCoord+n(2),xCoord-n(1):xCoord+n(1),:)*255;
    
                % Use CNN to classify each bubble
                classification = classify(net,currentNum);
                indexNumNetwork(i,j) = classification == 'Bubble';
            end

            xStore(j) = xCoord;
        end

        textLoc = {xStore, floor(optCoeffHorNum(1)+optCoeffHorNum(2)*([1:nHorNum]-1)+pageCropNum(1))};
    end
end

%% processStudentVersion
% Finds student version spatially by comparing marks to dashes. This script
% is sanity checked by checking which answer key version the student got
% the highest grade on so it does not have to be as robust as numbers or
% answers.

function [indexVer, textLoc, blank] = processStudentVersion(pageVal, blank)
    % Scan for test version dashes
    thresh = 0.8;
    reqBoundsDash = [250 840; 2000 2300];
    reqCent = [2125 2275];
    reqPixel = 10;
    maxHeight = 15;
    strelDiam = 2;
    [verDash,blank] = scanArea(pageVal,thresh,reqBoundsDash,reqPixel,'noiseReduction',strelDiam,'requiredCentroid',reqCent,'maxHeight',maxHeight,'addBlank',blank);
    
    if isempty(verDash)
        % Dont process if scanned area is blank
        indexVer = zeros(5,2);
        dashCent = [];
        textLoc = cell(1,2);
    else
        % Scan for test section bubbles
        thresh = 0.95;
        reqBoundsBlob = [250 840; 1850 2150];
        reqPixel = 120;
        reqSize = [50 0];
        [verBlob,blank] = scanArea(pageVal,thresh,reqBoundsBlob,reqPixel,'requiredSize',reqSize,'addBlank',blank);
        
        % Compare bubbles to dashes
        verBins = [1950 2075];
        centOffset = [reqBoundsBlob(2,1)-1,reqBoundsBlob(1,1)-reqBoundsDash(1,1)];
        [indexVer] = indexClosest(verDash,verBlob,verBins,centOffset);
        indexVer = logical(indexVer);

        % Find the dash centroids to make an initial guess for optimization
        dashCent = vertcat(verDash.Centroid);
        dashCent = [dashCent(:,1)+reqBoundsDash(2,1), dashCent(:,2)+reqBoundsDash(1,1)];
        [~, indSort] = sort(dashCent(:,2),"ascend");
        dashCent = dashCent(indSort,:);

        % Store location for graphic creation
        textLoc = {verBins, dashCent(:,2)};
    end
end

%% processStudentAnswers
% This function takes in a brightness map of the page and outputs the
% bubbled in student answers. The spatial classification detects the dashes 
% and student marks, then compares their location with eachother. The
% network classification fits a grid onto the student answer section, crops
% individual answers, and uses a CNN to label them as bubbled or unbubbled

function [indexAnsSpatial, indexAnsNetwork, textLoc, blank] = processStudentAnswers(pageVal, blank, numQuestions, net)
    
    % Initialize scanend answers
    indexAnsSpatial = zeros(numQuestions,6);
    indexAnsNetwork = zeros(numQuestions,5);

    % Scan for answer dashes
    thresh = 0.8;
    reqBoundsDash = [1000 3200; 1200 1330];
    reqCent = [1210 1310];
    reqPixel = 40;
    strelDiam = 2;
    [ansDash,blank] = scanArea(pageVal,thresh,reqBoundsDash,reqPixel,'noiseReduction',strelDiam,'requiredCentroid',reqCent,'addBlank',blank);
    
    if isempty(ansDash)
        % Dont process if scanned area is blank
        dashCent = [];
        textLoc = {};
    else
        %% Index Student Answers Sptially
        % Scan for left side answers
        thresh = 0.95;
        reqBoundsBlob = [1000 3200; 300 1200];
        reqPixel = 120;
        reqSize = [50 0];
        reqArea = 0.6;
        [ansBlobLeft,blank] = scanArea(pageVal,thresh,reqBoundsBlob,reqPixel,'requiredArea',reqArea,'requiredSize',reqSize,'addBlank',blank);
        
        % Compare left side bubbles to dashes and assign value
        ansBinsLeft = [388 540 683 835 975 1115];
        centOffset = [reqBoundsBlob(2,1)-1,reqBoundsBlob(1,1)-reqBoundsDash(1,1)];
        [indexAnsLeft] = indexClosest(ansDash,ansBlobLeft,ansBinsLeft,centOffset);
    
        if numQuestions<=25
            % Dont process right side answers
            indexAnsLeft = indexAnsLeft(1:numQuestions,:);
            numScanSpatial = min([numQuestions,size(indexAnsLeft,1)]);
            indexAnsSpatial(1:numScanSpatial,:) = indexAnsLeft(1:numScanSpatial,:);
        else
            % Scan for right side answers
            thresh = 0.95;
            reqBoundsBlob = [1000 3200; 1260 2400];
            reqPixel = 120;
            reqSize = [50 0];
            reqArea = 0.6;
            [ansBlobRight,blank] = scanArea(pageVal,thresh,reqBoundsBlob,reqPixel,'requiredArea',reqArea,'requiredSize',reqSize,'addBlank',blank);
            
            % Compare right side bubbles to dashes
            ansBinsRight = [1400 1535 1690 1830 1960 2110];
            centOffset = [reqBoundsBlob(2,1)-1,reqBoundsBlob(1,1)-reqBoundsDash(1,1)];
            [indexAnsRight] = indexClosest(ansDash,ansBlobRight,ansBinsRight,centOffset);
            indexAnsRight = indexAnsRight(1:numQuestions-25,:);
            
            % Store answers into 1 matrix
            numScanSpatial = min([numQuestions-25,size(indexAnsRight,1)]);
            indexAnsSpatial(1:size(indexAnsLeft,1),:) = indexAnsLeft;
            indexAnsSpatial(26:numScanSpatial+25,:) = indexAnsRight(1:numScanSpatial,:);
        end
    
        % Cut off No Answer category and convert to logical
        indexAnsSpatial = indexAnsSpatial(:,2:end);
        indexAnsSpatial = logical(indexAnsSpatial);
    
        %% Index Student Answers with Network
        % Find the spacing between the dashes to get a good first estimate
        dashCent = vertcat(ansDash.Centroid);
        dashCent = [dashCent(:,1)+reqBoundsDash(2,1), dashCent(:,2)+reqBoundsDash(1,1)];
        [~, indSort] = sort(dashCent(:,2),"ascend");
        dashCent = dashCent(indSort,:);
    
        % Crop and threshold values
        pageCropAnsLeft = floor([dashCent(1,2)-50, dashCent(1,2)+1950, mean(dashCent(:,1))-800, mean(dashCent(:,1))-50]);
        ansCropLeft = pageVal(pageCropAnsLeft(1):pageCropAnsLeft(2), pageCropAnsLeft(3):pageCropAnsLeft(4));
        ansCropLeft = ansCropLeft<=0.25;
        [row, col] = find(ansCropLeft);
        
        % Set parameters for line fitting
        initialGuessHorLeft = [0 dashCent(1,2)-pageCropAnsLeft(1) mean(dashCent(2:end,2)-dashCent(1:end-1,2))];
        nHorAnsLeft = 25; 
        pointsHor = [row, col];
        initialGuessVertLeft = [0 100 150];
        nVertAnsLeft = 5; 
        pointsVert = [col, row];
        
        % Fit a grid to the answer section to find centers of all answers
        optCoeffHorAnsLeft = fitEquidistant(initialGuessHorLeft,pointsHor,nHorAnsLeft);
        optCoeffVertAnsLeft = fitEquidistant(initialGuessVertLeft,pointsVert,nVertAnsLeft);

        % [optCoeffHorAnsLeftTest, optCoeffVertAnsLeftTest] = fitEquidistantGrid(pointsHor,nHorAnsLeft,nVertAnsLeft);

        yStoreLeft = zeros(1,min(numQuestions,nHorAnsLeft));
        n = [40 40];
        for i = 1:min(numQuestions,nHorAnsLeft)
            for j = 1:nVertAnsLeft
                % Crop pageVal to only show student mark centered on grid
                xCoord = floor(optCoeffVertAnsLeft(2)+optCoeffVertAnsLeft(3)*(j-1)+pageCropAnsLeft(3));
                yCoord = floor(optCoeffHorAnsLeft(2)+optCoeffHorAnsLeft(3)*(i-1)+pageCropAnsLeft(1));
                currentAns = pageVal(yCoord-n(2):yCoord+n(2),xCoord-n(1):xCoord+n(1),:)*255;
    
                % Use CNN to classify each bubble
                classification = classify(net,currentAns);
                indexAnsNetworkLeft(i,j) = classification == 'Bubble';
            end

            % Store location for graphic creation
            yStoreLeft(i) = yCoord;
        end
        xStore(1) = floor(optCoeffVertAnsLeft(2)+pageCropAnsLeft(3));
    
        if numQuestions<=25
            % Dont process right side for answers
            numScanNetwork = min([numQuestions,size(indexAnsNetworkLeft,1)]);
            indexAnsNetwork(1:numScanNetwork,:) = indexAnsNetworkLeft(1:numScanSpatial,:);
            yStoreRight = [];
        else
            % Process right section
    
            % Crop and threshold values
            pageCropAnsRight = floor([dashCent(1,2)-50, dashCent(1,2)+1950, mean(dashCent(:,1))+200, mean(dashCent(:,1))+950]);
            ansCropRight = pageVal(pageCropAnsRight(1):pageCropAnsRight(2), pageCropAnsRight(3):pageCropAnsRight(4));
            ansCropRight = ansCropRight<=0.25;
            [row, col] = find(ansCropRight);
            
            % Fit equidistant lines horizontally
            initialGuessHorRight = [0 dashCent(1,2)-pageCropAnsRight(1) mean(dashCent(2:end,2)-dashCent(1:end-1,2))];
            nHorAnsRight = 25; 
            pointsHor = [row, col];
            initialGuessRight = [0 100 150];
            nVertAnsRight = 5; 
            pointsVert = [col, row];
            
            % Fit a grid to the answer section to find centers of all answers
            optCoeffHorAnsRight = fitEquidistant(initialGuessHorRight,pointsHor,nHorAnsRight);
            optCoeffVertAnsRight = fitEquidistant(initialGuessRight,pointsVert,nVertAnsRight);
    
            yStoreRight = zeros(numQuestions-25);
            n = [40 40];
            for i = 1:min(numQuestions-25,25)
                for j = 1:nVertAnsRight
                    xCoord = floor(optCoeffVertAnsRight(2)+optCoeffVertAnsRight(3)*(j-1)+pageCropAnsRight(3));
                    yCoord = floor(optCoeffHorAnsRight(2)+optCoeffHorAnsRight(3)*(i-1)+pageCropAnsRight(1));
                    currentAns = pageVal(yCoord-n(2):yCoord+n(2),xCoord-n(1):xCoord+n(1),:)*255;
    
                    classification = classify(net,currentAns);
                    indexAnsNetworkRight(i,j) = classification=='Bubble';
                end

                % Store text for graphic creation
                yStoreRight(i) = yCoord;
            end
            xStore(2) = floor(optCoeffVertAnsRight(2)+pageCropAnsRight(3));

            % Store student answers into 1 matrix
            numScanNetwork = min([numQuestions-25,size(indexAnsNetworkRight,1)]);
            indexAnsNetwork(1:size(indexAnsNetworkLeft,1),:) = indexAnsNetworkLeft;
            indexAnsNetwork(26:numScanNetwork+25,:) = indexAnsNetworkRight(1:numScanNetwork,:);

            %% Plot optimization lines
            % figure(1)
            % subplot(1,3,2)
            % imshow(ansCropLeft)
            % impixelinfo
            % 
            % xHorAnsLeft = [1 size(ansCropLeft,2)];
            % for i = 0:nHorAnsLeft-1
            %     yHorAns = optCoeffHorAnsLeft(1).*xHorAnsLeft+optCoeffHorAnsLeft(2)+optCoeffHorAnsLeft(3)*i;
            %     line(xHorAnsLeft,yHorAns)
            % end
            % 
            % yVertAnsLeft = [1 size(ansCropLeft,1)];
            % for i = 0:nVertAnsLeft-1
            %     xVertAns = optCoeffVertAnsLeft(1).*yVertAnsLeft+optCoeffVertAnsLeft(2)+optCoeffVertAnsLeft(3)*i;
            %     line(xVertAns,yVertAnsLeft)
            % end
            % 
            % subplot(1,3,3)
            % imshow(ansCropRight)
            % impixelinfo
            % 
            % xHorAnsRight = [1 size(ansCropRight,2)];
            % for i = 0:nHorAnsRight-1
            %     yHorAns = optCoeffHorAnsRight(1).*xHorAnsRight+optCoeffHorAnsRight(2)+optCoeffHorAnsRight(3)*i;
            %     line(xHorAnsRight,yHorAns)
            % end
            % 
            % yVertAnsRight = [1 size(ansCropRight,1)];
            % for i = 0:nVertAnsRight-1
            %     xVertAns = optCoeffVertAnsRight(1).*yVertAnsRight+optCoeffVertAnsRight(2)+optCoeffVertAnsRight(3)*i;
            %     line(xVertAns,yVertAnsRight)
            % end

            %% Plot Optimizaition Points
            % figure(1)
            % subplot(1,3,2)
            % imshow(ansCropLeft)
            % hold on
            % impixelinfo
            % 
            % xHorAnsLeft = [1 size(ansCropLeft,2)];
            % for i = 0:nHorAnsLeft-1
            %     for j = 0:nVertAnsLeft-1
            %         x = optCoeffHorAnsLeftTest(1)+optCoeffHorAnsLeftTest(2)*i;
            %         y = optCoeffVertAnsLeftTest(1)+optCoeffVertAnsLeftTest(2)*j;
            %         plot(y,x,'*','LineWidth',15)
            %     end
            % end

            % subplot(1,3,3)
            % imshow(ansCropRight)
            % impixelinfo
            % 
            % xHorAnsRight = [1 size(ansCropRight,2)];
            % for i = 0:nHorAnsRight-1
            %     yHorAns = optCoeffHorAnsRight(1).*xHorAnsRight+optCoeffHorAnsRight(2)+optCoeffHorAnsRight(3)*i;
            %     line(xHorAnsRight,yHorAns)
            % end
            % 
            % yVertAnsRight = [1 size(ansCropRight,1)];
            % for i = 0:nVertAnsRight-1
            %     xVertAns = optCoeffVertAnsRight(1).*yVertAnsRight+optCoeffVertAnsRight(2)+optCoeffVertAnsRight(3)*i;
            %     line(xVertAns,yVertAnsRight)
            % end

        end
    
        % Store locations for graphic creation
        textLoc = {xStore, yStoreLeft, yStoreRight};
    end    
end

%% scanArea
% This function thresholds the image, connects pixels, and detects them
% based off area, centroid, size, height, etc. Used to spatially detect
% student marks.

function [s,blank] = scanArea(pageVal,thresh,bounds,reqPixel,varargin)

    %% Input Parser
    % Crop page
    [h w] = size(pageVal);
    pageVal = pageVal(bounds(1,1):bounds(1,2),bounds(2,1):bounds(2,2));

    % Check for inputs
    pOrient = inputParser();

    strelDiam = [];
    reqArea = 0;
    reqCentroid = [];
    reqSize = [];
    maxHeight = h;
    blank = zeros(h,w);

    addOptional(pOrient,'noiseReduction', strelDiam);
    addOptional(pOrient,'requiredArea', reqArea);
    addOptional(pOrient,'requiredCentroid', reqCentroid);
    addOptional(pOrient,'requiredSize', reqSize);
    addOptional(pOrient,'maxHeight', maxHeight);
    addOptional(pOrient,'addBlank', blank);

    parse(pOrient, varargin{:});
    
    strelDiam      = pOrient.Results.noiseReduction;
    reqArea        = pOrient.Results.requiredArea;
    reqCentroid    = pOrient.Results.requiredCentroid;
    reqSize        = pOrient.Results.requiredSize;
    maxHeight      = pOrient.Results.maxHeight;
    blank          = pOrient.Results.addBlank;

    %% Create Binary Map
    % HSV threshold
    pageLog = pageVal<=thresh;
    pageLog = bwareaopen(pageLog,reqPixel);
    pageLog = imfill(pageLog,"holes");
    if size(strelDiam,1)~=0
        pageLog = imclose(pageLog,strel('disk',strelDiam));
    end

    %% Scan Image for Blobs
    [pageLabel, points] = bwlabel(pageLog);
    s = regionprops(pageLabel, pageVal, 'Centroid', 'Area', 'BoundingBox','MeanIntensity');
    indStore = 1:points;

    if isempty(s)
        % Dont process if no blobs were found
    else
    
        %% Check which Blobs Meet Criteria
        % Centroid criteria
        if size(reqCentroid,1)~=0
            reqCentroid = reqCentroid - [bounds(2,1), bounds(2,1)];
            for i = 1:size(s,1)
                blobCent(i,:) = s(i).Centroid;
            end
            [indCent] = find(and(blobCent(:,1)>=reqCentroid(1),blobCent(:,1)<=reqCentroid(2)));
            s = s(indCent);
            indStore = indStore(indCent);
        end
    
        % Size criteria
        if size(reqSize,1)~=0
            for i = 1:size(s,1)
                blobDim(i,:) = [s(i).BoundingBox(3) s(i).BoundingBox(4)];
            end
            [indSize] = find(and(blobDim(:,1)>=reqSize(1),blobDim(:,2)>=reqSize(2)));
            s = s(indSize);
            indStore = indStore(indSize);
        end
    
        if size(s,1)==0
        else
            % Area criteria
            if reqArea~=0
                blobDim = [0 0];
                for i = 1:size(s,1)
                    blobArea(i,1) = s(i).Area;
                    blobDim(i,:) = [s(i).BoundingBox(3) s(i).BoundingBox(4)];
                end
                areaRatio = blobArea./(blobDim(:,1).*blobDim(:,2));
                [indArea] = find(areaRatio>=reqArea);
                s = s(indArea);
                indStore = indStore(indArea);
            end
        
            % Height criteria
            if maxHeight~=0
                blobDim = [0 0];
                for i = 1:size(s,1)
                    blobDim(i,:) = [s(i).BoundingBox(3) s(i).BoundingBox(4)];
                end
                [indHeight] = find(blobDim(:,2)<=maxHeight);
                s = s(indHeight);
                indStore = indStore(indHeight);
            end
        
            %% Add Resulting Blobs to Binary Map
            for i = 1:length(indStore)
                blankAdd = pageLabel==indStore(i);
                blank(bounds(1,1):bounds(1,2),bounds(2,1):bounds(2,2)) = blank(bounds(1,1):bounds(1,2),bounds(2,1):bounds(2,2))+blankAdd;
            end
        end
    end
end

%% indexClosest
% This function compares the location of the student marks to the location
% of the dashes and classifies them into a number or answer.

function [index] = indexClosest(dash,blob,bins,centOffset)

    % Store centroids and intensity for anchors and blobs
    for i = 1:size(dash,1)
        dashCent(i,:) = dash(i).Centroid;
    end
    [~,indSort] = sort(dashCent(:,2),'ascend');
    dashCent = dashCent(indSort,:);
    
    blobCent = [];
    for i = 1:size(blob,1)
        blobCent(i,:) = blob(i).Centroid+centOffset;
        blobVal(i) = blob(i).MeanIntensity;
    end

    index = zeros(size(dashCent,1),size(bins,2));

    for i = 1:size(blobCent,1)
        % Find closest anchor to blob in direction
        diffAnch = blobCent(i,2)-dashCent(:,2);
        [~, indDash] = min(abs(diffAnch));
    
        % Find closest bin to blob in other direction
        diffBins = blobCent(i,1)-bins;
        [~, indBins] = min(abs(diffBins));
        
        index(indDash,indBins) = 1;
    end
end

%% fitEquidistant
% This function solves the optimization problem of fitting vertical or
% horizontal lines to an image which minimize the distance between them and
% the relevant pixels. The lines have a slope x(1), initial offset x(2),
% and equal spacing between them x(3).

function [optCoeff] = fitEquidistant(initialGuess,points,numLines)

    % Set rows and columns
    row = points(:,1);
    col = points(:,2);
    
    % Objective function for slope
    % minDist = @(x) sum(min(abs(-x(1).*col'+row'-(x(2)+[0:(numLines-1)]'*x(3))),[],1),2);
    % Objective function for 0 slope
    minDist = @(x) sum(min(abs(row'-(x(2)+[0:(numLines-1)]'*x(3))),[],1),2);
    
    % Constraints to keep offset and spacing on the page
    A = [0 -1 0; 0 0 -1];
    b = [0; 0];
    
    % Optimization protocol
    options = optimoptions('fmincon','Display','off');
    optCoeff = fmincon(minDist,initialGuess,A,b,[],[],[],[],[],options);
end

function [optCoeffHor, optCoeffVert] = fitEquidistantGrid(points, numHorPoints, numVertPoints)

    initialGuess = [63 60 1 1]; % horOffset vertOffset horSpacing vertSpacing

    % Set rows and columns
    row = points(:,1);
    col = points(:,2);

    indHorPoint = [0:(numHorPoints-1)];
    indVertPoint = [0:(numVertPoints-1)];
    
    % Objective function for grid. This probably needs a rewrite to make
    % readable, basically solves min sum of norm2 of pixel distant from set
    % ammount of points with equal spacing and 0 slope
    minDist = @(x) sum(min((col'-reshape(x(3)+x(4)*indVertPoint'.*ones(1,numHorPoints),[],1)).^2+(row'-reshape(x(1)+x(2)*indHorPoint.*ones(numVertPoints,1),[],1)).^2,[],1),2);

    % Constraints to keep offset and spacing on the page
    A = [-1 0 0 0; 0 -1 0 0; 0 0 -1 0; 0 0 0 -1];
    b = [0; 0; 0; 0];
    
    % Optimization protocol
    options = optimoptions('fmincon','Display','off');
    optCoeff = fmincon(minDist,initialGuess,A,b,[],[],[],[],[],options);

    optCoeffHor = optCoeff(1:2);
    optCoeffVert = optCoeff(3:4);
end