FORM initialize_data. " initializes required datas before output
  PERFORM load_student_data.
  PERFORM load_failed_student_data.
  PERFORM calculate_next_student_id.
  PERFORM update_age_of_all_students.
ENDFORM.

FORM load_student_data.
  SELECT * FROM zstudent_t
    INTO CORRESPONDING FIELDS OF TABLE @gt_student_t. " fetches suitably into table
ENDFORM.

FORM load_failed_student_data.
  SELECT * FROM zfstudent_t
    INTO CORRESPONDING FIELDS OF TABLE @gt_failed_t. " fetches suitably into table
ENDFORM.

FORM process_student_data.
  PERFORM prepare_student_record.
  PERFORM save_student_record.
ENDFORM.

FORM update_age_of_all_students. " updates ages of all students
  SELECT * FROM zstudent_t
    INTO TABLE gt_student_t.

  LOOP AT gt_student_t INTO gs_student_t.
    DATA(lv_new_age) = lcl_age_calculator=>calculate_age( gs_student_t-studentbdate ).

    IF lv_new_age NE gs_student_t-studentage.
      gs_student_t-studentage = lv_new_age.

      UPDATE zstudent_t SET studentage = lv_new_age
                        WHERE studentid = gs_student_t-studentid.
    ENDIF.

  ENDLOOP.

  COMMIT WORK.

ENDFORM.

FORM prepare_student_record.
  CLEAR gs_student_t.

  gs_student_t-studentid  = lv_next_student_id.
  gs_student_t-studentname  = p_name.
  gs_student_t-studentlname = p_lname.
  gs_student_t-studentbdate = p_bdate.
  gs_student_t-studentmail  = p_mail.
  gs_student_t-studentscore = p_score.
  gs_student_t-studentgrade = lcl_grade_converter=>convertscoretograde( p_score ).
  gs_student_t-studentage   = lcl_age_calculator=>calculate_age( p_bdate ).

  IF gv_mrad EQ 'X'. " male button is ticked
    gs_student_t-studentgen = 'M'.
  ELSEIF gv_frad EQ 'X'. " female button is ticked
    gs_student_t-studentgen = 'F'.
  ENDIF.

  IF p_bdate <= sy-datum AND p_mail CS '@' AND p_mail CS '.'.
*   current date >= birth date mail contains @ .
    APPEND gs_student_t TO gt_student_t. " adds structure into table
  ELSE.
    MESSAGE 'MAKE SURE TO ENTER VALID VALUES' TYPE 'E'.
  ENDIF.

ENDFORM.

FORM calculate_next_student_id.
  SELECT MAX( studentID ) FROM zstudent_t INTO @lv_next_student_id.

  IF sy-subrc NE 0.
    lv_next_student_id = 1.
  ELSE.
    lv_next_student_id = lv_next_student_id + 1.
  ENDIF.
ENDFORM.

FORM save_student_record.
  INSERT zstudent_t FROM @gs_student_t.

  IF sy-subrc = 0. " process was successfull
    COMMIT WORK. " commits changes into database
    MESSAGE 'STUDENT ADDED' TYPE 'S'.
  ELSE.
    MESSAGE 'ERROR ADDING STUDENT' TYPE 'E'.
  ENDIF.
ENDFORM.

FORM display_added_student_details.
  WRITE: /1  '@0V@', 'NEW STUDENT'.
  WRITE: /3 '├─ STUDENT ID:      ', gs_student_t-studentid COLOR COL_HEADING.
  WRITE: /3 '├─ NAME:            ', gs_student_t-studentname COLOR COL_NORMAL.
  WRITE: /3 '├─ LASTNAME:        ', gs_student_t-studentlname COLOR COL_NORMAL.
  WRITE: /3 '├─ BIRTH DATE:      ', gs_student_t-studentbdate COLOR COL_NORMAL.
  WRITE: /3 '├─ AGE:             ', gs_student_t-studentage COLOR COL_NORMAL.
  WRITE: /3 '├─ MAIL:            ', gs_student_t-studentmail COLOR COL_NORMAL.
  WRITE: /3 '├─ GENDER:          ', gs_student_t-studentgen COLOR COL_NORMAL.
  WRITE: /3 '├─ SCORE:           ', gs_student_t-studentscore COLOR COL_NORMAL.
  WRITE: /3 '└─ GRADE:           ', gs_student_t-studentgrade COLOR COL_NORMAL.
  WRITE: /.
ENDFORM.

FORM handle_failed_students.
  IF gs_student_t-studentgrade = 'FF'.
    PERFORM process_failed_student.
  ENDIF.
