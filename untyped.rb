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
  def walk(c, t, d)
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
      [:abs, x, walk(c + 1, t1, d)]
    when t[0] == :app
      t1 = t[1]; t2 = t[2]
      [:app, walk(c, t1, d), walk(c, t2, d)]
    end
  end
  walk(0, t, d)
end

def termSubst(j, s, t)
  def walk(c, t, j, s)
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
      [:abs, x, walk(c + 1, t1, j, s)]
    when t[0] == :app
      t1 = t[1]; t2 = t[2]
      [:app, walk(c, t1, j, s), walk(c, t2, j, s)]
    end
  end
  walk(0, t, j, s)
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
    termSubstTop(t1p. t[2])
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
printf "test1: %s\n", isnamebound([], "x") == false
printf "test2: %s\n", isnamebound([["y", "NameBind"]], "x") == false
printf "test3: %s\n", isnamebound([["x", "NameBind"]], "x") == true
printf "test4: %s\n", isnamebound([["y", "NameBind"], ["x", "NameBind"]], "x") == true
printf "test5: %s\n", pickfreshname([], "x") == [[["x", "NameBind"]], "x"]
printf "test6: %s\n", pickfreshname([["x", "NameBind"]], "x") == [[["x'", "NameBind"], ["x", "NameBind"]], "x'"]
printf "test7: %s\n", index2name([["y", "NameBind"], ["x", "NameBind"]], 0) == "y"
printf "test8: %s\n", index2name([["y", "NameBind"], ["x", "NameBind"]], 1) == "x"
printf "test9: %s\n", index2name([["y", "NameBind"], ["x", "NameBind"]], 2) == nil
printf "test10: %s\n", sprinttm([["x", "NameBind"]], [:var, 0, 1]) == "x"
printf "test11: %s\n", sprinttm([], [:abs, "x", [:var, 0, 1]]) == "(lambda x. x)"
printf "test12: %s\n", sprinttm([], [:app, [:abs, "x", [:var, 0, 1]], [:abs, "x", [:var, 0, 1]]]) == "((lambda x. x) (lambda x. x))"
printf "test13: %s\n", sprinttm([], [:app, [:abs, "x", [:var, 0, 1]], [:abs, "y", [:app, [:var, 0, 1], [:var, 0, 1]]]]) == "((lambda x. x) (lambda y. (y y)))"
printf "test14: %s\n", sprinttm([], eval([], [:app, [:abs, "x", [:var, 0, 1]], [:abs, "y", [:app, [:var, 0, 1], [:var, 0, 1]]]])) == "(lambda y. (y y))"
