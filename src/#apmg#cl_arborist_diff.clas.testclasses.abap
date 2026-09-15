CLASS ltcl_diff DEFINITION FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS circular_order FOR TESTING.
    METHODS complete_change_nodes FOR TESTING.

ENDCLASS.


CLASS ltcl_diff IMPLEMENTATION.

  METHOD circular_order.

    DATA(actual) = NEW /apmg/cl_arborist_tree( ).
    DATA(ideal) = NEW /apmg/cl_arborist_tree( ).
    DATA(root) = ideal->add_node(
      manifest  = VALUE #( name = 'root' version = '1.0.0' )
      installed = abap_false ).
    DATA(a) = ideal->add_node(
      manifest  = VALUE #( name = 'a' version = '1.0.0' )
      installed = abap_false ).
    ideal->add_node(
      manifest  = VALUE #( name = 'b' version = '1.0.0' )
      installed = abap_false ).

    /apmg/cl_arborist_edge=>create(
      tree = ideal
      from = root
      type = /apmg/if_arborist=>c_dependency_type-prod
      name = 'a'
      spec = '*' ).
    /apmg/cl_arborist_edge=>create(
      tree = ideal
      from = root
      type = /apmg/if_arborist=>c_dependency_type-prod
      name = 'b'
      spec = '*' ).
    /apmg/cl_arborist_edge=>create(
      tree = ideal
      from = a
      type = /apmg/if_arborist=>c_dependency_type-prod
      name = 'root'
      spec = '*' ).

    DATA(diff) = /apmg/cl_arborist_diff=>calculate( actual = actual ideal = ideal ).
    DATA(changes) = diff->/apmg/if_arborist_diff~get_changes( 'root' ).

    cl_abap_unit_assert=>assert_equals( act = lines( changes ) exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = changes[ 1 ]->get_ideal( )->name exp = 'a' ).
    cl_abap_unit_assert=>assert_equals( act = changes[ 2 ]->get_ideal( )->name exp = 'b' ).
    cl_abap_unit_assert=>assert_equals( act = changes[ 3 ]->get_ideal( )->name exp = 'root' ).

  ENDMETHOD.


  METHOD complete_change_nodes.

    DATA(actual) = NEW /apmg/cl_arborist_tree( ).
    actual->add_node(
      package  = 'ZACTUAL'
      manifest = VALUE #( name = 'root' version = '1.0.0' ) ).

    DATA(ideal) = NEW /apmg/cl_arborist_tree( ).
    ideal->add_node(
      package  = 'ZACTUAL'
      manifest = VALUE #(
        name        = 'root'
        version     = '2.0.0'
        sap_package = VALUE #( default = 'ZDEFAULT' )
        dist        = VALUE #( integrity = 'sha512-target' ) ) ).

    DATA(diff) = /apmg/cl_arborist_diff=>calculate( actual = actual ideal = ideal ).
    DATA(changes) = diff->/apmg/if_arborist_diff~get_changes( 'root' ).

    cl_abap_unit_assert=>assert_equals( act = lines( changes ) exp = 1 ).
    cl_abap_unit_assert=>assert_bound( changes[ 1 ]->get_actual( ) ).
    cl_abap_unit_assert=>assert_bound( changes[ 1 ]->get_ideal( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = changes[ 1 ]->get_ideal( )->get_manifest( )-dist-integrity
      exp = 'sha512-target' ).
    cl_abap_unit_assert=>assert_equals(
      act = changes[ 1 ]->get_action( )
      exp = /apmg/if_arborist=>c_diff_action-change ).

  ENDMETHOD.

ENDCLASS.
