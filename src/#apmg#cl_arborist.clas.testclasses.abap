CLASS ltcl_arborist DEFINITION FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS factory_is_fresh FOR TESTING.

ENDCLASS.


CLASS ltcl_arborist IMPLEMENTATION.

  METHOD factory_is_fresh.

    /apmg/cl_arborist=>injector( ).
    DATA(first) = /apmg/cl_arborist=>factory( 'https://registry-one.example' ).
    DATA(second) = /apmg/cl_arborist=>factory( 'https://registry-two.example' ).

    cl_abap_unit_assert=>assert_false( xsdbool( first = second ) ).

  ENDMETHOD.

ENDCLASS.
