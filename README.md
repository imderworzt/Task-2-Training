# Task-2-Training

```
Task1.5:(dl: 4/2 10 ngày) ASM
    - Code chương trình thực hiện tính số fibbonaci thứ N(N được nhập vào từ bàn phím) theo 2 hướng: gọi đệ quy và DP. Giải thích sự khác biệt giữa 2 bên, vì sao gọi đệ quy lại có khả năng làm tràn stack...(1 yêu cầu nữa cho code bằng DP là phải đúng với cả trường hợp số lớn)
    - Code chương trình mã hóa RC4, nhập(string) và xuất(hex) trên console.
    - Code chương trình xây dựng lại stack bằng danh sách liên kết(khởi tạo các node bằng malloc()), thực hiện chuyển đổi cơ số từ 10 sang các cơ số khác, Nhập xuất trên console.

Yêu cầu:
    - chạy được
    - không sử dụng biến toàn cục, bắt buộc tự lấy stack để dùng biến cục bộ.
    - bắt buộc tất cả các bài phải xây dựng hàm xử lý(vd bài fibonacci phải có hàm tính fibbonacci, bài, chuyển đổi cơ số phải có hàm chuyển đổi...)
    - Input mặc định là string, xây dựng hàm convert string -> num, cộng trừ số lớn...
```

## Tính số fibonaci

### Trong folder có 2 file chương trình đại diện có 2 hướng là gọi đệ quy và DP

#### Trong đó:

1. Đệ quy: Muốn tính số fibonaci thứ n thì cần quay về bài toán tính số fibonaci thứ n-1 và n-2. Tính ngược đến khi n ở đây bằng 1, khi đó số fibonaci sẽ là 1.
2. DP: Gán số fibonaci thứ nhất và 2 là 1. Sau đó tính xuôi bằng cách cộng 2 giá trị trước đó để ra giá trị tiếp theo. Giá trị vừa tính sẽ được hoán đổi để tính ra giá trị tiếp theo. Cứ làm như vậy cho đến số fibonaci thứ n.

### So sánh:

#### Số phép tính toán khi sử dụng đệ quy sẽ lớn hơn rất nhiều so với sử dụng DP do số lượng lớn lời gọi hàm bị trùng nhau. Khi số lượng này vượt quá dung lượng stack được cấp phát, tràn stack sẽ xảy ra.
#### DP khó làm tràn stack hơn vì kết quả của lần gọi hàm trước được sử dụng ngay cho lần gọi hàm tiếp theo. Từ đó không có tình trạng một lời gọi hàm bị gọi đi gọi lại nhiều lần


