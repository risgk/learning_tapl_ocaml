# Modifying http://www.cis.upenn.edu/~bcpierce/tapl/checkers/simplebool/ for learning TAPL.
# TYPES AND PROGRAMMING LANGUAGES by Benjamin C. Pierce Copyright (c)2002 Benjamin C. Pierce

# ------------------------   SYNTAX  ------------------------

# Context management

def ctxlength(ctx)
  ctx.length
end

def addbinding(ctx, x, bind)
  [[x, bind]] + ctx
end

def isnamebound(ctx, x)
  if ctx[0].nil?
    false
  else
    y = ctx[0][0]; rest = ctx.drop(1)
    if y == x
      true
    else
      isnamebound(rest, x)
    end
  end
end

def pickfreshname(ctx, x)
  if isnamebound(ctx, x)
    pickfreshname(ctx, x + "'")
  else
    [[[x, "NameBind"]] + ctx, x]
  end
end

def index2name(ctx, x)
  if ctx[x].nil?
    puts "Variable lookup failure!"
    nil
  else
    ctx[x][0]
  end
end

# Shifting

def termShift(d, t)
  def walkShift(c, t, d)
    case
    when t[0] == :var
      x = t[1]; n = t[2]
      if x >= c
        [:var, x + d, n + d]
      else
        [:var, x, n + d]
      end
    when t[0] == :abs
      # todo: ty
      x = t[1]; t1 = t[2]
      [:abs, x, walkShift(c + 1, t1, d)]
    when t[0] == :app
      t1 = t[1]; t2 = t[2]
      [:app, walkShift(c, t1, d), walkShift(c, t2, d)]
    end
  end
  walkShift(0, t, d)
end

# Substitution

def termSubst(j, s, t)
  def walkSubst(c, t, j, s)
    case
    when t[0] == :var
      x = t[1]; n = t[2]
      if x == j + c
        termShift(c, s)
      else
        [:var, x, n]
      end
    when t[0] == :abs
      # todo: ty
      x = t[1]; t1 = t[2]
      [:abs, x, walkSubst(c + 1, t1, j, s)]
    when t[0] == :app
      t1 = t[1]; t2 = t[2]
      [:app, walkSubst(c, t1, j, s), walkSubst(c, t2, j, s)]
    end
  end
  walkSubst(0, t, j, s)
end

def termSubstTop(s, t)
  termShift(-1, (termSubst(0, (termShift(1, s)), t)))
end

# Context management (continued)

def getbinding(ctx, i)
=begin
 let getTypeFromContext fi ctx i =
   match getbinding fi ctx i with
       VarBind(tyT) -> tyT
     | _ -> error fi 
       ("getTypeFromContext: Wrong kind of binding for variable " 
        ^ (index2name fi ctx i)) 
=end
end

def getTypeFromContext(ctx, i)
=begin
let rec getbinding fi ctx i =
  try
    let (_,bind) = List.nth ctx i in
    bind 
  with Failure _ ->
    let msg =
      Printf.sprintf "Variable lookup failure: offset: %d, ctx size: %d" in
    error fi (msg i (List.length ctx))
=end
end

# Printing

def sprintty(tyT)
=begin
let rec printty_Type outer tyT = match tyT with
      tyT -> printty_ArrowType outer tyT

and printty_ArrowType outer  tyT = match tyT with 
    TyArr(tyT1,tyT2) ->
      obox0(); 
      printty_AType false tyT1;
      if outer then pr " ";
      pr "->";
      if outer then print_space() else break();
      printty_ArrowType outer tyT2;
      cbox()
  | tyT -> printty_AType outer tyT

and printty_AType outer tyT = match tyT with
    TyBool -> pr "Bool"
  | tyT -> pr "("; printty_Type outer tyT; pr ")"

let printty tyT = printty_Type true tyT 
=end
end

