{
open Parser
module M = Map.Make(String)
exception LexError of char * Lexing.position

let (^^^) = Ulib.Text.(^^^)
let r = Ulib.Text.of_latin1

let kw_table = 
  List.fold_left
    (fun r (x,y) -> M.add x y r)
    M.empty
    [("as",                      (fun x -> As(x)));
     ("fun",                     (fun x -> Fun_(x)));
     ("function",                (fun x -> Function_(x)));
     ("with",                    (fun x -> With(x)));
     ("match",                   (fun x -> Match(x)));
     ("let",                     (fun x -> Let_(x)));
     ("and",                     (fun x -> And(x)));
     ("in",                      (fun x -> In(x)));
     ("of",                      (fun x -> Of(x)));
     ("rec",                     (fun x -> Rec(x)));
     ("type",                    (fun x -> Type(x)));
     ("module",                  (fun x -> Module_(x)));
     ("struct",                  (fun x -> Struct(x)));
     ("end",                     (fun x -> End(x)));
     ("open",                    (fun x -> Open_(x)));
     ("true",                    (fun x -> True(x)));
     ("false",                   (fun x -> False(x)));
     ("begin",                   (fun x -> Begin_(x)));
     ("if",                      (fun x -> If_(x)));
     ("then",                    (fun x -> Then(x)));
     ("else",                    (fun x -> Else(x)));
     ("val",                     (fun x -> Val(x)));
     ("class",                   (fun x -> Class_(x)));
     ("instance",                (fun x -> Inst(x)));
     ("indreln",                 (fun x -> Indreln(x)));
     ("forall",                  (fun x -> Forall(x)));
     ("exists",                  (fun x -> Exists(x)));
     ("inline",                  (fun x -> Inline(x)));
     ("IN",                      (fun x -> IN(x,r"IN")));
     ("MEM",                     (fun x -> MEM(x,r"MEM")))]

}

let ws = [' ''\t']+
let letter = ['a'-'z''A'-'Z']
let digit = ['0'-'9']
let alphanum = letter|digit
let startident = letter|'_'
let ident = alphanum|['_''\'']
let oper_char = ['!''$''%''&''*''+''-''.''/'':''<''=''>''?''@''^''|''~']
let safe_com1 = [^'*''('')''\n']
let safe_com2 = [^'*''(''\n']
let com_help = "("*safe_com2 | "*"*"("+safe_com2 | "*"*safe_com1
let com_body = com_help*"*"*

