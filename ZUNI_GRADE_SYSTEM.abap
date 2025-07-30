REPORT zunigradesystem.

INCLUDE <icon>.
INCLUDE zuni_grade_system_data.
INCLUDE zuni_grade_system_class.
INCLUDE zuni_grade_system_modules.
INCLUDE zuni_grade_system_forms.

START-OF-SELECTION.
  PERFORM initialize_data.
  sy-title = 'UNI GRADE SYSTEM'. " sets title
  CALL SCREEN 0001. " opens screen called 0001

AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'BACK'. " hits back button
      LEAVE LIST-PROCESSING. " exit from list display
      LEAVE TO SCREEN 0001.

    WHEN 'EXIT'. " hits exit button
      LEAVE PROGRAM.
  ENDCASE.
