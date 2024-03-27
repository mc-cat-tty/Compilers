define i32 @neutral_sum(i32 noundef %0) {
  %2 = add i32 %0, 0
  %3 = add i32 0, %0
  %4 = mul i32 %2, %3
  ret i32 %4
}

define i32 @neutral_mul(i32 noundef %0) {
  %2 = mul i32 %0, 1
  %3 = mul i32 1, %0
  %4 = mul i32 %2, %3
  ret i32 %4
}