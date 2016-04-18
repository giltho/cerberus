val ($): ('a -> 'b) -> 'a -> 'b
(* val (|-): ('a -> 'b) -> ('b -> 'c) -> 'a -> 'c *)
val (-|): ('b -> 'c) -> ('a -> 'b) -> 'a -> 'c
(* let (>?>) x b f g = if b then f x else g x *)


(*
(* Requires ocaml at least 4.00.0 *)
(* let (|>) x f = f x *)
external (|>) : 'a -> ('a -> 'b) -> 'b = "%revapply"
*)


type execution_mode =
  | Interactive
  | Exhaustive
  | Random

(* val string_of_execution_mode: execution_mode -> string *)

type language =
  | Cabs
  | Ail
  | Core

(* val string_of_language: language -> string *)

type error_verbosity =
  | Basic    (* similar to a normal compiler *)
  | RefStd   (* add an std reference to Basic *)
  | QuoteStd (* print a full quote of the std text *)

type cerberus_conf = {
  cpp_cmd:         string;
  pps:             language list;
  core_stdlib:     unit Core.fun_map;
  core_impl_opt:   Core.impl option;
  core_parser:     Input.t -> (Core_parser_util.result, Errors.error) Exception.exceptM;
  exec_mode_opt:   execution_mode option;
  compile:         bool;
  progress:        bool;
  rewrite:         bool;
  sequentialise:   bool;
  concurrency:     bool;
  preEx:           bool;
  error_verbosity: error_verbosity;
  batch:           bool;
  experimental_unseq: bool;
}

(* print an error fatal message and exit with a given code (default is 1) *)
val error: ?code:int -> string -> 'a


val (!!): (unit -> 'a) ref -> 'a

val cerb_conf: (unit -> cerberus_conf) ref

val current_execution_mode: unit -> execution_mode option

val set_cerb_conf:
    string ->
    language list ->
    unit Core.fun_map ->
    Core.impl option ->
    bool ->
    execution_mode ->
    (Input.t -> (Core_parser_util.result, Errors.error) Exception.exceptM) ->
    bool ->
    bool ->
    bool ->
    bool ->
    bool ->
    bool ->
    error_verbosity ->
    bool ->
    bool ->
    unit

val progress_sofar: int ref


(* let pass_through        f = Exception.fmap (fun v ->           f v        ; v) *)
val pass_through_test: bool -> ('a -> unit) -> ('a, 'msg) Exception.exceptM -> ('a, 'msg) Exception.exceptM
val pass_message: string -> ('a, 'msg) Exception.exceptM -> ('a, 'msg) Exception.exceptM
(* let return_none m         = Exception.bind0 m (fun _ -> Exception.return0 None) *)
(* let return_empty m        = Exception.bind0 m (fun _ -> Exception.return0 []) *)

(* let return_value m        = Exception.bind0 m (fun _ -> Exception.return0 []) *)


val user_request_driver: string list -> int


val concurrency_mode: unit -> bool
