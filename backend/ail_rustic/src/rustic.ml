let plop (Symbol.Identifier (_, s)) = s

let foo3 attrs =
  String.concat ", " (List.map (fun a -> plop a.Annot.attr_id) attrs)

let foo2 (Symbol.Symbol (_, _, Some id), (_, Annot.Attrs attrs, _, _)) =
  print_string (id ^ ": " ^ foo3 attrs ^ "\n")

let foo fs =
  List.iter foo2 fs

let run_rustic ail_file =
  match ail_file with
  | (id, s) ->
    let fs = s.AilSyntax.function_definitions in
    foo fs;
    ()

