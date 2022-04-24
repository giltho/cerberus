#!/usr/bash

citests=(
  0001-emptymain.c
  0002-return_const.c
  0003-return_arith.c
  0004-return_var.c
  0005-return_var_arith.c
  0006-return_var_unspec.c
  0007-inits.c
  0008-cond_integer.c
  0009-cond-pointer.c
  0010-if_int.c
  0011-if_pointer.c
  0012-incr_integer.c
  0013-incr_pointer.c
  0014-labels_scopes_bug.syntax-only.c
  0015-while_break.c
  0016-do_break.c
  0017-for_simple.c
  0018-lt_promotion.c
  0019-arith_promotion.c
  0020-end_of_lifetime.undef.c
  0021-fact.c
  0022-while_continue.c
#  0023-jump1.c
  0024-jump2.c
#  0025-jump3.c
  0026-jump4.c
  0027-jump5.c
  0028-division_by_zero.undef.c
  0029-modulo_by_zero.undef.c
  0030-call_arith.c
  0031-global.c
  0032-empty_struct_decl.c
  0033-duplicate.error.c
  0034-duplicate_proto.error.c
  0035-thread_local_function.error.c
  0036-auto_register_function.error.c
  0037-function_conflicting_types.error.c
  0038-function_redefinition.error.c
  0039-struct_imcomplete.error.c
  0040-struct_redefinition.error.c
  0041-struct_incompatible.error.c
  0042-struct_namespace.c
  0043-struct_shadowing.syntax-only.c
  0044-init_scalar_enclosed.c
  0045-global_postinit.c
  0046-jump_inside_lifetime.c
  0047-conditional_eq.c
  0048-conditional_eq_else.c
  0049-void_return_empty.c
  0050-void_return_arith.c
  0051-global_non_startup.c
  0052-global_not_constant.error.c
  0053-recursive_factorial5.c
  0054-while_factorial5.c
  0055-while_acc.c
  0056-unary_plus.c
  0057-std_footnote_118.c
  0058-pointer_zero_init.c
  0059-glob_coretyping.c
  0060-emptydecl.c
  0061-cond_call_e.c
  0062-cond_call_e2.c
  0063-cond_e.c
  0064-cond_e2.c
  0065-const1.error.c
  0066-const2.error.c
  0067-band1.c
  0068-bor1.c
  0070-do-while1.c
  0071-do-while2.c
  0072-example03.c
  0073-example03.c
  0074-fun_returns.c
  0075-funscoped_static.error.c
  0076-odd_even.c
  0077-register_arg.c
  0078-struct1.c
  0079-struct2.error.c
  0080-struct3.c
  0081-struct4.c
  0082-OK1.c
  0083-OK2.c
  0084-KO1.error.c
  0086-literal_access.undef.c
  0087-array_with_delayed_size.c
# 0101-sym_cfunction.c
  0105-incr.c
  0106-typedef_parsing_bug.syntax-only.c
# 0108-shifts.c
  0109-promotion_lt.c
  0110-loop_in_loop.c
  0111-skipped_label.c
  0112-call_in_label.c
  0113-cast_assign_parsing.error.c
  0114-const_return.error.c
  0115-hex_char_const.c
  0116-enum_constants.c
  0119-block_array_init_rec.c
  0126-duff_device.c
  0127-function-pointer.c
  0128-function-pointer-void-cast.c
  0129-function-pointer-wrong-args.c
  0201-main-return-type.error.c
  0202-main-not-function.error.c
  0203-main-params1.error.c
  0204-main-params2.error.c
  0205-illegal-storage-class.error.c
  0209-static-assert-failed.error.c
  0210-illegal-storage-class-function.error.c
  0211-function-id-not-function-type.error.c
  0212-function-redefinition.error.c
  0214-illegal-storage-class-for-statement.error.c
  0215-continue-outside-loop.error.c
  0216-break-outside-loop.error.c
  0217-non-void-function-return.error.c
  0218-multiple-storage-class.error.c
  0219-thread-local-function-declaration.error.c
  0223-illegal-storage-class-static-init.error.c
  0224-enum-not-int.error.c
  0225-incomplete-field.error.c
  0226-function-field.error.c
  0227-illegal-type-specs.error.c
  0228-tag-redecl.error.c
  0229-illegal-enum-construction.error.c
  0230-enum-incomplete.error.c
  0231-tag-redefinition.error.c
  0232-invalid-use-Atomic.error.c
  0233-undeclared-identifier.error.c
  0234-array-static-outside-fun-proto.error.c
  0286-binary-operator.error.c
  0287-equality.error.c
  0288-sizeof-function-type.error.c
  0289-sizeof-incomplete-type.error.c
  0289-Alignof-incomplete-type.error.c
  0290-Alignof-incomplete-type.error.c
  0291-cast-not-scalar-type.error.c
  0292-cast-pointer-to-float.error.c
  0293-compound-assignment.error.c
  0297-atomic_memberof.undef.c
  0298-atomic_memberofptr.undef.c
  0299-qualified_ptrdiff.c
  0301-declaration_struct_pointer.error.c
)

# TESTS THAT ARE KNOW TO FAIL (for example .error test for which we need to improve the message)
skip=(
  0113-cast_assign_parsing.error.c            # REAL BUG (!) -- C parser
  0082-OK1.c                                  # REAL BUG (!) -- Ail typing ==> missing default argument promotions
  0072-example03.c                            # REAL BUG (!) -- Ail typing ==> missing default argument promotions
  0074-fun_returns.c                          # IMPROVE: pprint the UB
  0129-function-pointer-wrong-args.c          # IMPROVE: pprint the UB
  0205-illegal-storage-class.error.c          # IMPROVE: the location and message should be more specific
  0210-illegal-storage-class-function.error.c # IMPROVE: the location and message should be more specific
  0211-function-id-not-function-type.error.c  # IMPROVE: improve the message?
  0212-function-redefinition.error.c          # IMPROVE: would be nicer to say that the redefinition has an incompatible type
  0286-binary-operator.error.c                # IMPROVE: improve error message (anonymous struct)
)
