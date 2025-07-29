TYPES: BEGIN OF ty_cell_color,
         studentid    TYPE zstudentid_de,
         studentname  TYPE zstudentname_de,
         studentlname TYPE zstudentlname_de,
         studentgrade TYPE zstudent_grade_de,
         studentscore TYPE zstudent_score_de,
         studentmail  TYPE zstudentmail_de,
         studentgen   TYPE zstudentgen_de,
         studentage   TYPE zstudentage_de,
         studentbdate TYPE zstudentbdate_de,
         row_color    TYPE lvc_t_scol,
       END OF ty_cell_color.

DATA: gv_studentID      TYPE zstudentid_de,
      gv_studentName    TYPE zstudentname_de,
      gv_studentLName   TYPE zstudentlname_de,
      gv_studentGender  TYPE zstudentgen_de,
      gv_mrad           TYPE xfeld,
      gv_frad           TYPE xfeld,
      gv_studentBDate   TYPE zstudentbdate_de,
      gv_studentAge     TYPE zstudentage_de,
      gv_studentScore   TYPE zstudent_score_de,
      gv_studentGrade   TYPE zstudent_grade_de,
      gv_studentMail    TYPE zstudentmail_de,
      gs_student_t      TYPE zstudent_t,
      gt_student_t      TYPE TABLE OF zstudent_t,
      gs_failed_t       TYPE zfstudent_t,
      gt_failed_t       TYPE TABLE OF zfstudent_t,
      gs_ostudent_t     TYPE zstudent_t,
      gt_ostudent_t     TYPE TABLE OF zstudent_t,
      go_salv_students  TYPE REF TO cl_salv_table,
      gs_cell_color     TYPE ty_cell_color,
      gt_cell_color     TYPE TABLE OF ty_cell_color,
      go_ooalv_students TYPE REF TO cl_gui_alv_grid,
      go_cont           TYPE REF TO cl_gui_custom_container.

DATA: lv_next_student_id   TYPE zstudentid_de,
      lv_highest_score     TYPE zstudent_score_de VALUE 0,
      ls_max_grade_student TYPE zstudent_t.

DATA: p_name   TYPE zstudentname_de,
      p_lname  TYPE zstudentlname_de,
      p_bdate  TYPE zstudentbdate_de,
      p_score  TYPE zstudent_score_de,
      p_mail   TYPE zstudentmail_de,
      p_male   TYPE c,
      p_female TYPE c,
      p_sname  TYPE zstudentname_de,
      p_slname TYPE zstudentlname_de,
      p_sid    TYPE zstudentid_de,
      p_uid    TYPE zstudentid_de,
      p_mid    TYPE zstudentid_de,
      p_score1 TYPE i,
      p_score2 TYPE i.

DATA: recipients     TYPE somlreci1 OCCURS 0 WITH HEADER LINE, " who gets mail
* grows as needed and creates work area with the same name
      doc_chng       TYPE sodocchgi1, " mail properties
      object_hd      TYPE solisti1 OCCURS 0 WITH HEADER LINE, " mail text
      mail_msg       TYPE c LENGTH 100,
      lv_mail_adress TYPE c LENGTH 30.
