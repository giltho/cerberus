(* *********************************************************************)
(*                                                                     *)
(*              The Compcert verified compiler                         *)
(*                                                                     *)
(*          Xavier Leroy, INRIA Paris-Rocquencourt                     *)
(*                                                                     *)
(*  Copyright Institut National de Recherche en Informatique et en     *)
(*  Automatique.  All rights reserved.  This file is distributed       *)
(*  under the terms of the INRIA Non-Commercial License Agreement.     *)
(*                                                                     *)
(* *********************************************************************)

(** Constructions of ordered types, for use with the [FSet] functors
  for finite sets and the [FMap] functors for finite maps. *)

Require Import FSets.
Require Import Coqlib.
Require Import Maps.
Require Import Integers.

(** The ordered type of positive numbers *)

Module OrderedPositive <: OrderedType.

Definition t := positive.
Definition eq (x y: t) := x = y.
Definition lt := Plt.

Lemma eq_refl : forall x : t, eq x x.
Proof (@refl_equal t). 
Lemma eq_sym : forall x y : t, eq x y -> eq y x.
Proof (@sym_equal t).
Lemma eq_trans : forall x y z : t, eq x y -> eq y z -> eq x z.
Proof (@trans_equal t).
Lemma lt_trans : forall x y z : t, lt x y -> lt y z -> lt x z.
Proof Plt_trans.
Lemma lt_not_eq : forall x y : t, lt x y -> ~ eq x y.
Proof Plt_ne.
Lemma compare : forall x y : t, Compare lt eq x y.
Proof.
  intros. case (plt x y); intro.
  apply LT. auto.
  case (peq x y); intro.
  apply EQ. auto.
  apply GT. red; unfold Plt in *. 
  assert (Zpos x <> Zpos y). congruence. omega.
Qed.

Definition eq_dec : forall x y, { eq x y } + { ~ eq x y } := peq.

End OrderedPositive.

(** The ordered type of machine integers *)

Module OrderedInt <: OrderedType.

Variable wordsize_one: nat.
Definition t := Int.int wordsize_one.
Definition eq (x y: t) := x = y.
Definition lt (x y: t) := 
  Int.unsigned wordsize_one x < Int.unsigned wordsize_one y.

Lemma eq_refl : forall x : t, eq x x.
Proof (@refl_equal t). 
Lemma eq_sym : forall x y : t, eq x y -> eq y x.
Proof (@sym_equal t).
Lemma eq_trans : forall x y z : t, eq x y -> eq y z -> eq x z.
Proof (@trans_equal t).
Lemma lt_trans : forall x y z : t, lt x y -> lt y z -> lt x z.
Proof.
  unfold lt; intros. omega.
Qed.
Lemma lt_not_eq : forall x y : t, lt x y -> ~ eq x y.
Proof.
  unfold lt,eq; intros; red; intros. subst. omega.
Qed.
Lemma compare : forall x y : t, Compare lt eq x y.
Proof.
  intros. 
  destruct (zlt (Int.unsigned wordsize_one x) (Int.unsigned wordsize_one y)).
  apply LT. auto.
  destruct (Int.eq_dec wordsize_one x y).
  apply EQ. auto.
  apply GT.
  assert (Int.unsigned wordsize_one x <> Int.unsigned wordsize_one y).
    red; intros. rewrite <- (Int.repr_unsigned wordsize_one x) in n. 
      rewrite <- (Int.repr_unsigned wordsize_one y) in n. congruence.
  red. omega.
Qed.

Definition eq_dec : forall x y, { eq x y } + { ~ eq x y } := 
  Int.eq_dec wordsize_one.

End OrderedInt.

(** Indexed types (those that inject into [positive]) are ordered. *)

Module OrderedIndexed(A: INDEXED_TYPE) <: OrderedType.

Definition t := A.t.
Definition eq (x y: t) := x = y.
Definition lt (x y: t) := Plt (A.index x) (A.index y).

Lemma eq_refl : forall x : t, eq x x.
Proof (@refl_equal t). 
Lemma eq_sym : forall x y : t, eq x y -> eq y x.
Proof (@sym_equal t).
Lemma eq_trans : forall x y z : t, eq x y -> eq y z -> eq x z.
Proof (@trans_equal t).

