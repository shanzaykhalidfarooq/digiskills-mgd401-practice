/* Task: Write a function named describePerson that utilizes named parameters:
name (type String, required)
age (type int, required)
city (type String, optional with a default value of 'Unknown')
Behavior: The function should print a single line in this format:
"[name] is [age] years old from [city]." 
Verification: In your main() function, call describePerson twice:
Passing only the required arguments (name and age).
Passing all three arguments (name, age, and city).*/

void describePerson({
  required String name,
  required int age,
  String city = 'Unknown',
}) {
  print('$name is $age years old from $city');
}

void main() {
  describePerson(name: 'John', age: 20);
  describePerson(name: 'Bob', age: 18, city: 'New York');
}