ENDFORM.

FORM process_failed_student.
  IF gs_student_t-studentscore BETWEEN 34 AND 35.
    PERFORM upgrade_student_grade. " it takes the ceiling of score between 34 and 35
    MESSAGE 'STUDENT''S GRADE UPGRADED TO DD WITH THE SCORE OF 35' TYPE 'I'.
  ELSE.
    PERFORM add_to_failed_students. " if not in between of 34 and 35
    MESSAGE 'STUDENT HAS FAILED THE CLASS AND ADDED TO FAILED LIST' TYPE 'I'.
  ENDIF.
*   if students score between 34 and 35 it sets score to 35 else it processes failed student operationss
ENDFORM.

FORM upgrade_student_grade.
  gs_student_t-studentgrade = 'DD'.
  gs_student_t-studentscore = 35.

  UPDATE zstudent_t SET studentgrade = @gs_student_t-studentgrade,
                         studentscore = @gs_student_t-studentscore
                   WHERE studentid = @gs_student_t-studentid.

  IF sy-subrc = 0.
    COMMIT WORK. " commits changes into database
  ENDIF.
ENDFORM.

FORM add_to_failed_students.
  CLEAR gs_failed_t. " clears structure
  MOVE-CORRESPONDING gs_student_t TO gs_failed_t. " moves matching areas to another structure

  INSERT zfstudent_t FROM @gs_failed_t.

  IF sy-subrc = 0.
    COMMIT WORK.
  ENDIF.
ENDFORM.

FORM update_student_by_id.
  SELECT SINGLE * FROM zstudent_t
    INTO @gs_student_t
    WHERE studentid EQ @p_uid.

  IF sy-subrc = 0.
    IF p_name IS NOT INITIAL.
      gs_student_t-studentname = p_name.
    ENDIF.

    IF p_lname IS NOT INITIAL.
      gs_student_t-studentlname = p_lname.
    ENDIF.

    IF p_bdate IS NOT INITIAL AND p_bdate < sy-datum.
*     birth date is not initial and its lower than current date
      gs_student_t-studentbdate = p_bdate.
      gs_student_t-studentage = lcl_age_calculator=>calculate_age( p_bdate ).
    ENDIF.

    IF p_score IS NOT INITIAL AND p_score >= 0 AND p_score <= 100.
*     score is not initial and between 0 100 including 0 100
      gs_student_t-studentscore = p_score.
      gs_student_t-studentgrade = lcl_grade_converter=>convertscoretograde( p_score ).
    ENDIF.

    IF p_mail IS NOT INITIAL AND p_mail CS '@' AND p_mail CS '.'.
*     mail is not initial and contains @ .
      gs_student_t-studentmail = p_mail.
    ENDIF.

    IF gv_mrad EQ 'X'. " male radio button is checked
      gs_student_t-studentgen = 'M'.
    ELSEIF gv_frad EQ 'X'. " female radio button is checked
      gs_student_t-studentgen = 'F'.
    ENDIF.

    UPDATE zstudent_t FROM gs_student_t.

    IF sy-subrc = 0.
      COMMIT WORK. " commits changes into database
      MESSAGE 'STUDENT UPDATED SUCCESSFULLY' TYPE 'S'.
    ELSE.
      ROLLBACK WORK. " reverts database changes
      MESSAGE 'ERROR UPDATING STUDENT' TYPE 'E'.
    ENDIF.
  ELSE.
    MESSAGE 'STUDENT NOT FOUND FOR UPDATE' TYPE 'E'.
  ENDIF.
ENDFORM.

FORM search_student_by_id.
  SELECT SINGLE * FROM zstudent_t
    INTO @gs_student_t
    WHERE studentid EQ @p_sid. " searched student id equals to current student id
  IF sy-subrc = 0.
    WRITE: /1  '@08@', 'SEARCHED STUDENT'.
    WRITE: /3 '├─ STUDENT ID:      ', gs_student_t-studentid.
    WRITE: /3 '├─ NAME:            ', gs_student_t-studentname.
    WRITE: /3 '├─ LASTNAME:        ', gs_student_t-studentlname.
    WRITE: /3 '├─ BIRTH DATE:      ', gs_student_t-studentbdate.
    WRITE: /3 '├─ AGE:             ', gs_student_t-studentage.
    WRITE: /3 '├─ MAIL:            ', gs_student_t-studentmail.
    WRITE: /3 '├─ GENDER:          ', gs_student_t-studentgen.
    WRITE: /3 '├─ SCORE:           ', gs_student_t-studentscore.
    WRITE: /3 '└─ GRADE:           ', gs_student_t-studentgrade.
    WRITE: /.
  ELSE.
    WRITE: /1 '@0A@', 'STUDENT NOT FOUND'.
  ENDIF.
