*&---------------------------------------------------------------------*
*& Report d437b_eml_s1
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z10_eml_1 MESSAGE-ID devs4d437.

PARAMETERS pa_guid TYPE s_trguid DEFAULT '005056044E851EDE95BFA350885ECB09'.
PARAMETERS pa_stat TYPE s_status VALUE CHECK.

* Data declarations for read access

DATA gt_read_import TYPE TABLE FOR READ IMPORT z10_i_travel.
DATA gs_read_import TYPE STRUCTURE FOR READ IMPORT z10_i_travel.
DATA gt_read_result TYPE TABLE FOR READ RESULT z10_i_travel.
DATA gs_read_result TYPE STRUCTURE FOR READ RESULT z10_i_travel.

* Data declarations for update access

DATA gt_update_import TYPE TABLE FOR UPDATE z10_i_travel.
DATA gs_update_import TYPE STRUCTURE FOR UPDATE z10_i_travel.

* Data declarations for response

DATA gs_failed TYPE RESPONSE FOR FAILED z10_i_travel.
DATA gs_reported TYPE RESPONSE FOR REPORTED z10_i_travel.


START-OF-SELECTION.

* Read the RAP BO entity to check for current status
*---------------------------------------------------*
  READ ENTITY z10_i_travel
      ALL FIELDS WITH gt_read_import
      RESULT gt_read_result
      FAILED gs_failed.

  IF gs_failed IS NOT INITIAL.
    MESSAGE e110 WITH pa_guid pa_stat.
  ENDIF.


* Update RAP BO with new status
*-------------------------------*

  gs_update_import-%tky-Trguid = pa_guid.
  gs_update_import-status = pa_stat.

  APPEND gs_update_import TO gt_update_import.

  MODIFY ENTITY z10_i_travel
   UPDATE FIELDS (  status ) WITH gt_update_import
   FAILED gs_failed.


  IF gs_failed IS NOT INITIAL.
    ROLLBACK ENTITIES.
    MESSAGE e102 WITH pa_guid.
  ELSE.
    COMMIT ENTITIES.
    WRITE: / 'Status of instance', pa_guid,
             'successfully set to', pa_stat.

  ENDIF.




  WRITE: / 'Status of instance', pa_guid, 'successfully set to', pa_stat.
