REPORT zunigradesystem.

INCLUDE <icon>.
INCLUDE zuni_grade_system_data.
INCLUDE zuni_grade_system_class.
INCLUDE zuni_grade_system_modules.
INCLUDE zuni_grade_system_forms.

START-OF-SELECTION.
  PERFORM initialize_data.
  sy-title = 'UNI GRADE SYSTEM'.
  CALL SCREEN 0001.

AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'BACK'.
      LEAVE LIST-PROCESSING.
      LEAVE TO SCREEN 0001.

    WHEN 'EXIT'.
      LEAVE PROGRAM.
  ENDCASE.