ENDFORM.

FORM search_student_by_name.
  SELECT SINGLE * FROM zstudent_t
    INTO @gs_student_t
    WHERE studentname EQ @p_sname AND studentlname EQ @p_slname.
  IF sy-subrc = 0.
    WRITE: /1  '@08@', 'SEARCHED STUDENT'.
    WRITE: /3 '├─ STUDENT ID:      ', gs_student_t-studentid COLOR COL_HEADING.
    WRITE: /3 '├─ NAME:            ', gs_student_t-studentname COLOR COL_NORMAL.
    WRITE: /3 '├─ LASTNAME:        ', gs_student_t-studentlname COLOR COL_NORMAL.
    WRITE: /3 '├─ BIRTH DATE:      ', gs_student_t-studentbdate COLOR COL_NORMAL.
    WRITE: /3 '├─ AGE:             ', gs_student_t-studentage COLOR COL_NORMAL.
    WRITE: /3 '├─ MAIL:            ', gs_student_t-studentmail COLOR COL_NORMAL.
    WRITE: /3 '├─ GENDER:          ', gs_student_t-studentgen COLOR COL_NORMAL.
    WRITE: /3 '├─ SCORE:           ', gs_student_t-studentscore COLOR COL_NORMAL.
    WRITE: /3 '└─ GRADE:           ', gs_student_t-studentgrade COLOR COL_NORMAL.
    WRITE: /.
  ELSE.
    WRITE: /1 '@0A@', 'STUDENT NOT FOUND'.
  ENDIF.
ENDFORM.

FORM send_mail_to_student. " if student id is not initial
  SELECT SINGLE * FROM zstudent_t
      INTO @gs_student_t
      WHERE studentid EQ @p_mid.

  lv_mail_adress = gs_student_t-studentmail.

  IF gs_student_t-studentgrade NE 'FF'.
    mail_msg = 'CONGRATS YOU SUCCESSFULLY PASSED THE CLASS'.
  ELSE.
    mail_msg = 'WE ARE SORRY TO INFORM YOU THAT YOU FAILED THE CLASS'.
  ENDIF.

  CLEAR: recipients, object_hd.
  doc_chng-obj_descr = 'Grade Report'. " mail description
  object_hd-line = |HI! { gs_student_t-studentname } { gs_student_t-studentlname }|.
  APPEND object_hd. " adds to mail text
  object_hd-line = mail_msg.
  APPEND object_hd. " adds to mail text
  object_hd-line = | YOUR SCORE IS: { gs_student_t-studentscore } |.
  recipients-rec_type = 'U'.
  recipients-receiver = lv_mail_adress.
  APPEND recipients.

  CALL FUNCTION 'SO_NEW_DOCUMENT_SEND_API1' " mail sending function
    EXPORTING
      document_data      = doc_chng
      document_type      = 'RAW'
      put_in_outbox      = 'X'
      commit_work        = 'X'
    TABLES
      object_content     = object_hd
      receivers          = recipients
    EXCEPTIONS
      too_many_receivers = 1
      document_not_sent  = 2
      OTHERS             = 99.
  IF sy-subrc = 0.
    MESSAGE 'MAIL HAS BEEN SENT' TYPE 'S'.
  ELSE.
    MESSAGE 'MAIL SENDING FAILED' TYPE 'E'.
  ENDIF.
ENDFORM.

