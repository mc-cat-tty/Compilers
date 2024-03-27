define i32 @test(i32 noundef %0) {
  %2 = mul i32 16, %0
  %3 = add i32 %2, 1
  ret i32 %3
}