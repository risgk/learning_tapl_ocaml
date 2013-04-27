# Modifying http://www.cis.upenn.edu/~bcpierce/tapl/checkers/arith/ for learning TAPL.
# TYPES AND PROGRAMMING LANGUAGES by Benjamin C. Pierce Copyright (c)2002 Benjamin C. Pierce

class Array
  def head
    self[0]
  end

  def isnumericval
    t = self
    case
    when t.head == :zero
      true
    when t.head == :succ
      t1 = t[1]
      t1.isnumericval
    else
      false
    end
  end

  def isval
    t = self
    case
    when t.head == :true
      true
    when t.head == :false
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
    when t.head == :if && t[1].head == :true
      t[2]
    when t.head == :if && t[1].head == :false
      t[3]
    when t.head == :if
      t1p = t[1].eval1
      Term.new = [:if,tp,t[2],t[3]]
    # TODO
    else
      raise NoRuleApplies
    end
  end

  def eval
    begin
      self.eval1
    rescue NoRuleApplies
      self
    end
  end
end

# Test
printf("test1: %s\n", [:true].eval == [:true])
printf("test2: %s\n", [:if,[:false],[:true],[:false]].eval == [:false])
printf("test3: %s\n", [:zero].eval == [:zero])
printf("test4: %s\n", [:succ,[:pred,[:zero]]].eval == [:succ,[:zero]])
printf("test5: %s\n", [:izsero,[:pred,[:succ,[:succ,[:zero]]]]].eval == [:false])
