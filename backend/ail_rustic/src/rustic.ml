(* TODO: shared with BMC functors *)

module Map_of_list (X : Map.S) = struct
  let of_list (l : 'a) =
    List.fold_left
      (fun mo (x, v) ->
        match mo with
        | None -> None
        | Some m ->
          (match X.find_opt x m with
          | None -> Some (X.add x v m)
          | Some _ -> None))
      (Some X.empty)
      l
end

let rec map_option_aux f acc = function
  | [] -> List.rev acc
  | x :: xs ->
    (match f x with
     | None -> map_option_aux f acc xs
     | Some y -> map_option_aux f (y :: acc) xs)

let map_option f xs = map_option_aux f [] xs

module Option_map (X : Map.S) = struct
  module Z = Map_of_list(X)

  let map (f : X.key -> 'a -> 'b option) (s : 'a X.t) =
    let m = Z.of_list (map_option (fun (k, v) -> match f k v with None -> None | Some v' -> Some (k, v')) (X.bindings s)) in
    match m with
    | None -> (* it came from a map, and entries can only be deleted, so it is still functional *) assert false
    | Some m' -> m'
end

(* TODO: end of share *)

type fn_decl =
  { fn_decl_quals : Ctype.qualifiers;
    fn_decl_retty : Ctype.ctype;
    fn_decl_argstys : (Ctype.qualifiers * Ctype.ctype * bool) list; }

let cvt_decl ((quals, retty), argstys) =
  { fn_decl_quals = quals;
    fn_decl_retty = retty;
    fn_decl_argstys = argstys; }

type 'a fn_def =
  { fn_def_attrs : Annot.attribute list;
    fn_def_ids : AilSyntax.ail_identifier list;
    fn_def_sts : 'a AilSyntax.statement; }

let cvt_def (loc, Annot.Attrs attrs, ids, sts) =
  { fn_def_attrs = attrs; 
    fn_def_ids = ids;
    fn_def_sts = sts; }

open AilSyntax

let string_of_identifier (Symbol.Identifier (_, s)) = s

let plop2 = function
| [] -> ""
| _ :: _ as l -> "(" ^ String.concat ", " l ^ ")"

let string_of_attr attr =
  string_of_identifier attr.Annot.attr_id ^ plop2 attr.Annot.attr_args

let string_of_attrs attrs =
  String.concat ", " (List.map string_of_attr attrs)

let string_of_sym (Symbol.Symbol (_, _, Some id)) = id

let string_of_fun_wo_args sym fn_def =
  string_of_sym sym ^ ": " ^ string_of_attrs fn_def.fn_def_attrs

let string_of_ty = function
| Ctype.Ctype _ -> "?"

let string_of_annots annots =
  let annots =
    map_option
      (let open Annot in function
      | Astd x -> None
      | Aloc loc -> None
      | Auid _ -> None
      | Abmc _ -> None
      | Aattrs (Attrs attrs) -> Some attrs)
      annots in
  let annots = List.concat annots in
  String.concat " " (List.map string_of_attr annots)

let rec string_of_ctype = let open Ctype in function
| Ctype (annots, cty_) ->
  string_of_annots annots ^ string_of_ctype_ cty_
and string_of_ctype_ = function
| Void -> "void"
| Basic x -> "int" (* TODO: lies *)
| Array (cty, sz) -> "array(" ^ string_of_ctype cty ^ ")"
| Function _ -> "function"
| Pointer (qls, cty) -> string_of_ctype cty ^ "*"
| Atomic cty -> "atomic(" ^ string_of_ctype cty ^ ")"
| Struct name -> string_of_sym name
| Union name -> string_of_sym name

let string_of_arg (ty, id) =
  match ty with
  | (_, cty, _) ->
    string_of_sym id ^ " : " ^ string_of_ctype cty

let string_of_args args =
  String.concat "," (List.map string_of_arg args)

let string_of_fun_w_args sym fn_decl fn_def =
  let args = List.combine fn_decl.fn_decl_argstys fn_def.fn_def_ids in
  string_of_sym sym ^ ":" ^ (match fn_def.fn_def_attrs with | [] -> "" | _::_ -> " " ^ string_of_attrs fn_def.fn_def_attrs) ^ " (" ^ string_of_args args ^ ")"

let string_of_fun = function
| (x, (Some ty, Some bod)) -> string_of_fun_w_args x ty bod
| (x, (_, Some bod)) -> string_of_fun_wo_args x bod
| (_, (None, None)) -> assert false (* ? *)
| (x, _)-> string_of_sym x ^ " no body"

let print_funs fs =
  List.iter (fun f -> print_string (string_of_fun f ^ "\n")) fs

module Ail_identifier = struct
  type t = AilSyntax.ail_identifier
  let compare (x : t) y = Symbol.symbol_compare x y
end

module Ail_identifier_map = Map.Make(Ail_identifier)
module Ail_identifier_option_map = Option_map(Ail_identifier_map)
module Ail_identifier_map_aux = Map_of_list(Ail_identifier_map)

module String_map = Map.Make(String)
module String_map_aux = Map_of_list(String_map)

let add_left id x m =
  match Ail_identifier_map.find_opt id m with
  | None -> Ail_identifier_map.add id (Some x, None) m
  | Some (_, y) -> Ail_identifier_map.add id (Some x, y) m

let add_right id y m =
  match Ail_identifier_map.find_opt id m with
  | None -> Ail_identifier_map.add id (None, Some y) m
  | Some (x, _) -> Ail_identifier_map.add id (x, Some y) m

let collect_functions s =
  let ds = map_option (function (id, (_, Decl_function (a, b, c, d, e, f))) -> Some (id, (b, c)) | (_, (_, Decl_object _)) -> None) s.declarations in
  let fs = s.function_definitions in
  let m = Ail_identifier_map.empty in
  (* this may discard stuff *)
  let m = List.fold_left (fun m (id, d) -> add_left id (cvt_decl d) m) m ds in
  let m = List.fold_left (fun m (id, f) -> add_right id (cvt_def f) m) m fs in
  m

type rc_ownership =
| RC_read
| RC_write
| RC_zap
| RC_bad

let string_of_rc_ownership = function
| RC_read -> "read"
| RC_write -> "write"
| RC_zap -> "zap"
| RC_bad -> "BAD"

type rc_type =
| RC_scalar
| RC_ptr of rc_ownership * rc_type
| RC_struct of Symbol.sym * rc_ownership
| RC_atomic of rc_type

let rec string_of_rc_type = function
| RC_scalar -> "scalar"
| RC_ptr (o, t) -> "ptr[" ^ string_of_rc_ownership o ^ "] " ^ string_of_rc_type t ^ ""
| RC_struct (id, o) -> "struct " ^ string_of_sym id ^ "[" ^ string_of_rc_ownership o ^ "]"
| RC_atomic t -> "atomic " ^ string_of_rc_type t

type ('b) gamma_ty = (rc_type Ail_identifier_map.t * 'b) list

let rec lookup_in_gamma x = function
| [] -> None
| (bds, sts) :: gamma ->
  (match Ail_identifier_map.find_opt x bds with
   | None -> lookup_in_gamma x gamma
   | Some ty -> Some ty)

let rc_ownership_of_annot = function
| Annot.Aattrs (Attrs attrs) ->
  let f a =
    match a.Annot.attr_ns with
    | None -> None
    | Some x ->
      if string_of_identifier x = "rc" then
        (match string_of_identifier a.Annot.attr_id with
         | "read" -> Some RC_read
         | "write" -> Some RC_write
         | _ -> failwith "unknown attr")
      else None
    in
  (match map_option f attrs with
  | [x] -> Some x
  | _ -> failwith "?")
| _ -> None

let rc_ownership_of_annots annots =
  match map_option rc_ownership_of_annot annots with
  | [rcow] -> rcow
  | [] -> RC_bad
  | _ :: _ :: _ -> failwith "ambiguous annotations"

let rec rc_type_of_cty = function
| Ctype.Ctype (_, Void) -> RC_scalar
| Ctype.Ctype (_, Basic _) -> RC_scalar
| Ctype.Ctype (_, Array _) -> failwith "array"
| Ctype.Ctype (_, Function _) -> failwith "function"
| Ctype.Ctype (annots, Pointer (_, cty)) -> RC_ptr (rc_ownership_of_annots annots, rc_type_of_cty cty)
| Ctype.Ctype (_, Atomic cty) -> RC_atomic (rc_type_of_cty cty)
| Ctype.Ctype (annots, Struct s) -> RC_struct (s, rc_ownership_of_annots annots)
| Ctype.Ctype (_, Union _) -> failwith "union"

let type_of_fun (f : fn_decl) =
  (List.map (fun (_, b, _) -> rc_type_of_cty b) f.fn_decl_argstys, rc_type_of_cty f.fn_decl_retty)

let collect_function_types fs =
  (* TODO: probably needs something better *)
  let hh _ = function
  | (Some fn_decl, _) -> Some (type_of_fun fn_decl)
  | _ -> None in
  Ail_identifier_option_map.map hh fs

let zap = function
| RC_scalar -> RC_scalar
| RC_ptr (_, rcty) -> RC_ptr (RC_zap, rcty)
| RC_struct (id, _) -> RC_struct (id, RC_zap)

let own_rank = function
| RC_read -> 0
| RC_write -> 1
| RC_zap -> 2

let sub_own t1 t2 =
  own_rank t1 <= own_rank t2

let rec sub_rcty t1 t2 = match (t1, t2) with
| (RC_scalar, RC_scalar) -> true
| (RC_scalar, _) | (_, RC_scalar) -> false
| (RC_ptr (o1, t1), RC_ptr (o2, t2)) -> sub_own o1 o2 && sub_rcty t1 t2
| (RC_ptr _, _) | (_, RC_ptr _) -> false
| (RC_struct (_, o1), RC_struct (_, o2)) -> true

module Type_error = struct
type t =
| TE_general of string
| TE_todo of string
| TE_expected_at_most_but_got of rc_type * rc_type
| TE_expected_at_least_but_got of rc_type * rc_type
| TE_internal_error of string

let string_of = function
| TE_general s -> s
| TE_todo s -> "TODO: " ^ s
| TE_expected_at_most_but_got (t1, t2) -> "expected at most `" ^ string_of_rc_type t1 ^ "` but got `" ^ string_of_rc_type t2 ^ "`"
| TE_expected_at_least_but_got (t1, t2) -> "expected at least `" ^ string_of_rc_type t1 ^ "` but got `" ^ string_of_rc_type t2 ^ "`"
| TE_internal_error s -> "internal error: " ^ s
end
module TE_either = Either_fixed.Make(Type_error)

let rec check_expression stys ftys gamma (AnnotatedExpression (_, _, _, e)) : rc_type TE_either.t =
  check_expression_ stys ftys gamma e
and check_expression_ stys ftys gamma = function
| AilEident x ->
  (match lookup_in_gamma x gamma with
  | None -> TE_either.mzero (TE_general "unbound variable")
  | Some ty -> TE_either.return ty)
| AilEassign (e1, e2) ->
  TE_either.bind
    (check_expression stys ftys gamma e1)
    (function
      | RC_ptr (o, t) as ty ->
        print_string (string_of_rc_type ty ^ "\n");
        if sub_own RC_write o then TE_either.return RC_scalar (* TODO: ? *)
        else TE_either.mzero (Type_error.TE_expected_at_most_but_got (RC_ptr (RC_write, t), ty))
      | _ -> TE_either.mzero (Type_error.TE_internal_error "writing to a non-ptr?"))
| AilEcall (AnnotatedExpression (_, _, _, AilEfunction_decay (AnnotatedExpression (_, _, _, AilEident f))), [e]) ->
  (match Ail_identifier_map.find_opt f ftys with
   | None -> TE_either.mzero (TE_general ("unbound function " ^ string_of_sym f))
   | Some ([paramty], retty) ->
     TE_either.bind
     (check_expression stys ftys gamma e)
      (fun argty -> if sub_rcty argty paramty then TE_either.return retty else TE_either.mzero (TE_expected_at_least_but_got (paramty, argty)))
    | _ -> failwith "multiple args")
| AilEcall _ -> failwith "TODO: other AilEcall"
| AilEunary (Address, e) ->
  TE_either.bind
    (check_expression stys ftys gamma e)
    (fun ty -> TE_either.return (RC_ptr (RC_read, ty)))
| AilEunary (Indirection, e) ->
  TE_either.bind
    (check_expression stys ftys gamma e)
    (function
    | RC_ptr (_, t) -> TE_either.return t
    | _ -> TE_either.mzero (Type_error.TE_internal_error "derefing a non-pointer?"))
| AilEunary ((Plus|Minus|Bnot|PostfixIncr|PostfixDecr), e) -> check_expression stys ftys gamma e
| AilEbinary _ -> failwith "TODO: binary"
| AilEcompoundAssign _ -> failwith "TODO: compound assign"
| AilEcond _ -> failwith "TODO: cond"
| AilEcast (_, _, e) -> check_expression stys ftys gamma e
| AilEconst e -> TE_either.return RC_scalar
| AilEmemberof _ -> failwith "TODO: memberof"
| AilEfunction_decay _ -> TE_either.mzero (Type_error.TE_internal_error "non-directly-applied functions are not handled")
| AilEannot _ -> failwith "TODO: annot"
| AilEassert _ -> TE_either.return RC_scalar
| AilEcompound _ -> failwith "TODO: compound"
| AilErvalue e ->
  TE_either.bind
    (check_expression stys ftys gamma e)
    (function
    | RC_ptr (_, t) -> TE_either.return t
    | _ -> TE_either.mzero (Type_error.TE_general "rvalue?"))
| AilEmemberofptr (e, p) ->
  TE_either.bind
    (check_expression stys ftys gamma e)
    (function
     | RC_struct (s, o) ->
         (match Ail_identifier_map.find_opt s stys with
         | None -> TE_either.mzero (TE_general "???")
         | Some sty ->
           (match String_map.find_opt (string_of_identifier p) sty with
           | None -> TE_either.mzero (TE_general "???")
           | Some ty -> TE_either.return (RC_ptr (o, ty))
             ))
     | _ -> TE_either.mzero (TE_internal_error "memberofptr on non-struct"))
| _ -> failwith "TODO: unhandled expression"

(* TODO: this is completely wrong, it's just a skeleton *)
let rec check_statements stys ftys (gamma : 'b gamma_ty) : 'a -> unit TE_either.t = function
| [] -> pop stys ftys gamma
| AnnotatedStatement (_, AilSskip) :: sts -> check_statements stys ftys gamma sts
| AnnotatedStatement (_, AilSexpr e) :: sts ->
  TE_either.bind
    (check_expression stys ftys gamma e)
    (fun _ -> check_statements stys ftys gamma sts)
| AnnotatedStatement (_, AilSblock (bds, sts1)) :: sts ->
  (match Ail_identifier_map_aux.of_list bds with
  | None -> assert false
  | Some bds ->
    let bds = Ail_identifier_map.map (fun (_, _, cty) -> zap (rc_type_of_cty cty)) bds in
    check_statements stys ftys ((bds, sts) :: gamma) sts1)
| AnnotatedStatement (_, AilSif (_, s1, s2)) :: sts ->
  TE_either.bind
    (check_statements stys ftys ((Ail_identifier_map.empty, sts) :: gamma) [s1])
    (fun () -> check_statements stys ftys ((Ail_identifier_map.empty, sts) :: gamma) [s2])
| AnnotatedStatement (_, AilSreturnVoid) :: sts ->
  pop stys ftys gamma
| AnnotatedStatement (_, AilSdeclaration [(x, e)]) :: sts ->
  check_statements stys ftys gamma sts (* TODO: ? *)
| AnnotatedStatement (_, s) :: sts -> failwith "TODO: unhandled statement"
and pop stys ftys = function
| [] -> TE_either.return ()
| (_, sts) :: gamma -> check_statements stys ftys gamma sts

let should_typecheck_of (def : 'a fn_def) =
  let should_not_typecheck = 
  List.exists
    (fun a ->
      match a.Annot.attr_ns with
      | None -> false
      | Some ns ->
        string_of_identifier ns = "rc" && string_of_identifier a.Annot.attr_id = "should_not_typecheck"
      )
    def.fn_def_attrs in
  not should_not_typecheck

let check_function stys ftys id = function
| (Some dcl, Some def) ->
  let should_typecheck = should_typecheck_of def in
  let sad = " " ^ Ansi.start_red ^ "sad" ^ Ansi.reset_colour in
  let happy = " " ^ Ansi.start_green ^ "happy" ^ Ansi.reset_colour ^ "\n" in
  let rejected_as_expected = " " ^ Ansi.start_green ^ "rejected as expected" ^ Ansi.reset_colour ^ "\n" in
  let unexpectedly_accepted = " " ^ Ansi.start_red ^ "unexpectedly accepted" ^ Ansi.reset_colour ^ "\n" in
  print_string (string_of_sym id ^ ":");
  flush stdout;
  let m =
    let m = List.combine def.fn_def_ids (List.map (fun (_, cty, _) -> rc_type_of_cty cty) dcl.fn_decl_argstys) in
    (match Ail_identifier_map_aux.of_list m with
    | None -> assert false
    | Some m -> m) in
  (match check_statements stys ftys [(m, [])] [def.fn_def_sts] with
   | TE_either.Left err ->
     if should_typecheck then print_string (sad ^ ": " ^ Type_error.string_of err ^ "\n") else print_string rejected_as_expected
   | TE_either.Right () ->
     if should_typecheck then print_string happy else print_string unexpectedly_accepted)
| _ -> print_string (string_of_sym id ^ " skipped\n")

let collect_structs s =
  let g xs =
    let xs = List.map (fun (id, (_, cty)) -> (string_of_identifier id, rc_type_of_cty cty)) xs in
    match String_map_aux.of_list xs with
    | None -> assert false
    | Some xs -> xs in
  let s =
    map_option
      (function
      | (id, Ctype.StructDef xs) -> Some (id, g xs)
      | (_, Ctype.UnionDef _) -> None)
     s.tag_definitions in
  match Ail_identifier_map_aux.of_list s with
  | None -> assert false
  | Some s -> s

let run_rustic (id, s) =
  let fs = collect_functions s in
  let stys = collect_structs s in
  print_funs (Ail_identifier_map.bindings fs); flush stdout;
  let ftys = collect_function_types fs in
  Ail_identifier_map.iter (check_function stys ftys) fs;
  ()