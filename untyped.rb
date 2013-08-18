# Modifying http://www.cis.upenn.edu/~bcpierce/tapl/checkers/untyped/ for learning TAPL.
# TYPES AND PROGRAMMING LANGUAGES by Benjamin C. Pierce Copyright (c)2002 Benjamin C. Pierce

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

def ctxlength(ctx)
  ctx.length
end

def sprinttm(ctx, t)
  case
  when t[0] == :abs
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
      x = t[1]; t1 = t[2]
      [:abs, x, walkShift(c + 1, t1, d)]
    when t[0] == :app
      t1 = t[1]; t2 = t[2]
      [:app, walkShift(c, t1, d), walkShift(c, t2, d)]
    end
  end
  walkShift(0, t, d)
end

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
end

def eval(ctx, t)
  begin
    eval(ctx, eval1(ctx, t))
  rescue NoRuleApplies
    t
  end
end

# tests
printf "test1.1: %s\n", isnamebound([], "x") == false
printf "test1.2: %s\n", isnamebound([["y", "NameBind"]], "x") == false
printf "test1.3: %s\n", isnamebound([["x", "NameBind"]], "x") == true
printf "test1.4: %s\n", isnamebound([["y", "NameBind"], ["x", "NameBind"]], "x") == true
printf "test2.1: %s\n", pickfreshname([], "x") == [[["x", "NameBind"]], "x"]
printf "test2.2: %s\n", pickfreshname([["x", "NameBind"]], "x") == [[["x'", "NameBind"], ["x", "NameBind"]], "x'"]
printf "test3.1: %s\n", index2name([["y", "NameBind"], ["x", "NameBind"]], 0) == "y"
printf "test3.2: %s\n", index2name([["y", "NameBind"], ["x", "NameBind"]], 1) == "x"
printf "test4.1: %s\n", sprinttm([["x", "NameBind"]], [:var, 0, 1]) == "x"
printf "test4.2: %s\n", sprinttm([], [:abs, "x", [:var, 0, 1]]) == "(lambda x. x)"
printf "test4.3: %s\n", sprinttm([], [:app, [:abs, "x", [:var, 0, 1]], [:abs, "x", [:var, 0, 1]]]) == "((lambda x. x) (lambda x. x))"
printf "test4.4: %s\n", sprinttm([], [:app, [:abs, "x", [:var, 0, 1]], [:abs, "y", [:app, [:var, 0, 1], [:var, 0, 1]]]]) == "((lambda x. x) (lambda y. (y y)))"
# ((lambda x. x) (lambda y. (y y))) -> (lambda y. (y y))
# ((lambda x. x) (lambda y. y)) -> (lambda y. y)
# ((lambda x. (lambda y. x)) (lambda z. z)) -> (lambda y. (lambda z. z))
# ((lambda x. (lambda x'. x)) (lambda x. x)) -> (lambda x. (lambda x'. x'))
# (((lambda x. (lambda y. x)) (lambda z. z)) (lambda w. w)) -> (lambda z. z)
# ((lambda x. x) ((lambda y. y) (lambda z. z))) -> (lambda z. z)
printf "test5.1: %s\n", sprinttm([], eval([], [:app, [:abs, "x", [:var, 0, 1]], [:abs, "y", [:app, [:var, 0, 1], [:var, 0, 1]]]])) == "(lambda y. (y y))"
printf "test5.2: %s\n", sprinttm([], eval([], [:app, [:abs, "x", [:var, 0, 1]], [:abs, "y", [:var, 0, 1]]])) == "(lambda y. y)"
printf "test5.3: %s\n", sprinttm([], eval([], [:app, [:abs, "x", [:abs, "y", [:var, 1, 2]]], [:abs, "z", [:var, 0, 1]]])) == "(lambda y. (lambda z. z))"
printf "test5.4: %s\n", sprinttm([], eval([], [:app, [:abs, "x", [:abs, "x", [:var, 1, 2]]], [:abs, "x", [:var, 0, 1]]])) == "(lambda x. (lambda x'. x'))"
printf "test5.5: %s\n", sprinttm([], eval([], [:app, [:app, [:abs, "x", [:abs, "y", [:var, 1, 2]]], [:abs, "z", [:var, 0, 1]]], [:abs, "w", [:var, 0, 1]]])) == "(lambda z. z)"
printf "test5.6: %s\n", sprinttm([], eval([], [:app, [:abs, "x", [:var, 0, 1]], [:app, [:abs, "y", [:var, 0, 1]], [:abs, "z", [:var, 0, 1]]]])) == "(lambda z. z)"
