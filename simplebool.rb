# Modifying http://www.cis.upenn.edu/~bcpierce/tapl/checkers/simplebool/ for learning TAPL.
# TYPES AND PROGRAMMING LANGUAGES by Benjamin C. Pierce Copyright (c)2002 Benjamin C. Pierce

# ------------------------   SYNTAX  ------------------------

# Context management

def addbinding(ctx, x, bind)
  [[x, bind]] + ctx
end

# Shifting

def termShift(d, t)
  def walkShift(c, t, d)
    case
    when t[0] == :TmVar
      x = t[1]; n = t[2]
      if x >= c
        [:TmVar, x + d, n + d]
      else
        [:TmVar, x, n + d]
      end
    when t[0] == :TmAbs
      x = t[1]; tyT1 = t[2]; t2 = t[3]
      [:TmAbs, x, tyT1, walkShift(c + 1, t2, d)]
    when t[0] == :TmApp
      t1 = t[1]; t2 = t[2]
      [:TmApp, walkShift(c, t1, d), walkShift(c, t2, d)]
    when t[0] == :TmTrue
      t
    when t[0] == :TmFalse
      t
    when t[0] == :TmIf
      t1 = t[1]; t2 = t[2]; t3 = t[3]
      [:TmIf, walkShift(c, t1, d), walkShift(c, t2, d), walkShift(c, t3, d)]
    end
  end
  walkShift(0, t, d)
end

# Substitution

def termSubst(j, s, t)
  def walkSubst(c, t, j, s)
    case
    when t[0] == :TmVar
      x = t[1]; n = t[2]
      if x == j + c
        termShift(c, s)
      else
        [:TmVar, x, n]
      end
    when t[0] == :TmAbs
      x = t[1]; tyT1 = t[2]; t2 = t[3]
      [:TmAbs, x, tyT1, walkSubst(c + 1, t2, j, s)]
    when t[0] == :TmApp
      t1 = t[1]; t2 = t[2]
      [:TmApp, walkSubst(c, t1, j, s), walkSubst(c, t2, j, s)]
    when t[0] == :TmTrue
      t
    when t[0] == :TmFalse
      t
    when t[0] == :TmIf
      t1 = t[1]; t2 = t[2]; t3 = t[3]
      [:TmIf, walkSubst(c, t1, j, s), walkSubst(c, t2, j, s), walkSubst(c, t3, j, s)]
    end
  end
  walkSubst(0, t, j, s)
end

def termSubstTop(s, t)
  termShift(-1, (termSubst(0, (termShift(1, s)), t)))
end

# Context management (continued)

def getbinding(ctx, i)
  if i < ctx.length
    ctx[i][1]
  else
    raise "Variable lookup failure"
  end
end

def getTypeFromContext(ctx, i)
  b = getbinding(ctx, i)
  case
  when b[0] == :VarBind
    tyT = b[1]
  else
    raise "Wrong kind of binding for variable"
  end
end

# ------------------------   EVALUATION  ------------------------

def isval(ctx, t)
  case
  when t[0] == :TmTrue
    true
  when t[0] == :TmFalse
    true
  when t[0] == :TmAbs
    true
  else
    false
  end
end

class NoRuleApplies < Exception; end

def eval1(ctx, t)
  case
  when t[0] == :TmApp && t[1][0] == :TmAbs && isval(ctx, t[2])
    termSubstTop(t[2], t[1][3])
  when t[0] == :TmApp && isval(ctx, t[1])
    t2p = eval1(ctx, t[2])
    [:TmApp, t[1], t2p]
  when t[0] == :TmApp
    t1p = eval1(ctx, t[1])
    [:TmApp, t1p, t[2]]
  when t[0] == :TmIf && t[1] == [:TmTrue]
    t[2]
  when t[0] == :TmIf && t[1] == [:TmFalse]
    t[3]
  when t[0] == :TmIf
    [:TmIf, eval1(ctx, t[1]), t[2], t[3]]
  else
    raise NoRuleApplies
  end
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
  case
  when t[0] == :TmVar
    i = t[1]
    getTypeFromContext(ctx, i)
  when t[0] == :TmAbs
    x = t[1]; tyT1 = t[2]; t2 = t[3]
    ctxp = addbinding(ctx, x, [:VarBind, tyT1])
    tyT2 = typeof(ctxp, t2)
    [:TyArr, tyT1, tyT2]
  when t[0] == :TmApp
    t1 = t[1]; t2 = t[2]
    tyT1 = typeof(ctx, t1)
    tyT2 = typeof(ctx, t2)
    case
    when tyT1[0] == :TyArr
      tyT11 = tyT1[1]; tyT12 = tyT1[2]
      if tyT2 == tyT11
        tyT12
      else
        raise "parameter type mismatch"
      end
    else
      raise "arrow type expected"
    end
  when t[0] == :TmTrue
    [:TyBool]
  when t[0] == :TmFalse
    [:TyBool]
  when t[0] == :TmIf
    t1 = t[1]; t2 = t[2]; t3 = t[3]
    if typeof(ctx, t1) == [:TyBool]
      tyT2 = typeof(ctx, t2)
      if tyT2 == typeof(ctx, t3)
        tyT2
      else
        raise "arms of conditional have different types"
      end
    else
      raise "guard of conditional not a boolean"
    end
  end
end

# ------------------------   TEST  ------------------------

if ARGV[0] == "test"
  printf "test1.1: %s\n", getbinding([[:x, [:VarBind, [:TyBool]]]], 0) == [:VarBind, [:TyBool]]
  printf "test1.2: %s\n", getTypeFromContext([[:x, [:VarBind, [:TyBool]]]], 0) == [:TyBool]

  # eval lambda x:Bool. x;
  t = [:TmAbs, "x", [:TyBool], [:TmVar, 0, 1]]
  printf "test2.1: %s\n", typeof([], t) == [:TyArr, [:TyBool], [:TyBool]]
  printf "test2.2: %s\n", eval(  [], t) == [:TmAbs, "x", [:TyBool], [:TmVar, 0, 1]]

  # eval (lambda x:Bool. if x then false else true)
  t = [:TmAbs, "x", [:TyBool], [:TmIf, [:TmVar, 0, 1], [:TmFalse], [:TmTrue]]]
  printf "test3.1: %s\n", typeof([], t) == [:TyArr, [:TyBool], [:TyBool]]
  printf "test3.2: %s\n", eval(  [], t) == t

  # eval (lambda x:Bool->Bool. if x false then true else false)
  t = [:TmAbs, "x", [:TyArr, [:TyBool], [:TyBool]], [:TmIf, [:TmApp, [:TmVar, 0, 1], [:TmFalse]], [:TmTrue], [:TmFalse]]]
  printf "test4.1: %s\n", typeof([], t) == [:TyArr, [:TyArr, [:TyBool], [:TyBool]], [:TyBool]]
  printf "test4.2: %s\n", eval(  [], t) == t

  # eval (lambda x:Bool->Bool. if x false then true else false) (lambda x:Bool. if x then false else true)
  t = [:TmApp, [:TmAbs, "x", [:TyArr, [:TyBool], [:TyBool]], [:TmIf, [:TmApp, [:TmVar, 0, 1], [:TmFalse]], [:TmTrue], [:TmFalse]]], [:TmAbs, "x", [:TyBool], [:TmIf, [:TmVar, 0, 1], [:TmFalse], [:TmTrue]]]]
  printf "test5.1: %s\n", typeof([], t) == [:TyBool]
  printf "test5.2: %s\n", eval(  [], t) == [:TmTrue]
else
  # eval term from stdin
  puts eval([], Kernel.eval(gets())).to_s
end
