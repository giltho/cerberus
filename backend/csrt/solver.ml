open Environment
open Binders
open VarTypes
open List
open BaseTypes
open Cerb_frontend
open IndexTerms
open LogicalConstraints
(* open PPrint *)
open Pp_tools
open TypeErrors
open Except

module LS=LogicalSorts

(* copying bits and pieces from https://github.com/rems-project/asl-interpreter/blob/a896dd196996e2265eed35e8a1d71677314ee92c/libASL/tcheck.ml and https://github.com/Z3Prover/z3/blob/master/examples/ml/ml_example.ml *)



let sym_to_symbol ctxt (Symbol.Symbol (_digest, num, _mstring)) =
  Z3.Symbol.mk_int ctxt num

(* maybe fix Loc *)
let rec bt_to_sort loc env ctxt bt = 
  match bt with
  | Unit -> return (Z3.Sort.mk_uninterpreted_s ctxt "unit")
  | Bool -> return (Z3.Boolean.mk_sort ctxt)
  | Int -> return (Z3.Arithmetic.Integer.mk_sort ctxt)
  | Loc -> return (Z3.Arithmetic.Integer.mk_sort ctxt)
  | Tuple bts ->
     let names = mapi (fun i _ -> Z3.Symbol.mk_string ctxt (string_of_int i)) bts in
     mapM (bt_to_sort loc env ctxt) bts >>= fun sorts ->
     return (Z3.Tuple.mk_sort ctxt (Z3.Symbol.mk_string ctxt "tuple") names sorts)
  | Struct (S_Id typ) ->
     Environment.Global.get_struct_decl loc env.Env.global typ >>= fun decl ->
     fold_leftM (fun (names,sorts) {name = id; bound = t} ->
         match t with
         | A bt | L (Base bt) -> 
            bt_to_sort loc env ctxt bt >>= fun sort -> 
            return (Z3.Symbol.mk_string ctxt id :: names, sort :: sorts)
         | _ -> 
            return (names,sorts)
       ) ([],[]) decl.typ >>= fun (names,sorts) ->
     let name = Z3.Symbol.mk_string ctxt "struct" in
     return (Z3.Tuple.mk_sort ctxt name (rev names) (rev sorts))
  | Array
  | List _
  | StructField _ 
  | OpenStruct _
    ->
     fail loc (Z3_LS_not_implemented_yet (LS.Base bt))
  | FunctionPointer _ -> 
     return (Z3.Sort.mk_uninterpreted_s ctxt "function")

let ls_to_sort loc env ctxt ls = 
  match ls with
  | LogicalSorts.Base bt -> bt_to_sort loc env ctxt bt


let rec of_index_term loc env ctxt it = 
  let open PPrint in
  match it with
  | Num n -> 
     let nstr = Nat_big_num.to_string n in
     return (Z3.Arithmetic.Integer.mk_numeral_s ctxt nstr)
  | Bool true -> 
     return (Z3.Boolean.mk_true ctxt)
  | Bool false -> 
     return (Z3.Boolean.mk_false ctxt)
  | Add (it,it') -> 
     of_index_term loc env ctxt it >>= fun a ->
     of_index_term loc env ctxt it' >>= fun a' ->
     return (Z3.Arithmetic.mk_add ctxt [a;a'])
  | Sub (it,it') -> 
     of_index_term loc env ctxt it >>= fun a ->
     of_index_term loc env ctxt it' >>= fun a' ->
     return (Z3.Arithmetic.mk_sub ctxt [a;a'])
  | Mul (it,it') -> 
     of_index_term loc env ctxt it >>= fun a ->
     of_index_term loc env ctxt it' >>= fun a' ->
     return (Z3.Arithmetic.mk_mul ctxt [a; a'])
  | Div (it,it') -> 
     of_index_term loc env ctxt it >>= fun a ->
     of_index_term loc env ctxt it' >>= fun a' ->
     return (Z3.Arithmetic.mk_div ctxt a a')
  | Exp (it,it') -> 
     of_index_term loc env ctxt it >>= fun a ->
     of_index_term loc env ctxt it' >>= fun a' ->
     return (Z3.Arithmetic.mk_power ctxt a a')
  | Rem_t (it,it') -> 
     warn !^"Rem_t constraint" >>= fun () -> 
     of_index_term loc env ctxt it >>= fun a ->
     of_index_term loc env ctxt it' >>= fun a' ->
     return (Z3.Arithmetic.Integer.mk_rem ctxt a a')
  | Rem_f (it,it') -> 
     warn !^"Rem_f constraint" >>= fun () ->
     of_index_term loc env ctxt it >>= fun a ->
     of_index_term loc env ctxt it' >>= fun a' ->
     return (Z3.Arithmetic.Integer.mk_rem ctxt a a')
  | EQ (it,it') -> 
     of_index_term loc env ctxt it >>= fun a ->
     of_index_term loc env ctxt it' >>= fun a' ->
     return (Z3.Boolean.mk_eq ctxt a a')
  | NE (it,it') -> 
     of_index_term loc env ctxt it >>= fun a ->
     of_index_term loc env ctxt it' >>= fun a' ->
     return (Z3.Boolean.mk_distinct ctxt [a; a'])
  | LT (it,it') -> 
     of_index_term loc env ctxt it >>= fun a ->
     of_index_term loc env ctxt it' >>= fun a' ->
     return (Z3.Arithmetic.mk_lt ctxt a a')
  | GT (it,it') -> 
     of_index_term loc env ctxt it >>= fun a ->
     of_index_term loc env ctxt it' >>= fun a' ->
     return (Z3.Arithmetic.mk_gt ctxt a a') 
  | LE (it,it') -> 
     of_index_term loc env ctxt it >>= fun a ->
     of_index_term loc env ctxt it' >>= fun a' ->
     return (Z3.Arithmetic.mk_le ctxt a a')
  | GE (it,it') -> 
     of_index_term loc env ctxt it >>= fun a ->
     of_index_term loc env ctxt it' >>= fun a' ->
     return (Z3.Arithmetic.mk_ge ctxt a a')
  (* | Null t ->  *)
  | And (it,it') -> 
     of_index_term loc env ctxt it >>= fun a ->
     of_index_term loc env ctxt it' >>= fun a' ->
     return (Z3.Boolean.mk_and ctxt [a; a'])
  | Or (it,it') -> 
     of_index_term loc env ctxt it >>= fun a -> 
     of_index_term loc env ctxt it' >>= fun a' ->
     return (Z3.Boolean.mk_or ctxt [a; a'])
  | Not it -> 
     of_index_term loc env ctxt it >>= fun a ->
     return (Z3.Boolean.mk_not ctxt a)
  (* | Tuple of t * t list
   * | Nth of num * t (\* of tuple *\)
   * 
   * | List of t * t list
   * | Head of t
   * | Tail of t *)
  | S (s,ls) -> 
     let s = sym_to_symbol ctxt s in
     ls_to_sort loc env ctxt ls >>= fun bt ->
     return (Z3.Expr.mk_const ctxt s bt)
  | _ -> 
     fail loc (Z3_IT_not_implemented_yet it)


let z3_check loc ctxt solver constrs : (Z3.Solver.status, (Loc.t * TypeErrors.t)) m = 
  begin 
    let logfile = "/tmp/z3.log" in
    if not (Z3.Log.open_ logfile) 
    then fail loc (TypeErrors.Z3_fail "could not open /tmp/z3.log")
    else 
      try 
        Z3.Solver.add solver constrs;
        let result = Z3.Solver.check solver [] in
        Z3.Log.close ();
        return result
      with Z3.Error (msg : string) -> 
        Z3.Log.close ();
        fail loc (TypeErrors.Z3_fail msg)
  end


let negate (LC c) = (LC (Not c))

let constraint_holds_given_constraints loc env constraints c = 
  let open PPrint in
  let ctxt = Z3.mk_context [("model","true")] in
  let solver = Z3.Solver.mk_simple_solver ctxt in
  let lcs = (negate c :: constraints) in
  mapM (fun (LC it) -> tryM (of_index_term loc env ctxt it) 
                         (of_index_term loc env ctxt (Bool true))) lcs >>= fun constrs ->
  debug_print 4 (action "checking satisfiability of constraints") >>= fun () ->
  debug_print 4 (blank 3 ^^ item "constraints" (flow_map (break 1) (LogicalConstraints.pp true) lcs)) >>= fun () ->
  z3_check loc ctxt solver constrs >>= function
  (* the conjunction of existing constraints and 'not c' is unsatisfiable *)
  | UNSATISFIABLE -> 
     return true
  (* the conjunction of existing constraints and 'not c' is satisfiable *)
  | SATISFIABLE ->
     return false
  | UNKNOWN ->
     warn !^"constraint solver returned unknown" >>= fun () ->
     return false


let constraint_holds loc env c = 
  constraint_holds_given_constraints loc env (Env.get_all_constraints env) c



let is_unreachable loc env =
  constraint_holds loc env (LC (Bool false))


let rec check_constraints_hold loc env constr = 
  let open PPrint in
  let open Env in
  match constr with
  | [] -> return ()
  | {name; bound = c} :: constrs ->
     debug_print 2 (action "checking constraint") >>= fun () ->
     debug_print 2 (blank 3 ^^ item "environment" (Local.pp env.local)) >>= fun () ->
     debug_print 2 (blank 3 ^^ item "constraint" (LogicalConstraints.pp false c)) >>= fun () ->
     constraint_holds loc env c >>= function
     | true -> 
        debug_print 2 (blank 3 ^^ !^(greenb "constraint holds")) >>= fun () ->
        check_constraints_hold loc env constrs
     | false -> 
        debug_print 2 (blank 3 ^^ !^(redb "constraint does not hold")) >>= fun () ->
        fail loc (Call_error (Unsat_constraint (name, c)))
