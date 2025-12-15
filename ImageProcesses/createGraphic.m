function answerSheetGraphic = createGraphic(pageColor, blank, graphicFigure, boolVerify, studentNumber, studentVersion, studentAnswer, dashLocation)

    colors = [0 0.5 0;  % Green
              1 0.5 0.1; % Orange
              1 0 0;    % Red
              0 0 1];   % Blue

    % Convert student number to string
    studentNumber = num2str(studentNumber);

    % Store locations of numbers, version, and answers
    numberLoc = dashLocation{1};
    versionLoc = dashLocation{2};
    answerLoc = dashLocation{3};

    % Plot color figure
    answerSheetGraphic = imshow(pageColor, 'Parent', graphicFigure);
    % impixelinfo
    % p = get(0, "MonitorPositions");
    % figPos = p(2,1:2) + [500 100];
    % answerSheetGraphic.Position = [figPos 1000 800];
    hold(graphicFigure,'on')

    % Plot boundaries of blank
    [bounds,~] = bwboundaries(blank);
    for i = 1:length(bounds)
       boundary = bounds{i};
       plot(boundary(:,2), boundary(:,1),'color',colors(4,:), 'LineWidth', 2, 'Parent', graphicFigure)
    end

    %% Student Number
    % Calculate locations for text
    xLocNumber = sort(numberLoc{1},'ascend');
    yLocNumber = min(numberLoc{2})-100;
    numberColor = boolVerify{1}+1;

    % Write text to figure
    for i = 1:size(studentNumber,2)-2
        text(xLocNumber(i),yLocNumber,studentNumber(i+2),'color',colors(numberColor,:),'FontSize',20,'Parent', graphicFigure);
    end

    %% Student Version
    % Calculate locations for text
    xLocVersion = versionLoc{1};
    yLocVersion = min(versionLoc{2}-100);
    versionColor = boolVerify{2}+1;

    % Write text to figure
    for i = 1:size(studentVersion,2)
        text(xLocVersion(i),yLocVersion,studentVersion(i),'color',colors(versionColor,:),'FontSize',20,'Parent', graphicFigure);
    end

    %% Student Answer
    % Calcualte locations for text
    xLocAnswer = answerLoc{1};
    yLocAnswerLeft = sort(answerLoc{2},'ascend');
    yLocAnswerRight = sort(answerLoc{3},'ascend');
    answerColor = ones(1,size(studentAnswer,2));
    answerColor(boolVerify{3}) = 2;

    % Write text to figure
    for i = 1:min([25, size(studentAnswer,2)])
        text(xLocAnswer(1)-375,yLocAnswerLeft(i),append(num2str(i),'. ',studentAnswer{i}),'color',colors(answerColor(i),:),'FontSize',20,'Parent', graphicFigure);
    end
    for i = 26:size(studentAnswer,2)
        text(xLocAnswer(2)+650,yLocAnswerRight(i-25),append(num2str(i),'. ',studentAnswer{i}),'color',colors(answerColor(i),:),'FontSize',20,'Parent', graphicFigure);
    end

    hold(graphicFigure,'off')
end