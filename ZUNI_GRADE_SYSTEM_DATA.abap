TYPES: BEGIN OF ty_cell_color,
         studentid    TYPE zstudentid_de,
         studentname  TYPE zstudentname_de,
         studentlname TYPE zstudentlname_de,
         studentgen   TYPE zstudentgen_de,
         studentbdate TYPE zstudentbdate_de,
         studentage   TYPE zstudentage_de,
         studentmail  TYPE zstudentmail_de,
         studentscore TYPE zstudent_score_de,
         studentgrade TYPE zstudent_grade_de,
         studentbhv   TYPE zstudentbhv_de,
         row_color    TYPE lvc_t_scol, " cell color information table
       END OF ty_cell_color.

DATA: gv_studentID         TYPE zstudentid_de,
      gv_studentName       TYPE zstudentname_de,
      gv_studentLName      TYPE zstudentlname_de,
      gv_studentGender     TYPE zstudentgen_de,
      gv_mrad              TYPE xfeld,
      gv_frad              TYPE xfeld,
      gv_studentBDate      TYPE zstudentbdate_de,
      gv_studentAge        TYPE zstudentage_de,
      gv_studentMail       TYPE zstudentmail_de,
      gv_studentScore      TYPE zstudent_score_de,
      gv_studentGrade      TYPE zstudent_grade_de,
      gv_studentBhv        TYPE zstudentbhv_de,
      gs_student_t         TYPE zstudent_t,
      gt_student_t         TYPE TABLE OF zstudent_t,
      gs_failed_t          TYPE zfstudent_t,
      gt_failed_t          TYPE TABLE OF zfstudent_t,
      gs_ostudent_t        TYPE zstudent_t,
      gt_ostudent_t        TYPE TABLE OF zstudent_t,
      go_salv_students     TYPE REF TO cl_salv_table,
      gs_cell_color        TYPE ty_cell_color, " global structure for cell color
      gt_cell_color        TYPE TABLE OF ty_cell_color, " global table for cell color
      go_ooalv_students    TYPE REF TO cl_gui_alv_grid,
      go_cont              TYPE REF TO cl_gui_custom_container,
      ls_layout            TYPE lvc_s_layo, " ALV layout settings
      lt_sort              TYPE lvc_t_sort, " ALV sorting rules table
      lt_fieldcatalog      TYPE lvc_s_fcat, " single ALV column definition
      ls_fieldcatalog      TYPE lvc_s_fcat, " work area for field catalog
      lt_selected_rows     TYPE lvc_t_row, " table of selected row numbers
      lv_next_student_id   TYPE zstudentid_de,
      lv_highest_score     TYPE zstudent_score_de VALUE 0,
      lv_new_age           TYPE zstudentage_de,
      ls_max_grade_student TYPE zstudent_t,
      p_name               TYPE zstudentname_de,
      p_lname              TYPE zstudentlname_de,
      p_bdate              TYPE zstudentbdate_de,
      p_score              TYPE zstudent_score_de,
      p_mail               TYPE zstudentmail_de,
      p_male               TYPE c,
      p_female             TYPE c,
      P_bhv                TYPE zstudentbhv_de,
      p_sname              TYPE zstudentname_de,
      p_slname             TYPE zstudentlname_de,
      p_id                 TYPE zstudentid_de,
      p_uid                TYPE zstudentid_de,
      p_score1             TYPE i,
      p_score2             TYPE i,
      recipients           TYPE somlreci1 OCCURS 0 WITH HEADER LINE, " who gets mail
* grows as needed and creates work area with the same name
      doc_chng             TYPE sodocchgi1, " mail properties
      object_hd            TYPE solisti1 OCCURS 0 WITH HEADER LINE, " mail text
      mail_msg             TYPE c LENGTH 100,
      lv_mail_adress       TYPE c LENGTH 30,
      gs_outparams         TYPE sfpoutputparams,
      gv_name              TYPE fpname,
      gv_funcname          TYPE funcname,
      gs_docparams         TYPE sfpdocparams,
      gs_formoutput        TYPE fpformoutput.
