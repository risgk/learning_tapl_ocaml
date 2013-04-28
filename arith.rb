# Modifying http://www.cis.upenn.edu/~bcpierce/tapl/checkers/arith/ for learning TAPL.
# TYPES AND PROGRAMMING LANGUAGES by Benjamin C. Pierce Copyright (c)2002 Benjamin C. Pierce

class Array
  def isnumericval
    t = self
    case
    when t[0] == :zero
      true
    when t[0] == :succ
      t[1].isnumericval
    else
      false
    end
  end

  def isval
    t = self
    case
    when t[0] == :true
      true
    when t[0] == :false
      true
    when t.isnumericval
      true
    else
      false
    end
  end

  class NoRuleApplies < Exception; end

  def eval1
    t = self
    case
    when t[0] == :if && t[1][0] == :true
      t[2]
    when t[0] == :if && t[1][0] == :false
      t[3]
    when t[0] == :if
      [:if,t[1].eval1,t[2],t[3]]
    when t[0] == :succ
      [:succ,t[1].eval1]
    when t[0] == :pred && t[1][0] == :zero
      [:zero]
    when t[0] == :pred && t[1][0] == :succ && t[1][1].isnumericval
      t[1][1]
    when t[0] == :pred
      [:pred,t[1].eval1]
    when t[0] == :iszero && t[1][0] == :zero
      [:true]
    when t[0] == :iszero && t[1][0] == :succ && t[1][1].isnumericval
      [:false]
    when t[0] == :iszero
      [:iszero,t[1].eval1]
    else
      raise NoRuleApplies
    end
  end

  def eval
    t = self
    begin
      t.eval1.eval
    rescue NoRuleApplies
      t
    end
  end
end

# Test
printf("test1: %s\n", [:true].eval == [:true])
printf("test2: %s\n", [:false].eval == [:false])
printf("test3: %s\n", [:if,[:true],[:true],[:false]].eval == [:true])
printf("test4: %s\n", [:if,[:false],[:true],[:false]].eval == [:false])
printf("test5: %s\n", [:if,[:if,[:true],[:true],[:false]],[:true],[:false]].eval == [:true])
printf("test6: %s\n", [:if,[:if,[:false],[:true],[:false]],[:true],[:false]].eval == [:false])
printf("test7: %s\n", [:zero].eval == [:zero])
printf("test8: %s\n", [:succ,[:pred,[:zero]]].eval == [:succ,[:zero]])
printf("test9: %s\n", [:iszero,[:succ,[:zero]]].eval == [:false])
printf("test10: %s\n", [:iszero,[:pred,[:succ,[:zero]]]].eval == [:true])
printf("test11: %s\n", [:iszero,[:pred,[:succ,[:succ,[:zero]]]]].eval == [:false])
