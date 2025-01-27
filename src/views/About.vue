<script setup lang="ts"></script>

<template>
    <div id="about">
        <a-row justify="center">
            <a-col :span="20">
                <a-page-header title="使用说明" @back="$router.back()">
                    <a-typography>
                        <a-typography-paragraph>
                            这是一个用于计算 Western Blot
                            上样修正的工具，可以帮助你根据内参情况计算出修正后的蛋白质上样量。
                        </a-typography-paragraph>
                        <a-typography-title :heading="6"
                            >方法与步骤</a-typography-title
                        >
                        <a-typography-paragraph>
                            <ol>
                                <li>
                                    点击左上角的“添加”按钮，添加一条新的内参数据。
                                </li>
                                <li>
                                    点击“从剪贴板导入”按钮，将剪贴板中的数据导入到内参列表中。
                                </li>
                                <li>点击内参列表中的某一行，即可选中该行。</li>
                                <li>
                                    点击“删除”按钮，即可删除选中的内参数据。
                                </li>
                                <li>
                                    在“蛋白质上样量”输入框中输入蛋白质的上样量。
                                </li>
                                <li>
                                    点击“计算”按钮，即可计算出修正后的蛋白质上样量。
                                </li>
                                <li>
                                    计算结果的上方滑动条可以动态调整最终上样量。
                                </li>
                            </ol>
                        </a-typography-paragraph>
                        <a-typography-title :heading="6"
                            >如何从剪贴板导入数据</a-typography-title
                        >
                        <a-typography-paragraph>
                            本应用目前支持从imageJ中测量的内参数据导入，数据格式如下：
                            <pre>
                                1  11111.1111
                                2  22222.2222
                                3  33333.3333
                            </pre>
                            其中，第一列为内参编号，第二列为内参的灰度值。将这样的数据复制到剪贴板中，点击“从剪贴板导入”按钮，即可将数据导入到内参列表中。
                        </a-typography-paragraph>
                        <a-typography-title :heading="6"
                            >重要说明</a-typography-title
                        >
                        <a-typography-paragraph>
                            <ol>
                                <li>
                                    理论上，任何符合上述格式的数据都可以导入。
                                </li>
                                <li>
                                    本应用不会对数据进行任何的校验，导入的数据将直接显示在内参列表中，请确保数据的正确性。
                                </li>
                                <li>
                                    本应用不会保存任何数据，刷新页面或关闭浏览器后数据将丢失。
                                </li>
                                <li>
                                    本应用仅供学习交流使用，不保证计算结果的准确性，如有疑问请参考相关文献或咨询专业人士。
                                </li>
                            </ol>
                        </a-typography-paragraph>
                    </a-typography>
                </a-page-header>
            </a-col>
        </a-row>
    </div>
</template>
