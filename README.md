Matlab app that reads student number, test version, and test answers bubbled in "Multiple Choice Answer Sheet.pdf"

This app uses 2 a CNN and image processing based scanning method in parallel to increase the redundancy of reading answers. The workflow is the following.

1. Run the file "ScanTechApp.mlapp". Make sure the Matlab path is the folder containing the file or add the ImageProcessing folder to the path.
2. Click "New Session" to create a new folder for that test or "Load Session" to select an existing folder.
3. Click "Upload Answer Sheets" and select the .pdf containing the bubbled answer sheets for that exam.
5. In the "File List Panel", the files in the "Keys" folder must be filled out.
6. Click the "Keys" dropdown and click on a file to pull up the corresponding tables. These tables have copy (Ctrl + C) and paste (Ctrl + V) commands.
7. Click on the "answerKey.mat" file and fill out the points per question (number), the test version (A1, B3, etc) and question answers (A, B, C, D, E). The diagonal can be blank
8. Click on "classlist.mat" and fill out the classlist with the student name and student id (81#)
9. Click on the "Process Answer Sheets" button to start scanning the tests. This will take a few minutes.
10. Click on the "Validate Answers" button. This will show you the answers that were flagged during the redundancy check. Check if the answers shown in yellow are correct and if not, change the students answers on the left. 
The "Validation Panel" on the bottom left is used to save this information and move through tests.
11. Individual tests can be investigated by clicking on the .pdf of that student in the "ScoreReports" folder. The student's answers can be edited on the "studentOutput.mat" in the "Output" folder. 
12. Click on "Generate Answer Statistics" to fill out "answerStatistics.mat", "validClasslist.mat", and "invalidClasslist.mat" in the "Output" folder.
13. The "invalidClasslist.mat" will contain the scores of students which bubbled in their student id numbers incorrectly. You will have to find their test based on the page number, read their name, and manually input their score in the "validClasslist.mat" file.
14. The "validClasslist.mat" and "answerStatitsics.mat" are tables showing the results for each student/exam. These results can be copied (Ctrl + C) and pasted (Ctrl + V) into an excel workbook.
15. "studentOutput.mat" is a table containing the results from the scans. This data can be used for postprocessing.
