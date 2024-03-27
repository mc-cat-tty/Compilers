define i32 @test1(i32 noundef %0) {
  %2 = mul i32 %0, 9
  ret i32 %2 
}

define i32 @test2(i32 noundef %0) {
  %2 = mul i32 15, %0
  ret i32 %2 
}

define i32 @test3(i32 noundef %0) {
  %2 = mul i32 31, 8
  ret i32 %2 
}
