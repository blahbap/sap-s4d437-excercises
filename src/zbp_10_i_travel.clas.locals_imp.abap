CLASS lhc_Z10_I_TRAVEL DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS set_to_cancelled FOR MODIFY
      IMPORTING keys FOR ACTION z10_i_travel~set_to_cancelled.
    METHODS get_authorizations FOR AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR z10_i_travel RESULT result.
    METHODS validatecustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR z10_i_travel~validatecustomer.
    METHODS determinesemantickey FOR DETERMINE ON MODIFY
      IMPORTING keys FOR z10_i_travel~determinesemantickey.
    METHODS get_features FOR FEATURES
      IMPORTING keys REQUEST requested_features FOR z10_i_travel RESULT result.

ENDCLASS.

CLASS lhc_Z10_I_TRAVEL IMPLEMENTATION.





  METHOD set_to_cancelled.

    DATA lo_msg TYPE REF TO zcm_10_travel.


    DATA lt_read TYPE TABLE FOR READ IMPORT z10_i_travel.
    DATA ls_read TYPE STRUCTURE FOR READ IMPORT z10_i_travel.

    DATA ls_reported_travel LIKE LINE OF reported-z10_i_travel.

    DATA lt_update TYPE TABLE FOR UPDATE z10_i_travel.
    DATA ls_update LIKE LINE OF lt_update.


    LOOP AT keys INTO DATA(key).
      MOVE-CORRESPONDING key TO ls_read.
      APPEND ls_read TO lt_read.
    ENDLOOP.

    READ ENTITY IN LOCAL MODE z10_i_travel
        ALL FIELDS WITH lt_read
        RESULT DATA(lt_result) .

    LOOP AT lt_result INTO DATA(ls_result).
      IF ls_result-Status = 'C'.

        CREATE OBJECT lo_msg
          EXPORTING
            textid   = zcm_10_travel=>already_cancelled
            severity = if_abap_behv_message=>severity-error.

        ls_reported_travel-%tky = ls_result-%tky.
        ls_reported_travel-%msg = lo_msg.
        APPEND ls_reported_travel TO reported-z10_i_travel.
      ELSE.
        CLEAR lt_update.
        ls_update-%tky = ls_result-%tky.
        ls_update-status = 'C'.
        APPEND ls_update TO lt_update.
* Update Status of travel not yet cancelled
        MODIFY ENTITY IN LOCAL MODE z10_i_travel
            UPDATE FIELDS ( status ) WITH lt_update
            FAILED DATA(ls_failed).
        IF ls_failed IS INITIAL.
* Success message
          CREATE OBJECT lo_msg
            EXPORTING
              textid   = zcm_10_travel=>cancel_success
              severity = if_abap_behv_message=>severity-success.
          ls_reported_travel-%tky = ls_result-%tky.
          ls_reported_travel-%msg = lo_msg.
          APPEND ls_reported_travel TO reported-z10_i_travel.
        ENDIF.

      ENDIF.

    ENDLOOP.
*


  ENDMETHOD.

  METHOD get_authorizations.

    IF requested_authorizations-%update = if_abap_behv=>mk-on
    OR requested_authorizations-%action-set_to_cancelled =
     if_abap_behv=>mk-on.
      READ ENTITY IN LOCAL MODE z10_i_travel
      FIELDS ( AgencyID ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_travel).
* READ ENTITIES OF d437b_i_travel IN LOCAL MODE
* ENTITY travel
* FIELDS ( agencyid ) WITH CORRESPONDING #( keys )
* RESULT DATA(lt_travel).
      LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<ls_travel>).
        AUTHORITY-CHECK OBJECT 'S_AGENCY'
        ID 'AGENCYNUM' FIELD <ls_travel>-agencyid
        ID 'ACTVT' FIELD '02'.

        IF sy-subrc <> 0.
          "Use simulation of different roles for different users
          DATA(lv_subrc) = cl_s4d437_model=>authority_check(
          EXPORTING
          iv_agencynum = <ls_travel>-agencyid
          iv_actvt = '02'
          ).
          IF lv_subrc <> 0.
            APPEND VALUE #( %tky = <ls_travel>-%tky
            %update = if_abap_behv=>auth-unauthorized
            %action-set_to_cancelled =
           if_abap_behv=>auth-unauthorized
            )
            TO result.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.

  METHOD validateCustomer.

* for message object
    DATA lo_msg TYPE REF TO cm_devs4d437.
* work areas for response parameters
    DATA ls_reported_travel LIKE LINE OF reported-z10_i_travel.
    DATA ls_failed_travel LIKE LINE OF failed-z10_i_travel.
* read required data
**********************************************************************
    READ ENTITY IN LOCAL MODE z10_i_travel
    FIELDS ( customerid ) WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).
    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<ls_travel>).
