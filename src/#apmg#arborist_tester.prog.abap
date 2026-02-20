************************************************************************
* Arborist
*
* Copyright 2026 apm.to Inc. <https://apm.to>
* SPDX-License-Identifier: MIT
************************************************************************
REPORT /apmg/arborist_tester.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME.
  PARAMETERS:
    p_reg  TYPE string LOWER CASE OBLIGATORY DEFAULT 'https://registry.abappm.com',
    p_deps AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK b2.

START-OF-SELECTION.

  TRY.
      DATA(arborist) = /apmg/cl_arborist=>factory(
        registry                 = p_reg
        with_bundle_dependencies = p_deps ).

      DATA(tree) = arborist->load_actual_tree( ).

    CATCH cx_root INTO DATA(error).
      cl_abap_browser=>show_html( html_string = error->get_text( ) ).
      RETURN.
  ENDTRY.

  WRITE / 'Log:' COLOR COL_HEADING.
  SKIP.

  DATA(log) = arborist->get_log( ).

  LOOP AT log ASSIGNING FIELD-SYMBOL(<log>).
    WRITE: / <log>-type, <log>-message, <log>-name, <log>-version, <log>-spec.
  ENDLOOP.

  SKIP.
  ULINE.
  WRITE / 'Tree:' COLOR COL_HEADING.
  SKIP.
  WRITE: / 'Name @ Version', AT 55 'Package',
    AT 100 'Type', AT 105 'Prod', AT 110 'Dev', AT 115 'Opt', AT 120 'Peer', AT 130 'Status'.

  SKIP.

  LOOP AT tree ASSIGNING FIELD-SYMBOL(<node>).
    WRITE: / |{ <node>->name }: { <node>->version }| COLOR COL_KEY INTENSIFIED, AT 55 <node>->package,
      AT 100 '-',
      AT 105 lines( <node>->dependencies ) LEFT-JUSTIFIED,
      AT 110 lines( <node>->dev_dependencies ) LEFT-JUSTIFIED,
      AT 115 lines( <node>->optional_dependencies ) LEFT-JUSTIFIED,
      AT 120 lines( <node>->peer_dependencies ) LEFT-JUSTIFIED.

    IF <node>->errors IS INITIAL.
      WRITE: AT 130 'ok' COLOR COL_POSITIVE, |({ <node>->installed })|.
    ELSE.
      WRITE: AT 130 |{ lines( <node>->errors ) } errors| COLOR COL_NEGATIVE, |({ <node>->installed })|.
    ENDIF.
    SKIP.

    IF <node>->edges_out IS NOT INITIAL.
      WRITE AT /5 'Edges Out >' COLOR COL_NORMAL.
      SKIP.

      LOOP AT <node>->edges_out ASSIGNING FIELD-SYMBOL(<edge>).
        WRITE: AT /5 |{ <edge>->from->name } > { <edge>->to->name }|,
          AT 55 |{ <edge>->name }: { <edge>->spec }| COLOR COL_NORMAL, AT 100 <edge>->type.
        IF <edge>->error IS INITIAL.
          WRITE: AT 130 'ok' COLOR COL_POSITIVE, |({ <edge>->valid })|.
        ELSE.
          WRITE: AT 130 <edge>->error COLOR COL_NEGATIVE, |({ <edge>->valid })|.
        ENDIF.
      ENDLOOP.
      SKIP.
    ENDIF.

    IF <node>->edges_in IS NOT INITIAL.
      WRITE AT /5 '> Edges In' COLOR COL_NORMAL.
      SKIP.

      LOOP AT <node>->edges_in ASSIGNING <edge>.
        WRITE: AT /5 |{ <edge>->from->name } > { <edge>->to->name }|,
          AT 55 |{ <edge>->name }: { <edge>->spec }| COLOR COL_NORMAL, AT 100 <edge>->type.
        IF <edge>->error IS INITIAL.
          WRITE: AT 130 'ok' COLOR COL_POSITIVE, |({ <edge>->valid })|.
        ELSE.
          WRITE: AT 130 <edge>->error COLOR COL_NEGATIVE, |({ <edge>->valid })|.
        ENDIF.
      ENDLOOP.
      SKIP.
    ENDIF.

    SKIP.
  ENDLOOP.
