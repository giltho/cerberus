(* generated by Ott 0.21.2 from: AilTypes_.ott *)

Require Import Common.
Require Import Bool.
Require Import List.

Inductive integerBaseType : Set :=  (*r standard signed integer types (\S6.2.5\#4) *)
 | Ichar : integerBaseType (*r corresponds to \textbf{signed/unsigned char} *)
 | Short : integerBaseType (*r corresponds to \textbf{short int} *)
 | Int : integerBaseType
 | Long : integerBaseType (*r corresponds to \textbf{long int} *)
 | LongLong : integerBaseType (*r corresponds to \textbf{long long int} *).

Definition eq_integerBaseType x y :=
  match x, y with
  | Ichar   , Ichar    => true
  | Short   , Short    => true
  | Int     , Int      => true
  | Long    , Long     => true
  | LongLong, LongLong => true
  | _       , _        => false
  end.

Inductive integerType : Set :=  (*r integer types (\S6.2.5\#17) *)
 | Char : integerType
 | Bool : integerType (*r corresponds to \textbf{\_Bool} *)
 | Signed (ibt:integerBaseType)
 | Unsigned (ibt:integerBaseType).

Definition eq_integerType x y :=
  match x, y with
  | Char         , Char          => true
  | Bool         , Bool          => true
  | Signed   ibt1, Signed   ibt2 => eq_integerBaseType ibt1 ibt2
  | Unsigned ibt1, Unsigned ibt2 => eq_integerBaseType ibt1 ibt2
  | _            , _             => false
  end.

Record qualifiers := make_qualifiers {
  const    : bool;
  restrict : bool;
  volatile : bool
}.

Definition no_qualifiers := {|
  const    := false;
  restrict := false;
  volatile := false 
|}.

Definition eq_qualifiers x y := 
     Bool.eqb (const    x) (const    y)
  && Bool.eqb (restrict x) (restrict y)
  && Bool.eqb (volatile x) (volatile y).

Inductive basicType : Set :=  (*r basic types (\S6.2.5\#14) *)
 | Integer (it:integerType).

Definition eq_basicType x y :=
  match x, y with
  | Integer x, Integer y => eq_integerType x y
  end.

Inductive ctype : Set :=  (*r $\texttt{Ail}_\tau$ types *)
 | Void : ctype (*r \texttt{void} type (\S6.2.5\#19) *)
 | Basic (bt:basicType) (*r basic types (\S6.2.5\#14) *)
 | Array (t:ctype) (n:nat) (*r array types (\S6.2.5\#20) *)
 | Function (t:ctype) (p:list (qualifiers * ctype)) (*r function types *)
 | Pointer (q:qualifiers) (t:ctype) (*r pointer types *).

Definition eq_params_aux eq_ctype :=
  fix eq_params (p1 p2 : list (qualifiers * ctype)) : bool :=
    match p1, p2 with
    | nil            , nil             => true
    | cons (q1,t1) p1, cons (q2,t2) p2 => eq_qualifiers q1 q2 && eq_ctype t1 t2 && eq_params p1 p2
    | _              , _               => false
    end.

Fixpoint eq_ctype x y :=
  let eq_params := eq_params_aux eq_ctype in
  match x, y with
  | Void          , Void           => true
  | Basic    bt1  , Basic bt2      => eq_basicType bt1 bt2
  | Array    t1 n1, Array    t2 n2 => eq_ctype t1 t2 && eq_nat n1 n2
  | Function t1 p1, Function t2 p2 => eq_ctype t1 t2 && eq_params p1 p2
  | Pointer  q1 t1, Pointer  q2 t2 => eq_qualifiers q1 q2 && eq_ctype t1 t2
  | _             , _              => false
  end.

Definition eq_params := eq_params_aux eq_ctype.

Inductive typeCategory : Set := 
 | LValueType (q:qualifiers) (t:ctype)
 | RValueType (t:ctype).

Definition eq_typeCategory x y : bool :=
  match x, y with
  | LValueType q1  t1, LValueType q2  t2 => eq_ctype t1 t2 && eq_qualifiers q1 q2
  | RValueType     t1, RValueType     t2 => eq_ctype t1 t2
  | _                , _                 => false
  end.

Inductive storageDuration : Set :=  (*r storage duration (\S6.2.4\#1) *)
 | Static : storageDuration
 | Thread : storageDuration
 | Automatic : storageDuration
 | Allocated : storageDuration.

Definition eq_storageDuration x y : bool := 
  match x, y with
  | Static   , Static    => true
  | Thread   , Thread    => true
  | Automatic, Automatic => true
  | Allocated, Allocated => true
  | _        , _         => false
  end.