define i32 @test_mul_1(i32 noundef %0) {
  %2 = mul i32 %0, 8
  %3 = add i32 %2, 1
  ret i32 %3
}

define i32 @test_mul_2(i32 noundef %0) {
  %2 = mul i32 8, %0
  %3 = add i32 %2, 1
  ret i32 %3
}

define i32 @test_mul_3(i32 noundef %0) {
  %2 = mul i32 8, 16
  %3 = add i32 %2, 1
  ret i32 %3
}

define i32 @test_div_1(i32 noundef %0) {
  %2 = udiv i32 %0, 8
  %3 = add i32 %2, 1
  ret i32 %3
}

define i32 @test_div_2(i32 noundef %0) {
  %2 = udiv i32 8, %0
  %3 = add i32 %2, 1
  ret i32 %3
}

define i32 @test_div_3(i32 noundef %0) {
  %2 = udiv i32 16, 8
  %3 = add i32 %2, 1
  ret i32 %3
}