Lemma lt_trans : forall x y z : t, lt x y -> lt y z -> lt x z.
Proof.
  unfold lt; intros. eapply Plt_trans; eauto.
Qed.

Lemma lt_not_eq : forall x y : t, lt x y -> ~ eq x y.
Proof.
  unfold lt; unfold eq; intros.
  red; intro. subst y. apply Plt_strict with (A.index x). auto.
Qed.

Lemma compare : forall x y : t, Compare lt eq x y.
Proof.
  intros. case (OrderedPositive.compare (A.index x) (A.index y)); intro.
  apply LT. exact l. 
  apply EQ. red; red in e. apply A.index_inj; auto.
  apply GT. exact l.
Qed.

Lemma eq_dec : forall x y, { eq x y } + { ~ eq x y }.
Proof.
  intros. case (peq (A.index x) (A.index y)); intros.
  left. apply A.index_inj; auto.
  right; red; unfold eq; intros; subst. congruence. 
Qed.

End OrderedIndexed.

(** The product of two ordered types is ordered. *)

Module OrderedPair (A B: OrderedType) <: OrderedType.

Definition t := (A.t * B.t)%type.

Definition eq (x y: t) :=
  A.eq (fst x) (fst y) /\ B.eq (snd x) (snd y).

Lemma eq_refl : forall x : t, eq x x.
Proof.
  intros; split; auto.
Qed.

Lemma eq_sym : forall x y : t, eq x y -> eq y x.
Proof.
  unfold eq; intros. intuition auto.
Qed.

Lemma eq_trans : forall x y z : t, eq x y -> eq y z -> eq x z.
Proof.
  unfold eq; intros. intuition eauto.
Qed.

Definition lt (x y: t) :=
  A.lt (fst x) (fst y) \/
  (A.eq (fst x) (fst y) /\ B.lt (snd x) (snd y)).

Lemma lt_trans : forall x y z : t, lt x y -> lt y z -> lt x z.
Proof.
  unfold lt; intros.
  elim H; elim H0; intros.

  left. apply A.lt_trans with (fst y); auto.

  left.  elim H1; intros.
  case (A.compare (fst x) (fst z)); intro.
  assumption.
  generalize (A.lt_not_eq H2); intro. elim H5.
  apply A.eq_trans with (fst z). auto. auto.
  generalize (@A.lt_not_eq (fst z) (fst y)); intro.
  elim H5. apply A.lt_trans with (fst x); auto.
  apply A.eq_sym; auto.

  left. elim H2; intros.
  case (A.compare (fst x) (fst z)); intro.
  assumption.
  generalize (A.lt_not_eq H1); intro. elim H5.
  apply A.eq_trans with (fst x). 
  apply A.eq_sym. auto. auto.
  generalize (@A.lt_not_eq (fst y) (fst x)); intro.
  elim H5. apply A.lt_trans with (fst z); auto.
  apply A.eq_sym; auto.

  right. elim H1; elim H2; intros.
  split. apply A.eq_trans with (fst y); auto.
  apply B.lt_trans with (snd y); auto.
Qed.

Lemma lt_not_eq : forall x y : t, lt x y -> ~ eq x y.
Proof.
  unfold lt, eq, not; intros.
  elim H0; intros.
  elim H; intro.
  apply (@A.lt_not_eq _ _ H3 H1).
  elim H3; intros.
  apply (@B.lt_not_eq _ _ H5 H2).
Qed.
  
Lemma compare : forall x y : t, Compare lt eq x y.
Proof.
  intros.
  case (A.compare (fst x) (fst y)); intro.
  apply LT. red. left. auto.
  case (B.compare (snd x) (snd y)); intro.
  apply LT. red. right. tauto.
  apply EQ. red. tauto.
  apply GT. red. right. split. apply A.eq_sym. auto. auto.
  apply GT. red. left. auto.
Qed.

Lemma eq_dec : forall x y, { eq x y } + { ~ eq x y }.
Proof.
  unfold eq; intros.
  case (A.eq_dec (fst x) (fst y)); intros.
  case (B.eq_dec (snd x) (snd y)); intros.
  left; auto.
  right; intuition.
  right; intuition.
Qed.

End OrderedPair.

(*
*** Local Variables: ***
*** coq-prog-name: "coqtop" ***
*** coq-prog-args: ("-emacs-U" "-I" "../") ***
*** End: ***
 *)