FORM send_mail_to_students. " if student id is initial
* same form with the one above but it sends bulk mail
  SELECT * FROM zstudent_t
  INTO CORRESPONDING FIELDS OF TABLE gt_student_t.

  LOOP AT gt_student_t INTO gs_student_t.
    lv_mail_adress = gs_student_t-studentmail.

    IF gs_student_t-studentgrade NE 'FF'.
      mail_msg = 'CONGRATS YOU SUCCESSFULLY PASSED THE CLASS'.
    ELSE.
      mail_msg = 'WE ARE SORRY TO INFORM YOU THAT YOU FAILED THE CLASS'.
    ENDIF.

    CLEAR: recipients, object_hd.
    doc_chng-obj_descr = 'Grade Report'.
    object_hd-line = |HI! { gs_student_t-studentname } { gs_student_t-studentlname }|.
    APPEND object_hd.
    object_hd-line = mail_msg.
    APPEND object_hd.
    object_hd-line = | YOUR SCORE IS: { gs_student_t-studentscore } |.
    recipients-rec_type = 'U'.
    recipients-receiver = lv_mail_adress.
    APPEND recipients.

    CALL FUNCTION 'SO_NEW_DOCUMENT_SEND_API1'
      EXPORTING
        document_data      = doc_chng
        document_type      = 'RAW'
        put_in_outbox      = 'X'
        commit_work        = 'X'
      TABLES
        object_content     = object_hd
        receivers          = recipients
      EXCEPTIONS
        too_many_receivers = 1
        document_not_sent  = 2
        OTHERS             = 99.
    IF sy-subrc = 0.
      MESSAGE 'MAIL HAS BEEN SENT' TYPE 'S'.
    ELSE.
      MESSAGE 'MAIL SENDING FAILED' TYPE 'E'.
    ENDIF.
  ENDLOOP.

ENDFORM.

FORM list_students_by_score.
  SELECT * FROM zstudent_t
    INTO CORRESPONDING FIELDS OF TABLE @gt_student_t
    WHERE studentscore >= @p_score1 AND studentscore <= @p_score2.

  WRITE: /1 '@08@', 'STUDENTS IN RANGE'.

  IF lines( gt_student_t ) > 0.
    LOOP AT gt_student_t INTO gs_student_t.
      WRITE: /3 '├─   ', gs_student_t-studentname, gs_student_t-studentlname, gs_student_t-studentscore.
    ENDLOOP.
  ELSE.
    WRITE: /3 '└─   ','@0A@','   NO DATA FOUND'.
  ENDIF.
  WRITE: /.
ENDFORM.

FORM clear_all_data_with_popup.
  DATA lv_answer TYPE c.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = 'CONFIRM DATA DELETION'
      text_question         = 'YOU WANT TO DELETE ALL STUDENT DATA?'
      text_button_1         = 'YES'
      text_button_2         = 'NO'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answer. " imports users answer

  IF lv_answer = '1'.
    DELETE FROM zstudent_t. " empties table
    DELETE FROM zfstudent_t. " empties table
    COMMIT WORK. " commits changes into database

    lv_next_student_id = 1.
    CLEAR: gt_student_t, gt_failed_t. " empties both tables and cleans memory
    MESSAGE 'ALL STUDENTS HAVE BEEN DELETED' TYPE 'S'.
  ENDIF.
ENDFORM.

FORM display_statistics.
  DATA lv_total   TYPE i.
  DATA lv_avg     TYPE p DECIMALS 3. " ,000 type
  DATA lv_passed  TYPE i.
  DATA lv_failed  TYPE i.

  SELECT COUNT(*) FROM zstudent_t INTO @lv_total. " select all rows from zstudent table
  SELECT AVG( studentscore ) FROM zstudent_t INTO @lv_avg. " calculates avg student score
  SELECT COUNT(*) FROM zstudent_t INTO @lv_passed WHERE studentscore >= 35.
  lv_failed = lv_total - lv_passed.

  WRITE: /1  '@17@', 'STATS'.
  WRITE: /3 '├─ STUDENTS:        ', lv_total.
  WRITE: /3 '├─ PASSED:          ', lv_passed.
  WRITE: /3 '├─ FAILED:          ', lv_failed.
  WRITE: /3 '└─ AVG SCORE:     ', lv_avg.
  WRITE: /.
ENDFORM.

FORM find_top_student.
  CLEAR: ls_max_grade_student, lv_highest_score. " clear both areas

  SELECT MAX( studentscore ) FROM zstudent_t INTO @lv_highest_score. " selects max value
  IF sy-subrc = 0 AND lv_highest_score IS NOT INITIAL.
    SELECT SINGLE * FROM zstudent_t
      INTO @ls_max_grade_student
      WHERE studentscore EQ @lv_highest_score.
  ENDIF.
ENDFORM.

FORM display_top_student.
  PERFORM find_top_student.

  IF ls_max_grade_student IS NOT INITIAL.
    WRITE: /1  '@10@', 'TOP STUDENT'.
    WRITE: /3 '├─ FULLNAME:        ', ls_max_grade_student-studentname.
    WRITE: /3 '├─ NAME:            ', ls_max_grade_student-studentlname.
    WRITE: /3 '├─ ID:              ', ls_max_grade_student-studentid.
    WRITE: /3 '└─ SCORE:           ', ls_max_grade_student-studentscore.
    WRITE: /.
  ELSE.
    WRITE: /1 '@0A@', '└─ ⚠️  NO DATA FOUND'.
    WRITE: /.
  ENDIF.
