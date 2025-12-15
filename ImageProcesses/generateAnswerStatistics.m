function [answerStatistics, percentCorrect, validClasslist, invalidClasslist] = generateAnswerStatistics(studentData, classlist, answerKey)

    % Load answer key data and remove blanks
    checkNumbers = classlist(:,2);
    checkNumbers(cellfun(@isempty, checkNumbers)) = [];
    % checkNumbers = cellfun(@(x) x{1}, checkNumbers, 'UniformOutput', false);
    checkVersions = answerKey(1,2:end);
    checkVersions(cellfun(@isempty, checkVersions)) = [];
    numVersions = size(checkVersions,2);
    perQuestion = answerKey(2:end,1);
    perQuestion(cellfun(@isempty, perQuestion)) = [];
    perQuestion = cellfun(@str2num, perQuestion);
    checkAnswers = answerKey(2:end,2:end);
    checkAnswers(all(cellfun(@isempty, checkAnswers), 2), :) = [];
    checkAnswers(:, all(cellfun(@isempty, checkAnswers), 1)) = [];
    numQuestions = size(checkAnswers,1);
    ansStr = {'NA', 'A', 'B', 'C', 'D', 'E'};
    numAnswers = size(ansStr,2);

    % Load student data
    studentNumbers = studentData(1,:);
    studentVersions = studentData(2,:);
    studentAnswers = studentData(3:end,:);
    numStudents = size(studentAnswers,2);

    % Initialize output data
    validClasslist = classlist;
    validClasslist(:,3) = {0};
    indInvalid = 1;
    invalidClasslist = cell(0,4);
    answerStatistics = zeros(numAnswers, numQuestions, numVersions);
    percentCorrect = zeros(numVersions, numQuestions);
    for i = 1:numStudents
        % Check Version
        stuVer = find(strcmp(checkVersions, studentVersions{i}));
        if isempty(stuVer)
            invalidClasslist(indInvalid,:) = [{strcat('Page ',num2str(i))}, studentNumbers(i), studentVersions(i), {0}];
            indInvalid = indInvalid + 1;
            break;
        end

        % Check Answers
        verAns = checkAnswers(:,stuVer);
        stuAns = studentAnswers(:,i);
        stuCorrect = strcmp(stuAns, verAns);
        stuPercent = sum(perQuestion(stuCorrect));

        % Check student number
        stuNum = find(strcmp(checkNumbers, num2str(studentNumbers{i})),1);
        if isempty(stuNum)
            invalidClasslist(indInvalid,:) = [{strcat('Page ',num2str(i))}, studentNumbers(i), studentVersions(i), {stuPercent}];
            indInvalid = indInvalid + 1;
            break;
        end

        % Store to classlist
        validClasslist{stuNum,3} = stuPercent;

        % Store student's answers to statistics
        [ansStrMap, stuStrMap] = ndgrid(ansStr, stuAns);
        answerMap = strcmp(ansStrMap, stuStrMap);
        answerMap = double(answerMap);
        answerStatistics(:,:,stuVer) = answerStatistics(:,:,stuVer) + answerMap;
    end

    for i = 1:numVersions
        [ansStrMap, keyStrMap] = ndgrid(ansStr, checkAnswers(:,i));
        correctAnsMap = double(strcmp(ansStrMap, keyStrMap));
        numCorrect = correctAnsMap.*answerStatistics(:,:,i);
        numCorrect = sum(numCorrect,1);

        totalAnswered = sum(answerStatistics(:,:,i),1);
        percentCorrect(i,:) = numCorrect./totalAnswered;
    end

    answerStatistics = num2cell(answerStatistics);
    percentCorrect = num2cell(percentCorrect);
end