<script setup lang="ts">
import { ref, computed } from "vue";
import { invoke } from "@tauri-apps/api/core";
import { TableRowSelection } from "@arco-design/web-vue";
import { IconPlus, IconDelete, IconImport } from "@arco-design/web-vue/es/icon";

//定义表格的数据类型
interface TableData {
    key: string;
    name: string;
    volumn: number;
    value: number;
}

//左侧可编辑表格的列定义
const editable_columns = [
    {
        title: "样品",
        dataIndex: "name",
        slotName: "name",
    },
    {
        title: "内参上样量",
        dataIndex: "volumn",
        slotName: "volumn",
    },
    {
        title: "内参灰度值",
        dataIndex: "value",
        slotName: "value",
    },
];

//右侧表格的列定义，该表格数据由左侧表格数据经计算参生
const computed_columns = [
    {
        title: "调整上样量",
        dataIndex: "modified_volumn",
        slotName: "modified_volumn",
    },
];

// 表格数据的响应变量
const data = ref<TableData[]>([]);

// 开启表格的选择功能
const rowSelection: TableRowSelection = {
    type: "checkbox",
    showCheckedAll: true,
};
// 绑定所选行的key
const selectedKeys = ref([]);

// slide相关响应变量
// slide绑定的是通过表格计算出的平均灰度值，调整该值可响应式调整上样量
const slide_disabled = ref(false);
const target_value = ref(0);
const minValue = ref(0);
const maxValue = ref(0);

// 计算单位体积的灰度值
// 计算平均灰度值、最大灰度值和最小灰度值
// 设置slide的值为平均灰度值
const computedData = computed(() => {
    if (data.value.length === 0) {
        target_value.value = 0;
        slide_disabled.value = true;
        return [];
    }

    slide_disabled.value = false;

    if (data.value.length < 2) {
        minValue.value = 0;
        maxValue.value = Math.round(data.value[0].value);
        target_value.value = maxValue.value;
    } else {
        minValue.value = Math.round(
            Math.min(...data.value.map((item) => item.value)),
        );
        maxValue.value = Math.round(
            Math.max(...data.value.map((item) => item.value)),
        );
        const total = data.value.reduce((sum, item) => sum + item.value, 0);
        const avg = total / data.value.length;
        target_value.value = Math.round(avg);
    }

    return data.value.map((item) => ({
        key: item.key,
        value_per_volumn: item.volumn > 0 ? item.value / item.volumn : 0,
    }));
});

const handleAdd = () => {
    data.value.push({
        key: String(data.value.length + 1),
        name: String(data.value.length + 1),
        volumn: 0,
        value: 0,
    });
};

const handleDel = (keys: string[]) => {
    data.value = data.value.filter((item) => !keys.includes(item.key));
    selectedKeys.value = [];
};

// 从剪贴板导入数据
// 目前实现特定场景下的imageJ测量数据
const fetchClipboardData = async () => {
    try {
        const resp = await invoke<string>("read_clipboard");
        console.log(resp);
        data.value = JSON.parse(resp) as TableData[];
    } catch (error) {
        console.log("read clipboard with error:", error);
    }
};
</script>

<template>
    <main class="container">
        <!-- title -->
        <a-row justify="center" style="margin-bottom: 20px">
            <a-col :span="18" style="text-align: center">
                <h1>Western Blot 上样修正计算器</h1>
            </a-col>
        </a-row>

        <!-- button -->
        <a-row justify="center" style="margin-bottom: 5px">
            <a-col :span="20">
                <a-row justify="space-between" align="center">
                    <a-col :span="5">
                        <a-space align="start" size="mini">
                            <a-tooltip content="添加" mini>
                                <a-button type="outline" @click="handleAdd"
                                    ><template #icon><icon-plus /></template
                                ></a-button>
                            </a-tooltip>
                            <a-tooltip content="从剪贴板导入" mini>
                                <a-button
                                    type="outline"
                                    @click="fetchClipboardData"
                                >
                                    <template #icon><icon-import /></template>
                                </a-button>
                            </a-tooltip>
                            <a-tooltip content="删除" mini>
                                <a-button
                                    type="outline"
                                    status="danger"
                                    :disabled="selectedKeys.length === 0"
                                    @click="handleDel(selectedKeys)"
                                    ><template #icon><icon-delete /></template
                                ></a-button>
                            </a-tooltip>
                        </a-space>
                    </a-col>
                    <a-col :span="5">
                        <a-slider
                            v-model="target_value"
                            :min="minValue"
                            :max="maxValue"
                            style="display: inline-flex"
                            :disabled="slide_disabled"
                            :format-tooltip="(value) => `目标灰度值：${value}`"
                        />
                    </a-col>
                </a-row>
            </a-col>
        </a-row>

        <!-- table -->
        <a-row justify="center" style="margin-bottom: 20px">
            <a-col :span="20">
                <a-row justify="space-between">
                    <a-col :span="18">
                        <a-table
                            :columns="editable_columns"
                            :data="data"
                            :pagination="false"
                            :row-selection="rowSelection"
                            v-model:selectedKeys="selectedKeys"
                        >
                            <template #volumn="{ record }">
                                <a-input-number
                                    v-model="record.volumn"
                                    :hide-button="true"
                                    style="width: 100px"
                                />
                            </template>
                            <template #value="{ record }">
                                <a-input-number
                                    v-model="record.value"
                                    :hide-button="true"
                                />
                            </template>
                        </a-table>
                    </a-col>
                    <a-col :span="5">
                        <a-table
                            :columns="computed_columns"
                            :data="computedData"
                            :pagination="false"
                        >
                            <template #modified_volumn="{ record }">
                                <div style="padding: 5px">
                                    {{
                                        record.value_per_volumn > 0
                                            ? Math.round(
                                                  target_value /
                                                      record.value_per_volumn,
                                              )
                                            : 0
                                    }}
                                </div>
                            </template>
                        </a-table>
                    </a-col>
                </a-row>
            </a-col>
        </a-row>
    </main>
</template>

<style>
:root {
    font-family: Inter, Avenir, Helvetica, Arial, sans-serif;
    font-size: 16px;
    line-height: 24px;
    font-weight: 400;

    color: #0f0f0f;
    background-color: #f6f6f6;

    font-synthesis: none;
    text-rendering: optimizeLegibility;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    -webkit-text-size-adjust: 100%;
}

.container {
    margin: 0;
    padding-top: 10vh;
    padding-bottom: 10vh;
    display: flex;
    flex-direction: column;
    /* justify-content: center; */
    /* text-align: center; */
}
</style>
