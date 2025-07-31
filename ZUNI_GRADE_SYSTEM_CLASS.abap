CLASS lcl_grade_converter DEFINITION. " defines score-grade converter
  PUBLIC SECTION.
    CLASS-METHODS:
      convertscoretograde " creates score-grade converter method
        IMPORTING
          iv_score        TYPE zstudent_score_de " imports score
        RETURNING
          VALUE(rv_grade) TYPE zstudent_grade_de. " returns grade
ENDCLASS.

CLASS lcl_grade_converter IMPLEMENTATION. " implements score-grade converter
  METHOD convertscoretograde. " sets score-grade converter
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

CLASS lcl_age_calculator DEFINITION. " defines age calculator
  PUBLIC SECTION.
    CLASS-METHODS: " creates age calculator method
      calculate_age
        IMPORTING
          iv_bdate      TYPE zstudentbdate_de " imports birth date
        RETURNING
          VALUE(rv_age) TYPE zstudentage_de. " returns age
ENDCLASS.

CLASS lcl_age_calculator IMPLEMENTATION. " implements age calculator
  METHOD calculate_age.
    rv_age = sy-datum(4) - iv_bdate(4). " sets age to current year - birth date year

    IF sy-datum+4(4) < iv_bdate+4(4).
      rv_age = rv_age - 1. " subtracts 1 from age if birthday hasnt occurred this year
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
          VALUE(rv_color) TYPE lvc_s_scol. " lvc_s_scol is structure used to define the color properties
ENDCLASS.

CLASS lcl_set_cell_color IMPLEMENTATION.
  METHOD set_cell_color.
    CLEAR rv_color.
    rv_color-fname = 'STUDENTGRADE'.
    rv_color-color-int = '1'. " sets color intensity to make it vibrant

    CASE iv_grade.
      WHEN 'FF'.
        rv_color-color-col = col_negative. " red
      WHEN 'DD' OR 'CD'.
        rv_color-color-col = col_total. " yellow
      WHEN 'CC' OR 'BC' OR 'BB'.
        rv_color-color-col = col_key. " blue
      WHEN 'AB' OR 'AA'.
        rv_color-color-col = col_positive. " green
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