def sprinttm(ctx, t)
  case
  when t[0] == :abs
    # todo: ty
    x = t[1]; t1 = t[2]
    ctxp, xp = pickfreshname(ctx, x)
    "(lambda " + xp + ". " + sprinttm(ctxp, t1) + ")"
  when t[0] == :app
    t1 = t[1]; t2 = t[2]
    "(" + sprinttm(ctx, t1) + " " + sprinttm(ctx, t2) + ")"
  when t[0] == :var
    x = t[1]; n = t[2]
    if ctxlength(ctx) == n
      index2name(ctx, x)
    else
      puts "[bad index]"
    end
  end
end

def sprbinding(ctx, b)
=begin
let prbinding ctx b = match b with
    NameBind -> ()
  | VarBind(tyT) -> pr ": "; printty tyT 
=end
end

# ------------------------   EVALUATION  ------------------------

def isval(ctx, t)
  case
  when t[0] == :abs
    true
  else
    false
  end
end

class NoRuleApplies < Exception; end

def eval1(ctx, t)
  # p sprinttm(ctx, t)
  case
  # todo: ty
  when t[0] == :app && t[1][0] == :abs && isval(ctx, t[2])
    termSubstTop(t[2], t[1][2])
  when t[0] == :app && isval(ctx, t[1])
    t2p = eval1(ctx, t[2])
    [:app, t[1], t2p]
  when t[0] == :app
    t1p = eval1(ctx, t[1])
    [:app, t1p, t[2]]
  else
    raise NoRuleApplies
  end
=begin
let rec eval1 ctx t = match t with
    TmApp(fi,TmAbs(_,x,tyT11,t12),v2) when isval ctx v2 ->
      termSubstTop v2 t12
  | TmApp(fi,v1,t2) when isval ctx v1 ->
      let t2' = eval1 ctx t2 in
      TmApp(fi, v1, t2')
  | TmApp(fi,t1,t2) ->
      let t1' = eval1 ctx t1 in
      TmApp(fi, t1', t2)
  | TmIf(_,TmTrue(_),t2,t3) ->
      t2
  | TmIf(_,TmFalse(_),t2,t3) ->
      t3
  | TmIf(fi,t1,t2,t3) ->
      let t1' = eval1 ctx t1 in
      TmIf(fi, t1', t2, t3)
=end
end

def eval(ctx, t)
  begin
    eval(ctx, eval1(ctx, t))
  rescue NoRuleApplies
    t
  end
end

# ------------------------   TYPING  ------------------------

def typeof(ctx, t)
=begin
let rec typeof ctx t =
  match t with
    TmVar(fi,i,_) -> getTypeFromContext fi ctx i
  | TmAbs(fi,x,tyT1,t2) ->
      let ctx' = addbinding ctx x (VarBind(tyT1)) in
      let tyT2 = typeof ctx' t2 in
      TyArr(tyT1, tyT2)
  | TmApp(fi,t1,t2) ->
      let tyT1 = typeof ctx t1 in
      let tyT2 = typeof ctx t2 in
      (match tyT1 with
          TyArr(tyT11,tyT12) ->
            if (=) tyT2 tyT11 then tyT12
            else error fi "parameter type mismatch"
        | _ -> error fi "arrow type expected")
  | TmTrue(fi) -> 
      TyBool
  | TmFalse(fi) -> 
      TyBool
  | TmIf(fi,t1,t2,t3) ->
     if (=) (typeof ctx t1) TyBool then
       let tyT2 = typeof ctx t2 in
       if (=) tyT2 (typeof ctx t3) then tyT2
       else error fi "arms of conditional have different types"
     else error fi "guard of conditional not a boolean"
=end
end

# ------------------------   MAIN  ------------------------

def process(ctx, t)
  # todo
end

# ------------------------   TESTS  ------------------------

printf "test0: %s\n", true == true
=begin
 lambda x:Bool. x;
 (lambda x:Bool->Bool. if x false then true else false) 
   (lambda x:Bool. if x then false else true); 
=end
