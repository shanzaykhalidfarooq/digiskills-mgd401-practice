//Print 1-5 using For, While and Do-while loop
void main() {
  print("=== 01. FOR Loop ===");
  for (int i = 1; i <= 5; i++) {
    print(i);
  }

  print("=== 02. WHILE Loop ===");
  int j = 1;
  while(j <= 5){
    print(j);
    j++;
  }

  print("=== 03. DO-WHILE Loop ===");
  int k = 1;
  do{
    print(k);
    k++;
  }while(k <= 5);
}