* validate data and create message object in case of error
**********************************************************************
      IF <ls_travel>-customerid IS INITIAL.
        "error because of initial input field
        CREATE OBJECT lo_msg
          EXPORTING
            textid   = cm_devs4d437=>field_empty
            severity = cm_devs4d437=>severity-error.
        " expression-based alternative
* lo_msg = new #( textid = cm_devs4d437=>field_empty
* severity = cm_devs4d437=>severity-error ).
      ELSE.
        "existence check for customer
        SELECT SINGLE @abap_true
        FROM d437_i_customer
        INTO @DATA(lv_exists)
        WHERE customer = @<ls_travel>-customerid.
        IF lv_exists <> abap_true.
          " error because of non-existent customer
          CREATE OBJECT lo_msg
            EXPORTING
              textid     = cm_devs4d437=>customer_not_exist
              customerid = <ls_travel>-customerid
              severity   = cm_devs4d437=>severity-error.
          " expression-based alternative
* lo_msg = new #(
* textid = cm_devs4d437=>customer_not_exist
* customerid = <ls_travel>-customerid

* severity = cm_devs4d437=>severity-error
* ).
        ENDIF.
      ENDIF.
* report message and mark flight travel as failed
**********************************************************************
      IF lo_msg IS BOUND.
        CLEAR ls_failed_travel.
        MOVE-CORRESPONDING <ls_travel> TO ls_failed_travel.
        APPEND ls_failed_travel TO failed-z10_i_travel.
        CLEAR ls_reported_travel.
        MOVE-CORRESPONDING <ls_travel> TO ls_reported_travel.
        ls_reported_travel-%element-customerid = if_abap_behv=>mk-on.
        ls_reported_travel-%msg = lo_msg.
        APPEND ls_reported_travel TO reported-z10_i_travel.
        " expression-based alternative without helper variables
* APPEND CRRESPONDING #( <ls_travel> )
* TO failed-travel.
*
* APPEND VALUE #(
* %tky = <ls_travel>-%ky
* %element = VALUE #( custmerid = if_abap_behv=>mk-on )
* %msg = NEW cm_devs4d437
* textid = cm_devs4d437=>customr_not_exist
* customerid = <ls_travel>-cusomerid
* sevrity = cm_devs4d437=>sverity-error
* )
* )
* TO reported-travel.
*
        CLEAR lo_msg.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD determineSemanticKey.

    " GET AgencyID for all NEW travels
    DATA(lv_agencyid) = cl_s4d437_model=>get_agency_by_user( ).
    MODIFY ENTITY IN LOCAL MODE z10_i_travel
        UPDATE FIELDS ( agencyid travelid )
        WITH VALUE #( FOR key IN keys
            (
                %tky = key-%tky
                agencyid = lv_agencyid
                travelid = cl_s4d437_model=>get_next_travelid_for_agency( iv_agencynum = lv_agencyid )
            )
        )
    REPORTED DATA(ls_reported).
    reported = CORRESPONDING #( DEEP ls_reported ).

  ENDMETHOD.

  METHOD get_features.

    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
    READ ENTITY IN LOCAL MODE z10_i_travel
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_travel).

    result =
     VALUE #( FOR <travel> IN lt_travel
     (
     "key
     %tky = <travel>-%tky
     "action control
     %features-%action-set_to_cancelled
     = COND #(
        WHEN <travel>-status = 'C'
            THEN
                if_abap_behv=>fc-o-disabled
        WHEN <travel>-enddate IS NOT INITIAL AND <travel>-enddate <= lv_today
            THEN
                if_abap_behv=>fc-o-disabled
        ELSE
            if_abap_behv=>fc-o-enabled
     )
     "operation control

     %features-%update
     = COND #(
        WHEN <travel>-status = 'C'
            THEN if_abap_behv=>fc-o-disabled
        WHEN <travel>-enddate IS NOT INITIAL AND <travel>-enddate <= lv_today
            THEN if_abap_behv=>fc-o-disabled
        ELSE if_abap_behv=>fc-o-enabled
     )
     "field control
     %features-%field-startdate
     = COND #(
        WHEN <travel>-startdate IS NOT INITIAL AND <travel>-startdate <= lv_today
            THEN if_abap_behv=>fc-f-read_only
        ELSE if_abap_behv=>fc-f-mandatory
     )
     %features-%field-customerid
     = COND #(
         WHEN <travel>-startdate IS NOT INITIAL AND <travel>-startdate <= lv_today
            THEN if_abap_behv=>fc-f-read_only
            ELSE if_abap_behv=>fc-f-mandatory
         )
        )
     ).



  ENDMETHOD.

ENDCLASS.