rule token skips = parse
  | ws as i
    { token (Ast.Ws(Ulib.Text.of_latin1 i)::skips) lexbuf }
  | "\n"
    { Lexing.new_line lexbuf;
      token (Ast.Nl::skips) lexbuf } 
  
  | "."                                 { (Dot(Some(skips))) }

  | "("                                 { (Lparen(Some(skips))) }
  | ")"                                 { (Rparen(Some(skips))) }
  | ","                                 { (Comma(Some(skips))) }
  | "_"                                 { (Under(Some(skips))) }
  | "*"                                 { (Star(Some(skips),r"*")) }
  | ":"                                 { (Colon(Some(skips))) }
  | "{"                                 { (Lcurly(Some(skips))) }
  | "}"                                 { (Rcurly(Some(skips))) }
  | ";"                                 { (Semi(Some(skips))) }
  | "["                                 { (Lsquare(Some(skips))) }
  | "]"                                 { (Rsquare(Some(skips))) }
  | "="                                 { (Eq(Some(skips),r"=")) }
  | "|"                                 { (Bar(Some(skips))) }
  | "->"                                { (Arrow(Some(skips))) }
  | ";;"                                { (SemiSemi(Some(skips))) }
  | "::" as i                           { (ColonColon(Some(skips),Ulib.Text.of_latin1 i)) }
  | "&&" as i                           { (AmpAmp(Some(skips),Ulib.Text.of_latin1 i)) }
  | "||" as i                           { (BarBar(Some(skips),Ulib.Text.of_latin1 i)) }
  | "=>"                                { (EqGt(Some(skips))) }

  | "==>"                               { (EqEqGt(Some(skips))) }
  | "-->" as i                          { (MinusMinusGt(Some(skips),Ulib.Text.of_latin1 i)) }
  | "<|"                                { (LtBar(Some(skips))) }
  | "|>"                                { (BarGt(Some(skips))) }

  | "union" as i                        { (PlusX(Some(skips),Ulib.Text.of_latin1 i)) }
  | "inter" as i                        { (StarX(Some(skips),Ulib.Text.of_latin1 i)) }
  | "subset" | "\\" as i                { (EqualX(Some(skips),Ulib.Text.of_latin1 i)) }
  | "lsl" | "lsr" | "asr" as i          { (StarstarX(Some(skips), Ulib.Text.of_latin1 i)) }
  | "mod" | "land" | "lor" | "lxor" as i  { (StarX(Some(skips), Ulib.Text.of_latin1 i)) }

  (* TODO: Add checking that keywords aren't used in these *)
  (* TODO: make union, inter, subset appear as oper_char+, or make them not infix *)
  | "`" (startident ident* as i) "`"    { (BquoteX(Some(skips),Ulib.Text.of_latin1 i)) }

  | "(*"                           
    { token (Ast.Com(Ast.Comment(comment lexbuf))::skips) lexbuf }

  | startident ident* as i              { if M.mem i kw_table then
                                            (M.find i kw_table) (Some(skips))
                                          else
                                            X(Some(skips), Ulib.Text.of_latin1 i) }

  | "\\\\" ([^' ' '\t' '\n']+ as i)     { (X(Some(skips), Ulib.Text.of_latin1 i)) } 

  | "'" (startident ident* as i)        { (Tyvar(Some(skips), Ulib.Text.of_latin1 i)) }
  | ['!''?''~'] oper_char* as i         { (X(Some(skips), Ulib.Text.of_latin1 i)) }

  | "**" oper_char* as i                { (StarstarX(Some(skips), Ulib.Text.of_latin1 i)) }
  | ['/''%'] oper_char* as i         { (StarX(Some(skips), Ulib.Text.of_latin1 i)) }
  | "*" oper_char+ as i         { (StarX(Some(skips), Ulib.Text.of_latin1 i)) }
  | ['+''-'] oper_char* as i            { (PlusX(Some(skips), Ulib.Text.of_latin1 i)) }
  | ['@''^'] oper_char* as i            { (AtX(Some(skips), Ulib.Text.of_latin1 i)) }
  | ['=''<''>''|''&''$'] oper_char* as i { (EqualX(Some(skips), Ulib.Text.of_latin1 i)) }
  | digit+ as i                         { (Num(Some(skips),int_of_string i)) }
  | '"'                                 { (String(Some(skips), string lexbuf)) }
  | eof                                 { (Eof(Some(skips))) }
  | _  as c                             { raise (LexError(c, Lexing.lexeme_start_p lexbuf)) }


and comment = parse
  | (com_body "("* as i) "(*"           { let c1 = comment lexbuf in
                                          let c2 = comment lexbuf in
                                            Ast.Chars(Ulib.Text.of_latin1 i) :: Ast.Comment(c1) :: c2}
  | (com_body as i) "*)"                { [Ast.Chars(Ulib.Text.of_latin1 i)] }
  | com_body "("* "\n" as i             { Lexing.new_line lexbuf; 
                                          (Ast.Chars(Ulib.Text.of_latin1 i) :: comment lexbuf) }
  | _  as c                             { raise (LexError(c, Lexing.lexeme_start_p lexbuf)) }
  | eof                                 { [] }

and string = parse
  | ([^'"''\n']*'\n' as i)              { Lexing.new_line lexbuf; i ^ (string lexbuf) }
  | ([^'"''\n']* as i)                      { i ^ (string lexbuf) }
  | '"'                                 { "" }
