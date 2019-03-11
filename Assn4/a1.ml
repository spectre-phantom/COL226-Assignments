open A0

exception Invalid_Expression

(* abstract syntax  *)
type exptree =
  | N of int
  (* Integer constant *)
  | B of bool
  (* Boolean constant *)
  | Var of string
  (* variable *)
  | Conjunction of exptree * exptree
  (* binary operators on booleans /\ *)
  | Disjunction of exptree * exptree
  (* binary operators on booleans \/ *)
  | Equals of exptree * exptree
  (* comparison operations on integers *)
  | GreaterTE of exptree * exptree
  (* comparison operations on integers *)
  | LessTE of exptree * exptree
  (* comparison operations on integers *)
  | GreaterT of exptree * exptree
  (* comparison operations on integers *)
  | LessT of exptree * exptree
  (* comparison operations on integers *)
  | InParen of exptree
  (* expressions using parenthesis *)
  | IfThenElse of exptree * exptree * exptree
  (* a conditional expression *)
  | Tuple of int * exptree list
  (* creating n-tuples (n >= 0) *)
  | Project of (int * int) * exptree list
  (* projecting the i-th component of an expression (which evaluates to an n-tuple, and 1 <= i <= n) *)
  | Add of exptree * exptree
  (* binary operators on integers *)
  | Sub of exptree * exptree
  (* binary operators on integers *)
  | Mult of exptree * exptree
  (* binary operators on integers *)
  | Div of exptree * exptree
  (* binary operators on integers *)
  | Rem of exptree * exptree
  (* binary operators on integers *)
  | Negative of exptree
  | Not of exptree
  | Exp of exptree * exptree
  (* unary operators on booleans *)
  | Abs of exptree

(* unary operators on integers *)

type opcode =
  | VAR of string
  | NCONST of bigint
  | BCONST of bool
  | PLUS
  | MULT
  | MINUS
  | DIV
  | REM
  | EXP
  | ABS
  | UNARYMINUS
  | EQS
  | GTE
  | LTE
  | GT
  | LT
  | PAREN
  | CONJ
  | DISJ
  | NOT
  | IFTE
  | TUPLE of int
  | PROJ of int * int

(* type special_ret_type = Int of int | Bool of bool *)
type answer = Num of bigint | Bool of bool | Tup of int * answer list

exception Zero_exp_zero_error

let rec eval_b_exponent acc x y =
  match y with
  | NonNeg, [] ->
      if x = (NonNeg, []) then raise Zero_exp_zero_error else (NonNeg, [1])
  | NonNeg, [1] -> mult acc x
  | power -> eval_b_exponent (mult acc x) x (sub y (NonNeg, [1]))

