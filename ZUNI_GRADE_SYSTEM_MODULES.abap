MODULE status_0001 OUTPUT.
  SET PF-STATUS '0001'.
  SET TITLEBAR 'SALV VIEW'.
ENDMODULE.

MODULE user_command_0001 INPUT.
  CASE sy-ucomm.
    WHEN 'ADD'.
      IF p_name IS NOT INITIAL AND p_score >= 0 AND p_score <= 100.
        PERFORM process_student_data.
        PERFORM handle_failed_students.
        PERFORM calculate_next_student_id.
        PERFORM display_added_student_details.
        LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0001.
        CLEAR: p_name, p_lname, p_bdate, p_score, p_mail, p_bhv, gv_mrad, gv_frad.
      ELSE.
        MESSAGE 'FILL REQUIRED FIELDS' TYPE 'E'.
      ENDIF.

    WHEN 'UPD'.
      IF p_uid IS NOT INITIAL.
        PERFORM update_student_by_id.
        CLEAR: p_uid, p_name, p_lname, p_bdate, p_score, p_mail, p_bhv, gv_mrad, gv_frad.
      ELSE.
        MESSAGE 'ENTER STUDENT ID' TYPE 'E'.
      ENDIF.

    WHEN 'SEARCH'.
      IF p_id IS NOT INITIAL.
        PERFORM search_student_by_id.
        LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0001.
        CLEAR: P_id, p_sname, p_slname.
      ELSEIF p_sname IS NOT INITIAL AND p_slname IS NOT INITIAL.
        PERFORM search_student_by_name.
        LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0001.
      ELSE.
        MESSAGE 'FILL REQUIRED FIELDS' TYPE 'E'.
      ENDIF.

    WHEN 'SENDMAIL'.
      IF p_id IS NOT INITIAL.
        PERFORM send_mail_to_student.
      ELSE.
        PERFORM send_mail_to_students.
      ENDIF.
      CLEAR: p_id.

    WHEN 'FORM'.
      IF p_id IS NOT INITIAL.
        PERFORM prepare_form.
        PERFORM create_form.
        CLEAR p_id.
      ELSE.
        MESSAGE 'FILL REQUIRED FIELDS' TYPE 'E'.
      ENDIF.

    WHEN 'FILTER'.
      IF p_score1 IS NOT INITIAL AND p_score2 IS NOT INITIAL AND p_score1 => 0 AND p_score2 <= 100 AND p_score1 < p_score2.
        PERFORM list_students_by_score.
        LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0001.
      ELSE.
        MESSAGE 'ENTER VALID VALUES' TYPE 'E'.
      ENDIF.
      CLEAR: p_score1, p_score2.

    WHEN 'DEL'.
      PERFORM clear_all_data_with_popup.

    WHEN 'STATS'.
      PERFORM display_statistics.
      LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0001.

    WHEN 'SSTUDENTS'.
      PERFORM display_top_student.
      LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0001.

    WHEN 'FSTUDENTS'.
      PERFORM display_failed_students.
      LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0001.

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
      ENDIF.
      IF go_cont IS BOUND.
        CALL METHOD go_cont->free.
        CLEAR go_cont.
      ENDIF.
      LEAVE PROGRAM.

  ENDCASE.
ENDMODULE.

MODULE status_0002 OUTPUT.
  SET PF-STATUS '0002'.
  SET TITLEBAR 'OO ALV VIEW'.
ENDMODULE.

MODULE user_command_0002 INPUT.
  CASE sy-ucomm.
    WHEN 'SAVE'.
      PERFORM save_changes_from_bhv.
    WHEN 'BACK'.
      IF go_ooalv_students IS BOUND.
        CALL METHOD go_ooalv_students->free.
        CLEAR go_ooalv_students.
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
      ENDIF.
      IF go_cont IS BOUND.
        CALL METHOD go_cont->free.
        CLEAR go_cont.
      ENDIF.
      LEAVE PROGRAM.

  ENDCASE.
ENDMODULE.
