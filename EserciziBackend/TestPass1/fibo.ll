; ModuleID = 'fibo.c'
source_filename = "fibo.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx14.0.0"

@__stdoutp = external global ptr, align 8
@.str = private unnamed_addr constant [9 x i8] c"f(0) = 0\00", align 1
@.str.1 = private unnamed_addr constant [9 x i8] c"f(1) = 1\00", align 1
@.str.2 = private unnamed_addr constant [22 x i8] c"f(%d) = f(%d) + f(%d)\00", align 1

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @printf(ptr noundef %format, ...) #0 {
entry:
  %format.addr = alloca ptr, align 8
  %ret = alloca i32, align 4
  %args = alloca ptr, align 8
  store ptr %format, ptr %format.addr, align 8
  call void @llvm.va_start(ptr %args)
  %0 = load ptr, ptr @__stdoutp, align 8
  %1 = load ptr, ptr %format.addr, align 8
  %2 = load ptr, ptr %args, align 8
  %call = call i32 @vfprintf(ptr noundef %0, ptr noundef %1, ptr noundef %2)
  store i32 %call, ptr %ret, align 4
  call void @llvm.va_end(ptr %args)
  %3 = load i32, ptr %ret, align 4
  ret i32 %3
}

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start(ptr) #1

declare i32 @vfprintf(ptr noundef, ptr noundef, ptr noundef) #2

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end(ptr) #1

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @Fibonacci(i32 noundef %n) #0 {
entry:
  %retval = alloca i32, align 4
  %n.addr = alloca i32, align 4
  store i32 %n, ptr %n.addr, align 4
  %0 = load i32, ptr %n.addr, align 4
  %cmp = icmp eq i32 %0, 0
  br i1 %cmp, label %if.then, label %if.end

if.then:                                          ; preds = %entry
  %call = call i32 (ptr, ...) @printf(ptr noundef @.str)
  store i32 0, ptr %retval, align 4
  br label %return

if.end:                                           ; preds = %entry
  %1 = load i32, ptr %n.addr, align 4
  %cmp1 = icmp eq i32 %1, 1
  br i1 %cmp1, label %if.then2, label %if.end4

if.then2:                                         ; preds = %if.end
  %call3 = call i32 (ptr, ...) @printf(ptr noundef @.str.1)
  store i32 1, ptr %retval, align 4
  br label %return

if.end4:                                          ; preds = %if.end
  %2 = load i32, ptr %n.addr, align 4
  %3 = load i32, ptr %n.addr, align 4
  %sub = sub nsw i32 %3, 1
  %4 = load i32, ptr %n.addr, align 4
  %sub5 = sub nsw i32 %4, 2
  %call6 = call i32 (ptr, ...) @printf(ptr noundef @.str.2, i32 noundef %2, i32 noundef %sub, i32 noundef %sub5)
  %5 = load i32, ptr %n.addr, align 4
  %sub7 = sub nsw i32 %5, 1
  %call8 = call i32 @Fibonacci(i32 noundef %sub7)
  %6 = load i32, ptr %n.addr, align 4
  %sub9 = sub nsw i32 %6, 2
  %call10 = call i32 @Fibonacci(i32 noundef %sub9)
  %add = add nsw i32 %call8, %call10
  store i32 %add, ptr %retval, align 4
  br label %return

return:                                           ; preds = %if.end4, %if.then2, %if.then
  %7 = load i32, ptr %retval, align 4
  ret i32 %7
}

attributes #0 = { noinline nounwind optnone ssp uwtable(sync) "frame-pointer"="non-leaf" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8.5a,+v8a,+zcm,+zcz" }
attributes #1 = { nocallback nofree nosync nounwind willreturn }
attributes #2 = { "frame-pointer"="non-leaf" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8.5a,+v8a,+zcm,+zcz" }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"uwtable", i32 1}
!3 = !{i32 7, !"frame-pointer", i32 1}
!4 = !{!"clang version 17.0.6 (https://github.com/llvm/llvm-project/ 6009708b4367171ccdbf4b5905cb6a803753fe18)"}
