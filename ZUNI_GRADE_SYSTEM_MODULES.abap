MODULE status_0001 OUTPUT. " sets GUI status and title for main screen
  SET PF-STATUS '0001'.
  SET TITLEBAR 'SALV VIEW'.
ENDMODULE.

MODULE user_command_0001 INPUT. " handles user actions on main screen
  CASE sy-ucomm. " stores the function code of the last user action
    WHEN 'ADD'.
      IF p_name IS NOT INITIAL AND p_score >= 0 AND p_score <= 100. " checks if name parameter's value valid
        PERFORM process_student_data.
        PERFORM handle_failed_students.
        PERFORM calculate_next_student_id.
        PERFORM display_added_student_details.
        LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0001. " outputs texts then returns to screen
        CLEAR: p_name, p_lname, p_bdate, p_score, p_mail, p_bhv, gv_mrad, gv_frad.
      ELSE.
        MESSAGE 'FILL REQUIRED FIELDS' TYPE 'E'.
      ENDIF.

    WHEN 'UPD'.
      IF p_uid IS NOT INITIAL. " checks if update by id parameter's value is valid
        PERFORM update_student_by_id.
        CLEAR: p_uid, p_name, p_lname, p_bdate, p_score, p_mail, p_bhv, gv_mrad, gv_frad.
      ELSE.
        MESSAGE 'ENTER STUDENT ID' TYPE 'E'.
      ENDIF.

    WHEN 'SEARCH'.
      IF p_sid IS NOT INITIAL. " checks if search by id parameter's value is valid
        PERFORM search_student_by_id.
        LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0001. " outputs texts than returns to screen
        CLEAR: P_uid, p_sname, p_slname.
      ELSEIF p_sname IS NOT INITIAL AND p_slname IS NOT INITIAL. " checks if search by name parameter's value valid
        PERFORM search_student_by_name.
        LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0001. " outputs texts than returns to screen
      ELSE.
        MESSAGE 'FILL REQUIRED FIELDS' TYPE 'E'.
      ENDIF.

    WHEN 'SENDMAIL'.
      IF p_mid IS NOT INITIAL. " checks if send mail by id parameter's value is valid
        PERFORM send_mail_to_student.
      ELSE. " checks if mail by id parameter's is not valid or initial
        PERFORM send_mail_to_students.
      ENDIF.
      CLEAR: p_mid.

    WHEN 'FILTER'.
      IF p_score1 IS NOT INITIAL AND p_score2 IS NOT INITIAL.
        PERFORM list_students_by_score.
        LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0001. " outputs texts than returns to screen
      ELSE.
        MESSAGE 'ENTER TOP AND BOTTOM SCORES' TYPE 'E'.
      ENDIF.
      CLEAR: p_score1, p_score2.

    WHEN 'DEL'.
      PERFORM clear_all_data_with_popup. " calls the popup function to clear whole database

    WHEN 'STATS'.
      PERFORM display_statistics.
      LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0001. " outputs texts than returns to screen

    WHEN 'SSTUDENTS'.
      PERFORM display_top_student.
      LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0001. " outputs texts than returns to screen

    WHEN 'FSTUDENTS'.
      PERFORM display_failed_students.
      LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0001. " outputs texts than returns to screen

    WHEN 'SALV'.
      PERFORM set_cell_color.
      PERFORM create_student_salv.

    WHEN 'OOALV'.
      PERFORM create_student_ooalv.
      CALL SCREEN 0002.

    WHEN 'EXIT'.
      IF go_ooalv_students IS BOUND.
        CALL METHOD go_ooalv_students->free.
        CLEAR go_ooalv_students.
        " clears ALV objects
      ENDIF.
      IF go_cont IS BOUND.
        CALL METHOD go_cont->free.
        CLEAR go_cont.
      ENDIF.
      LEAVE PROGRAM.

  ENDCASE.
ENDMODULE.

MODULE status_0002 OUTPUT. " sets GUI status and title for ALV screen
  SET PF-STATUS '0002'.
  SET TITLEBAR 'OO ALV VIEW'.
ENDMODULE.

MODULE user_command_0002 INPUT. " handles user actions on ALV screen
  CASE sy-ucomm.
    WHEN 'SAVE'.
      PERFORM save_changes_from_bhv.
    WHEN 'BACK'.
      IF go_ooalv_students IS BOUND.
        CALL METHOD go_ooalv_students->free.
        CLEAR go_ooalv_students.
        " clears ALV objects
      ENDIF.
      IF go_cont IS BOUND.
        CALL METHOD go_cont->free.
        CLEAR go_cont.
      ENDIF.
      LEAVE TO SCREEN 0001.

    WHEN 'EXIT'.
      IF go_ooalv_students IS BOUND.
        CALL METHOD go_ooalv_students->free.
        CLEAR go_ooalv_students.
        " clears ALV objects
      ENDIF.
      IF go_cont IS BOUND.
        CALL METHOD go_cont->free.
        CLEAR go_cont.
      ENDIF.
      LEAVE PROGRAM.

  ENDCASE.
ENDMODULE.
