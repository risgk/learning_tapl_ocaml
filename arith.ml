(* Modifying http://www.cis.upenn.edu/~bcpierce/tapl/checkers/arith/ for learning TAPL. *)
(* TYPES AND PROGRAMMING LANGUAGES by Benjamin C. Pierce Copyright (c)2002 Benjamin C. Pierce *)

type term =
    TmTrue
  | TmFalse
  | TmIf of term * term * term
  | TmZero
  | TmSucc of term
  | TmPred of term
  | TmIsZero of term

let rec isnumericval t = match t with
    TmZero -> true
  | TmSucc(t1) -> isnumericval t1
  | _ -> false

let rec isval t = match t with
    TmTrue  -> true
  | TmFalse -> true
  | t when isnumericval t  -> true
  | _ -> false

exception NoRuleApplies

let rec eval1 t = match t with
    TmIf(TmTrue,t2,t3) ->
      t2
  | TmIf(TmFalse,t2,t3) ->
      t3
  | TmIf(t1,t2,t3) ->
      let t1' = eval1 t1 in
      TmIf(t1', t2, t3)
  | TmSucc(t1) ->
      let t1' = eval1 t1 in
      TmSucc(t1')
  | TmPred(TmZero) ->
      TmZero
  | TmPred(TmSucc(nv1)) when (isnumericval nv1) ->
      nv1
  | TmPred(t1) ->
      let t1' = eval1 t1 in
      TmPred(t1')
  | TmIsZero(TmZero) ->
      TmTrue
  | TmIsZero(TmSucc(nv1)) when (isnumericval nv1) ->
      TmFalse
  | TmIsZero(t1) ->
      let t1' = eval1 t1 in
      TmIsZero(t1')
  | _ -> 
      raise NoRuleApplies

let rec eval t =
  try let t' = eval1 t
      in eval t'
  with NoRuleApplies -> t

(* Test *)
let test1 = eval(TmTrue) = TmTrue;;
let test2 = eval(TmIf(TmFalse,TmTrue,TmFalse)) = TmFalse;;
let test3 = eval(TmZero) = TmZero;;
let test4 = eval(TmSucc(TmPred(TmZero))) = TmSucc(TmZero);;
let test5 = eval(TmIsZero(TmPred(TmSucc(TmSucc(TmZero))))) = TmFalse;;
