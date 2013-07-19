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

def printtm(ctx, t)
  case
  when t[0] == :abs
    x  = t[1]; t1 = t[2]
    ctxp, xp = pickfreshname(ctx, x)
    "(lambda " + xp + ". " + printtm(ctxp, t1) + ")"
  when t[0] == :app
    t1 = t[1]; t2 = t[2]
    "(" + printtm(ctx, t1) + " " + printtm(ctx, t2) + ")"
  when t[0] == :var
    x  = t[1]; n  = t[2]
    if ctxlength(ctx) == n
      index2name(ctx, x)
    else
      puts "[bad index]"
    end
  end
end

def term_shift(d, t)
  # todo
end

def term_subst(j, s, t)
  # todo
end

def term_subst_top(s, t)
  # todo
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
  # todo
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
printf "test10: %s\n", printtm([["x", "NameBind"]], [:var, 0, 1]) == "x"
printf "test11: %s\n", printtm([], [:abs, "x", [:var, 0, 1]]) == "(lambda x. x)"
printf "test12: %s\n", printtm([], [:app, [:abs, "x", [:var, 0, 1]], [:abs, "x", [:var, 0, 1]]]) == "((lambda x. x) (lambda x. x))"
printf "test13: %s\n", printtm([], [:app, [:abs, "x", [:var, 0, 1]], [:abs, "x", [:app, [:var, 0, 1], [:var, 0, 1]]]]) == "((lambda x. x) (lambda x. (x x)))"