let rec eval exp rho =
  match exp with
  | N number -> Num number
  | B value -> Bool value
  | Var var_name -> VarTable.find var_name rho
  | Conjunction (e1, e2) -> (
    match (eval e1, eval e2) with
    | Bool a, Bool b -> Bool (a && b)
    | _, _ -> raise Invalid_Expression )
  | Disjunction (e1, e2) -> (
    match (eval e1, eval e2) with
    | Bool a, Bool b -> Bool (a || b)
    | _, _ -> raise Invalid_Expression )
  | Equals (e1, e2) -> (
    match (eval e1, eval e2) with
    | Bool a, Bool b -> Bool (a = b)
    | _, _ -> raise Invalid_Expression )
  | GreaterTE (e1, e2) -> (
    match (eval e1, eval e2) with
    | Bool a, Bool b -> Bool (a >= b)
    | _, _ -> raise Invalid_Expression )
  | LessTE (e1, e2) -> (
    match (eval e1, eval e2) with
    | Bool a, Bool b -> Bool (a <= b)
    | _, _ -> raise Invalid_Expression )
  | GreaterT (e1, e2) -> (
    match (eval e1, eval e2) with
    | Bool a, Bool b -> Bool (a > b)
    | _, _ -> raise Invalid_Expression )
  | LessT (e1, e2) -> (
    match (eval e1, eval e2) with
    | Bool a, Bool b -> Bool (a < b)
    | _, _ -> raise Invalid_Expression )
  | InParen e1 -> eval e1
  | IfThenElse (e1, e2, e3) -> (
    match eval e1 with
    | Bool a -> if a = true then eval e2 else eval e3
    | _ -> raise Invalid_Expression )
  (* | Tuple (e1, e2) ->
     | Project (e1, e2) ->  *)
  | Add (e1, e2) -> (
    match (eval e1, eval e2) with
    | Num a, Num b -> Num (a + b)
    | _, _ -> raise Invalid_Expression )
  | Sub (e1, e2) -> (
    match (eval e1, eval e2) with
    | Num a, Num b -> Num (a - b)
    | _, _ -> raise Invalid_Expression )
  | Mult (e1, e2) -> (
    match (eval e1, eval e2) with
    | Num a, Num b -> Num (a * b)
    | _, _ -> raise Invalid_Expression )
  | Div (e1, e2) -> (
    match (eval e1, eval e2) with
    | Num a, Num b ->
        if a < 0 && b > 0 && b * (a / b) <> a then Num ((a / b) - 1)
        else Num (a / b)
    (* Done to make sure Euclidean Division is satisfied *)
    (* To make remainder always greater than 0 *)
    | _, _ -> raise Invalid_Expression )
  | Rem (e1, e2) -> (
    match (eval e1, eval e2) with
    | Num a, Num b ->
        if a < 0 && b > 0 && b * (a / b) <> a then Num ((a mod b) + b)
        else Num (a mod b)
    (* Done to make sure Euclidean Division is satisfied *)
    (* To make remainder always greater than 0 *)
    | _, _ -> raise Invalid_Expression )
  | Exp (e1, e2) -> (
    match (eval e1, eval e2) with
    | Num a, Num b -> Num (eval_b_exponent 1 a b)
    | _, _ -> raise Invalid_Expression )
  | Negative e1 -> (
    match eval e1 with Num a -> Num (-1 * a) | _ -> raise Invalid_Expression )
  | Not e1 -> (
    match eval e1 with Bool a -> Bool (not a) | _ -> raise Invalid_Expression )
  | Abs e1 -> (
    match eval e1 with
    | Num a -> if a < 0 then Num (-1 * a) else Num a
    | _ -> raise Invalid_Expression )
  | _ -> raise Invalid_Expression

let rec compile exp =
  match exp with
  | Var x -> [VAR x]
  | N number -> [NCONST (mk_big number)]
  | B value -> [BCONST value]
  | Equals (e1, e2) -> compile e1 @ compile e2 @ [EQS]
  | GreaterTE (e1, e2) -> compile e1 @ compile e2 @ [GTE]
  | LessTE (e1, e2) -> compile e1 @ compile e2 @ [LTE]
  | GreaterT (e1, e2) -> compile e1 @ compile e2 @ [GT]
  | LessT (e1, e2) -> compile e1 @ compile e2 @ [LT]
  | Conjunction (e1, e2) -> compile e1 @ compile e2 @ [CONJ]
  | Disjunction (e1, e2) -> compile e1 @ compile e2 @ [DISJ]
  | InParen e1 -> [PAREN] @ compile e1 @ [PAREN]
  | Add (e1, e2) -> compile e1 @ compile e2 @ [PLUS]
  | Sub (e1, e2) -> compile e1 @ compile e2 @ [MINUS]
  | Mult (e1, e2) -> compile e1 @ compile e2 @ [MULT]
  | Div (e1, e2) -> compile e1 @ compile e2 @ [DIV]
  | Rem (e1, e2) -> compile e1 @ compile e2 @ [REM]
  | Abs e1 -> compile e1 @ [ABS]
  | Negative e1 -> compile e1 @ [UNARYMINUS]
  | Not e1 -> compile e1 @ [NOT]
  | Exp (e1, e2) -> compile e1 @ compile e2 @ [EXP]
  | IfThenElse (e1, e2, e3) -> compile e3 @ compile e2 @ compile e1 @ [IFTE]
  (* | Tuple (e1, e2) ->
     | Project (e1, e2) ->  *)
  | _ -> raise Invalid_Expression

