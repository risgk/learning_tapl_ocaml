# Modifying http://www.cis.upenn.edu/~bcpierce/tapl/checkers/simplebool/ for learning TAPL.
# TYPES AND PROGRAMMING LANGUAGES by Benjamin C. Pierce Copyright (c)2002 Benjamin C. Pierce

# CAUTION: Pattern match may not work well...

# $ gem install case_class
# ref: http://github.com/mame/case_class
require "case_class"
include CaseClass

# Datatypes

# ty
TyArr  = Case[:ty1,:ty2]
TyBool = Case[:dummy]

# term
TmVar   = Case[:x,:n]
TmAbs   = Case[:x,:tyT1,:t2]
TmApp   = Case[:t1,:t2]
TmTrue  = Case[:dummy]
TmFalse = Case[:dummy]
TmIf    = Case[:t1,:t2,:t3]

# binding
NameBind = Case[:dummy]
VarBind  = Case[:ty]

# ------------------------   SYNTAX  ------------------------

# Context management

def addbinding(ctx,x,bind)
  [[x,bind]] + ctx
end

# Shifting

def termShift(d,t)
  def walkShift(c,t,d)
    case t
    when TmVar[x=_,n=_]
      if x >= c
        TmVar[x+d,n+d]
      else
        TmVar[x,n+d]
      end
    when TmAbs[x=_,tyT1=_,t2=_]
      TmAbs[x,tyT1,walkShift(c+1,t2,d)]
    when TmApp[t1=_,t2=_]
      TmApp[walkShift(c,t1,d),walkShift(c,t2,d)]
    when TmTrue[nil]
      t
    when TmFalse[nil]
      t
    when TmIf[t1=_,t2=_,t3=_]
      TmIf[walkShift(c,t1,d),walkShift(c,t2,d),walkShift(c,t3,d)]
    end
  end
  walkShift(0,t,d)
end

# Substitution

def termSubst(j,s,t)
  def walkSubst(c,t,j,s)
    case t
    when TmVar[x=_,n=_]
      if x == j+c
        termShift(c,s)
      else
        TmVar[x,n]
      end
    when TmAbs[x=_,tyT1=_,t2=_]
      TmAbs[x,tyT1,walkSubst(c+1,t2,j,s)]
    when TmApp[t1=_,t2=_]
      TmApp[walkSubst(c,t1,j,s),walkSubst(c,t2,j,s)]
    when TmTrue[nil]
      t
    when TmFalse[nil]
      t
    when TmIf[t1=_,t2=_,t3=_]
      TmIf[walkSubst(c,t1,j,s),walkSubst(c,t2,j,s),walkSubst(c,t3,j,s)]
    end
  end
  walkSubst(0,t,j,s)
end

def termSubstTop(s,t)
  termShift(-1,(termSubst(0,(termShift(1,s)),t)))
end

# Context management (continued)

def getbinding(ctx,i)
  if i < ctx.length
    ctx[i][1]
  else
    raise "Variable lookup failure"
  end
end

def getTypeFromContext(ctx,i)
  b = getbinding(ctx,i)
  case b
  when VarBind[tyT=_]
    tyT
  else
    raise "Wrong kind of binding for variable"
  end
end

# ------------------------   EVALUATION  ------------------------

def isval(ctx,t)
  case t
  when TmTrue[nil]
    true
  when TmFalse[nil]
    true
  when TmAbs[_,_,_]
    true
  else
    false
  end
end

class NoRuleApplies < Exception; end

