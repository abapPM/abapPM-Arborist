CLASS ltcl_node DEFINITION FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS preserves_manifest FOR TESTING.
    METHODS synchronizes_manifest FOR TESTING.
    METHODS clone_is_independent FOR TESTING.

ENDCLASS.


CLASS ltcl_node IMPLEMENTATION.

  METHOD clone_is_independent.

    DATA(tree) = NEW /apmg/cl_arborist_tree( ).
    tree->add_node(
      package  = 'ZACTUAL'
      manifest = VALUE #(
        name        = 'root'
        version     = '1.0.0'
        sap_package = VALUE #( default = 'ZDEFAULT' ) ) ).

    DATA(clone) = tree->clone( ).
    DATA(clone_node) = clone->get_by_name( 'root' ).
    clone_node->update_manifest( VALUE #(
      name        = 'root'
      version     = '2.0.0'
      sap_package = VALUE #( default = 'ZCHANGED' ) ) ).

    cl_abap_unit_assert=>assert_equals(
      act = tree->get_by_name( 'root' )->version
      exp = '1.0.0' ).
    cl_abap_unit_assert=>assert_equals(
      act = tree->get_by_name( 'root' )->get_manifest( )-sap_package-default
      exp = 'ZDEFAULT' ).
    cl_abap_unit_assert=>assert_equals( act = clone_node->package exp = 'ZACTUAL' ).

  ENDMETHOD.


  METHOD preserves_manifest.

    DATA(node) = NEW /apmg/cl_arborist_node(
      installed = abap_false
      manifest  = VALUE #(
        name        = 'full-manifest'
        version     = '1.2.3'
        deprecated  = 'Use replacement'
        sap_package = VALUE #( default = 'ZDEFAULT' )
        dist        = VALUE #(
          tarball   = 'https://registry.example/full-manifest.tgz'
          integrity = 'sha512-example' ) ) ).

    DATA(manifest) = node->get_manifest( ).
    cl_abap_unit_assert=>assert_equals( act = manifest-sap_package-default exp = 'ZDEFAULT' ).
    cl_abap_unit_assert=>assert_equals(
      act = manifest-dist-tarball
      exp = 'https://registry.example/full-manifest.tgz' ).
    cl_abap_unit_assert=>assert_equals( act = manifest-dist-integrity exp = 'sha512-example' ).
    cl_abap_unit_assert=>assert_equals( act = manifest-deprecated exp = 'Use replacement' ).

  ENDMETHOD.


  METHOD synchronizes_manifest.

    DATA(node) = NEW /apmg/cl_arborist_node(
      manifest = VALUE #( name = 'package' version = '1.0.0' ) ).

    node->update_manifest( VALUE #(
      name                  = 'package'
      version               = '2.0.0'
      dependencies          = VALUE #( ( key = 'prod' range = '^2' ) )
      dev_dependencies      = VALUE #( ( key = 'dev' range = '^1' ) )
      optional_dependencies = VALUE #( ( key = 'optional' range = '*' ) )
      peer_dependencies     = VALUE #( ( key = 'peer' range = '^3' ) )
      bundle_dependencies   = VALUE #( ( table_line = 'bundled' ) ) ) ).

    cl_abap_unit_assert=>assert_equals( act = node->version exp = '2.0.0' ).
    cl_abap_unit_assert=>assert_equals( act = lines( node->dependencies ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lines( node->dev_dependencies ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lines( node->optional_dependencies ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lines( node->peer_dependencies ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lines( node->bundle_dependencies ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = node->get_target_version( ) exp = '2.0.0' ).

  ENDMETHOD.

ENDCLASS.
