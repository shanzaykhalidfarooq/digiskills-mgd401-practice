/*Task: Define a Student class with:
Two properties: String name and List<double> marks.
A constructor to initialize both properties.
A method named calculateAverage() that returns a double representing the average of the items in the marks list.
Verification: In your main() function:
Instantiate a Student object (e.g., name: 'Alex', marks: [85.5, 90.0, 78.5]).
Call calculateAverage() and print the returned average score along with the student's name.*/

class Student{
    String name;
    List<double> marks;
    Student(this.name, this.marks);
    double calculateAverage(){
        double sum = 0;
        for(double mark in marks){
            sum += mark;
        }
        return sum / marks.length;
    }
}

void main(){
    Student student = Student('Alex', [85.5, 90.0, 78.5]);
    double average = student.calculateAverage();
    print('${student.name} has an average score of $average');
}
