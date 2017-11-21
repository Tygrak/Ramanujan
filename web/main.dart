import 'dart:html';
import 'dart:math';
import 'dart:collection';

ButtonElement button;

class Complex {
  double _r,_i;
 
  Complex(this._r,this._i);
  double get r => _r;
  double get i => _i;
  int get hashCode => ((17 * r) * 31 + i).floor();
  String toString() => "($r,$i)";
 
  Complex operator +(Complex other) => new Complex(r+other.r,i+other.i);
  Complex operator -(Complex other) => new Complex(r-other.r,i-other.i);
  Complex operator *(Complex other) => new Complex(r*other.r-i*other.i,r*other.i+other.r*i);
  Complex operator /(Complex other) => _Divide(other);
  bool operator ==(Complex other) => (r == other.r) && (i == other.i);
  Complex _Divide (Complex other){
    double temp = other.r*other.r + other.i*other.i;
    if (temp == 0){
      return new Complex(0.0, 0.0);
      //throw new Exception("Complex division leads to division by zero.");
    }
    return new Complex((r*other.r + i*other.i)/temp, (i*other.r - r*other.i)/temp);
  }
  Complex pow (int toPow){
    Complex val = this;
    for (var i = 0; i < toPow; i++) {
      val = val * this;
    }
    return val;
  }
  Complex timesConst (num constant){
    return new Complex(r*constant, i*constant);
  }
  Complex sin (){
    return (Pow(E, new Complex(0.0, 1.0)*this)-Pow(E, new Complex(0.0, -1.0)*this))/(new Complex(0.0, 1.0).timesConst(2));
  }
  Complex cos (){
    return (Pow(E, new Complex(0.0, 1.0)*this)+Pow(E, new Complex(0.0, -1.0)*this))/(new Complex(1.0, 0.0).timesConst(2));
  }
  double abs() => r*r+i*i;
}

Complex Pow(double n, Complex toPow){
  //12^(3 + 2 I) = 1728 cos(2 log(12)) + 1728 i sin(2 log(12))
  return new Complex(cos(toPow.i * log(n)), sin(toPow.i * log(n))).timesConst(pow(n, toPow.r));
}

void main(){
  button = querySelector("#calculatebutton");
  button.addEventListener("click", ButtonClicked);
}

void ButtonClicked(e){
  PageClearResult();
  InputElement element = querySelector("[name=equation]");
  String equation = element.value;
  List<String> inFixStack = ParseEquation(equation);
  print("$inFixStack");
  List<String> postFixStack = InfixToPostfix(inFixStack);
  try {
    double expressionValue = GetPostfixValue(postFixStack);
    print("$inFixStack -> $postFixStack -> $expressionValue");
    PageAddResult("Result", "$expressionValue");
  } catch (e) {
  }
}

void PageClearResult(){
  Element results = querySelector("#results");
  results.innerHtml = "";
}

void PageAddResult(String type, String value){
  Element results = querySelector("#results");
  String result = 
"""<div class="${results.innerHtml.contains("resultitem") ? "resultitem border" : "resultitem"}">
    <div class="type">
      $type:
    </div>
    <div class="result">
      $value
    </div>
  </div>""";
  results.innerHtml = result + results.innerHtml;
}

List<String> ParseEquation(String equation){
  equation = equation.replaceAll(new RegExp("[	 ]"), "");
  String number = "";
  String lastSymbol = "";
  List<String> stack = new List<String>();
  void AddNumberToStack(){
    if (number != ""){
      stack.add(number);
      number = "";
    }
  }
  for (var i = 0; i < equation.length; i++){
    if (equation[i] == "+"){
      AddNumberToStack();
      stack.add("+");
    } else if (equation[i] == "-"){
      if (!lastSymbol.contains(new RegExp("[0-9i.)]")) && number == ""){
        number += "-";
      } else{
        AddNumberToStack();
        stack.add("-");
      }
    } else if (equation[i] == "*" && i < equation.length && equation[i+1] == "*"){
      AddNumberToStack();
      stack.add("**");
      lastSymbol = "**";
      i++;
    } else if (equation[i] == "^"){
      AddNumberToStack();
      stack.add("**");
      lastSymbol = "**";
    } else if (equation[i] == "*"){
      AddNumberToStack();
      stack.add("*");
    } else if (equation[i] == "/"){
      AddNumberToStack();
      stack.add("/");
    } else if (equation[i] == "%"){
      AddNumberToStack();
      stack.add("%");
    } else if (equation[i] == "("){
      bool flag = false;
      if (number == "-"){
        number = "-1";
        flag = true;
      } else if (number != ""){
        flag = true;
      }
      AddNumberToStack();
      if (flag){
        stack.add("*");
      }
      stack.add("(");
    } else if (equation[i] == ")"){
      AddNumberToStack();
      stack.add(")");
    } else if (equation.length > i+2 && equation[i] == "s" && equation[i+1] == "i" && equation[i+2] == "n"){
      AddNumberToStack();
      stack.add("sin");
      i += 2;
    } else if (equation.length > i+2 && equation[i] == "c" && equation[i+1] == "o" && equation[i+2] == "s"){
      AddNumberToStack();
      stack.add("cos");
      i += 2;
    } else if (equation.length > i+2 && equation[i] == "l" && equation[i+1] == "o" && equation[i+2] == "g"){
      AddNumberToStack();
      stack.add("log");
      i += 2;
    } else if (equation.length > i+1 && equation[i] == "l" && equation[i+1] == "n"){
      AddNumberToStack();
      stack.add("ln");
      i += 1;
    } else if (equation.length > i+3 && equation[i] == "s" && equation[i+1] == "q" && equation[i+2] == "r" && equation[i+3] == "t"){
      AddNumberToStack();
      stack.add("sqrt");
      i += 3;
    } else if (equation[i].contains(new RegExp("[0-9i.]"))){
      number += equation[i];
    }
    lastSymbol = equation[i];
  }
  AddNumberToStack();
  return stack;
}

