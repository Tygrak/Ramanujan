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
  print(GetPostfixValue(["5", "2", "+", "3", "*", "3", "-", "6", "/"]));
}

void ButtonClicked(e){
  InputElement element = querySelector("[name=equation]");
  String equation = element.value;
  print(equation);
}

List<String> ParseEquation(String equation){
  equation = equation.replaceAll(new RegExp("\s"), "");
  String number = "";
  String lastSymbol = "";
  List<String> stack = new List<String>();
  for (var i = 0; i < equation.length; i++){
    void AddNumberToStack(){
      if (number != ""){
        stack.add(number);
        number = "";
      }
    }
    lastSymbol = equation[i];
    if (equation[i].contains(new RegExp("[0-9i.]"))){
      number += equation[i];
    } else if (equation[i] == "+"){
      AddNumberToStack();
      stack.add("+");
    } else if (equation[i] == "-"){
      if (!lastSymbol.contains(new RegExp("[0-9i.)]"))){
        number += "-";
      } else{
        AddNumberToStack();
        stack.add("-");
      }
    } else if (equation[i] == "*" && i < equation.length && equation[i+1] == "*"){
      AddNumberToStack();
      stack.add("**");
      lastSymbol = "**";
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
      if (number != ""){
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
    }
  }
  return stack;
}

List<String> InfixToPostfix(List<String> inFixStack){
  List<String> stack = new List<String>();
  String lastOperation = "";
  for (var i = 0; i < inFixStack.length; i++){
    int partEnd = i;
    for (var j = i; j < inFixStack.length; j++){
      if (inFixStack[j] == "+" || inFixStack[j] == "-"){
        partEnd = j;
        break;
      }
    }
    for (var j = i; j < inFixStack.length; j++){
      if (inFixStack[j] == "+" || inFixStack[j] == "-"){
        partEnd = j;
        break;
      }
    }
    i = partEnd;
  }
  return inFixStack;
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
    } else if (postfixStack[i] == "pow"){
      double last = stack.removeLast();
      stack.add(pow(stack.removeLast(), last));
    } else if (postfixStack[i] == "ln" || postfixStack[i] == "log"){
      stack.add(log(stack.removeLast()));
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
    } else if (postfixStack[i] == "pi"){
      stack.add(PI);
    } else if (postfixStack[i] == "e"){
      stack.add(E);
    }
    //print(stack);
  }
  return stack.removeLast().toDouble();
}