def eval1(ctx,t)
  # p t
  case
  when TmApp[TmAbs[_,_,t13=_],t2=_] === t && isval(ctx,t2)
    termSubstTop(t2,t13)
  when TmApp[t1=_,t2=_] === t && isval(ctx,t1)
    t2p = eval1(ctx,t2)
    TmApp[t1,t2p]
  when TmApp[t1=_,t2=_] === t
    t1p = eval1(ctx,t1)
    TmApp[t1p,t2]
  when TmIf[t1=_,t2=_,_] === t && t1 === TmTrue[nil]
    t2
  when TmIf[t1=_,_,t3=_] === t && t1 === TmFalse[nil]
    t3
  when TmIf[t1=_,t2=_,t3=_] === t
    TmIf[eval1(ctx,t1),t2,t3]
  else
    raise NoRuleApplies
  end
end

def eval(ctx,t)
  begin
    eval(ctx,eval1(ctx,t))
  rescue NoRuleApplies
    t
  end
end

# ------------------------   TYPING  ------------------------

def typeof(ctx,t)
  # p t
  case t
  when TmVar[i=_,_]
    getTypeFromContext(ctx,i)
  when TmAbs[x=_,tyT1=_,t2=_]
    ctxp = addbinding(ctx,x,VarBind[tyT1])
    tyT2 = typeof(ctxp,t2)
    TyArr[tyT1,tyT2]
  when TmApp[t1=_,t2=_]
    tyT1 = typeof(ctx,t1)
    tyT2 = typeof(ctx,t2)
    case tyT1
    when TyArr[tyT11=_,tyT12=_]
      if tyT2 === tyT11
        tyT12
      else
        raise "parameter type mismatch"
      end
    else
      raise "arrow type expected"
    end
  when TmTrue[nil]
    TyBool[nil]
  when TmFalse[nil]
    TyBool[nil]
  when TmIf[t1=_,t2=_,t3=_]
    if typeof(ctx,t1) == TyBool[nil]
      tyT2 = typeof(ctx,t2)
      if tyT2 == typeof(ctx,t3)
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
  printf "test1.1: %s\n",getbinding([[:x,VarBind[TyBool[nil]]]],0) == VarBind[TyBool[nil]]
  printf "test1.2: %s\n",getTypeFromContext([[:x,VarBind[TyBool[nil]]]],0) == TyBool[nil]

  # eval lambda x:Bool. x;
  t = TmAbs["x",TyBool[nil],TmVar[0,1]]
  printf "test2.1: %s\n",typeof([],t) == TyArr[TyBool[nil],TyBool[nil]]
  printf "test2.2: %s\n",eval(  [],t) == TmAbs["x",TyBool[nil],TmVar[0,1]]

  # eval (lambda x:Bool. if x then false else true)
  t = TmAbs["x",TyBool[nil],TmIf[TmVar[0,1],TmFalse[nil],TmTrue[nil]]]
  printf "test3.1: %s\n",typeof([],t) == TyArr[TyBool[nil],TyBool[nil]]
  printf "test3.2: %s\n",eval(  [],t) == t

  # eval (lambda x:Bool->Bool. if x false then true else false)
  t = TmAbs["x",TyArr[TyBool[nil],TyBool[nil]],TmIf[TmApp[TmVar[0,1],TmFalse[nil]],TmTrue[nil],TmFalse[nil]]]
  printf "test4.1: %s\n",typeof([],t) == TyArr[TyArr[TyBool[nil],TyBool[nil]],TyBool[nil]]
  printf "test4.2: %s\n",eval(  [],t) == t

  # eval (lambda x:Bool->Bool. if x false then true else false) (lambda x:Bool. if x then false else true)
  t = TmApp[TmAbs["x",TyArr[TyBool[nil],TyBool[nil]],TmIf[TmApp[TmVar[0,1],TmFalse[nil]],TmTrue[nil],TmFalse[nil]]],TmAbs["x",TyBool[nil],TmIf[TmVar[0,1],TmFalse[nil],TmTrue[nil]]]]
  printf "test5.1: %s\n",typeof([],t) == TyBool[nil]
  printf "test5.2: %s\n",eval(  [],t) == TmTrue[nil]
else
  # eval term from stdin
  puts eval([],Kernel.eval(gets())).to_s
end
