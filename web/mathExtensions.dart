import 'dart:math';

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

double OddFact(double val){
  double res = 1.0;
  for (var i = 3; i < val.round().abs(); i+=2) {
    res *= i;
  }
  return res;
  //TODO: Gamma function.
}

double EvenFact(double val){
  double res = 1.0;
  for (var i = 2; i < val.round().abs(); i+=2) {
    res *= i;
  }
  return res;
  //TODO: Gamma function.
}

double ArcSin(double x){
  double res = 0.0;
  for (double i = 1.0; i < 70; i++) {
    // (x^(1 + 2 k) (1/2)_k)/(k! + 2 k k!)
    res += (pow(x, 1+2*i)*(i/2));
  }
  return res;
}