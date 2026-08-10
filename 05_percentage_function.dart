//find percentage using user-defined function
double calculatePercentage(double obtainedMarks, double totalMarks) {
  return (obtainedMarks / totalMarks) * 100;
}

void main() {
  double result = calculatePercentage(87, 100);
  print("The Percentage is: $result%");
}
