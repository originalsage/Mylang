// =============================================================================
// MyLang 错误处理与日志模块（Error Handling & Logging）
// 功能：统一错误报告（wa）与轻量日志输出（log），支持 Token 级错误定位
// 作者：李隆生（23009200365）
// 日期：2025-12-05
// 语言：仓颉（Cangjie）
// 依赖：需配合 Parser 模块（使用 curtoken 全局上下文）
// -----------------------------------------------------------------------------
// 核心接口：
//   - log(info: String)         // 简易控制台输出（无换行）
//   - wa(cas: Int64)            // 预定义错误码：1=非法字符，2=语法不匹配
//   - wa(expect: TokenType)     // 精确报错：显示实际输入 vs 期望 Token 类型
// -----------------------------------------------------------------------------
// 报错策略：
//   - 立即 throw Exception，终止当前解析流程（Fail-Fast）
//   - 错误信息含 lexeme 原始文本，便于定位问题输入
// =============================================================================
package Mylang
//打印信息
func log(info:String){
    print(info);
}
//error函数 1非法字符 2输入与预期不符
func wa(cas:Int64) {
    var msg:String = match (cas){
        case 1 => "输入非法字符:${curtoken.lexeme}";
        case 2 => "输入与预期不符:${curtoken.lexeme}";
        case _ => "未知错误"
    }
    throw Exception(msg);
}

func wa(expect:TokenType) {
    var msg:String = "输入与预期不符，输入:${curtoken.lexeme},预期:${getTokenTypeName(expect)}";
    throw Exception(msg);
}