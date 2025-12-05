// =============================================================================
// MyLang 绘图与图像输出模块（Rasterizer + BMP Exporter）
// 功能：实现像素级绘制（抗锯齿增强）与 24-bit BMP 无压缩图像保存
// 作者：李隆生（23009200365）
// 日期：2025-12-05
// 语言：仓颉（Cangjie）
// 依赖：std.fs；服务于语义分析模块的 drawpixel / saveImage 接口
// -----------------------------------------------------------------------------
// 核心接口：
//   - drawpixel(x, y, color)     // 绘制 2×2 像素块（简易抗锯齿）
//   - saveImage(filename)        // 保存全局 image 为 filename.bmp
// -----------------------------------------------------------------------------
// Image 类能力：
//   - 白底初始化（800×800 默认）
//   - setpixel(x, y, 0xRRGGBB)  // 自动边界检查，BGR 字节序写入
//   - savebmp(filename)         // 生成标准 BMP（含行对齐、底部起始）
// -----------------------------------------------------------------------------
// 设计说明：
//   - 坐标系：原点 (0,0) 位于左上角，向下 y 递增（符合 BMP 规范）
//   - 颜色格式：输入为 0xRRGGBB，内部存储为 BGR（BMP 要求）
//   - 未压缩 24-bit：兼容性强，便于后续查看/调试
// =============================================================================
package Mylang

import std.fs.*

//全局Image示例
public var image: Image = Image(800, 800)


//外部接口
public func drawpixel(x:Float64,y:Float64,color:UInt32){
    var c:UInt32 = color & 0x00FFFFFF;
    image.setpixel(Int64(x),Int64(y),color)
    image.setpixel(Int64(x)+1,Int64(y),color)
    image.setpixel(Int64(x),Int64(y)+1,color)
    image.setpixel(Int64(x)+1,Int64(y)+1,color)
}

public class Image {
    private var width: Int64
    private var height: Int64
    private var data: Array<Byte>

    // 构造函数：创建白底图像
    public init(w: Int64, h: Int64) {
        this.width = w
        this.height = h
        let size = w * h * 3
        this.data = Array<Byte>(size, repeat: 255);
    }

    //设置像素 (x, y)，左上角为 (0,0)
    // color: 0xRRGGBB, e.g. red = 0xFF0000
    public func setpixel(x: Int64, y: Int64, color: UInt32): Unit {
        if (x < 0 || x >= this.width || y < 0 || y >= this.height) {
            return
        }
        let idx:Int64 = (y * this.width + x) * 3
        this.data[idx + 0] = UInt8((color >> 0) & 0xFF)   // B
        this.data[idx + 1] = UInt8((color >> 8) & 0xFF)    // G
        this.data[idx + 2] = UInt8((color >> 16) & 0xFF)  // R
    }

    // 保存为 24-bit 无压缩 BMP 文件
    public func savebmp(filename: String): Unit {
        var file: File = File(Path(filename + ".bmp"), Write)

        // 计算行字节数（4 字节对齐）
        let row_bytes = ((this.width * 3 + 3) / 4) * 4
        let pixel_data_size = this.height * row_bytes
        let file_size = 14 + 40 + pixel_data_size

        // === BMP 文件头 (14 bytes) ===
        let bm: Array<Byte> = [0x42,0x4D]
        file.write(bm) // BM
        this.write_uint32_le(file, UInt32(file_size))
        this.write_uint16_le(file, 0) // reserved1
        this.write_uint16_le(file, 0) // reserved2
        this.write_uint32_le(file, 54) // offset to pixel data

        // === BMP 信息头 (40 bytes) ===
        this.write_uint32_le(file, 40)                  // header size
        this.write_int32_le(file, Int32(this.width))  // width
        this.write_int32_le(file, Int32(this.height)) // height
        this.write_uint16_le(file, 1)                   // planes
        this.write_uint16_le(file, 24)                  // bit count
        this.write_uint32_le(file, 0)                   // compression (BI_RGB)
        this.write_uint32_le(file, UInt32(pixel_data_size)) // image size
        this.write_int32_le(file, 0)                    // x ppm
        this.write_int32_le(file, 0)                    // y ppm
        this.write_uint32_le(file, 0)                   // colors used
        this.write_uint32_le(file, 0)                   // important colors

        // === 像素数据：从 bottom 行 → top 行 ===
        var row_buffer: Array<Byte> = Array<Byte>(row_bytes, repeat: 0)
        for ( y in this.height-1..=0:-1){
            let src_start = y * this.width * 3
            for (i in 0..this.width * 3) {
                row_buffer[i] = this.data[src_start + i]
            }
            file.write(row_buffer)
        }
        file.close()
    }

    // 小端写入工具函数
    private func write_uint16_le(file: File, v: UInt16): Unit {
        let info:Array<Byte> = [
            UInt8(v & 0xFF),
            UInt8((v >> 8) & 0xFF)
        ]
        file.write(info)
    }

    private func write_uint32_le(file: File, v: UInt32): Unit {
        let info:Array<Byte> = [
            UInt8(v & 0xFF),
            UInt8((v >> 8) & 0xFF),
            UInt8((v >> 16) & 0xFF),
            UInt8((v >> 24) & 0xFF)
        ]
        file.write(info)
    }

    private func write_int32_le(file: File, v: Int32): Unit {
        this.write_uint32_le(file, UInt32(v))
    }
}

public func saveImage(filename:String){
    image.savebmp(filename)
}