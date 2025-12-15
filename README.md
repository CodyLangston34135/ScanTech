# ScanTech MATLAB App

**ScanTech** is a MATLAB application for automatically grading multiple-choice exams from scanned answer sheets. The app reads **student ID numbers**, **test versions**, and **bubbled answers** from the provided *Multiple Choice Answer Sheet.pdf*.

To improve reliability, ScanTech processes answer sheets using both a CNN-based model and traditional image-processing methods in parallel, with a redundancy check that flags uncertain answers for manual validation.

---

## Features

- Automatic reading of student IDs, test versions, and answers from PDFs
- Parallel CNN and image-processing scanning for increased accuracy
- Interactive validation of flagged responses
- Automatic scoring and statistics generation
- Export-ready tables for Excel or post-processing

---

## Requirements

- MATLAB  
- Image Processing Toolbox  
- Machine Learning and Deep Learning Toolbox

---

## Getting Started

1. Open MATLAB.
2. Ensure the current directory contains `ScanTechApp.mlapp`, **or** add the `ImageProcessing` folder to the MATLAB path.
3. Open **`ScanTechApp.mlapp`** to launch the application.

---

## Workflow

### 1. Create or Load a Session

- Click **New Session** to create a new folder for an exam, **or**
- Click **Load Session** to select an existing session folder.

---

### 2. Upload Answer Sheets

- Click **Upload Answer Sheets**.
- Select the PDF containing the bubbled answer sheets for the exam.

---

### 3. Configure Key Files

In the **File List Panel**, ensure all required files in the **Keys** folder are completed.

- Use the **Keys** dropdown to select a file.
- The associated tables will appear in the app.
- Tables support copy (`Ctrl + C`) and paste (`Ctrl + V`).

#### Required Key Files

**`answerKey.mat`**
- Points per question
- Test version (e.g., `A1`, `B3`)
- Correct answers (`A`–`E`)
- Diagonal entries may be left blank

**`classlist.mat`**
- Student names
- Student ID numbers (81# format)

---

### 4. Process Answer Sheets

- Click **Process Answer Sheets** to begin scanning.
- Processing time depends on the number of exams and may take several minutes.

---

### 5. Validate Answers

- Click **Validate Answers** to review responses flagged during the redundancy check.
- Answers highlighted in **yellow** should be verified.
- If incorrect, edit the student’s answers on the left panel.
- Use the **Validation Panel** (bottom-left) to:
  - Save validation changes
  - Navigate between exams

---

### 6. Review Individual Exams

- Individual student exams can be opened from the **ScoreReports** folder.
- Student responses may be manually edited in:
  - **`studentOutput.mat`** (located in the **Output** folder)

---

### 7. Generate Results

- Click **Generate Answer Statistics** to create:
  - `answerStatistics.mat`
  - `validClasslist.mat`
  - `invalidClasslist.mat`

#### Important Notes

- **`invalidClasslist.mat`** contains students who incorrectly bubbled their ID numbers.
- Locate the correct student using the page number and name.
- Manually enter their score into **`validClasslist.mat`**.

---

## Output Files

- **`validClasslist.mat`**  
  Final scores for students with valid IDs

- **`invalidClasslist.mat`**  
  Scores for students with invalid or unreadable IDs

- **`answerStatistics.mat`**  
  Question-level and exam-level statistics

- **`studentOutput.mat`**  
  Raw scan results for post-processing and analysis

All tables can be copied (`Ctrl + C`) and pasted (`Ctrl + V`) directly into Excel.

---

## Notes

This app is designed for semi-automated grading workflows. Manual validation is required for responses flagged during redundancy checks or when student IDs are unreadable.
