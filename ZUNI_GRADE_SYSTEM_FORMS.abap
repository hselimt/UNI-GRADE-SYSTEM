FORM initialize_data. " initializes required data before output
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
  gs_student_t-studentbhv   = p_bhv.

  IF gv_mrad EQ 'X'. " male button is ticked
    gs_student_t-studentgen = 'M'.
  ELSEIF gv_frad EQ 'X'. " female button is ticked
    gs_student_t-studentgen = 'F'.
  ENDIF.

  IF p_bdate <= sy-datum AND p_mail CS '@' AND p_mail CS '.'.
*   birth date <= current date, mail contains '@' and '.'
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

  IF sy-subrc = 0. " process was successful
    COMMIT WORK. " commits changes into database
    MESSAGE 'STUDENT ADDED' TYPE 'S'.
  ELSE.
    MESSAGE 'ERROR ADDING STUDENT' TYPE 'E'.
  ENDIF.
ENDFORM.

FORM display_added_student_details.
  SET PF-STATUS '0001'.

  WRITE: /1  '@0V@', 'NEW STUDENT'.
  WRITE: /3 '├─ STUDENT ID:      ', gs_student_t-studentid COLOR COL_HEADING.
  WRITE: /3 '├─ NAME:            ', gs_student_t-studentname COLOR COL_NORMAL.
  WRITE: /3 '├─ LASTNAME:        ', gs_student_t-studentlname COLOR COL_NORMAL.
  WRITE: /3 '├─ BIRTH DATE:      ', gs_student_t-studentbdate COLOR COL_NORMAL.
  WRITE: /3 '├─ AGE:             ', gs_student_t-studentage COLOR COL_NORMAL.
  WRITE: /3 '├─ MAIL:            ', gs_student_t-studentmail COLOR COL_NORMAL.
  WRITE: /3 '├─ GENDER:          ', gs_student_t-studentgen COLOR COL_NORMAL.
  WRITE: /3 '├─ SCORE:           ', gs_student_t-studentscore COLOR COL_NORMAL.
  WRITE: /3 '├─ GRADE:           ', gs_student_t-studentgrade COLOR COL_NORMAL.
  WRITE: /3 '└─ BEHAVIOUR:       ', gs_student_t-studentbhv COLOR COL_NORMAL.
  WRITE: /.
ENDFORM.

FORM handle_failed_students.
  IF gs_student_t-studentgrade = 'FF'.
    PERFORM process_failed_student.
  ENDIF.
ENDFORM.

FORM process_failed_student.
  IF gs_student_t-studentscore BETWEEN 34 AND 35.
    PERFORM upgrade_student_grade.
*   it takes ceiling of the score which is between 34 and 35
    MESSAGE 'STUDENT''S GRADE UPGRADED TO DD WITH THE SCORE OF 35' TYPE 'I'.
  ELSE.
    PERFORM add_to_failed_students. " if not in between 34 and 35
    MESSAGE 'STUDENT HAS FAILED THE CLASS AND ADDED TO FAILED LIST' TYPE 'I'.
  ENDIF.
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
* adds structure to table
  IF sy-subrc = 0.
    COMMIT WORK.
  ENDIF.
ENDFORM.

FORM update_student_by_id.
  SELECT SINGLE * FROM zstudent_t
    INTO @gs_student_t
    WHERE studentid EQ @p_uid.
*   retrieves single record where student id equels to user input

  IF sy-subrc = 0.
    IF p_name IS NOT INITIAL.
      gs_student_t-studentname = p_name.
    ENDIF.

    IF p_lname IS NOT INITIAL.
      gs_student_t-studentlname = p_lname.
    ENDIF.

    IF p_bdate IS NOT INITIAL AND p_bdate <= sy-datum.
*     birth date is not initial and its <= than current date
      gs_student_t-studentbdate = p_bdate.
      gs_student_t-studentage = lcl_age_calculator=>calculate_age( p_bdate ).
    ENDIF.

    IF p_score IS NOT INITIAL AND p_score >= 0 AND p_score <= 100.
*     score is not initial and 0 <= score <= 100
      gs_student_t-studentscore = p_score.
      gs_student_t-studentgrade = lcl_grade_converter=>convertscoretograde( p_score ).
      gs_failed_t-studentscore = p_score.

      PERFORM update_failed_student_table.
    ENDIF.

    IF p_mail IS NOT INITIAL AND p_mail CS '@' AND p_mail CS '.'.
