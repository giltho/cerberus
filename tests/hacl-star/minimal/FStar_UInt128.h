/* This file was generated by KreMLin <https://github.com/FStarLang/kremlin>
 * KreMLin invocation: ../krml -fparentheses -fcurly-braces -fno-shadow -minimal -tmpdir dist/minimal -skip-compilation -extract-uints -add-include <inttypes.h> -add-include <stdbool.h> -add-include "kremlin/internal/compat.h" -add-include "kremlin/c_endianness.h" -add-include "kremlin/internal/types.h" -bundle FStar.UInt64+FStar.UInt32+FStar.UInt16+FStar.UInt8=[rename=FStar_UInt_8_16_32_64] -bundle C.Endianness= -library FStar.UInt128 -bundle FStar.UInt128= -bundle *,WindowsWorkaroundSigh fstar_uint128.c -o libkremlib.a .extract/prims.krml .extract/FStar_Pervasives_Native.krml .extract/FStar_Pervasives.krml .extract/FStar_Mul.krml .extract/FStar_Squash.krml .extract/FStar_Classical.krml .extract/FStar_StrongExcludedMiddle.krml .extract/FStar_FunctionalExtensionality.krml .extract/FStar_List_Tot_Base.krml .extract/FStar_List_Tot_Properties.krml .extract/FStar_List_Tot.krml .extract/FStar_Seq_Base.krml .extract/FStar_Seq_Properties.krml .extract/FStar_Seq.krml .extract/FStar_Math_Lib.krml .extract/FStar_Math_Lemmas.krml .extract/FStar_BitVector.krml .extract/FStar_UInt.krml .extract/FStar_UInt32.krml .extract/FStar_Int.krml .extract/FStar_Int16.krml .extract/FStar_Preorder.krml .extract/FStar_Ghost.krml .extract/FStar_ErasedLogic.krml .extract/FStar_UInt64.krml .extract/FStar_Set.krml .extract/FStar_PropositionalExtensionality.krml .extract/FStar_PredicateExtensionality.krml .extract/FStar_TSet.krml .extract/FStar_Monotonic_Heap.krml .extract/FStar_Heap.krml .extract/FStar_Map.krml .extract/FStar_Monotonic_HyperHeap.krml .extract/FStar_Monotonic_HyperStack.krml .extract/FStar_HyperStack.krml .extract/FStar_Monotonic_Witnessed.krml .extract/FStar_HyperStack_ST.krml .extract/FStar_HyperStack_All.krml .extract/FStar_Date.krml .extract/FStar_Universe.krml .extract/FStar_GSet.krml .extract/FStar_ModifiesGen.krml .extract/LowStar_Monotonic_Buffer.krml .extract/LowStar_Buffer.krml .extract/Spec_Loops.krml .extract/LowStar_BufferOps.krml .extract/C_Loops.krml .extract/FStar_UInt8.krml .extract/FStar_Kremlin_Endianness.krml .extract/FStar_UInt63.krml .extract/FStar_Exn.krml .extract/FStar_ST.krml .extract/FStar_All.krml .extract/FStar_Dyn.krml .extract/FStar_Int63.krml .extract/FStar_Int64.krml .extract/FStar_Int32.krml .extract/FStar_Int8.krml .extract/FStar_UInt16.krml .extract/FStar_Int_Cast.krml .extract/FStar_UInt128.krml .extract/C_Endianness.krml .extract/FStar_List.krml .extract/FStar_Float.krml .extract/FStar_IO.krml .extract/C.krml .extract/FStar_Char.krml .extract/FStar_String.krml .extract/LowStar_Modifies.krml .extract/C_String.krml .extract/FStar_Bytes.krml .extract/FStar_HyperStack_IO.krml .extract/C_Failure.krml .extract/TestLib.krml .extract/FStar_Int_Cast_Full.krml
 * F* version: 8f0ddba4
 * KreMLin version: 9768dccd
 */


#ifndef __FStar_UInt128_H
#define __FStar_UInt128_H

#include "FStar_UInt_8_16_32_64.h"
#include <inttypes.h>
#include <stdbool.h>
#include "kremlin/internal/compat.h"
#include "kremlin/c_endianness.h"
#include "kremlin/internal/types.h"

extern uint64_t FStar_UInt128___proj__Mkuint128__item__low(FStar_UInt128_uint128 x0);

extern uint64_t FStar_UInt128___proj__Mkuint128__item__high(FStar_UInt128_uint128 x0);

typedef FStar_UInt128_uint128 FStar_UInt128_t;

extern FStar_UInt128_uint128
FStar_UInt128_add(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128
FStar_UInt128_add_underspec(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128
FStar_UInt128_add_mod(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128
FStar_UInt128_sub(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128
FStar_UInt128_sub_underspec(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128
FStar_UInt128_sub_mod(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128
FStar_UInt128_logand(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128
FStar_UInt128_logxor(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128
FStar_UInt128_logor(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128 FStar_UInt128_lognot(FStar_UInt128_uint128 x0);

extern FStar_UInt128_uint128 FStar_UInt128_shift_left(FStar_UInt128_uint128 x0, uint32_t x1);

extern FStar_UInt128_uint128 FStar_UInt128_shift_right(FStar_UInt128_uint128 x0, uint32_t x1);

extern bool FStar_UInt128_eq(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern bool FStar_UInt128_gt(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern bool FStar_UInt128_lt(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern bool FStar_UInt128_gte(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern bool FStar_UInt128_lte(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128
FStar_UInt128_eq_mask(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128
FStar_UInt128_gte_mask(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128 FStar_UInt128_uint64_to_uint128(uint64_t x0);

extern uint64_t FStar_UInt128_uint128_to_uint64(FStar_UInt128_uint128 x0);

extern FStar_UInt128_uint128
FStar_UInt128_op_Plus_Hat(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128
FStar_UInt128_op_Plus_Question_Hat(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128
FStar_UInt128_op_Plus_Percent_Hat(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128
FStar_UInt128_op_Subtraction_Hat(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128
FStar_UInt128_op_Subtraction_Question_Hat(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128
FStar_UInt128_op_Subtraction_Percent_Hat(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128
FStar_UInt128_op_Amp_Hat(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128
FStar_UInt128_op_Hat_Hat(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128
FStar_UInt128_op_Bar_Hat(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128
FStar_UInt128_op_Less_Less_Hat(FStar_UInt128_uint128 x0, uint32_t x1);

extern FStar_UInt128_uint128
FStar_UInt128_op_Greater_Greater_Hat(FStar_UInt128_uint128 x0, uint32_t x1);

extern bool FStar_UInt128_op_Equals_Hat(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern bool FStar_UInt128_op_Greater_Hat(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern bool FStar_UInt128_op_Less_Hat(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern bool
FStar_UInt128_op_Greater_Equals_Hat(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern bool
FStar_UInt128_op_Less_Equals_Hat(FStar_UInt128_uint128 x0, FStar_UInt128_uint128 x1);

extern FStar_UInt128_uint128 FStar_UInt128_mul32(uint64_t x0, uint32_t x1);

extern FStar_UInt128_uint128 FStar_UInt128_mul_wide(uint64_t x0, uint64_t x1);

#define __FStar_UInt128_H_DEFINED
#endif
