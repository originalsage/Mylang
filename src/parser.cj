// =============================================================================
// MyLang 语法分析器（Parser） + 语义动作骨架
// 功能：基于词法 Token 序列，构建表达式语法树（ExprNode），驱动语义分析接口
// 作者：李隆生（23009200365）
// 日期：2025-12-05
// 语言：仓颉（Cangjie）
// 依赖：std.fs, std.math；需配合 MyLang/Lexer 使用
// -----------------------------------------------------------------------------
// 核心接口：
//   - Parse(filePath: Path, bmpName: String)   // 入口：解析文件 → 生成图像
//   - program() / statement() / expression() …  // 递归下降语法分析
//   - MakeExprNode(…)                         // 语法树节点构造工厂
// -----------------------------------------------------------------------------
// 语义动作占位（需外部实现）：
//   - setOrigin(x, y)  / setScale(x, y)
//   - setRot(angle)    / setcolor(color)
//   - drawloop(start, end, step, x, y)
//   - saveImage(name)
// -----------------------------------------------------------------------------
// 特色支持：
//   - 完整表达式文法：支持 + - * / **、一元 +/-、函数调用、括号嵌套
//   - 语法树可视化：缩进式打印（AST 折叠风格）
//   - 调试追踪：enter/outer 缩进日志，token 匹配 trace
// =============================================================================
package Mylang
import std.fs.*
import std.math.*

// 全局变量

public var paramt:Float64 = 0.0;
// 辅助变量
public var curtoken:Token = Token();
var xnode:ExprNode=ExprNode();
var ynode:ExprNode=ExprNode();
var startnode:ExprNode=ExprNode();
var endnode:ExprNode=ExprNode();
var stepnode:ExprNode=ExprNode();
var anglenode:ExprNode=ExprNode();
var colornode:ExprNode=ExprNode();

var indentcnt:Int64 = 0;//缩进字符数

//语法树节点 class 引用类型
public class ExprNode{
    //主构造函数
    ExprNode(
        protected var op!:TokenType = NONTOKEN,
        protected var left!:?ExprNode = None,//左子树
        protected var right!:?ExprNode = None,//右子树
        protected var funcchild!:?ExprNode = None,//函数子树
        protected var mfunc!:?(Float64)->Float64 = None,//函数指针 Option<(f)->f>类型
        protected var num!:Float64 = 0.0//常量
        ){

    }
    public func printtree(indent:Int64,islast:Bool,prefix:String):Unit{
        if(this.op == NONTOKEN){
            return;
        }
        print(prefix);
        match (islast){
            case true => print("└── ");
            case false => print("├── ");
        };
        match(this.op){
            case CONST_ID => println(this.num);
            case FUNC => println("func");
            case T => println("T");
            case PLUS => println("+");
            case MINUS => println("-");
            case MUL => println("*");
            case DIV => println("/");
            case POWER => println("**");
            case _ => println("UNKNOWN");return;
        };
        var newprefix:String = prefix + match(islast){
            case true  => "    ";
            case false => "│   ";
        };
        match (this.op){
            case FUNC => 
                this.funcchild?.printtree(indent + 1,true,newprefix);
            case PLUS|MINUS|MUL|DIV|POWER => 
                this.left?.printtree(indent + 1,false,newprefix);
                this.right?.printtree(indent + 1,true,newprefix);
            case _ => ();
        }
    }
}


