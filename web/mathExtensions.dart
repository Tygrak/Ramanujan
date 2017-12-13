import 'dart:math';
import 'Complex.dart';

List<int> NumDivisors(int number){
  List<int> divisors = new List<int>();
  for (var a = 1; a <= sqrt(number); a++){
    if (number % a == 0){
      int b = number~/a;
      divisors.add(a);
      if (a != b){
        divisors.add(b);
      }
    }
  }
  return divisors;
}

double MapToRange(double value, double min1, double max1, double min2, double max2){
  return (value-min1)/(max1-min1) * (max2-min2) + min2;
}

double Fact(double val){
  double res = 1.0;
  for (var i = 2; i < val.round().abs(); i++) {
    res *= i;
  }
  return res;
  //TODO: Gamma function.
}

double cotan(double x){
  return 1/tan(x);
}

double sec(double x){
  return 1/cos(x);
}

double cosec(double x){
  return 1/sin(x);
}

double sinh(double x){
  return (pow(E, x)-pow(E, -x))/2;
}

double cosh(double x){
  return (pow(E, x)+pow(E, -x))/2;
}

double tanh(double x){
  return ((pow(E, x)-pow(E, -x))/2)/((pow(E, x)+pow(E, -x))/2);
}

double cotanh(double x){
  return ((pow(E, x)+pow(E, -x))/2)/((pow(E, x)-pow(E, -x))/2);
}

double sech(double x){
  return 2/(pow(E, x)+pow(E, -x));
}

double cosech(double x){
  return 2/(pow(E, x)-pow(E, -x));
}

double arcsin(double x){
  double a = pi/2;
  double b = -pi/2;
  for (var i = 0; i < 100; i++) {
    if ((sin(a)-x).abs() < (sin(b)-x).abs()){
      b = (a+b*2)/3;
    } else{
      a = (a*2+b)/3;
    }
  }
  return a;
}

double arccos(double x){
  double a = 0.0;
  double b = pi;
  for (var i = 0; i < 100; i++) {
    if ((cos(a)-x).abs() < (cos(b)-x).abs()){
      b = (a+b*2)/3;
    } else{
      a = (a*2+b)/3;
    }
  }
  return a;
}

double arctan(double x){
  double a = pi/2-0.0000001;
  double b = -pi/2+0.0000001;
  for (var i = 0; i < 100; i++) {
    if ((tan(a)-x).abs() < (tan(b)-x).abs()){
      b = (a+b*6)/7;
    } else{
      a = (a*6+b)/7;
    }
  }
  return a;
}

double arccotan(double x){
  double a = 0.0000001;
  double b = pi-0.0000001;
  for (var i = 0; i < 100; i++) {
    if ((cotan(a)-x).abs() < (cotan(b)-x).abs()){
      b = (a+b*6)/7;
    } else{
      a = (a*6+b)/7;
    }
  }
  return a;
}

double arcsec(double x){
  double a = 0.0;
  double b = pi/2-0.0000001;
  x = 1/x;
  for (var i = 0; i < 100; i++) {
    if ((cos(a)-x).abs() < (cos(b)-x).abs()){
      b = (a+b*2)/3;
    } else{
      a = (a*2+b)/3;
    }
  }
  return a;
}

double arccosec(double x){
  double a = 0.0000001;
  double b = pi/2;
  x = 1/x;
  for (var i = 0; i < 100; i++) {
    if ((sin(a)-x).abs() < (sin(b)-x).abs()){
      b = (a+b*2)/3;
    } else{
      a = (a*2+b)/3;
    }
  }
  return a;
}