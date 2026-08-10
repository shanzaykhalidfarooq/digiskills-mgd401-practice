//students record management system
void main(){
  List<String> studentName = ["Ali", "Ahmed", "Umer", "Bilal", "Hamza"];
  List<int> studentMarks = [98, 67, 23, 81, 75];

  int fail = 0;
  for(int i=0; i<studentMarks.length; i++){
    if(studentMarks[i] > 33){
      print("Student Name: ${studentName[i]} , Marks: ${studentMarks[i]} , Status = Passed!");
    }else{
      fail++;
      print("Student Name: ${studentName[i]} , Marks: ${studentMarks[i]} , Status = Failed!");
    }
  }

  int max = studentMarks[0];
  for(int j=0; j<studentMarks.length; j++){
    if(max<studentMarks[j]){
      max = studentMarks[j];
    }
  }
  print("1st Position = $max marks");
  print("Passed students: ${studentMarks.length - fail}");
  print("Failed students: $fail");
}
