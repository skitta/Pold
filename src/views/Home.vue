<script setup lang="ts">
import { ref, computed } from "vue";
import { invoke } from "@tauri-apps/api/core";
import { TableRowSelection, Modal } from "@arco-design/web-vue";
import { useRouter } from "vue-router";

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
        // console.log(resp);
        data.value = JSON.parse(resp) as TableData[];
    } catch (error) {
        console.log("read clipboard with error:", error);
        Modal.error({
            title: "导入失败",
            content: "请确保剪贴板中有正确的数据",
        });
    }
};

const router = useRouter();
const handleHelp = () => {
    router.push({ name: "About" });
};
</script>

<template>
    <div id="home">
        <!-- title -->
        <a-row justify="center" style="margin-bottom: 20px">
            <a-col :span="18" style="text-align: center">
                <h1>Western Blot 上样修正计算器</h1>
            </a-col>
        </a-row>

        <a-row justify="center" style="margin-bottom: 5px">
            <!-- 左侧 -->
            <a-col :span="14">
                <a-space size="mini" direction="vertical" fill>
                    <!-- 左侧头部按钮 -->
                    <a-row justify="space-between" align="center">
                        <a-col :span="12">
                            <a-space align="start" size="mini">
                                <a-tooltip content="添加" mini>
                                    <a-button
                                        size="mini"
                                        type="outline"
                                        @click="handleAdd"
                                        ><template #icon><icon-plus /></template
                                    ></a-button>
                                </a-tooltip>
                                <a-tooltip content="从剪贴板导入" mini>
                                    <a-button
                                        type="outline"
                                        size="mini"
                                        @click="fetchClipboardData"
                                    >
                                        <template #icon
                                            ><icon-import
                                        /></template>
                                    </a-button>
                                </a-tooltip>
                                <a-tooltip content="删除" mini>
                                    <a-button
                                        type="outline"
                                        status="danger"
                                        size="mini"
                                        :disabled="selectedKeys.length === 0"
                                        @click="handleDel(selectedKeys)"
                                        ><template #icon
                                            ><icon-delete /></template
                                    ></a-button>
                                </a-tooltip>
                            </a-space>
                        </a-col>
                        <a-col :span="12" style="text-align: right">
                            <a-tooltip content="帮助" mini>
                                <a-button
                                    type="outline"
                                    size="mini"
                                    @click="handleHelp"
                                >
                                    <template #icon><icon-question /></template>
                                </a-button>
                            </a-tooltip>
                        </a-col>
                    </a-row>
                    <!-- 左侧表格 -->
                    <a-row>
                        <a-table
                            :columns="editable_columns"
                            :data="data"
                            :pagination="false"
                            :row-selection="rowSelection"
                            v-model:selectedKeys="selectedKeys"
                            style="width: 100%"
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
                                    style="width: 110px"
                                />
                            </template>
                        </a-table>
                    </a-row>
                </a-space>
            </a-col>

            <!-- 右侧 -->
            <a-col :span="5" :offset="1">
                <a-space size="mini" direction="vertical" fill>
                    <a-row>
                        <a-slider
                            v-model="target_value"
                            :min="minValue"
                            :max="maxValue"
                            style="display: inline-flex; height: 25px"
                            :disabled="slide_disabled"
                            :format-tooltip="
                                (value: number) => `目标灰度值：${value}`
                            "
                        />
                    </a-row>

                    <a-row>
                        <a-table
                            :columns="computed_columns"
                            :data="computedData"
                            :pagination="false"
                            style="width: 100%"
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
                    </a-row>
                </a-space>
            </a-col>
        </a-row>
    </div>
</template>
