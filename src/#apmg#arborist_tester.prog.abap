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
    p_prod AS CHECKBOX DEFAULT 'X',
    p_add  TYPE string LOWER CASE,
    p_ver  TYPE string LOWER CASE,
    p_rm   TYPE string LOWER CASE.
SELECTION-SCREEN END OF BLOCK b2.

START-OF-SELECTION.

  TRY.
      DATA(arborist) = /apmg/cl_arborist=>factory(
        registry                 = p_reg
        with_bundle_dependencies = abap_false ).

      DATA(add_packages) = VALUE /apmg/if_arborist=>ty_add_packages( ).
      IF p_add IS NOT INITIAL AND p_ver IS NOT INITIAL.
        INSERT VALUE #(
          name    = p_add
          version = p_ver ) INTO TABLE add_packages.
      ENDIF.

      DATA(remove_packages) = VALUE string_table( ).
      IF p_rm IS NOT INITIAL.
        INSERT p_rm INTO TABLE remove_packages.
      ENDIF.

      IF add_packages IS NOT INITIAL OR remove_packages IS NOT INITIAL.
        arborist->build_ideal_tree(
          add_packages    = add_packages
          remove_packages = remove_packages
          production      = p_prod ).
        DATA(tree) = arborist->get_ideal_tree( ).
      ELSE.
        tree = arborist->load_actual_tree( ).
      ENDIF.

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

  IF add_packages IS NOT INITIAL OR remove_packages IS NOT INITIAL.
    SKIP.
    ULINE.
    WRITE / 'Diff:' COLOR COL_HEADING.
    SKIP.

    DATA(diff) = arborist->get_diff( ).
    IF diff IS BOUND.
      PERFORM print_diff USING diff 0.
    ENDIF.
  ENDIF.

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

    IF <node>->max_satisfying_version IS NOT INITIAL AND <node>->max_satisfying_version <> <node>->version.
      WRITE AT 45 |-> { <node>->max_satisfying_version }| COLOR COL_TOTAL.
    ENDIF.

    IF <node>->errors IS INITIAL.
      WRITE: AT 130 'ok' COLOR COL_POSITIVE, |({ <node>->installed })|.
    ELSE.
      WRITE: AT 130 |{ lines( <node>->errors ) } errors| COLOR COL_NEGATIVE, |({ <node>->installed })|.
      LOOP AT <node>->errors ASSIGNING FIELD-SYMBOL(<error>).
        WRITE <error> COLOR COL_NEGATIVE.
      ENDLOOP.
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
          WRITE: AT 130 <edge>->error COLOR COL_NEGATIVE, |({ <edge>->valid })|,
                 <edge>->get_error_description( ) COLOR COL_NEGATIVE.
        ENDIF.
      ENDLOOP.
      SKIP.
    ENDIF.

    IF <node>->edges_in IS NOT INITIAL.
      WRITE AT /5 'Edges In <' COLOR COL_NORMAL.
      SKIP.

      LOOP AT <node>->edges_in ASSIGNING <edge>.
        WRITE: AT /5 |{ <edge>->to->name } < { <edge>->from->name }|,
          AT 55 |{ <edge>->name }: { <edge>->spec }| COLOR COL_NORMAL, AT 100 <edge>->type.
        IF <edge>->error IS INITIAL.
          WRITE: AT 130 'ok' COLOR COL_POSITIVE, |({ <edge>->valid })|.
        ELSE.
          WRITE: AT 130 <edge>->error COLOR COL_NEGATIVE, |({ <edge>->valid })|,
                 <edge>->get_error_description( ) COLOR COL_NEGATIVE.
        ENDIF.
      ENDLOOP.
      SKIP.
    ENDIF.

    SKIP.
  ENDLOOP.

FORM print_diff USING diff TYPE REF TO /apmg/cl_arborist_diff
                      indent TYPE i.

  PERFORM print_diff_line USING diff indent.

  LOOP AT diff->children INTO DATA(child_diff).
    PERFORM print_diff USING child_diff indent + 2.
  ENDLOOP.

ENDFORM.


FORM print_diff_line USING diff TYPE REF TO /apmg/cl_arborist_diff
                           indent TYPE i.

  CHECK diff->action IS NOT INITIAL.

  DATA(indent_str) = repeat( val = ` ` occ = indent ).
  DATA(name) = COND string(
    WHEN diff->ideal IS BOUND THEN diff->ideal->name
    WHEN diff->actual IS BOUND THEN diff->actual->name
    ELSE '' ).

  WRITE: / indent_str, diff->action, name COLOR COL_KEY.

ENDFORM.
