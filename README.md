# 函数绘图语言解释器  
—— 西安电子科技大学 · 李隆生（学号：23009200365）

一个用仓颉语言（Cangjie）实现的领域专用语言（DSL）解释器，支持通过简洁脚本描述参数曲线并绘图。程序读取同目录下的 `input.txt`，解析执行后输出图形，生成`output.bmp`。

## 语法规则

- 坐标系设置：
  - `origin is (x, y);`        // 设置逻辑原点在画布的位置（像素）
  - `scale is (sx, sy);`       // 设置单位长度对应的像素缩放（负值可镜像）
  - `rot is θ;`                // 设置旋转角度（弧度，逆时针为正）

- 颜色设置：
  - `color is RED | GREEN | BLUE | YELLOW | BLACK | WHITE | LLS | 常数;`
  - `LLS` 为作者自定义随机颜色

- 绘图命令：
  - `for t from a to b step dt draw (expr_x, expr_y);`
  - `t` 是唯一变量，仅在该语句内有效

- 表达式支持：
  - 常量：`PI`, `E`
  - 函数：`sin`, `cos`, `tan`, `exp`, `log`, `sqrt`, `abs`
  - 运算符：`+`, `-`, `*`, `/`, `**`
  - 注释：`//` 或 `--`
  - 字母大小写不敏感：`FOR T FROM`、`color IS red;`、`PI`/`pi` 均合法
- 字母大小写

## 示例 input.txt
-- 绘制单位圆  
`origin is (400, 300);`  
`scale is (100, 100);`  
`rot is 0;`
`color is BLUE;`  
`for t from 0 to 2*PI step 0.01 draw (cos(t), sin(t));`

-- 绘制经典爱心曲线  
`origin is (400, 300);`  
`scale is (15, 15);`  
`rot is PI/12;`  
`color is RED;`  
`for t from 0 to 2*PI step 0.002 draw (16*(sin(t))**3, 13*cos(t) - 5*cos(2*t) - 2*cos(3*t) - cos(4*t));`

## 运行方式

0. **环境准备**  
   确保已正确配置仓颉编译环境（详见官网），在MyLang目录下运行cjpm -v 查看是否配置成功：  
   ```sh
   cjpm -v  
1. **使用 cjpm 构建运行**  
   在MyLang目录下运行cjpm run 即可读取同目录下的 `input.txt`，生成`output.bmp` ：
   ```sh
   cjpm run
## 设计实现简要说明

- **模块化 pipeline**：词法 → 语法 → 语义 → 渲染四阶段解耦，支持增量扩展。  
- **词法分析**：手写直接扫描器，Token 含类型/词素/数值/函数指针；关键字与函数名查表映射；支持 `//` / `--` 注释与大小写不敏感。  
- **语法分析**：递归下降解析器，三层优先级（`Expr → Term → Factor`）构建 AST；支持嵌套表达式与右结合幂运算 `**`。  
- **语义执行**：  
  - 全局上下文维护 `origin` / `scale` / `rot` / `color`；  
  - `GetExprValue` 递归求值，结合 `match case` 与 `Option` 安全访问子节点；  
  - `CalcCoord` 按「缩放 → 旋转 → 平移」顺序变换坐标。  
- **图形输出**：  
  - `Image` 类：`Array<Byte>` 存储 800×800 24-bit BGR 位图；  
  - `setpixel` 边界检查 + `drawpixel` 绘 2×2 块抗锯齿；  
  - `savebmp` 实现标准 BMP 编码（小端序、行4字节对齐、倒序存储），**零外部依赖** 纯仓颉原生库。  