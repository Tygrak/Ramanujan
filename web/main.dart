import 'dart:html';
import 'dart:math';
import 'dart:collection';
import 'Variable.dart';
import 'Complex.dart';

ButtonElement button;

void main(){
  button = querySelector("#calculatebutton");
  button.addEventListener("click", ButtonClicked);
}

void ButtonClicked(e){
  PageClearResult();
  InputElement element = querySelector("[name=equation]");
  String equation = element.value;
  List<String> infixStack = ParseEquation(equation);
  print("$infixStack");
  List<String> postfixStack = InfixToPostfix(infixStack);
  print("----------");
  try {
    double expressionValue = GetPostfixValue(postfixStack);
    print("$infixStack -> $postfixStack -> $expressionValue");
    PageAddResult("Result", "$expressionValue");
  } catch (e) {
    VariablePolynom vp = SimplifyPostfix(postfixStack);
    print("$infixStack -> $postfixStack -> $vp");
    PageAddResult("Simplified", "$vp");
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
      if (!lastSymbol.contains(new RegExp("[0-9.)]")) && number == ""){
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
    } else if (equation.length > i+1 && equation.substring(i, i+2) == "pi"){
      if (number == "-"){
        number += PI.toString();
      } else if (number.length > 0){
        AddNumberToStack();
        stack.add("*");
        number = PI.toString();
      } else{
        number = PI.toString();
      }
      AddNumberToStack();
      i += 1;
    } else if (equation[i] == "e"){
      if (number == "-"){
        number += E.toString();
      } else if (number.length > 0){
        AddNumberToStack();
        stack.add("*");
        number = E.toString();
      } else{
        number = E.toString();
      }
      AddNumberToStack();
    } else if (equation[i] == "!"){
      AddNumberToStack();
      stack.add("!");
    } else if (equation.length > i+2 && equation.substring(i, i+3) == "sin"){
      AddNumberToStack();
      stack.add("sin");
      i += 2;
    } else if (equation.length > i+2 && equation.substring(i, i+3) == "cos"){
      AddNumberToStack();
      stack.add("cos");
      i += 2;
    } else if (equation.length > i+2 && equation.substring(i, i+3) == "log"){
      AddNumberToStack();
      stack.add("log");
      i += 2;
    } else if (equation.length > i+1 && equation.substring(i, i+2) == "ln"){
      AddNumberToStack();
      stack.add("ln");
      i += 1;
    } else if (equation.length > i+3 && equation.substring(i, i+4) == "sqrt"){
      AddNumberToStack();
      stack.add("sqrt");
      i += 3;
    } else if (equation[i].contains(new RegExp("[0-9.]"))){
      number += equation[i];
    } else{
      if (number == "-"){
        number += equation[i];
      } else if (number.length > 0){
        AddNumberToStack();
        stack.add("*");
        number = equation[i];
      } else{
        number = equation[i];
      }
      AddNumberToStack();
    }
    lastSymbol = equation[i];
  }
  AddNumberToStack();
  return stack;
}

List<String> InfixToPostfix(List<String> infixStack){
  List<String> stack = new List<String>();
  List<String> opstack = new List<String>();
  for (var i = 0; i < infixStack.length; i++){
    if (infixStack[i].contains(new RegExp("[0-9.]")) || (infixStack[i].contains(new RegExp("[A-Za-z]")) && infixStack[i].length == 1)){
      stack.add(infixStack[i]);
    } else{
      if (infixStack[i] == "("){
        opstack.add("(");
      } else if (infixStack[i] == ")"){
        for (var j = opstack.length-1; j >= 0; j--){
          String last = opstack.removeLast();
          if (last != "("){
            stack.add(last);
          } else{
            break;
          }
        }
      } else if (opstack.length == 0 || opstack[opstack.length-1] == "("){
        opstack.add(infixStack[i]);
      } else if (GetOpPrecedence(opstack[opstack.length-1]) >= GetOpPrecedence(infixStack[i])){
        while (opstack.length > 0 && GetOpPrecedence(opstack[opstack.length-1]) >= GetOpPrecedence(infixStack[i])){
          stack.add(opstack.removeLast());
        }
        opstack.add(infixStack[i]);
      } else if (GetOpPrecedence(opstack[opstack.length-1]) < GetOpPrecedence(infixStack[i])){
        opstack.add(infixStack[i]);
      }
    }
    print("${infixStack[i]} : $opstack : $stack");
  }
  for (var j = opstack.length-1; j >= 0; j--){
    stack.add(opstack.removeLast());
    print("_ : $opstack : $stack");
  }
  return stack;
}

VariablePolynom SimplifyPostfix(List<String> postfixStack){
  List<VariablePolynom> stack = new List<VariablePolynom>();
  for (var i = 0; i < postfixStack.length; i++){
    VariablePolynom value;
    try{
      VariablePolynom vp = new VariablePolynom();
      double val = num.parse(postfixStack[i]);
      vp.variables.add(new Variable(val, 0.0));
      stack.add(vp);
    } catch (e){
      try{
        if (postfixStack[i].contains(new RegExp("[A-Za-z]"))){
          VariablePolynom vp = new VariablePolynom();
          String toParse = postfixStack[i].replaceAll(new RegExp("[A-Za-z]"), "");
          if (toParse.length == 0){
            toParse = "1";
          }
          double val = num.parse(toParse);
          vp.variables.add(new Variable(val, 1.0));
          stack.add(vp);
        }
      } catch (e){
      }
    }
    if (value != null){
      stack.add(value);
    } else if (postfixStack[i] == "+"){
      VariablePolynom last = stack.removeLast();
      stack.add(stack.removeLast()+last);
    } else if (postfixStack[i] == "-"){
      VariablePolynom last = stack.removeLast();
      stack.add(stack.removeLast()-last);
    } else if (postfixStack[i] == "*"){
      VariablePolynom last = stack.removeLast();
      stack.add(stack.removeLast()*last);
    } else if (postfixStack[i] == "**"){
      VariablePolynom last = stack.removeLast();
      VariablePolynom slast = stack.removeLast();
      VariablePolynom res = new VariablePolynom();
      res.variables = new List.from(slast.variables);
      if ((last.variables[0].c).round() == 0){
        res = new VariablePolynom();
        res.variables.add(new Variable(1.0, 0.0));
      } else{
        for (var j = 0; j < (last.variables[0].c-1).round(); j++) {
          res = res * slast;
        }
      }
      stack.add(res);
    } else if (postfixStack[i] == "/"){
      VariablePolynom last = stack.removeLast();
      stack.add(stack.removeLast()/last);
    }
    print("${postfixStack[i]} : $stack");
  }
  return stack.removeLast();
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
    } else if (postfixStack[i] == "!"){
      double fact(double val){
        double res = 1.0;
        for (var i = 2; i < val.round().abs(); i++) {
          res *= i;
        }
        return res;
        //TODO: Gamma function.
      }
      stack.add(fact(stack.removeLast()));
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
    print("${postfixStack[i]} : $stack");
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
  return 4;
}