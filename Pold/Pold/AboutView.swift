import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("如何导入数据")
                            .font(.headline)
                        Text("1. 在 ImageJ 或其他软件中复制蛋白质条带数据")
                        Text("2. 点击「从剪贴板导入」按钮")
                        Text("3. 数据将自动解析并填入表格")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("数据格式")
                            .font(.headline)
                        Text("支持 ImageJ 风格的文本格式，每行一个数据点：")
                        Text("  条带名称   数值")
                        Text("例如：")
                        Text("  Band1   100.5")
                        Text("  Band2   85.3")
                        Text("  Band3   92.1")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("体积计算原理")
                            .font(.headline)
                        Text("1. 系统计算所有数值的最小值、最大值和平均值")
                        Text("2. 平均值自动设为目标值")
                        Text("3. 每个条带的修改体积 = 目标值 ÷ (数值 ÷ 体积)")
                        Text("4. 拖动滑块可调整目标值，实时查看修改后的结果")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("表格操作")
                            .font(.headline)
                        Text("• 点击单元格可直接编辑名称和数值")
                        Text("• 使用 + / - 按钮添加或删除数据行")
                        Text("• 双击历史记录可重命名")
                        Text("• 点击垃圾桶图标可删除记录")
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