List<String> InfixToPostfix(List<String> inFixStack){
  List<String> stack = new List<String>();
  List<String> opstack = new List<String>();
  for (var i = 0; i < inFixStack.length; i++){
    if (inFixStack[i].contains(new RegExp("[0-9i.]")) && inFixStack[i] != "sin" && inFixStack[i] != "sign" && inFixStack[i] != "ceil"){
      stack.add(inFixStack[i]);
    } else{
      if (inFixStack[i] == "("){
        opstack.add("(");
      } else if (inFixStack[i] == ")"){
        for (var j = opstack.length-1; j >= 0; j--){
          String last = opstack.removeLast();
          if (last != "("){
            stack.add(last);
          } else{
            break;
          }
        }
      } else if (opstack.length == 0 || opstack[opstack.length-1] == "("){
        opstack.add(inFixStack[i]);
      } else if (GetOpPrecedence(opstack[opstack.length-1]) >= GetOpPrecedence(inFixStack[i])){
        while (opstack.length > 0 && GetOpPrecedence(opstack[opstack.length-1]) >= GetOpPrecedence(inFixStack[i])){
          stack.add(opstack.removeLast());
        }
        opstack.add(inFixStack[i]);
      } else if (GetOpPrecedence(opstack[opstack.length-1]) < GetOpPrecedence(inFixStack[i])){
        opstack.add(inFixStack[i]);
      }
    }
    print("${inFixStack[i]} : $opstack : $stack");
  }
  for (var j = opstack.length-1; j >= 0; j--){
    stack.add(opstack.removeLast());
    print("_ : $opstack : $stack");
  }
  return stack;
}

double GetPostfixValue(List<String> postfixStack){
  Queue<num> stack = new Queue<num>();
  for (var i = 0; i < postfixStack.length; i++){
    num value;
    try{
      value = num.parse(postfixStack[i]);
    } catch (e){
    }
    if (value != null){
      stack.add(value);
    } else if (postfixStack[i] == "+"){
      double last = stack.removeLast();
      stack.add(stack.removeLast()+last);
    } else if (postfixStack[i] == "-"){
      double last = stack.removeLast();
      stack.add(stack.removeLast()-last);
    } else if (postfixStack[i] == "*"){
      double last = stack.removeLast();
      stack.add(stack.removeLast()*last);
    } else if (postfixStack[i] == "**"){
      double last = stack.removeLast();
      stack.add(pow(stack.removeLast(), last));
    } else if (postfixStack[i] == "/"){
      double last = stack.removeLast();
      stack.add(stack.removeLast()/last);
    } else if (postfixStack[i] == "%"){
      double last = stack.removeLast();
      stack.add(stack.removeLast()%last);
    } else if (postfixStack[i] == "sin"){
      stack.add(sin(stack.removeLast()));
    } else if (postfixStack[i] == "cos"){
      stack.add(cos(stack.removeLast()));
    } else if (postfixStack[i] == "tan"){
      stack.add(tan(stack.removeLast()));
    } else if (postfixStack[i] == "sqrt"){
      stack.add(sqrt(stack.removeLast()));
    } else if (postfixStack[i] == "ln"){
      stack.add(log(stack.removeLast()));
    } else if (postfixStack[i] == "log"){
      stack.add(log(stack.removeLast())/log(10));
    } else if (postfixStack[i] == "abs"){
      double last = stack.removeLast();
      if (last > 0){
        stack.add(last);
      } else{
        stack.add(-last);
      }
    } else if (postfixStack[i] == "sign"){
      double last = stack.removeLast();
      if (last > 0){
        stack.add(1);
      } else if (last < 0){
        stack.add(-1);
      } else{
        stack.add(0);
      }
    } else if (postfixStack[i] == "floor"){
      stack.add((stack.removeLast()).floorToDouble());
    } else if (postfixStack[i] == "ceil"){
      stack.add((stack.removeLast()).ceilToDouble());
    } else if (postfixStack[i] == "round"){
      stack.add((stack.removeLast()).roundToDouble());
    }
  }
  return stack.removeLast().toDouble();
}

int GetOpPrecedence(String op){
  if (op == "+"){
    return 1;
  } else if (op == "-"){
    return 1;
  } else if (op == "*"){
    return 2;
  } else if (op == "/"){
    return 2;
  } else if (op == "%"){
    return 2;
  } else if (op == "**"){
    return 3;
  } else if (op == "("){
    return 0;
  } 
  return 1;
}