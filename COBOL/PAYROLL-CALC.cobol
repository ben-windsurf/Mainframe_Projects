       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAYROLL-CALC.
       AUTHOR. ASHLEY CHANCE.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT EMP-FILE ASSIGN TO "EMPLOYEES.IN"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT PAYROLL-FILE ASSIGN TO "PAYROLL.OUT"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD EMP-FILE.
       01 EMP-RECORD.
          05 EMP-ID     PIC X(10).
          05 EMP-NAME   PIC X(30).
          05 EMP-SALARY PIC 9(6).

       FD PAYROLL-FILE.
       01 PAYROLL-RECORD PIC X(80).

       WORKING-STORAGE SECTION.
       01 WS-MONTHLY-PAY     PIC 9(4).99.
       01 WS-PAYROLL-LINE    PIC X(80).
       01 WS-EOF             PIC X VALUE "N".

       PROCEDURE DIVISION.
           OPEN INPUT EMP-FILE
                OUTPUT PAYROLL-FILE
           PERFORM UNTIL WS-EOF = "Y"
               READ EMP-FILE INTO EMP-RECORD
                  AT END
                      MOVE "Y" TO WS-EOF
                  NOT AT END
                      COMPUTE WS-MONTHLY-PAY = EMP-SALARY / 12
                      STRING EMP-ID SPACE EMP-NAME SPACE EMP-SALARY 
                          SPACE WS-MONTHLY-PAY DELIMITED BY SIZE 
                          INTO WS-PAYROLL-LINE
                      WRITE PAYROLL-RECORD FROM WS-PAYROLL-LINE
               END-READ
           END-PERFORM
           CLOSE EMP-FILE PAYROLL-FILE
           DISPLAY "Payroll calculation complete!"
           STOP RUN.