//------------------------语法分析--------------------------
func program(){ 
    enter("program");
    while(curtoken.tokentype != NONTOKEN){
        statement();
        MatchToken(SEMICO);
    }
    outer("program");
}
func statement(){
    enter("statement");
    match(curtoken.tokentype){
        case ORIGIN => originstm();
        case SCALE => scalestm();
        case ROT => rotstm();
        case COLOR => colstm()
        case FOR => forstm();
        
        case _ => wa(2);
    }
    outer("statement");
}
func originstm(){
    enter("origin");
    MatchToken(ORIGIN);
    MatchToken(IS);
    MatchToken(L_BRACKET);
    //x
    xnode = expression();
    printExprtree(xnode);
    MatchToken(COMMA);
    //y
    ynode = expression();
    printExprtree(ynode);
    MatchToken(R_BRACKET);
    outer("origin");
    setOrigin(xnode,ynode);//语义分析
    
}
func scalestm(){
    enter("scale");
    MatchToken(SCALE);
    MatchToken(IS);
    MatchToken(L_BRACKET);
    //x
    xnode = expression();
    printExprtree(xnode);
    MatchToken(COMMA);
    //y
    ynode = expression();
    printExprtree(ynode);
    MatchToken(R_BRACKET);
    outer("scale");
    setScale(xnode,ynode);//语义分析
}
func rotstm(){
    enter("rot");
    MatchToken(ROT);
    MatchToken(IS);
    //angle
    anglenode = expression();
    printExprtree(anglenode);
    outer("rot");
    setRot(anglenode);//语义分析
}
func colstm(){
    enter("color");
    MatchToken(COLOR);
    MatchToken(IS);
    //color
    colornode = expression();
    printExprtree(colornode);
    outer("color");
    setcolor(colornode);//语义分析
}
func forstm(){
    enter("for");
    MatchToken(FOR);
    MatchToken(T);
    MatchToken(FROM);
    //start
    startnode = expression();
    printExprtree(startnode);
    MatchToken(TO);
    //end
    endnode = expression();
    printExprtree(endnode);
    MatchToken(STEP);
    //step
    stepnode = expression();
    printExprtree(stepnode);
    MatchToken(DRAW);
    MatchToken(L_BRACKET);
    //x
    xnode = expression();
    printExprtree(xnode);
    MatchToken(COMMA);
    //y
    ynode = expression();
    printExprtree(ynode);
    MatchToken(R_BRACKET);
    outer("for");
    drawloop(startnode,endnode,stepnode,xnode,ynode);//语义分析
}
// Expression → Term  {（PLUS |MINUS ） Term }
func expression(){
    var left:ExprNode;
    var right:ExprNode;
    var op:TokenType;//保存运算符类型
    left = term();
    while(curtoken.tokentype == PLUS || curtoken.tokentype == MINUS){
        op = curtoken.tokentype;
        MatchToken(op);
        right = term();
        left = MakeExprNode(op,left,right);
    }
    return left;
}
//Term → Factor { （ MUL | DIV ） Factor }
func term():ExprNode{ 
    var left:ExprNode;
    var right:ExprNode;
    var op:TokenType;//保存运算符类型
    left = factor();
    while(curtoken.tokentype == MUL || curtoken.tokentype == DIV){
        op = curtoken.tokentype;
        MatchToken(op);
        right = factor();

        left = MakeExprNode(op,left,right);
    }
    return left;
}
//Factor →（PLUS | MINUS） Factor | Component
func factor():ExprNode{
    var left:ExprNode;
    var right:ExprNode;
    match(curtoken.tokentype){
        case PLUS =>
            MatchToken(PLUS);
            right = factor();
        case MINUS =>
            MatchToken(MINUS);
            right = factor();
            left = ExprNode();
            left.op = CONST_ID;
            left.num = 0.0;
            right = MakeExprNode(MINUS,left,right);
        case _=>
            right = component();
    }
    return right;
}
//Component → Atom [ POWER Component ]
func component():ExprNode{ 
    var left:ExprNode;
    var right:ExprNode;
    left = atom();
    match (curtoken.tokentype){
        case POWER =>
            MatchToken(POWER);
            right = component();
            left = MakeExprNode(POWER,left,right);
        case _ => ()//仓颉nb
    }
    return left;
}
//Atom → CONST_ID 
//      | T 
//      | FUNC L_BRACKET Expression R_BRACKET 
//      | L_BRACKET Expression R_BRACKET
func atom():ExprNode{ 
    var t:Token = curtoken;
    var node:ExprNode = ExprNode();
    match(t.tokentype){
        case CONST_ID =>
            MatchToken(CONST_ID);
            node = MakeExprNode(CONST_ID,t.value);
        case T =>
            MatchToken(T);
            node = MakeExprNode(T);
        case FUNC =>
            MatchToken(FUNC);
            MatchToken(L_BRACKET);
            node = MakeExprNode(FUNC,t.Func,expression());
            MatchToken(R_BRACKET);
        case L_BRACKET =>
            MatchToken(L_BRACKET);
            node = expression();
            MatchToken(R_BRACKET);
        case _ => wa(2);
    }
    return node;
}

//MakeNode函数
//各个节点的构造函数
//二元运算符
func MakeExprNode(op:TokenType,left:ExprNode,right:ExprNode):ExprNode{
    var node:ExprNode = ExprNode();
    node.op = op;
    node.left = left;
    node.right = right;
    return node;
}
//num
func MakeExprNode(op:TokenType,num:Float64){
    var node:ExprNode = ExprNode();
    node.op = op;
    node.num = num;
    return node;
}
//T
func MakeExprNode(op:TokenType){
    var node:ExprNode = ExprNode();
    node.op = op;
    return node;
}
//FUNC
func MakeExprNode(op:TokenType,mfunc:?(Float64)->Float64,funcchild:ExprNode){
    var node:ExprNode = ExprNode();
    node.op = op;
    node.mfunc = mfunc;
    node.funcchild = funcchild;
    return node;
}


//---------------------------辅助函数-------------------------
//获取下一个token
func FetchToken(){
    curtoken = getNextToken();
    if(curtoken.tokentype == ERRTOKEN){
        wa(1);
    }
}
//匹配token
func MatchToken(expect:TokenType){
    if(curtoken.tokentype != expect){
        wa(expect);
    }else{
        for(_ in 0..indentcnt){
            print("  ");
        }
        println("matchtoken ${getTokenTypeName(curtoken.tokentype)}");
    }
    FetchToken();
}

//词法分析器入口
public func Parse(filePath:Path,bmpName:String){
    if(initparser(filePath) == 0){
        return;
    }
    FetchToken();
    program();
    closeparser(bmpName);
}
//初始化词法分析器
func initparser(filePath:Path):Int64{
    indentcnt = 0;
    return initscanner(filePath);
}
//关闭词法分析器
func closeparser(bmpName:String){
    closescanner();
    //保存bmp
    saveImage(bmpName);
}



//---------------------------------打印函数-----------------------------
func printExprtree(node:ExprNode){ 
    for (i in 0..indentcnt){
        print("  ");
    }
    println("Expr Tree:");
    node.printtree(0,true,"".padEnd(indentcnt*2+4, padding:" "));
}
func enter(str:String){
    for(_ in 0..indentcnt){
        print("  ");
    }
    println("enter ${str}");
    indentcnt += 2;
}
func outer(str:String){
    indentcnt -= 2;
    for(_ in 0..indentcnt){
        print("  ");
    }
    println("outer ${str}");
}
