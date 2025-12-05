// =============================================================================
// MyLang 语义分析器（Semantic Analyzer） + 坐标变换核心
// 功能：解释语法树、维护绘图状态（origin/scale/rot/color）、驱动参数化绘图循环
// 作者：李隆生（23009200365）
// 日期：2025-12-05
// 语言：仓颉（Cangjie）
// 依赖：std.math；需配合 Lexer 与 Parser 使用
// -----------------------------------------------------------------------------
// 核心能力：
//   - GetExprValue(root)        // 递归求值 ExprNode（支持 T 参数绑定）
//   - CalcCoord(xnode, ynode)   // 完整坐标变换：缩放 → 旋转 → 平移
//   - setOrigin / setScale / setRot / setcolor  // 更新全局绘图状态
//   - drawloop(...)             // 驱动 FOR-DRAW 循环，调用 drawpixel
// -----------------------------------------------------------------------------
// 全局状态：
//   origin(x,y), scale(x,y), rot(angle), color, paramt（T 的运行时值）
// -----------------------------------------------------------------------------
// 输出接口（需 UI 层实现）：
//   - drawpixel(x: Float64, y: Float64, color: UInt32)
// =============================================================================
package Mylang
import std.math.*

//------------------------------语义分析----------------------------------

// 绘图参数私有变量
var originx:Float64 = 0.0;
var originy:Float64 = 0.0;
var scalex:Float64 = 1.0;
var scaley:Float64 = 1.0;
var rotangle:Float64 = 0.0;
var color:UInt32 = 0x000000;

// 计算表达式的值
func GetExprValue(root:ExprNode):Float64{
    if (root.op == NONTOKEN){
        return 0.0;
    }
    
    return match (root.op){
        case PLUS =>GetExprValue(root.left.getOrThrow()) + GetExprValue(root.right.getOrThrow());
        case MINUS =>GetExprValue(root.left.getOrThrow()) - GetExprValue(root.right.getOrThrow());
        case MUL =>GetExprValue(root.left.getOrThrow()) * GetExprValue(root.right.getOrThrow());
        case DIV =>GetExprValue(root.left.getOrThrow()) / GetExprValue(root.right.getOrThrow());
        case POWER =>pow(GetExprValue(root.left.getOrThrow()), GetExprValue(root.right.getOrThrow()));
        case FUNC =>match (root.mfunc){
                        case Some(function) =>function(GetExprValue(root.funcchild.getOrThrow()));
                        case None => 0.0;
                    }
        case CONST_ID => root.num;
        case T => paramt;
        case _ => 0.0;
    }

}

func CalcCoord(xnode:ExprNode, ynode:ExprNode):(Float64, Float64){
    var x:Float64 = GetExprValue(xnode);
    var y:Float64 = GetExprValue(ynode);
    x *= scalex;
    y *= scaley;
    let tmpx:Float64 = x * cos(rotangle) - y * sin(rotangle);
    y = x * sin(rotangle) + y * cos(rotangle);
    x = tmpx;
    x += originx;
    y += originy;
    return (x, y);
}


func setOrigin(x:ExprNode,y:ExprNode){
    originx = GetExprValue(x);
    originy = GetExprValue(y);
}
func setScale(x:ExprNode,y:ExprNode){
    scalex = GetExprValue(x);
    scaley = GetExprValue(y);
}
func setRot(angle:ExprNode){
    rotangle = GetExprValue(angle);
}
func setcolor(colornode:ExprNode){
    color =UInt32(GetExprValue(colornode));
}

func drawloop(
    startnode:ExprNode,
    endnode:ExprNode, 
    stepnode:ExprNode, 
    xnode:ExprNode, 
    ynode:ExprNode)
{
    var x:Float64 = GetExprValue(xnode);
    var y:Float64 = GetExprValue(ynode);
    var start:Float64 = GetExprValue(startnode);
    var end:Float64 = GetExprValue(endnode);
    var step:Float64 = GetExprValue(stepnode);
    //变量T的动态更新
    paramt = start;
    while (paramt <= end){
        let (xpoint, ypoint) = CalcCoord(xnode, ynode);
        drawpixel(xpoint, ypoint,color);//ui层绘图
        paramt += step;
    }
    paramt = 0.0;
}