*     mail is not initial, mail contains '@' and '.'
      gs_student_t-studentmail = p_mail.
    ENDIF.

    IF gv_mrad EQ 'X'. " male radio button is checked
      gs_student_t-studentgen = 'M'.
    ELSEIF gv_frad EQ 'X'. " female radio button is checked
      gs_student_t-studentgen = 'F'.
    ENDIF.

    IF p_bhv IS NOT INITIAL.
      gs_student_t-studentbhv = p_bhv.
    ENDIF.

    UPDATE zstudent_t FROM gs_student_t.

    IF sy-subrc = 0.
      COMMIT WORK. " commits changes into database
      MESSAGE 'STUDENT UPDATED SUCCESSFULLY' TYPE 'S'.

      WRITE: /1  '@08@', 'SEARCHED STUDENT'.
      WRITE: /3 '├─ STUDENT ID:      ', gs_student_t-studentid COLOR COL_HEADING.
      WRITE: /3 '├─ NAME:            ', gs_student_t-studentname COLOR COL_NORMAL.
      WRITE: /3 '├─ LASTNAME:        ', gs_student_t-studentlname COLOR COL_NORMAL.
      WRITE: /3 '├─ BIRTH DATE:      ', gs_student_t-studentbdate COLOR COL_NORMAL.
      WRITE: /3 '├─ AGE:             ', gs_student_t-studentage COLOR COL_NORMAL.
      WRITE: /3 '├─ MAIL:            ', gs_student_t-studentmail COLOR COL_NORMAL.
      WRITE: /3 '├─ GENDER:          ', gs_student_t-studentgen COLOR COL_NORMAL.
      WRITE: /3 '├─ SCORE:           ', gs_student_t-studentscore COLOR COL_NORMAL.
      WRITE: /3 '├─ GRADE:           ', gs_student_t-studentgrade COLOR COL_NORMAL.
      WRITE: /3 '└─ BEHAVIOUR:       ', gs_student_t-studentbhv COLOR COL_NORMAL.
      WRITE: /.
    ELSE.
      ROLLBACK WORK. " reverts database changes
      MESSAGE 'ERROR UPDATING STUDENT' TYPE 'E'.
    ENDIF.
  ELSE.
    MESSAGE 'STUDENT NOT FOUND FOR UPDATE' TYPE 'E'.
  ENDIF.
ENDFORM.

FORM update_failed_student_table.
  PERFORM handle_failed_students.
* if updated grade is ff and student doesnt exist in failed students table it adds student to the table

  IF gs_student_t-studentgrade NE 'FF'.
    SELECT SINGLE * FROM zfstudent_t
      WHERE studentid = @p_uid
      INTO @gs_failed_t.
* if updated grade is not ff and student does exist in failed students table it removes student from the table

    IF sy-subrc = 0.
      DELETE FROM zfstudent_t WHERE studentid = @p_uid.
      COMMIT WORK.
    ENDIF.
  ENDIF.
ENDFORM.


FORM search_student_by_id.
  SET PF-STATUS '0001'.

  SELECT SINGLE * FROM zstudent_t
    INTO @gs_student_t
    WHERE studentid EQ @p_sid. " searched student id equals to current student id

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
    WRITE: /3 '├─ GRADE:           ', gs_student_t-studentgrade COLOR COL_NORMAL.
    WRITE: /3 '└─ BEHAVIOUR:       ', gs_student_t-studentbhv COLOR COL_NORMAL.
    WRITE: /.
  ELSE.
    WRITE: /1 '@0A@', 'STUDENT NOT FOUND'.
  ENDIF.
ENDFORM.

FORM search_student_by_name.
  SET PF-STATUS '0001'. " activates GUI status

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
    WRITE: /3 '├─ GRADE:           ', gs_student_t-studentgrade COLOR COL_NORMAL.
    WRITE: /3 '└─ BEHAVIOUR:       ', gs_student_t-studentbhv COLOR COL_NORMAL.
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
    MESSAGE 'MAIL SENDING HAS FAILED' TYPE 'E'.
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
*   adds elements to mail message

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
  SET PF-STATUS '0001'. " activates GUI status

  SELECT * FROM zstudent_t
    INTO CORRESPONDING FIELDS OF TABLE @gt_student_t
    WHERE studentscore >= @p_score1 AND studentscore <= @p_score2.

  WRITE: /1 '@08@', 'STUDENTS IN RANGE'.

  IF lines( gt_student_t ) > 0. " atleast 1 row exists in the table
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
  SET PF-STATUS '0001'.
  DATA: lv_total  TYPE i,
        lv_avg    TYPE p DECIMALS 3, " ,000 type
        lv_passed TYPE i,
        lv_failed TYPE i.

  SELECT COUNT(*) FROM zstudent_t INTO @lv_total. " gets row count from zstudent table
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
  SET PF-STATUS '0001'. " activates GUI status

  PERFORM find_top_student.

  IF ls_max_grade_student IS NOT INITIAL.
    WRITE: /1  '@10@', 'TOP STUDENT'.
    WRITE: /3 '├─ FULLNAME:        ', ls_max_grade_student-studentname.
    WRITE: /3 '├─ NAME:            ', ls_max_grade_student-studentlname.
    WRITE: /3 '├─ ID:              ', ls_max_grade_student-studentid.
    WRITE: /3 '└─ SCORE:           ', ls_max_grade_student-studentscore.
    WRITE: /.
  ELSE.
    WRITE: /1 '└─   ','@0A@','   NO DATA FOUND'.
    WRITE: /.
  ENDIF.
ENDFORM.

