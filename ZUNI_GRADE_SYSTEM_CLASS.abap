CLASS lcl_grade_converter DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      convertscoretograde
        IMPORTING
          iv_score        TYPE zstudent_score_de
        RETURNING
          VALUE(rv_grade) TYPE zstudent_grade_de.
ENDCLASS.

CLASS lcl_grade_converter IMPLEMENTATION.
  METHOD convertscoretograde.
    IF iv_score >= 95.
      rv_grade = 'AA'.
    ELSEIF iv_score >= 90.
      rv_grade = 'AB'.
    ELSEIF iv_score >= 85.
      rv_grade = 'BB'.
    ELSEIF iv_score >= 75.
      rv_grade = 'BC'.
    ELSEIF iv_score >= 55.
      rv_grade = 'CC'.
    ELSEIF iv_score >= 45.
      rv_grade = 'CD'.
    ELSEIF iv_score >= 35.
      rv_grade = 'DD'.
    ELSE.
      rv_grade = 'FF'.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_age_calculator DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      calculate_age
        IMPORTING
          iv_bdate      TYPE zstudentbdate_de
        RETURNING
          VALUE(rv_age) TYPE zstudentage_de.
ENDCLASS.

CLASS lcl_age_calculator IMPLEMENTATION.
  METHOD calculate_age.
    rv_age = sy-datum(4) - iv_bdate(4).

    IF sy-datum+4(4) < iv_bdate+4(4).
      rv_age = rv_age - 1.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_set_cell_color DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      set_cell_color
        IMPORTING
          iv_grade        TYPE zstudent_grade_de
        RETURNING
          VALUE(rv_color) TYPE lvc_s_scol.
ENDCLASS.

CLASS lcl_set_cell_color IMPLEMENTATION.
  METHOD set_cell_color.
    CLEAR rv_color.
    rv_color-fname = 'STUDENTGRADE'.
    rv_color-color-int = '1'.

    CASE iv_grade.
      WHEN 'FF'.
        rv_color-color-col = col_negative.
      WHEN 'DD' OR 'CD'.
        rv_color-color-col = col_total.
      WHEN 'CC' OR 'BC' OR 'BB'.
        rv_color-color-col = col_key.
      WHEN 'AB' OR 'AA'.
        rv_color-color-col = col_positive.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
