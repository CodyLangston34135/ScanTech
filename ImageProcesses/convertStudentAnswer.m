%% convertStudentAnswer.m
% This module converts back and forth between numerical indexing and
% alphabetical indexing for student answers. Useful for tables and UI

function [studentAnswer] = convertStudentAnswer(studentAnswer,conversionType)

    switch conversionType
        case 'num2str'
            for i = 1:size(studentAnswer,2)
                % Store current answers
                storeLetter = [];
                currentAnswer = studentAnswer{i};

                % Loop through multiple answer questions
                for j = 1:size(currentAnswer,2)

                    % Assign letter to value
                    switch currentAnswer(j)
                        case 0
                            currentLetter = 'NA';
                        case 1
                            currentLetter = 'A';
                        case 2
                            currentLetter = 'B';
                        case 3
                            currentLetter = 'C';
                        case 4
                            currentLetter = 'D';
                        case 5
                            currentLetter = 'E';
                    end

                    % Store letters
                    if j==1
                        storeLetter = currentLetter;
                    else
                        % Needs a ', '
                        storeLetter = [storeLetter, ', ', currentLetter];
                    end
                end

                % Store letter answers
                studentAnswer{i} = storeLetter;
            end
        case 'str2num'
            for i = 1:size(studentAnswer,2)
                % Store current answers
                storeLetter = [];
                currentAnswer = studentAnswer{i};

                % Loop through multiple answer questions
                for j = 1:size(currentAnswer,2)

                    % Assign letter to value
                    switch currentAnswer(j)
                        case 'NA'
                            currentNumber = 0;
                        case 'A'
                            currentNumber = 1;
                        case 'B'
                            currentNumber = 2;
                        case 'C'
                            currentNumber = 3;
                        case 'D'
                            currentNumber = 4;
                        case 'E'
                            currentNumber = 5;
                    end
                end

                % Store letter answers
                studentAnswer{i} = currentNumber;
            end
    end
end