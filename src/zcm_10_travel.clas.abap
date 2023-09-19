CLASS zcm_10_travel DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_t100_dyn_msg .
    INTERFACES if_t100_message .
    interfaces IF_ABAP_BEHV_MESSAGE.

    CONSTANTS:
      BEGIN OF cancel_success,
        msgid TYPE symsgid VALUE 'DEVS4D437',
        msgno TYPE symsgno VALUE '120',
        attr1 TYPE scx_attrname VALUE 'attr1',
        attr2 TYPE scx_attrname VALUE 'attr2',
        attr3 TYPE scx_attrname VALUE 'attr3',
        attr4 TYPE scx_attrname VALUE 'attr4',
      END OF cancel_success,

      BEGIN OF already_cancelled,
        msgid TYPE symsgid VALUE 'DEVS4D437',
        msgno TYPE symsgno VALUE '130',
        attr1 TYPE scx_attrname VALUE 'attr1',
        attr2 TYPE scx_attrname VALUE 'attr2',
        attr3 TYPE scx_attrname VALUE 'attr3',
        attr4 TYPE scx_attrname VALUE 'attr4',
      END OF already_cancelled.


    METHODS constructor
      IMPORTING
        !textid   LIKE if_t100_message=>t100key OPTIONAL
        !previous LIKE previous OPTIONAL
        !severity TYPE  if_abap_behv_message=>t_severity OPTIONAL.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcm_10_travel IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    CALL METHOD super->constructor
      EXPORTING
        previous = previous.
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.

    if_abap_behv_message~m_severity = severity.

  ENDMETHOD.
ENDCLASS.