ENDFORM.

FORM display_failed_students.
  DATA lv_count TYPE i.

  WRITE: /1 '@17@', 'FAILED STUDENTS'.

  SELECT COUNT(*) FROM zfstudent_t INTO @lv_count. " counts all rows

  IF lv_count > 0. " checks if there are any rows in the table
    SELECT * FROM zfstudent_t INTO TABLE @gt_failed_t. " fetches data and loops thru table

    LOOP AT gt_failed_t INTO gs_failed_t.
      WRITE: /3 |├─ { gs_failed_t-studentname } { gs_failed_t-studentscore }|.
    ENDLOOP.
  ELSE.
    WRITE: /3 '└─ ','@0A@','NO DATA FOUND'.
  ENDIF.
  WRITE: /.
ENDFORM.

FORM create_student_salv.

  cl_salv_table=>factory(
        IMPORTING
          r_salv_table = go_salv_students
        CHANGING
          t_table      = gt_cell_color
      ).

  TRY.
      DATA(lo_display) = go_salv_students->get_display_settings( ).
      lo_display->set_list_header( value = 'STUDENT SALV VIEW' ).

      DATA(lo_columns) = go_salv_students->get_columns( ).
      lo_columns->set_color_column( 'ROW_COLOR' ).
      lo_columns->set_optimize( value = 'X' ).
    CATCH cx_salv_data_error INTO DATA(lx_error1).
*   catches error and displays it in error message
      MESSAGE lx_error1->get_text( ) TYPE 'E'.
  ENDTRY.

  TRY.
      go_salv_students->set_screen_popup(
      EXPORTING
        start_column = 20
        end_column   = 80
        start_line   = 5
        end_line     = 15
      ).
    CATCH cx_salv_msg INTO DATA(lx_error4).
*   catches error and displays it in error message
      MESSAGE lx_error4->get_text( ) TYPE 'E'.

  ENDTRY.

  TRY.
      DATA(lt_columns) = lo_columns->get( ).
      LOOP AT lt_columns INTO DATA(ls_column).
        ls_column-r_column->set_alignment(
            value = if_salv_c_alignment=>centered " set cell values as centered
        ).
      ENDLOOP.
    CATCH cx_salv_data_error INTO DATA(lx_error2).
*   catches error and displays it in error message
      MESSAGE lx_error2->get_text( ) TYPE 'E'.
  ENDTRY.

  TRY.
      DATA(lo_sorts) = go_salv_students->get_sorts( ).
      lo_sorts->add_sort(
      EXPORTING
        columnname = 'STUDENTSCORE'
        sequence   = if_salv_c_sort=>sort_down " sorts the rows
    ).
    CATCH cx_salv_msg INTO DATA(lx_error3).
*   catches error and displays it in error message
      MESSAGE lx_error3->get_text( ) TYPE 'E'.
  ENDTRY.

  go_salv_students->display( ). " displays alv


ENDFORM.

FORM set_cell_color.
  SELECT * FROM zstudent_t
    INTO CORRESPONDING FIELDS OF TABLE @gt_cell_color.
  LOOP AT gt_cell_color INTO gs_cell_color.
    DATA: lt_color TYPE lvc_t_scol. " table to store cell coloring information
    CLEAR lt_color.
    DATA(ls_color) = lcl_set_cell_color=>set_cell_color( gs_cell_color-studentgrade ).

    APPEND ls_color TO lt_color.
    gs_cell_color-row_color = lt_color.
    MODIFY gt_cell_color FROM gs_cell_color.
  ENDLOOP.
ENDFORM.

FORM create_student_ooalv.
  CREATE OBJECT go_cont
    EXPORTING
      container_name = 'CC_ALV'.

  IF go_ooalv_students IS NOT BOUND.
    CREATE OBJECT go_ooalv_students
      EXPORTING
        i_parent = go_cont.
  ENDIF.

  SELECT * FROM zstudent_t
    INTO TABLE gt_ostudent_t.
*    INTO TABLE @DATA(gt_data).
    IF sy-subrc EQ 0.
    CALL METHOD go_ooalv_students->set_table_for_first_display
      EXPORTING
        i_structure_name = 'ZSTUDENT_T'
      CHANGING
        it_outtab        = gt_ostudent_t.
    ELSE.
      MESSAGE 'Değer bulunamamıştır.' TYPE 'E'.
    ENDIF.
ENDFORM.
