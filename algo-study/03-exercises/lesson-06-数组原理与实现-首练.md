# Lesson 06 首练：数组原理与实现

## 使用说明

- 本练习分为“理解题 + 代码骨架填空”两部分。
- 先写思路，再动代码；代码不求一步到位。
- 我会按你的推理过程点评，不直接给完整答案。

---

## 一、理解题（先写）

### 1) 数组为什么支持按下标快速访问？

你的作答：

因为数组是连续存储的


### 2) 数组中间插入为什么常常更慢？

你的作答：

因为数组是连续存储的，中间插入需要将后面的元素向后移动，所以更慢。


### 3) 数组删除中间元素为什么也可能更慢？

你的作答：

因为数组是连续存储的，删除中间元素需要将后面的元素向前移动，所以更慢。

---

## 二、复杂度判断（写“常数级/线性级”即可）

假设数组长度为 `n`：

- 读取 `arr[i]`：常数级
- 在尾部追加（容量足够）：常数级，因为数组是连续存储的，所以在尾部追加的时间复杂度是O(1)。单次扩容会慢，但长期平均追加依然很快（均摊意义上接近常数）。
- 在头部插入：线性级，因为数组是连续存储的，所以需要将后面的元素向后移动，所以时间复杂度是O(n)。
- 查找某个值（无序数组）：线性级，因为需要遍历数组，所以时间复杂度是O(n)。

你的简要理由：



---

## 三、代码骨架（请你补全 TODO）

请在本文件直接补全以下代码里的 TODO，不要另建文件。

```python
class MyArray:
    def __init__(self, capacity=4):
        self.capacity = capacity
        self.size = 0
        self.data = [None] * capacity

    def _resize(self):
        # TODO 1: 扩容为原来的 2 倍
        self.capacity = self.capacity * 2
        # TODO 2: 把旧数据拷贝到新数组
        new_data = [None] * self.capacity
        for i in range(self.size):
            new_data[i] = self.data[i]
        self.data = new_data

    def append(self, val):
        # TODO 3: 容量满时先扩容
        if self.size == self.capacity:
            self._resize()
        # TODO 4: 在尾部写入 val，并维护 size
        self.data[self.size] = val
        self.size += 1
        return self.data

    def get(self, index):
        # TODO 5: 做边界检查，越界抛出 IndexError
        if index < 0 or index >= self.size:
            raise IndexError("Index out of range")
        # TODO 6: 返回对应位置元素
        return self.data[index]

    def insert(self, index, val):
        # TODO 7: 边界检查（允许 index == size）
        if index < 0 or index > self.size:
            raise IndexError("Index out of range")
        # TODO 8: 必要时扩容
        if self.size == self.capacity:
            self._resize()
        # TODO 9: 从后往前搬移元素，腾出 index 位置
        for i in range(self.size - 1, index - 1, -1):
            self.data[i + 1] = self.data[i]
        # TODO 10: 写入 val，维护 size
        self.data[index] = val
        self.size += 1
        return self.data

    def __repr__(self):
        return str(self.data[:self.size])
```

---

## 四、自测（做完再看）

- 你是否能说清：`append` 绝大多数时候快，但偶尔扩容会慢？
- 你是否能解释：`insert` 慢主要慢在“搬移元素”？
- 你是否在 `get` / `insert` 做了边界检查？
