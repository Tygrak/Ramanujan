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