exception Drop_number_exceeds_list

exception Invalid_type

let rec drop l n =
  match l with
  | [] -> if n = 0 then [] else raise Drop_number_exceeds_list
  | hd :: tl -> if n = 0 then l else drop tl (n - 1)

(* type answer = BInt of bigint | Bool of bool *)

let get_int a = match a with Num e1 -> e1 | _ -> raise Invalid_type

let get_bool a = match a with Bool e1 -> e1 | _ -> raise Invalid_type

exception Ill_Formed_Stack

let rec find_paren list accumulator =
  match list with
  | PAREN :: e -> accumulator
  | a :: b -> find_paren b accumulator @ [a]
  | [] -> raise Ill_Formed_Stack

let rec stackmc_prototype (acc : answer list) (op : opcode list) (a : int) rho
    =
  try
    match op with
    | VAR (x : string) :: e ->
        stackmc_prototype (VarTable.find x rho :: acc) e a
    | NCONST (num : bigint) :: e -> stackmc_prototype (Num num :: acc) e a
    | BCONST (value : bool) :: e -> stackmc_prototype (Bool value :: acc) e a
    | PLUS :: e ->
        if List.length acc >= a + 2 then
          stackmc_prototype
            ( Num
                (add (get_int (List.hd acc)) (get_int (List.hd (List.tl acc))))
            :: drop acc 2 )
            e a
        else raise Ill_Formed_Stack
    | MULT :: e ->
        if List.length acc >= a + 2 then
          stackmc_prototype
            ( Num
                (mult (get_int (List.hd acc)) (get_int (List.hd (List.tl acc))))
            :: drop acc 2 )
            e a
        else raise Ill_Formed_Stack
    | MINUS :: e ->
        if List.length acc >= a + 2 then
          stackmc_prototype
            ( Num
                (sub (get_int (List.hd (List.tl acc))) (get_int (List.hd acc)))
            :: drop acc 2 )
            e a
        else raise Ill_Formed_Stack
    | EXP :: e ->
        if List.length acc >= a + 2 then
          stackmc_prototype
            ( Num
                (eval_b_exponent
                   (NonNeg, [1])
                   (get_int (List.hd (List.tl acc)))
                   (get_int (List.hd acc)))
            :: drop acc 2 )
            e a
        else raise Ill_Formed_Stack
    | DIV :: e ->
        if List.length acc >= a + 2 then
          stackmc_prototype
            ( Num
                (div (get_int (List.hd (List.tl acc))) (get_int (List.hd acc)))
            :: drop acc 2 )
            e a
        else raise Ill_Formed_Stack
    | REM :: e ->
        if List.length acc >= a + 2 then
          stackmc_prototype
            ( Num
                (rem (get_int (List.hd (List.tl acc))) (get_int (List.hd acc)))
            :: drop acc 2 )
            e a
        else raise Ill_Formed_Stack
    | ABS :: e ->
        if List.length acc >= a + 1 then
          stackmc_prototype
            (Num (abs (get_int (List.hd acc))) :: drop acc 1)
            e a
        else raise Ill_Formed_Stack
    | UNARYMINUS :: e ->
        if List.length acc >= a + 1 then
          stackmc_prototype
            (Num (minus (get_int (List.hd acc))) :: drop acc 1)
            e a
        else raise Ill_Formed_Stack
    | EQS :: e ->
        if List.length acc >= a + 2 then
          stackmc_prototype
            ( Bool
                (eq (get_int (List.hd acc)) (get_int (List.hd (List.tl acc))))
            :: drop acc 2 )
            e a
        else raise Ill_Formed_Stack
    | GTE :: e ->
        if List.length acc >= a + 2 then
          stackmc_prototype
            ( Bool
                (geq (get_int (List.hd (List.tl acc))) (get_int (List.hd acc)))
            :: drop acc 2 )
            e a
        else raise Ill_Formed_Stack
    | LTE :: e ->
        if List.length acc >= a + 2 then
          stackmc_prototype
            ( Bool
                (leq (get_int (List.hd (List.tl acc))) (get_int (List.hd acc)))
            :: drop acc 2 )
            e a
        else raise Ill_Formed_Stack
    | GT :: e ->
        if List.length acc >= a + 2 then
          stackmc_prototype
            ( Bool
                (gt (get_int (List.hd (List.tl acc))) (get_int (List.hd acc)))
            :: drop acc 2 )
            e a
        else raise Ill_Formed_Stack
    | LT :: e ->
        if List.length acc >= a + 2 then
          stackmc_prototype
            ( Bool
                (lt (get_int (List.hd (List.tl acc))) (get_int (List.hd acc)))
            :: drop acc 2 )
            e a
        else raise Ill_Formed_Stack
    | PAREN :: e ->
        let temp = stackmc_prototype [] (find_paren e []) 0 in
        stackmc_prototype (temp :: acc)
          (drop e (List.length (find_paren e []) + 1))
          a
    | CONJ :: e ->
        if List.length acc >= a + 2 then
          stackmc_prototype
            ( Bool (get_bool (List.hd (List.tl acc)) && get_bool (List.hd acc))
            :: drop acc 2 )
            e a
        else raise Ill_Formed_Stack
    | DISJ :: e ->
        if List.length acc >= a + 2 then
          stackmc_prototype
            ( Bool (get_bool (List.hd (List.tl acc)) || get_bool (List.hd acc))
            :: drop acc 2 )
            e a
        else raise Ill_Formed_Stack
    | NOT :: e ->
        if List.length acc >= a + 1 then
          stackmc_prototype
            (Bool (not (get_bool (List.hd acc))) :: drop acc 1)
            e a
        else raise Ill_Formed_Stack
    | IFTE :: e ->
        if List.length acc >= a + 3 then
          if get_bool (List.hd acc) = true then
            stackmc_prototype (List.hd (List.tl acc) :: drop acc 3) e a
          else
            stackmc_prototype
              (List.hd (List.tl (List.tl acc)) :: drop acc 3)
              e a
        else raise Ill_Formed_Stack
    (* Tuple and Projection pending *)
    | [] ->
        if List.length acc = a + 1 then List.hd acc else raise Ill_Formed_Stack
    (* Assuming that acc need not always be empty *)
    (* if List.length acc = 1 then List.hd acc else raise Invalid_Expression *)
  with
  | Failure _ -> raise Ill_Formed_Stack
  | Drop_number_exceeds_list -> raise Ill_Formed_Stack
  | Ill_Formed_Stack -> raise Ill_Formed_Stack
  | Invalid_type -> raise Invalid_type

let stackmc (acc : answer list) rho (op : opcode list) =
  stackmc_prototype acc op (List.length acc) rho

(* let a0 = N 2000

   let a1 = N 4

   let a2 = N 1200

   let a3 = N 50000

   let a4 = N 10

   let a5 = N 2

   let a6 = N 500

   let a7 = B true

   let a8 = B false

   let opcode1 = compile (Add (Mult (a1, a2), a3))

   let opcode2 = compile (Div (Negative a3, Mult (a4, a4)))

   let opcode3 = compile (Negative (Sub (Div (a6, a5), Mult (a1, a2))))

   let opcode4 = compile (Abs (Div (Negative a3, Rem (a4, a3))))

   let opcode5 =
   compile
    (IfThenElse
       ( Conjunction (a7, a8)
       , Add (Mult (a1, a2), a3)
       , Negative (Sub (Div (a6, a5), Mult (a1, a2))) )) *)