FORM display_failed_students.
  SET PF-STATUS '0001'. " activates GUI status

  DATA lv_count TYPE i.

  WRITE: /1 '@17@', 'FAILED STUDENTS'.

  SELECT * FROM zfstudent_t INTO TABLE @gt_failed_t. " fetches data and loops thru table

  IF lines( gt_failed_t ) > 0. " atleast 1 row exists in the table
    LOOP AT gt_failed_t INTO gs_failed_t.
      WRITE: /3 |├─ { gs_failed_t-studentid } { gs_failed_t-studentname } { gs_failed_t-studentscore }|.
    ENDLOOP.
  ELSE.
    WRITE: /1 '└─   ','@0A@','   NO DATA FOUND'.
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

  DATA(lo_display) = go_salv_students->get_display_settings( ).
  lo_display->set_list_header( value = 'STUDENT SALV VIEW' ).

  DATA(lo_columns) = go_salv_students->get_columns( ).
  lo_columns->set_color_column( 'ROW_COLOR' ).
  lo_columns->set_optimize( value = 'X' ).

  go_salv_students->set_screen_popup(
    EXPORTING " sets SALV popup screen display properties
      start_column = 20
      end_column   = 90
      start_line   = 5
      end_line     = 15
      ).

  DATA(lt_columns) = lo_columns->get( ).
  LOOP AT lt_columns INTO DATA(ls_column).
    ls_column-r_column->set_alignment(
       value = if_salv_c_alignment=>centered " sets cell elements as centered
    ).
  ENDLOOP.

  DATA(lo_sorts) = go_salv_students->get_sorts( ).
  lo_sorts->add_sort(
    EXPORTING
      columnname = 'STUDENTSCORE'
      sequence   = if_salv_c_sort=>sort_down " sorts the rows
      ).

  IF gt_cell_color IS NOT INITIAL.
    go_salv_students->display( ). " displays alv
  ELSE.
    MESSAGE 'ERROR DISPLAYING ALV SINCE ITS EMPTY' TYPE 'E'.
  ENDIF.
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
* creates objects that holds ALV grid
  CREATE OBJECT go_cont
    EXPORTING
      container_name = 'CC_ALV'.

* creates ALV grid if not exists
  IF go_ooalv_students IS NOT BOUND.
    CREATE OBJECT go_ooalv_students
      EXPORTING
        i_parent = go_cont.
  ENDIF.

  PERFORM set_cell_color.

  DATA: ls_layout       TYPE lvc_s_layo,
        lt_sort         TYPE lvc_t_sort,
        lt_fieldcatalog TYPE lvc_t_fcat.

* gets field catalog
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = 'zstudent_t'
    CHANGING
      ct_fieldcat      = lt_fieldcatalog.

  READ TABLE lt_fieldcatalog INTO ls_fieldcatalog WITH KEY fieldname = 'STUDENTBHV'.
  IF sy-subrc = 0.
    ls_fieldcatalog-edit = 'X'.
    MODIFY lt_fieldcatalog FROM ls_fieldcatalog INDEX sy-tabix.
  ENDIF.

  LOOP AT lt_fieldcatalog ASSIGNING FIELD-SYMBOL(<fs_fcat>).
    <fs_fcat>-just = 'C'.
  ENDLOOP.

  ls_layout-ctab_fname = 'ROW_COLOR'. " color field name
  ls_layout-cwidth_opt = 'X'. " auto fit columns
  ls_layout-col_opt = 'X'. " sets cell length accordingly

* sort score by descending
  APPEND VALUE #( fieldname = 'STUDENTSCORE' down = 'X' ) TO lt_sort.

  IF gt_cell_color IS NOT INITIAL.
    CALL METHOD go_ooalv_students->set_table_for_first_display
      EXPORTING
        is_layout        = ls_layout
        i_structure_name = 'ZSTUDENT_T'
      CHANGING
        it_outtab        = gt_cell_color
        it_fieldcatalog  = lt_fieldcatalog
        it_sort          = lt_sort.
  ELSE.
    MESSAGE 'ERROR DISPLAYING ALV SINCE ITS EMPTY' TYPE 'E'.
  ENDIF.
ENDFORM.

FORM save_changes_from_bhv.
  CALL METHOD go_ooalv_students->check_changed_data.

  CALL METHOD go_ooalv_students->get_selected_rows
    IMPORTING
      et_index_rows = lt_selected_rows. " stores which rows user selected

  IF lines( lt_selected_rows ) > 0. " atleast 1 row exists in the table
    READ TABLE gt_cell_color INTO gs_cell_color INDEX lt_selected_rows[ 1 ]-index.
*   get cell color data for first selected row

    UPDATE zstudent_t SET studentbhv = @gs_cell_color-studentbhv
                  WHERE studentid = @gs_cell_color-studentid.

    IF sy-subrc = 0.
      COMMIT WORK.
      MESSAGE 'DATA SAVED' TYPE 'S'.
      CALL METHOD go_ooalv_students->refresh_table_display
        EXPORTING
          is_stable = VALUE #( row = 'X' col = 'X' ).
*         keeps the current positions stable during refresh
    ELSE.
      MESSAGE 'ERROR SAVING DATA' TYPE 'E'.
    ENDIF.
  ELSE.
    MESSAGE 'SELECT A ROW' TYPE 'W'.
  ENDIF.
ENDFORM.
